import numpy as np

max_pixel = 256  # 256 for 8bit, 1024 for 10bit
in_signal = np.arange(max_pixel) / (max_pixel - 1)
out_signal_601 = (in_signal > 0.018) * (1.099 * in_signal**0.45 - 0.099) + (
    in_signal <= 0.018
) * (4.5 * in_signal)
out_lut = (out_signal_601 * (max_pixel - 1)).astype(int)

for i in range(len(out_lut)):
    print(
        f"gamma_rom_r[{i}] = 'd{out_lut[i]}; gamma_rom_g[{i}] = 'd{out_lut[i]}; gamma_rom_b[{i}] = 'd{out_lut[i]};"
    )
