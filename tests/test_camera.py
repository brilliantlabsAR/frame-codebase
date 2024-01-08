"""
Tests the camera over Bluetooth.
"""

import asyncio
from frameutils import Bluetooth
import sys

ints = []
def add_to_log(response):
    global ints
    ints.extend([x for x in response])
    print(f"got {len(response)}")

async def main():
    dev = Bluetooth()
    await dev.connect (
        data_response_handler=add_to_log,
    )
    response = await dev.send_lua("print(frame.camera.capture())", await_print=True)
    print(response)
    await asyncio.sleep(0.5)
    for i in range(625):
        await dev.send_lua("frame.bluetooth.send(frame.camera.read(64))")
        await asyncio.sleep(0.05)
        print(i)
    await asyncio.sleep(1)
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