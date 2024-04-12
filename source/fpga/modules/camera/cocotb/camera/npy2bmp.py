#
# Authored by: Robert Metchev / Chips & Scripts (rmetchev@ieee.org)
#
# CERN Open Hardware Licence Version 2 - Permissive
#
# Copyright (C) 2024 Robert Metchev
#
import numpy as np
import cv2
import sys

with open(sys.argv[1], "rb") as f:
    i = np.load(f);
cv2.imwrite(sys.argv[2], i)

