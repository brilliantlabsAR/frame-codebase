import os
import sys

with open('img.mem', 'r') as f:
    data = f.readlines()

with open('img.bin', 'wb') as f:
    for i in data:

        f.write(((int(i) & 0xff000000) >> 24).to_bytes(length=1, byteorder=sys.byteorder))
        f.write(((int(i) & 0x00ff0000) >> 16).to_bytes(length=1, byteorder=sys.byteorder))
        f.write(((int(i) & 0x0000ff00) >> 8).to_bytes(length=1, byteorder=sys.byteorder))
        f.write(((int(i) & 0x000000ff) >> 0).to_bytes(length=1, byteorder=sys.byteorder))

os.system("cat header.bin img.bin footer.bin > img.jpg")