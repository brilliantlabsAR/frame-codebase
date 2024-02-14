#!/bin/bash

stty -echoctl

echo "Frame programming scrpt"
echo "-----------------------"

while :
do
    echo ""
    read -p "Press Enter key to start, or Ctrl-C to quit"

    # Automatically assign port depending if MacOS or Linux
    if [ "`uname`" = Darwin ]; then
        PORT=`ls /dev/cu.usbmodem*1 | grep "cu."`
    else
        PORT=/dev/ttyACM0
    fi

    # Create timestamp
    NOW=`date -u +'%d/%m/%Y - %H:%M:%S'`

    # TODO create logfile

    # Unlock chip
    echo "$NOW - Unlocking chip"
    arm-none-eabi-gdb \
        -nx \
        --batch-silent \
        -ex "target extended-remote ${PORT}" \
        -ex "monitor swd_scan" \
        -ex "attach 1" \
        -ex "monitor erase_mass" \
        2> /dev/null

    # Erase chip (same thing as before, but here we do want to catch the error)
    echo "$NOW - Erasing chip"
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

        # Get and print device address
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
            -ex 'kill' \
            build/frame-firmware-v*.hex \
            2> /dev/null

        # If successful, start the camera focusing script otherwise throw error
        if [ $? -eq 0 ]; then
            echo "$NOW - Programmed succesfully"

            # Run the camera focusing script
            echo "$NOW - Starting focusing app. Press Ctrl-C when complete"
            python3 production/focusing_script.py 2> /dev/null

            # Clear the download counter and done
            if [ $? -eq 0 ]; then
                echo -e -n "\033[2K"
                echo "$NOW - Done"
            else
                echo -e -n "\033[2K"
                echo "$NOW - Error: Could not connect to start focusing"
            fi

        else
            echo "$NOW - Error: Chip could not be programmed"
        fi

    else
        echo "$NOW - Error: Chip not found"
    fi

done