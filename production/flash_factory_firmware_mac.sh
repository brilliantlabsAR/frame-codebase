#!/bin/bash

# TODO automaically get the port
PORT=/dev/cu.usbmodem97B6BC101

echo "Frame programming scrpt"
echo "-----------------------"

while :
do
    echo ""
    read -p "Press Enter key to start, or Ctrl-C to quit"

    # Create timestamp
    NOW=`date -u +'%d/%m/%Y - %H:%M:%S'`

    # TODO create logfile

    # Erase chip (suppress all output)
    echo "$NOW - Erasing and unlocking chip"
    arm-none-eabi-gdb \
        -nx \
        --batch-silent \
        -ex "target extended-remote ${PORT}" \
        -ex "monitor swd_scan" \
        -ex "attach 1" \
        -ex "monitor erase_mass" \
        2> /dev/null
    
    # If successful, continue otherwise throw and error and return to top of loop
    if [ $? -eq 0 ]; then

        # Get and print device ID
        echo -n "$NOW - "
        arm-none-eabi-gdb \
            -nx \
            --batch-silent \
            -ex "target extended-remote ${PORT}" \
            -ex "monitor swd_scan" \
            -ex "attach 1" \
            -ex "set logging file /dev/stdout" \
            -ex "set logging enabled on" \
            -ex "monitor read deviceid" \
            -ex "set logging enabled off" \
            2> /dev/null

        # Get and print device Address
        echo -n "$NOW - "
        arm-none-eabi-gdb \
            -nx \
            --batch-silent \
            -ex "target extended-remote ${PORT}" \
            -ex "monitor swd_scan" \
            -ex "attach 1" \
            -ex "set logging file /dev/stdout" \
            -ex "set logging enabled on" \
            -ex "monitor read deviceaddr" \
            -ex "set logging enabled off" \
            2> /dev/null

        # Program sections
        echo "$NOW - Programming chip. Please wait"
        arm-none-eabi-gdb \
            -nx \
            --batch-silent \
            -ex "target extended-remote ${PORT}" \
            -ex 'monitor swd_scan' \
            -ex 'attach 1' \
            -ex 'load' \
            -ex 'compare-sections' \
            build/frame-firmware-v*.hex \
            2> /dev/null

        # If successful, start the camera focusing script otherwise throw error
        if [ $? -eq 0 ]; then
            echo "$NOW - Programmed succesfully"
        else
            echo "$NOW - Error: Chip could not be programmed"
        fi

    else
        echo "$NOW - Error: Chip not found"
    fi

done