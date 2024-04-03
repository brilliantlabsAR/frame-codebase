"""
Simulates the auto-exposure control loop used in camera.auto()
"""

import asyncio
from frameutils import Bluetooth
import numpy as np
import matplotlib.pyplot as plt

image_buffer = b""
expected_length = 0

x = [0]
y = [0]
plt.ion()
plt.rcParams.update({'font.size': 18})
figure, ax = plt.subplots(figsize=(10,10))
line1, = ax.plot(x, y, linewidth=2)
ax.set_xlabel("frame")
ax.set_ylabel("gain")
 
async def plot():
    global x
    global y
    while True:
        line1.set_data(x, y)
        xmin, xmax = min(x), max(x)
        ymin, ymax = min(y), max(y)
        margin = (np.abs(ymax - ymin) / 10) + 0.1
        ax.set_xlim((xmin, xmax + 1))
        ax.set_ylim((ymin - margin, ymax + margin))
        figure.canvas.flush_events()
        await asyncio.sleep(0.05)

def update_graph(e):
    global x
    global y
    x.append(max(x)+1)
    y.append(float(e))

def escape_line(line):
    escape_seq = [('\n', '\\n'), 
                  ('\t', '\\t'), 
                  ("\'", "\\'")]

    for s in escape_seq:
        line = line.replace(s[0], s[1])
    
    return line
    
async def main():
    b = Bluetooth()

    await b.connect(
        print_response_handler=update_graph,
    )

    await b.send_break_signal()
    await b.send_lua("f=frame.file.open('main.lua', 'w')")

    with open('lua_script.lua', 'r') as f:
        for line in f.readlines():
            line = escape_line(line)
            await b.send_lua(f"f:write(\"{line}\")")

    await b.send_lua("f:close()")

    await asyncio.sleep(0.1)

    await b.send_reset_signal()

    plot_task = loop.create_task(plot())

    await plot_task

loop = asyncio.new_event_loop()
loop.run_until_complete(main())
