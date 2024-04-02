# Using Black Magic probes for debugging and production

The production script relies on programming via a [Black Magic v2.3 Probe](https://black-magic.org/index.html) rather than a J-Link debugger. Full debugging is also supported using the Black Magic probes. To ensure compatibility, make sure your Black Magic probe is using the `blackmagic.bin` firmware found within this folder.

1. Install [`dfu-util`](https://dfu-util.sourceforge.net):

    ```sh
    # e.g. MacOS
    brew install dfu-util
    ```

2. Flash the firmware:

    ```sh
    # MacOS / Linux
    sudo dfu-util -d 1d50:6018,:6017 -s 0x08002000:leave -D blackmagic.bin

    # Windows
    dfu-util.exe -d 1d50:6018,:6017 -s 0x08002000:leave -D blackmagic.bin
    ```

The `blackmagic.bin` firmware is based on the v1.10.0 firmware but with RTT enabled for debugging. To rebuild this firmware based on the latest version, follow the build setup instructions [here](https://github.com/blackmagic-debug/blackmagic?tab=readme-ov-file#getting-started), and then rebuild the firmware:

```sh
git clone https://github.com/blackmagic-debug/blackmagic.git
cd blackmagic

rm -rf build
mkdir build

meson setup build --cross-file cross-file/native.ini -Drtt_support=true -Dtargets=cortexm,nrf,rp,stm
meson compile -C build    
```