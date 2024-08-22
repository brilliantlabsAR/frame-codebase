import asyncio
import collections
import time
from aioconsole import ainput
from frameutils import Bluetooth

total_data_received = 0
last_data_time = time.time()


def receive_data(data):
    global total_data_received
    global last_data_time
    total_data_received += len(data)

    if len(data) == 0:
        throughput = total_data_received / (time.time() - last_data_time)
        last_data_time = time.time()
        total_data_received = 0
        print(f"Throughput: {throughput/1000:.2f} KB/s")


async def main():

    lua_script = """
    function send_data(data)
        while true do 
            if (pcall(frame.bluetooth.send, data)) then
                break
            end
        end
    end

    data = string.rep('a',frame.bluetooth.max_length())
    
    while true do 
        for i = 1, 100 do send_data(data) end
        send_data('')
    end
    """

    b = Bluetooth()

    await b.connect(data_response_handler=receive_data)

    print("Testing throughput")
    print("Press Enter to quit")

    await b.upload_file(lua_script, "main.lua")
    await b.send_reset_signal()

    # Wait until a keypress
    await ainput("")

    await b.send_break_signal()
    await b.disconnect()


asyncio.run(main())
