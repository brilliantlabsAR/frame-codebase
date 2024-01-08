"""
Tests the Frame specific Lua libraries over Bluetooth.
"""

import asyncio
from frameutils import Bluetooth


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


async def capture_and_download(b: Bluetooth):
    global image_buffer
    global expected_length

    print(f"Capturing image")
    await b.send_lua(f"frame.camera.capture()")
    await asyncio.sleep(0.5)

    expected_length = 200 * 200

    image_buffer = b""

    mtu = b.max_data_payload()

    while len(image_buffer) < expected_length:
        await b.send_lua(f"frame.bluetooth.send(frame.camera.read({mtu}))")

    print("\nConverting to image")

    raise NotImplementedError("TODO")


async def main():
    b = Bluetooth()

    await b.connect(data_response_handler=receive_data)

    await capture_and_download(b)

    await b.disconnect()


asyncio.run(main())
