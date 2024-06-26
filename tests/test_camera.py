from frameutils import Bluetooth
import asyncio

image_buffer = b""
done = False


def receive_data(data):
    global image_buffer
    global done

    if data[0] == 0x00:
        done = True
        return

    image_buffer += data[1:]
    print(f"Received {str(len(image_buffer)-1)} bytes", end="\r")


async def capture_and_download(b: Bluetooth):
    global image_buffer
    global done
    image_buffer = b""
    done = False

    print("Capturing image")
    await b.send_lua("frame.camera.set_shutter(50)")
    await b.send_lua("frame.camera.set_gain(0)")
    await asyncio.sleep(0.1)
    await b.send_lua("frame.camera.capture{quality_factor=10}")
    await asyncio.sleep(0.5)

    print("Downloading image")
    await b.send_lua(
        "while true do local i=frame.camera.read(frame.bluetooth.max_length()-1) if (i==nil) then break end while true do if pcall(frame.bluetooth.send,'\\x01'..i) then break end end end frame.sleep(0.1); frame.bluetooth.send('\\x00')"
    )

    while done == False:
        await asyncio.sleep(0.001)

    print("\nDone. Saving image")

    with open("test_camera_image.jpg", "wb") as f:
        f.write(image_buffer)


async def main():
    b = Bluetooth()

    await b.connect(
        data_response_handler=receive_data, print_response_handler=lambda s: print(s)
    )

    await capture_and_download(b)

    await b.disconnect()


asyncio.run(main())
