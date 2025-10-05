# Frame Firmware & RTL Codebase

Welcome to the complete codebase of the Frame hardware. For regular usage, check out the docs [here](https://docs.brilliant.xyz).

## System architecture

The codebase is split into three sections. The **nRF52 Application**, the **nRF52 Bootloader**, and the **FPGA RTL**. 

The nRF52 is designed to handle the overall system operation. It runs Lua, as well as handles Bluetooth networking, AI tasks and power management. The FPGA meanwhile, simply handles acceleration of the graphics and camera.

![Frame system architecture diagram](docs/diagrams/frame-system-architecture.drawio.png)

## Getting started with nRF52 firmware development

1. Ensure you have the [ARM GCC Toolchain](https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads) installed.

1. Ensure you have the [nRF Command Line Tools](https://www.nordicsemi.com/Products/Development-tools/nRF-Command-Line-Tools) installed.

1. Ensure you have [nRF Util](https://www.nordicsemi.com/Products/Development-tools/nRF-Util) installed, along with the `device` and `nrf5sdk-tools` subcommands.

    ```sh
    ./nrfutil install device
    ./nrfutil install nrf5sdk-tools
    ```

1. Clone this repository with submodules:

    ```sh
    git clone --recurse-submodules https://github.com/brilliantlabsAR/frame-codebase.git brilliantlabs-frame-codebase
    
    cd brilliantlabs-frame-codebase
    ```

1. You should now be able to build and flash the project to an [nRF52840 DK](https://www.nordicsemi.com/Products/Development-hardware/nRF52840-DK) by calling the following commands from the `brilliantlabs-frame-codebase` folder.

    ```sh
    make release
    make erase-jlink # Unlocks the flash protection if needed
    make flash-jlink
    ```

### Debugging

1. Open the project in [VSCode](https://code.visualstudio.com).

    There are some build tasks already configured within `.vscode/tasks.json`. Access them by pressing `Ctrl-Shift-P` (`Cmd-Shift-P` on MacOS) → `Tasks: Run Task`.

    Try running the `Build` task. The project should build normally.

    You may need to unlock the device by using the `Erase` task before programming or debugging.

1. To enable IntelliSense, be sure to select the correct compiler from within VSCode. `Ctrl-Shift-P` (`Cmd-Shift-P` on MacOS) → `C/C++: Select IntelliSense Configuration` → `Use arm-none-eabi-gcc`.

1. Install the [Cortex-Debug](https://marketplace.visualstudio.com/items?itemName=marus25.cortex-debug) extension for VSCode in order to enable debugging.

1. A debugging launch is already configured within `.vscode/launch.json`. Run the `Application (J-Link)` launch configuration from the `Run and Debug` panel, or press `F5`. The project will automatically build and flash before launching.

1. To monitor the logs, run the task `RTT Console (J-Link)` and ensure the `Application (J-Link)` launch configuration is running.

1. To debug using [Black Magic Probes](https://black-magic.org/index.html), follow the instructions [here](/production/blackmagic/README.md).

## Getting started with FPGA development

The complete FPGA architecture is described in the documentation [here](docs/fpga-architecture.md).

The FPGA RTL is prebuilt and included in `fpga_application.h` for convenience. If you wish to modify the FPGA RTL, follow the instructions [here](docs/fpga-toolchain-setup.md).
