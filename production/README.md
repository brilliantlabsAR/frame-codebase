# Production programming, testing and camera focusing script

The `production_script.sh` file runs a complete factory programming and test process. It also allows the operator to focus the camera lens.

## Setup

> Currently the script only works in MacOS due to an issue within the python Bleak library.

1. Install the latest `python3` if you don't already have it. e.g. using [`brew`](https://brew.sh):

    ```sh
    brew install python
    ```

1. Install the following python packages:

    ```sh
    pip3 install frameutils pillow sounddevice numpy
    ```

1. Make the production script executable:

    ```sh
    chmod +x production_script.sh
    ```

## Usage

1. Ensure you have a Frame board wired up for programming using a [Black Magic v2.3 debugger](https://black-magic.org). You will also need to provide 5V charging power to the board as well as assert the reset pin.

1. Run the script from the `production` directory:

    ```sh
    cd production
    ./production_script.sh
    ```
1. You should then see a prompt to start programming. Press Enter and allow the board to program:

    ```
    Frame programming script
    -----------------------

    Press Enter key to start, or Ctrl-C to quit
    16/02/2024 - 14:26:48 - Unlocking chip
    16/02/2024 - 14:26:48 - Erasing chip
    16/02/2024 - 14:26:48 - Device ID: 0x5F1C733B69DD9882
    16/02/2024 - 14:26:48 - Randomly Assigned Address: 0x82F93FCBA833
    16/02/2024 - 14:26:48 - Programming chip. Please wait
    16/02/2024 - 14:26:48 - Programmed successfully
    ```

1. After programming, the focusing and test scripts will run. Follow the instructions show to complete the process.

1. The `temp_focus_image.jpg` is continuously updated to show what the camera is seeing. This image can be kept open to help the operator focus the camera lens.

1. The `log.txt` file will store a complete history of all programmed boards.