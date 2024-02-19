"""
Tests the camera libraries over Bluetooth.
"""

import asyncio
from frameutils import Bluetooth
from PIL import Image
import numpy as np
import cv2

image_buffer = b""
expected_length = 0
COLORMODE = "YUV"
# COLORMODE = "RGB"

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

    print(f"Capturing image")
    await b.send_lua(f"frame.camera.capture()")
    await asyncio.sleep(0.5)

    expected_length = height * width

    image_buffer = b""

    mtu = b.max_data_payload()

    while len(image_buffer) < expected_length:
        await b.send_lua(f"frame.bluetooth.send(frame.camera.read({mtu}))")

    print("\nConverting to image")

    image_data = np.frombuffer(image_buffer, dtype=np.uint8)
    rgb_array = np.zeros((height, width, 3), dtype=np.uint8)
    yuv_array = np.zeros((height, width, 3), dtype=np.uint8)

    if COLORMODE == "RGB":
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
    
    elif COLORMODE == "YUV": 
        for y in range(height):
            for x in range(width):
                pixel = image_data[y * width + x]
                
                Y = (pixel & 0b11110000) >> 4
                Cb = (pixel & 0b00001100) >> 2
                Cr = pixel & 0b00000011

                Y = (0b11111111 / 0b1111) * Y
                Cb = (0b11111111 / 0b11) * Cb
                Cr = (0b11111111 / 0b11) * Cr

                yuv_array[y, x] = [Y, Cb, Cr]

        rgb_array = cv2.cvtColor(yuv_array, cv2.COLOR_YUV2RGB)

    image = Image.fromarray(rgb_array)
    image.show()

# gain = 16
gain = 48
exposure = 25000 #us
MAX = 8000
MIN = 1000

async def update_camera(b):
    await b.send_lua(f"frame.camera.set_register({int(0x3500)}, {int((exposure >> 12) & 0xff)})")
    await b.send_lua(f"frame.camera.set_register({int(0x3501)}, {int((exposure >> 4) & 0xff)})")
    await b.send_lua(f"frame.camera.set_register({int(0x3502)}, {int(exposure & 0xf) << 4}")
    
    await b.send_lua(f"frame.camera.set_register({int(0x350a)}, {int(0x00)})")
    await b.send_lua(f"frame.camera.set_register({int(0x350b)}, {int(gain & 0xff)})")

    await asyncio.sleep(0.2)

async def main():
    b = Bluetooth()
    global gain
    global exposure

    await b.connect(data_response_handler=receive_data)

    await update_camera(b)
    response = await b.send_lua(f"print(frame.camera.brightness())", await_print=True)
    print(f"gain {gain} exposure {exposure} -> {response}")
        
    await capture_and_download(b, 180, 180)

    await b.disconnect()

asyncio.run(main())
