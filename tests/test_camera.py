"""
Tests the camera over Bluetooth.
Usage: JLinkRTTClient | tee tests/log.txt
After RTT log is dumped to file, keep only the spi data and run this script
"""

import asyncio
from frameutils import Bluetooth
from time import sleep

class Dev(Bluetooth):
    def __init__(self):
        self.ints = []

    async def lua_resp(self, send: str):
        response = await self.send_lua(f"print({send})", await_print=True)
        print(response)

    async def lua_log(self, send: str):
        response = await self.send_lua(f"print({send})", await_print=True)
        self.ints.extend(list(map(ord, response)))
        print(str(response.__len__())+" bytes")

async def main():
    dev = Dev()
    await dev.connect()
    await dev.lua_resp("frame.camera.capture()")
    await asyncio.sleep(1)
    for i in range(625):
        await dev.lua_log("frame.camera.read(64)")
        await asyncio.sleep(0.1)
    with open('log.txt', 'w') as f:
        for x in dev.ints:
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