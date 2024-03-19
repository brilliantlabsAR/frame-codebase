"""
Tests the Frame specific Lua libraries over Bluetooth.
"""

import asyncio
from frameutils import Bluetooth
from PIL import Image
import numpy as np

image_buffer = b""

def receive_data(data):
    global image_buffer
    image_buffer += data

    print(data)
    print(
        f"Received {str(len(image_buffer))} bytes",
    )

async def jpeg(b):
    await b.send_lua("frame.camera.reset_jpeg()") # reset
    await b.send_lua("frame.camera.capture()") # capture
    await asyncio.sleep(1)
    await b.send_lua("size = frame.camera.jpeg_size()") # read jpeg size
    expected_length = int(float(await b.send_lua("print(size)", await_print=True)))
    return expected_length

async def download_jpeg(b, expected_length):
    global image_buffer

    await b.send_lua("while true do local i = frame.camera.read_jpeg(frame.bluetooth.max_length()) if (i == nil) then break end while true do if pcall(frame.bluetooth.send, i) then break end end end")
    
    while len(image_buffer) < expected_length:
        await asyncio.sleep(0.01)
    
    await b.send_lua("print('done')", await_print=True)
    with open('img.bin', 'wb') as f:
        f.write(image_buffer)
        f.flush()
    
async def download_rgb(b, expected_length):
    global image_buffer

    image_buffer = b""

    await b.send_lua("while true do local i = frame.camera.read(frame.bluetooth.max_length()) if (i == nil) then break end while true do if pcall(frame.bluetooth.send, i) then break end end end")

    while len(image_buffer) < expected_length:
        await asyncio.sleep(0.01)

    print("\nConverting to image")

    image_data = np.frombuffer(image_buffer, dtype=np.uint8)
    rgb_array = np.zeros((200, 200, 3), dtype=np.uint8)

    for y in range(200):
        for x in range(200):
            pixel = image_data[y * 200 + x]

            red = (pixel & 0b11100000) >> 5
            green = (pixel & 0b00011100) >> 2
            blue = pixel & 0b00000011

            red = (0b11111111 / 0b111) * red
            green = (0b11111111 / 0b111) * green
            blue = (0b11111111 / 0b11) * blue

            rgb_array[y, x] = [red, green, blue]

    image = Image.fromarray(rgb_array)
    image.show()

async def main():
    b = Bluetooth()

    await b.connect(data_response_handler=receive_data, print_response_handler=lambda s:print(s))

    await b.send_lua("frame.camera.set_exposure(800)")
    await b.send_lua("frame.camera.set_gain(200)")

    expected_length = await jpeg(b)
    await download_jpeg(b, expected_length)
    
    await b.disconnect()


asyncio.run(main())