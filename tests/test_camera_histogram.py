from frameutils import Bluetooth
import asyncio
import matplotlib.pyplot as plt
import numpy as np
from aioconsole import ainput

image_buffer = b""
done = False
red_bars = None
green_bars = None
blue_bars = None
avg_bars = None

lua_script_b = """
count = 0
while count < 20 do
h = frame.camera.histogram()
print('r:'..h['r'][0]..':'..h['r'][1]..':'..h['r'][2]..':'..h['r'][3]..':'..h['r'][4]..':'..h['r'][5]..':'..h['r'][6]..':'..h['r'][7])
print('g:'..h['g'][0]..':'..h['g'][1]..':'..h['g'][2]..':'..h['g'][3]..':'..h['g'][4]..':'..h['g'][5]..':'..h['g'][6]..':'..h['g'][7])
print('b:'..h['b'][0]..':'..h['b'][1]..':'..h['b'][2]..':'..h['b'][3]..':'..h['b'][4]..':'..h['b'][5]..':'..h['b'][6]..':'..h['b'][7])
print('a:'..h['a'][0]..':'..h['a'][1]..':'..h['a'][2]..':'..h['a'][3]..':'..h['a'][4]..':'..h['a'][5]..':'..h['a'][6]..':'..h['a'][7])
count = count + 1
frame.sleep(0.4)
end
"""

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

    # print("Exposing")
    # await b.send_lua("frame.camera.set_gain(10)")
    # await b.send_lua("frame.camera.set_shutter(16300)")

    print("Capturing image")
    await b.send_lua("frame.camera.capture()")
    await asyncio.sleep(2)

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
    global red_bars
    global green_bars
    global blue_bars
    global avg_bars

    figure, ax = plt.subplots(4, 1, sharex=True)
    x = np.linspace(0, 8, 8)
    red_val = np.linspace(0, 8, 8)
    green_val = np.linspace(0, 8, 8)
    blue_val = np.linspace(0, 8, 8)
    avg_val = np.linspace(0, 8, 8)
    red_bars = ax[0].bar(x, red_val, color='red')
    green_bars = ax[1].bar(x, green_val, color='green')
    blue_bars = ax[2].bar(x, blue_val, color='blue')
    avg_bars = ax[3].bar(x, avg_val, color='black')

    def update_graph(response: str):
        global red_bars
        global green_bars
        global blue_bars
        global avg_bars

        data = response.split(":")
        color = data[0]
        data = data[1:]
        data = [float(i) for i in data]

        if color == 'r':
            red_bars.remove()
            red_bars = ax[0].bar(x, data, color='red', label='red')
        elif color == 'g':
            green_bars.remove()
            green_bars = ax[1].bar(x, data, color='green', label='green')
        elif color == 'b':
            blue_bars.remove()
            blue_bars = ax[2].bar(x, data, color='blue', label='blue')
        elif color == 'a':
            avg_bars.remove()
            avg_bars = ax[3].bar(x, data, color='black', label='average')

        print(f'{color} : {data}')
        plt.pause(0.001)

    b = Bluetooth()

    await b.connect(data_response_handler=receive_data, print_response_handler=update_graph)

    await b.send_break_signal()

    # await capture_and_download(b)

    # await b.send_lua("h = frame.camera.histogram()")
    # await b.send_lua("print('r:'..h['r'][0]..':'..h['r'][1]..':'..h['r'][2]..':'..h['r'][3]..':'..h['r'][4]..':'..h['r'][5]..':'..h['r'][6]..':'..h['r'][7])")
    # await b.send_lua("print('g:'..h['g'][0]..':'..h['g'][1]..':'..h['g'][2]..':'..h['g'][3]..':'..h['g'][4]..':'..h['g'][5]..':'..h['g'][6]..':'..h['g'][7])")
    # await b.send_lua("print('b:'..h['b'][0]..':'..h['b'][1]..':'..h['b'][2]..':'..h['b'][3]..':'..h['b'][4]..':'..h['b'][5]..':'..h['b'][6]..':'..h['b'][7])")
    # await b.send_lua("print('a:'..h['a'][0]..':'..h['a'][1]..':'..h['a'][2]..':'..h['a'][3]..':'..h['a'][4]..':'..h['a'][5]..':'..h['a'][6]..':'..h['a'][7])")

    print("Uploading script")
    await b.send_lua("f=frame.file.open('main.lua', 'w')")
    for line in lua_script_b.splitlines():
        await b.send_lua(f'f:write("{line.replace("'", "\\'")}\\n");print(nil)', await_print=True)
    await b.send_lua("f:close()")
    await asyncio.sleep(0.1)
    await b.send_reset_signal()

    # Wait until a keypress
    await ainput("Press enter to exit")

    await b.send_break_signal()

    await capture_and_download(b)

    await b.disconnect()



loop = asyncio.new_event_loop()
loop.run_until_complete(main())

plt.show()
