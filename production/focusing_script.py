from frameutils import Bluetooth
from PIL import Image
import asyncio
import numpy as np
import os

image_buffer = b""
expected_length = 0


def receive_data(data):
    global image_buffer
    global expected_length
    image_buffer += data
    print(
        f"                        Received {str(len(image_buffer))} / {str(int(expected_length))} bytes",
        end="\r",
    )


async def capture_and_download(b: Bluetooth, height, width):
    global image_buffer
    global expected_length

    await b.send_lua(f"frame.camera.capture()")
    await asyncio.sleep(0.5)

    expected_length = height * width

    image_buffer = b""

    mtu = b.max_data_payload()

    while len(image_buffer) < expected_length:
        await b.send_lua(f"frame.bluetooth.send(frame.camera.read({mtu}))")

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
    image.save("production/temp_focus_image.jpg")


if __name__ == "__main__":
    b = Bluetooth()

    try:
        loop = asyncio.get_event_loop()
        loop.run_until_complete(b.connect(data_response_handler=receive_data))

        while True:
            loop.run_until_complete(capture_and_download(b, 200, 200))

    except KeyboardInterrupt:
        os._exit(0)
