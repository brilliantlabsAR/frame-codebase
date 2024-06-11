from frameutils import Bluetooth
import asyncio
import os

image_buffer = b""
done = False


def receive_data(data):
    global image_buffer
    global done

    if data[0] == 0x00:
        done = True
        return

    image_buffer += data[1:]
    print(
        f"                        Received {str(len(image_buffer)-1)} bytes. Press Ctrl-C when complete      ",
        end="\r",
    )


async def capture_and_download(b: Bluetooth):
    global image_buffer
    global done
    image_buffer = b""
    done = False

    await b.send_lua(f"frame.camera.capture()")

    for _ in range(3):
        await b.send_lua("frame.camera.auto{}")
        await asyncio.sleep(0.1)

    await b.send_lua(
        "while true do local i=frame.camera.read(frame.bluetooth.max_length()-1) if (i==nil) then break end while true do if pcall(frame.bluetooth.send,'\\x01'..i) then break end end end frame.sleep(0.1); frame.bluetooth.send('\\x00')"
    )

    while done == False:
        await asyncio.sleep(0.001)

    with open("temp_focus_image.jpg", "wb") as f:
        f.write(image_buffer)


if __name__ == "__main__":
    b = Bluetooth()

    try:
        loop = asyncio.new_event_loop()
        loop.run_until_complete(b.connect(data_response_handler=receive_data))

        while True:
            loop.run_until_complete(capture_and_download(b))

    except KeyboardInterrupt:
        os._exit(0)
