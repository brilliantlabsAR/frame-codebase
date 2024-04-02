import numpy as np
import cv2
import sys

with open(sys.argv[1], "rb") as f:
    i = np.load(f);
cv2.imwrite(sys.argv[2], i)

