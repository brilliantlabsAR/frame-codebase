"""
Simulates the auto-exposure control loop used in camera.auto()
"""

import asyncio
from frameutils import Bluetooth
from PIL import Image
import numpy as np

image_buffer = b""
expected_length = 0


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

    await b.connect(
        data_response_handler=receive_data,
        print_response_handler=lambda s: print(s),
    )

    # Get initial values of the currently set exposure and gain
    await b.send_lua("exposure = 800")
    await b.send_lua("gain = 240")

    while True:

        await b.send_lua("resp = frame.camera.get_brightness()")

        # Calculate the average brightness
        await b.send_lua("r = resp['r']")
        await b.send_lua("g = resp['g']")
        await b.send_lua("b = resp['b']")
        await b.send_lua("current = (r + g + b) / 3")

        # Calculate the error value
        await b.send_lua("target = 175")
        await b.send_lua("error = target - current")

        # Apply P gains to exposure and gain
        await b.send_lua("exposure = exposure + (error * 1.5)")
        await b.send_lua("gain = gain + (error * 0.3)")

        # Limit the values
        await b.send_lua("if exposure > 800 then exposure = 800 end")
        await b.send_lua("if exposure < 20 then exposure = 20 end")

        await b.send_lua("if gain > 255 then gain = 255 end")
        await b.send_lua("if gain < 0 then gain = 0 end")

        await b.send_lua(
            "print('current = '..tostring(current)..', error = '..tostring(error)..', exposure = '..tostring(exposure)..', gain = '..tostring(gain))"
        )

        # Set the new values
        await b.send_lua("frame.camera.set_exposure(math.floor(exposure + 0.5))")
        await b.send_lua("frame.camera.set_gain(math.floor(gain + 0.5))")

        # Capture an image once the values have had a chance to take affect
        await asyncio.sleep(0.1)
        await capture_and_download(b, 200, 200)

    await b.disconnect()


asyncio.run(main())
