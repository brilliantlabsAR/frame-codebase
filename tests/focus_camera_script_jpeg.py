from frameutils import Bluetooth
from PIL import Image
import asyncio
import numpy as np
import os
import sys

sys.path.append("../source/fpga/modules/camera/cocotb/jed")
sys.path.append("../source/fpga/modules/camera/cocotb/python_common")
import encoder

image_buffer = b""
expected_length = 0


def receive_data(data):
    global image_buffer
    global expected_length
    image_buffer += data
    print(
        f"                        Downloading camera data {str(len(image_buffer))} / {str(int(expected_length))} bytes. Press Ctrl-C when complete      ",
        end="\r",
    )


async def capture_and_download(b: Bluetooth, height, width):
    global image_buffer
    global expected_length

    await b.send_lua(f"frame.camera.capture()")
    await asyncio.sleep(0.5)

    # read jpeg_size, add 4 to get expected length of bit stream
    await b.send_lua("function get_jsize() ba = frame.fpga.read(0x31, 2); return (string.byte(ba, 2)<<8 | string.byte(ba, 1)) end")
    ecs_bytes = await b.send_lua("print(get_jsize())", await_print=True)
    ecs_bytes = 4 + int(ecs_bytes)
    expected_length = ecs_bytes

    image_buffer = b""

    await b.send_lua(
        "while true do local i = frame.camera.read(frame.bluetooth.max_length()) if (i == nil) then break end while true do if pcall(frame.bluetooth.send, i) then break end end end"
    )

    while len(image_buffer) < expected_length:
        await asyncio.sleep(0.001)

    image_data = np.frombuffer(image_buffer, dtype=np.uint8)

    # write ECS
    if False:
        file_name = f"ecs.{width}x{height}.bin"
        with open (file_name, 'wb') as f:
            f.write(bytearray(image_data))

    # assemble jpeg image
    jpg = encoder.writeJPG_header(height, width, 0)
    jpg.extend(image_data)
    jpg.extend(encoder.writeJPG_footer())
    file_name = f"img.{width}x{height}.jpg"
    with open (file_name, 'wb') as f:
        f.write(bytearray(jpg))


if __name__ == "__main__":
    b = Bluetooth()

    try:
        loop = asyncio.new_event_loop()
        loop.run_until_complete(b.connect(data_response_handler=receive_data))


        while True:
            loop.run_until_complete(
                b.send_lua("frame.camera.auto(true, 'center_weighted')")
            )
            loop.run_until_complete(asyncio.sleep(1))
            loop.run_until_complete(capture_and_download(b, 480, 640))

    except KeyboardInterrupt:
        os._exit(0)
