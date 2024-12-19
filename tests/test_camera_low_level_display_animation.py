from aioconsole import ainput
from frameutils import Bluetooth
import asyncio
import time
import math

image_buffer = b""
last_fps_time = time.time()
fps = 0


def receive_data(data):
    global image_buffer
    global last_fps_time
    global fps

    if len(data) == 1:
        with open("temp_focus_image.jpg", "wb") as f:
            f.write(header + image_buffer)
            image_buffer = b""
            fps = 1 / (time.time() - last_fps_time)
            last_fps_time = time.time()
        return

    image_buffer += data[1:]
    print(
        f"\rReceived {str(len(image_buffer)-1)} bytes. FPS = {fps}. Press enter to finish      ",
        end="",
    )


async def main():
    # Connect to bluetooth
    b = Bluetooth()
    print("Connect Bluetooth")
    
    lua_script = """
    while false do
    end
    """

    await b.connect(
        # print_response_handler=lambda s: print("\r" + s, end=""),
        data_response_handler=receive_data,
    )
    await b.upload_file(lua_script, "main.lua")

    print("Send reset")
    await b.send_reset_signal()

    async def rr(a):
        r = await b.send_lua(f'print(string.byte(frame.fpga_read(0x{a:02X}, 1), 1))', await_print=True)
        return int(r)
        
    async def rr_(a):
        r = await rr(a)
        print(hex(a), hex(r))
        return r

    # Read ID
    print("Read ID")
    await rr_(0xdb)

    # Check PLL lock flag
    print("Check PLL lock flag")
    while True:
        lock = await rr_(0x41)
        if lock:
            break

    # Display buffer
    buf = await rr_(0x18)    

    # Animation 16x16 block
    for i in range(100):
        x_pos = 250 + int(150*math.sin(-2*math.pi*i/20))
        y_pos = 175 + int(150*math.cos(2*math.pi*i/20))

        sprite_cmd = [x_pos>>8, x_pos & 0xff, y_pos>>8, y_pos & 0xff, 0, 16, 2, 0] + [0xff]*32
        sprite_cmd = ''.join([f"\\{j}" for j in sprite_cmd])
        sprite_cmd = f"frame.fpga_write(0x12, \"{sprite_cmd}\")"

        timeout = 0;
        while True:        
            await b.send_lua(sprite_cmd)
            time.sleep(0.05)
     
            print(f"Switch Display buffer {buf} -> {1-buf}")
            await b.send_lua(f'frame.fpga_write(0x14, "")')
            time.sleep(0.05)

            while True:
                new_buf = await rr_(0x18)
                if new_buf in [0, 1]:
                    break
            if new_buf != buf:
                buf = new_buf
                break
            timeout += 1;
            if timeout > 5:
                raise Exception

    await b.upload_file(lua_script, "main.lua")
    print("Send reset")
    await b.send_reset_signal()

    # Wait until a keypress
    print("Wait until a keypress")
    await ainput("")

    await b.send_break_signal()
    await b.disconnect()


loop = asyncio.new_event_loop()
loop.run_until_complete(main())
