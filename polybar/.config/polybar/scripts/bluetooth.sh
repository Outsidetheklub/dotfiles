#!/bin/sh

# Check if Bluetooth controller is powered on
powered=$(bluetoothctl show | grep "Powered:" | awk '{print $2}')

if [ "$powered" != "yes" ]; then
    echo " off"
    exit 0
fi

# Check for connected devices
connected=$(bluetoothctl devices Connected | wc -l)

if [ "$connected" -gt 0 ]; then
    # Get the first connected device name
    name=$(bluetoothctl devices Connected | head -1 | cut -d ' ' -f 3-)
    echo " $name"
else
    echo " on"
fi
