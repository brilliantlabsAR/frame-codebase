"""
Tests the camera over Bluetooth.
"""

import asyncio
from frameutils import Bluetooth
from time import sleep

ints = []
def add_to_log(response):
    global ints
    ints.extend([x for x in response])

async def main():
    dev = Bluetooth()
    await dev.connect (
        data_response_handler=add_to_log,
    )
    await dev.send_reset_signal()
    await asyncio.sleep(0.1)
    await dev.send_lua("frame.camera.capture()")
    await asyncio.sleep(1)
    for i in range(625):
        await dev.send_lua("frame.bluetooth.send(frame.camera.read(64))", await_print=True)
        print(i)
    with open('log.txt', 'w') as f:
        for x in ints:
            f.write(str(x)+'\n')
    await dev.disconnect()
    

asyncio.run(main())

from PIL import Image, ImageDraw
import numpy as np

pixels = np.loadtxt("log.txt", dtype=int)

img = Image.new("RGB", (201, 201))

img1 = ImageDraw.Draw(img)

for i in range(0,200):
    for j in range(0,200):
        img1.rectangle([(j, i), (j+1, i+1)], fill = (int(pixels[i*200+j]) & 0xe0, int(int(pixels[i*200+j]) & 0x1e)*8, int(int(pixels[i*200+j]) & 0x03)*64))
img.save("camera_test.png", "PNG")