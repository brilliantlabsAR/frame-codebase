import numpy as np
from PIL import Image

frame_color_pallette = [
    [0, 0, 0],
    [255, 255, 255],
    [157, 157, 157],
    [190, 38, 51],
    [224, 111, 139],
    [73, 60, 43],
    [164, 100, 34],
    [235, 137, 49],
    [247, 226, 107],
    [47, 72, 78],
    [68, 137, 26],
    [163, 206, 39],
    [27, 38, 50],
    [0, 87, 132],
    [49, 162, 242],
    [178, 220, 239]
]

raw_data = []
with open('simulation/frame_buffer.txt', 'r') as f:
    for line in f.readlines():
        if ('//' not in line and 'x' not in line):
            raw_data.append(line.strip('\n'))

buffer = []
for idx, line in enumerate(raw_data):
    for i in range(7, -1, -1):
        val = int(line[i], 16)
        buffer.append(val)

frame_buffer = np.zeros((400, 640, 3))

for i in range(400):
    for j in range(640):
        idx = buffer[640*i+j]
        frame_buffer[i][j] = frame_color_pallette[idx]

frame_buffer = np.array(frame_buffer, np.uint8)
img = Image.fromarray(frame_buffer)
img.save('simulation/frame_buffer.png')