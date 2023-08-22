# MicroPython for Frame

A custom deployment of MicroPython designed specifically for Frame. Check out the user docs [here](https://docs.brilliant.xyz).

For those of you who want to modify the standard firmware, keep on reading.

## Getting started with development

1. Ensure you have the [ARM GCC Toolchain](https://developer.arm.com/downloads/-/gnu-rm) installed.

1. Ensure you have the [nRF Command Line Tools](https://www.nordicsemi.com/Products/Development-tools/nrf-command-line-tools) installed.

1. Clone this repository along with submodules and build the mpy-cross toolchain:

    ```sh
    git clone https://github.com/brilliantlabsAR/frame-micropython.git
    cd frame-micropython

    git submodule update --init
    git -C frame_network_core/micropython submodule update --init lib/micropython-lib

    make -C frame_network_core/micropython/mpy-cross
    ```

1. Open the project in [VSCode](https://code.visualstudio.com).

    There are some build tasks already configured and ready for use. Access them by pressing `Ctrl-Shift-P` (`Cmd-Shift-P` on MacOS) → `Tasks: Run Task`.

    1. Build
    1. Build & Flash
    1. Clean
    1. Erase Chip
    1. Release

1. To enable IntelliSense, be sure to select the correct compiler from within VSCode. `Ctrl-Shift-P` (`Cmd-Shift-P` on MacOS) → `C/C++: Select IntelliSense Configuration` → `Use arm-none-eabi-gcc`.

## FPGA

For information on developing and flashing the FPGA binary. Check the [Frame FPGA](https://github.com/brilliantlabsAR/frame-fpga) repository.