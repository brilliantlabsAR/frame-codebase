# Frame Firmware & RTL Codebase

Welcome to the complete codebase of the Frame hardware. For regular usage, check out the docs [here](https://docs.brilliant.xyz).

## System architecture

The codebase is split into two sections. The **nRF53 Firmware**, and the **FPGA RTL**. 

The nRF53 is designed to handle the overall system operation. It runs Lua, as well as handle Bluetooth networking, AI tasks and power management. The FPGA meanwhile, simply handles acceleration of the graphics and camera.

![Frame system architecture diagram](docs/frame-system-architecture.drawio.png)

## Getting started with nRF53 firmware development

1. Ensure you have the [ARM GCC Toolchain](https://developer.arm.com/downloads/-/gnu-rm) installed.

1. Ensure you have the [nRF Command Line Tools](https://www.nordicsemi.com/Products/Development-tools/nrf-command-line-tools) installed.

1. Clone this repository along with its submodules:

    ```sh
    git clone https://github.com/brilliantlabsAR/frame-codebase.git
    
    cd frame-codebase

    git submodule update --init
    ```

1. You should now be able to build the project by calling `make` from the `frame-codebase` folder.

    ```sh
    make
    ```

1. Before flashing an nRF5340, you may need to unlock the chip first.

    ```sh
    nrfjprog --recover
    ```

1. You should then be able to flash the device.

    ```sh
    make flash
    ```

### Debugging

1. Open the project in [VSCode](https://code.visualstudio.com).

    There are some build tasks already configured within `.vscode/tasks.json`. Access them by pressing `Ctrl-Shift-P` (`Cmd-Shift-P` on MacOS) → `Tasks: Run Task`.

    Try running the `Build Firmware` task. The project should build normally.

    You many need to unlock the device by using the `Erase & Unlock nRF53` task before programming or debugging.

1. To enable IntelliSense, be sure to select the correct compiler from within VSCode. `Ctrl-Shift-P` (`Cmd-Shift-P` on MacOS) → `C/C++: Select IntelliSense Configuration` → `Use arm-none-eabi-gcc`.

1. Install the [Cortex-Debug](https://marketplace.visualstudio.com/items?itemName=marus25.cortex-debug) extension for VSCode in order to enable debugging.

1. A debugging launch is already configured within `.vscode/launch.json`. Run the `J-Link` launch configuration from the `Run and Debug` panel, or press `F5`. The project will automatically build and flash before launching.

1. To monitor the logs, run the task `RTT Console` and ensure the `J-Link` launch configuration is running.

## Getting started with FPGA development

For quickly getting up and running, the accelerators which run on the FPGA are already pre-built and bundled within this repo. If you wish to modify the FPGA RTL, you will need to rebuild the `fpga_application.h` file which contains the entire FPGA application.

1. Ensure you have the [Yosys](https://github.com/YosysHQ/yosys) installed.

1. Ensure you have the [Project Oxide](https://github.com/gatecat/prjoxide) installed.

1. Ensure you have the [nextpnr](https://github.com/YosysHQ/nextpnr) installed.

1. **MacOS users** can do the above three steps in one using [Homebrew](https://brew.sh).

    ```sh
    brew install --HEAD siliconwitchery/oss-fpga/nextpnr-nexus
    ```

1. You should now be able to rebuild the project by calling `make`:

    ```sh
    make application_core/fpga_application.h
    ```