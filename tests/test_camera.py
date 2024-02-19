"""
Tests the Frame specific Lua libraries over Bluetooth.
"""

import asyncio
from frameutils import Bluetooth
from PIL import Image
import numpy as np

image_buffer = b""
expected_length = 0
COLORMODE = "YUV"


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

    for y in range(height):
        for x in range(width):
            pixel = image_data[y * width + x]

            if COLORMODE == "YUV":
                Y = (pixel & 0b11110000) >> 4
                U = (pixel & 0b00001100) >> 2
                V = (pixel & 0b00000011)

                Y = (0b11111111 / 0b1111) * Y
                U = (0b11111111 / 0b11) * U
                V = (0b11111111 / 0b11) * V

                red = Y + 1.140*V
                green = Y - 0.395*U - 0.581*V
                blue = Y + 2.032*U
            else:
                red = (pixel & 0b11100000) >> 5
                green = (pixel & 0b00011100) >> 2
                blue = pixel & 0b00000011

                red = (0b11111111 / 0b111) * red
                green = (0b11111111 / 0b111) * green
                blue = (0b11111111 / 0b11) * blue

            rgb_array[y, x] = [red, green, blue]

    image = Image.fromarray(rgb_array)
    image.show()

gain = 46
exposure = 20000 #us
MAX = 35000
MIN = 25000

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
    response = await b.send_lua(f"print(frame.camera.read_counts())", await_print=True)
    print(f"gain {gain} exposure {exposure} -> {response}")

    while (int(response) > MAX or int(response) < MIN):
        if (int(response) > MAX):
            if exposure < 45000:
                exposure += 2500
            else: 
                if gain <= 228:
                    gain += 20
                else:
                    print("val at max")
                    break
        elif (int(response) < MIN):
            if gain >= 26:
                gain -= 20
            else: 
                if exposure > 15000:
                    exposure -= 2500
                else:
                    print("val at min")
                    break
        
        else:
            break

        await update_camera(b)
        response = await b.send_lua(f"print(frame.camera.read_counts())", await_print=True)
        print(f"gain {gain} exposure {exposure} -> {response}")
        
    await capture_and_download(b, 200, 200)

    await b.disconnect()

asyncio.run(main())
