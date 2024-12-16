#!/bin/bash

stty -echoctl

echo "Frame programming script"
echo "-----------------------"

while :
do

    NOW=`date -u +'%d/%m/%Y - %H:%M:%S'`

    echo ""
    echo "" >> log.txt
    read -p "Press Enter key to start, or Ctrl-C to quit"

    # Automatically assign port depending if MacOS or Linux
    if [ "`uname`" = Darwin ]; then
        PORT=`ls /dev/cu.usbmodem*1 2> /dev/null`
    else
        PORT=`ls /dev/ttyACM0 2> /dev/null`
    fi

    if [ $? -eq 1 ]; then
        echo "$NOW - Error: Programmer not found" | tee -a log.txt
        continue
    fi

    # Unlock chip (and ignore errors)
    echo "$NOW - Unlocking chip" | tee -a log.txt
    arm-none-eabi-gdb \
        -nx \
        --batch-silent \
        -ex "target extended-remote ${PORT}" \
        -ex "monitor swd_scan" \
        -ex "attach 1" \
        -ex "monitor erase_mass" \
        2> /dev/null

    # Erase chip (same thing as before, but here we do want to catch the error)
    echo "$NOW - Erasing chip" | tee -a log.txt
    arm-none-eabi-gdb \
        -nx \
        --batch-silent \
        -ex "target extended-remote ${PORT}" \
        -ex "monitor swd_scan" \
        -ex "attach 1" \
        -ex "monitor erase_mass" \
        2> /dev/null
    
    if [ $? -eq 1 ]; then
        echo "$NOW - Error: Chip not found" | tee -a log.txt
        continue
    fi

    # Get and print device ID
    echo -n "$NOW - " | tee -a log.txt
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
        | tee -a log.txt

    # Get and print device address
    echo -n "$NOW - " | tee -a log.txt
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
        | tee -a log.txt

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
        frame-firmware-v*.hex \
        2> /dev/null

    if [ $? -eq 1 ]; then
        echo "$NOW - Error: Chip could not be programmed" | tee -a log.txt
        continue
    fi

    echo "$NOW - Programmed successfully" | tee -a log.txt

    # Short delay to allow the chip to boot
    sleep 3

    # Test display/LED
    echo -e -n "                        Running display/LED test\r"
    python test_display_led_script.py 2> /dev/null
    
    if [ $? -eq 1 ]; then
        echo -e -n $"\r\033[2K"
        echo "$NOW - Error: Could not connect to start microphone test" | tee -a log.txt
        continue
    fi

    echo -n "                        Press y if display/LED is working, otherwise n"
    read -s -n1 input

    if [ $input == "n" ]; then
        echo -e -n $"\r\033[2K"
        echo "$NOW - Error: Display/LED not working" | tee -a log.txt
        continue
    fi

    echo -e -n $"\r\033[2K"
    echo "$NOW - Display/LED okay" | tee -a log.txt

    # Test microphone
    echo -e -n "                        Recording audio\r"
    python test_microphone_script.py 2> /dev/null

    if [ $? -eq 1 ]; then
        echo -e -n $"\r\033[2K"
        echo "$NOW - Error: Could not connect to start microphone test" | tee -a log.txt
        continue
    fi

    echo -e -n $"\r\033[2K"
    echo -n "                        Press y if microphone is working, otherwise n"
    read -s -n1 input

    if [ $input == "n" ]; then
        echo -e -n $"\r\033[2K"
        echo "$NOW - Error: Microphone not working" | tee -a log.txt
        continue
    fi

    echo -e -n $"\r\033[2K"
    echo "$NOW - Microphone okay" | tee -a log.txt
                        
    # Run the camera focusing script
    python test_focus_camera_script.py 2> /dev/null

    if [ $? -eq 1 ]; then
        echo -e -n $"\r\033[2K"
        echo "$NOW - Error: Could not connect to start focusing" | tee -a log.txt
        continue
    fi

    echo -e -n $"\r\033[2K"
    echo "$NOW - Camera focused" | tee -a log.txt

    echo "$NOW - Done" | tee -a log.txt

done