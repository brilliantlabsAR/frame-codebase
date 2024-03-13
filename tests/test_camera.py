"""
Tests the Frame specific Lua libraries over Bluetooth.
"""

import asyncio
from frameutils import Bluetooth
from PIL import Image
import numpy as np

image_buffer = b""
expected_length = 40000


def receive_data(data):
    global image_buffer
    global expected_length
    image_buffer += data
    print(
        f"Received {str(len(image_buffer))} / {str(int(expected_length))} bytes",
        end="\r",
    )


async def capture_and_download(b: Bluetooth, height, width):
    global image_buffer
    global expected_length
    image_buffer = b""

    print("Auto exposing")
    await b.send_lua(
        "for i=1,25 do frame.camera.auto(); frame.sleep(0.033) end print(nil)",
        await_print=True,
    )

    print("Capturing image")
    await b.send_lua("frame.camera.capture()")
    await asyncio.sleep(0.5)

    print("Downloading image")
    await b.send_lua(
        "while true do local i = frame.camera.read(frame.bluetooth.max_length()) if (i == nil) then break end while true do if pcall(frame.bluetooth.send, i) then break end end end"
    )

    while len(image_buffer) < expected_length:
        await asyncio.sleep(0.001)

    print("\nConverting to image")

    image_data = np.frombuffer(image_buffer, dtype=np.uint8)
    rgb_array = np.zeros((height, width, 3), dtype=np.uint8)

    for y in range(height):
        for x in range(width):
            pixel = image_data[y * width + x]

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

    await b.connect(data_response_handler=receive_data)

    await capture_and_download(b, 200, 200)

    await b.disconnect()


asyncio.run(main())
