from aioconsole import ainput
from frameutils import Bluetooth
import asyncio

image_buffer = b""


def receive_data(data):
    global image_buffer

    if len(data) == 1:
        with open("temp_focus_image.jpg", "wb") as f:
            f.write(image_buffer)
            image_buffer = b""
        return

    image_buffer += data[1:]
    print(
        f"Received {str(len(image_buffer)-1)} bytes. Press enter to finish      ",
        end="\r",
    )


async def main():

    lua_script = """
    local last_autoexp_time = 0
    local state = 'CAPTURE'
    local state_time = 0

    while true do
        if state == 'CAPTURE' then
            frame.camera.capture { quality_factor = 10 }
            state_time = frame.time.utc()
            state = 'WAIT'
        elseif state == 'WAIT' then
            if frame.time.utc() > state_time + 0.5 then
                state = 'SEND'
            end
        elseif state == 'SEND' then
            local i = frame.camera.read(frame.bluetooth.max_length() - 1)
            if (i == nil) then
                state = 'DONE'
            else
                while true do
                    if pcall(frame.bluetooth.send, '0' .. i) then
                        break
                    end
                end
            end
        elseif state == 'DONE' then
            while true do
                if pcall(frame.bluetooth.send, '0') then
                    break
                end
            end
            state = 'CAPTURE'
        end

        if frame.time.utc() - last_autoexp_time > 0.1 then
            frame.camera.auto { metering = 'CENTER_WEIGHTED', exposure = -0.5, exposure_limit = 5500 }
            last_autoexp_time = frame.time.utc()
        end
    end
    """

    # Connect to bluetooth and upload file
    b = Bluetooth()
    await b.connect(
        print_response_handler=lambda s: print(s), data_response_handler=receive_data
    )

    print("Uploading script")

    await b.send_break_signal()

    await b.send_lua("f=frame.file.open('main.lua', 'w')")

    for line in lua_script.splitlines():
        await b.send_lua(f'f:write("{line}\\n");print(nil)', await_print=True)

    await b.send_lua("f:close()")

    await asyncio.sleep(0.1)

    await b.send_reset_signal()

    # Wait until a keypress
    await ainput("")

    await b.send_break_signal()
    await b.disconnect()


loop = asyncio.new_event_loop()
loop.run_until_complete(main())
