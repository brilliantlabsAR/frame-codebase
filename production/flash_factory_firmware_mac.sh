#!/bin/bash

stty -echoctl

echo "Frame programming script"
echo "-----------------------"

while :
do
    echo ""  | tee -a production/log.txt
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
    echo "$NOW - Unlocking chip" | tee -a production/log.txt
    arm-none-eabi-gdb \
        -nx \
        --batch-silent \
        -ex "target extended-remote ${PORT}" \
        -ex "monitor swd_scan" \
        -ex "attach 1" \
        -ex "monitor erase_mass" \
        2> /dev/null

    # Erase chip (same thing as before, but here we do want to catch the error)
    echo "$NOW - Erasing chip" | tee -a production/log.txt
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
        echo -n "$NOW - " | tee -a production/log.txt
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
            2> /dev/null \
            | tee -a production/log.txt

        # Get and print device address
        echo -n "$NOW - " | tee -a production/log.txt
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
            2> /dev/null \
            | tee -a production/log.txt

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
            echo "$NOW - Programmed successfully" | tee -a production/log.txt

            # Run the camera focusing script
            echo "$NOW - Starting focusing app. Press Ctrl-C when complete"
            python3 production/focusing_script.py 2> /dev/null

            # Clear the download counter and done
            if [ $? -eq 0 ]; then
                echo -e -n "\033[2K"
                echo "$NOW - Done" | tee -a production/log.txt
            else
                echo -e -n "\033[2K"
                echo "$NOW - Error: Could not connect to start focusing" | tee -a production/log.txt
            fi

        else
            echo "$NOW - Error: Chip could not be programmed" | tee -a production/log.txt
        fi

    else
        echo "$NOW - Error: Chip not found" | tee -a production/log.txt
    fi

done