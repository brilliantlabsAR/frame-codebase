# FPGA Toolchain Setup

## Vendor recommended workflow

**Radiant** is Lattice's proprietary FPGA toolchain available on x86 Linux and Windows. It is currently the only supported way to synthesize and build the FPGA project due to the requirement of Lattice IP cores which are utilized within the camera pipeline of the project.

1. Download Radiant [here](https://www.latticesemi.com/en/Products/DesignSoftwareAndIP/FPGAandLDS/Radiant)

1. Obtain a free node locked [license](https://www.latticesemi.com/Support/Licensing/DiamondAndiCEcube2SoftwareLicensing/Radiant)

1. You will need to purchase the following two licenses in order to build the camera pipeline portion of the project. Trial IP is available for free, however the camera pipeline will only function for a short period of time, after which the FPGA will need to be rebooted. Both licenses can be obtained from DigiKey, Mouser, or other distributors

    - [CSI Receiver Core (DPHY-RX-CNX-US)](https://www.latticesemi.com/products/designsoftwareandip/intellectualproperty/ipcore/ipcores04/csi2dsidphyreceiver)
    - [Byte to Pixel Converter Core (BYTE-PIXEL-CNX-US)](https://www.latticesemi.com/products/designsoftwareandip/intellectualproperty/ipcore/ipcores04/bytetopixelconverter)

1. Open and build the FPGA project within the Radiant GUI

1. The FPGA bitstream is now ready to be used in the application firmware. Convert the `.bit` file to a C header file using the command

    ```sh
    make -C source/fpga RADIANT_PATH=/path/to/radiant
    ```

## Open source workflow

An open source workflow is possible, but not yet supported in the project due to the proprietary nature of the two Lattice IP cores mentioned above. These cores would need to be replaced with open source alternatives.

1. Ensure you have [Yosys](https://github.com/YosysHQ/yosys) installed

1. Ensure you have [Project Oxide](https://github.com/gatecat/prjoxide) installed

1. Ensure you have [nextpnr](https://github.com/YosysHQ/nextpnr) installed

1. **MacOS users** can do the above three steps in one using [Homebrew](https://brew.sh).

    ```sh
    brew install --HEAD siliconwitchery/oss-fpga/nextpnr-nexus
    ```

1. The FPGA bitstream can be build and converted to a C header file using the command

    ```sh
    make -C source/fpga TOOLCHAIN=YOSYS
    ```

## Post RTL steps

After building the bitstream using either Radiant or Yosys, the [FPGA Makefile](/source/fpga/Makefile) converts the `.bit` file into a compressed LZ4 file. This file is then converted using `xxd` into a C header file. This header file is then included in the application firmware, and the FPGA bitstream is decompressed and loaded onto the FPGA at boot time by the main processor.

Be sure to perform a clean build of the application firmware after rebuilding the `fpga_application.h` file:

```sh
make clean
make
```