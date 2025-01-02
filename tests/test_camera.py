from aioconsole import ainput
from frameutils import Bluetooth
import asyncio
import time

image_buffer = b""
image_suffix = 1


def receive_data(data):
    global image_buffer
    global image_suffix

    if len(data) == 1:
        with open(f"test_camera_image_{image_suffix}.jpg", "wb") as f:
            print(f"Image {image_suffix} - Received {str(len(image_buffer)-1)} bytes")
            f.write(image_buffer)
            image_buffer = b""
            image_suffix += 1
        return

    image_buffer += data[1:]


async def main():

    lua_script = """

    function transfer()
        while frame.camera.image_ready() == false do
            -- wait
        end

        while true do
            local i = frame.camera.read(frame.bluetooth.max_length() - 1)
            if (i == nil) then
                break
            else
                while true do
                    if pcall(frame.bluetooth.send, '0' .. i) then
                        break
                    end
                end
            end
        end

        while true do
            if pcall(frame.bluetooth.send, '0') then
                break
            end
        end
    end

    frame.display.power_save(true)
    frame.camera.power_save(false)

    frame.camera.set_gain(40)
    frame.camera.set_shutter(2500)

    frame.camera.capture { resolution = 100, quality = 'VERY_HIGH' }; transfer()
    frame.camera.capture { resolution = 100, quality = 'HIGH' }; transfer()
    frame.camera.capture { resolution = 100, quality = 'MEDIUM' }; transfer()
    frame.camera.capture { resolution = 100, quality = 'LOW' }; transfer()
    frame.camera.capture { resolution = 100, quality = 'VERY_LOW' }; transfer()

    frame.camera.capture { resolution = 256, quality = 'VERY_HIGH' }; transfer()
    frame.camera.capture { resolution = 256, quality = 'HIGH' }; transfer()
    frame.camera.capture { resolution = 256, quality = 'MEDIUM' }; transfer()
    frame.camera.capture { resolution = 256, quality = 'LOW' }; transfer()
    frame.camera.capture { resolution = 256, quality = 'VERY_LOW' }; transfer()

    frame.camera.capture { resolution = 512, quality = 'VERY_HIGH' }; transfer()
    frame.camera.capture { resolution = 512, quality = 'HIGH' }; transfer()
    frame.camera.capture { resolution = 512, quality = 'MEDIUM' }; transfer()
    frame.camera.capture { resolution = 512, quality = 'LOW' }; transfer()
    frame.camera.capture { resolution = 512, quality = 'VERY_LOW' }; transfer()

    frame.camera.capture { resolution = 720, quality = 'VERY_HIGH' }; transfer()
    frame.camera.capture { resolution = 720, quality = 'HIGH' }; transfer()
    frame.camera.capture { resolution = 720, quality = 'MEDIUM' }; transfer()
    frame.camera.capture { resolution = 720, quality = 'LOW' }; transfer()
    frame.camera.capture { resolution = 720, quality = 'VERY_LOW' }; transfer()

    print("Done - Press enter to finish")
    """

    # Connect to bluetooth and upload file
    b = Bluetooth()
    await b.connect(
        print_response_handler=lambda s: print(s),
        data_response_handler=receive_data,
    )

    print("Uploading script")

    await b.upload_file(lua_script, "main.lua")
    await b.send_reset_signal()

    # Wait until a keypress
    await ainput("")

    await b.send_break_signal()
    await b.disconnect()


loop = asyncio.new_event_loop()
loop.run_until_complete(main())
