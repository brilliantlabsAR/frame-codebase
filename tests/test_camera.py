"""
Tests the camera over Bluetooth.
Usage: JLinkRTTClient | tee tests/log.txt
After RTT log is dumped to file, keep only the spi data and run this script
"""

from PIL import Image, ImageDraw
import numpy as np

pixels = np.loadtxt("log.txt", dtype=int)

img = Image.new("RGB", (201, 201))

img1 = ImageDraw.Draw(img)

for i in range(0,200):
    for j in range(0,200):
        img1.rectangle([(j, i), (j+1, i+1)], fill = (int(pixels[i*200+j]) & 0xe0, int(int(pixels[i*200+j]) & 0x1e)*8, int(int(pixels[i*200+j]) & 0x03)*64))
img.save("camera_test.png", "PNG")