#!/bin/sh

# Rofi Bluetooth Manager

powered=$(bluetoothctl show | grep "Powered:" | awk '{print $2}')

if [ "$powered" != "yes" ]; then
    action=$(echo -e " Turn On" | rofi -dmenu -p "Bluetooth" -theme-str 'listview {lines:1;}')
    if [ "$action" = " Turn On" ]; then
        bluetoothctl power on
    fi
    exit 0
fi

# Build menu
menu=""

# Check for already paired devices
paired=$(bluetoothctl devices Paired)
if [ -n "$paired" ]; then
    menu="--- Paired devices ---\n"
    while IFS= read -r line; do
        mac=$(echo "$line" | awk '{print $2}')
        name=$(echo "$line" | cut -d ' ' -f 3-)
        menu="${menu} $name ($mac)\n"
    done << EOF
$paired
EOF
fi

menu="${menu}───\n"
menu="${menu} Add new device\n"
menu="${menu} Power off"

choice=$(echo -e "$menu" | rofi -dmenu -p "Bluetooth")

# Extract MAC if present
mac=$(echo "$choice" | grep -oP '\(([0-9A-Fa-f:]+)\)' | tr -d '()')

if echo "$choice" | grep -q "Power off"; then
    bluetoothctl power off
elif echo "$choice" | grep -q "Add new device"; then
    notify-send "Bluetooth" "Scanning for devices..."
    bluetoothctl pairable on
    bluetoothctl discoverable on

    # Use --timeout for clean non-interactive output
    scan_output=$(bluetoothctl --timeout 10 scan on 2>&1)

    # Strip ANSI codes and extract discovered devices
    echo "$scan_output" | perl -pe 's/\e\[[0-9;]*[a-zA-Z]//g' | \
        grep -E '^\[NEW\] Device ' | awk '{
            mac = $3
            name = ""
            for(i=4; i<=NF; i++) name = name $i " "
            gsub(/^ +| +$/, "", name)
            if(name == "") name = mac
            if(!seen[mac]++) print mac "|" name
        }' > /tmp/bt-found.tmp

    devices=$(cat /tmp/bt-found.tmp 2>/dev/null)
    rm -f /tmp/bt-found.tmp

    if [ -z "$devices" ]; then
        notify-send "Bluetooth" "No devices found"
    else
        # Show names only in rofi, keep MAC hidden for selection
        display=$(echo "$devices" | awk -F'|' '{print $2}')
        device=$(echo -e "$display" | rofi -dmenu -p "Select device to pair")
        if [ -n "$device" ]; then
            # Look up the MAC by matching the name
            mac=$(echo "$devices" | grep -F "|$device") && mac=$(echo "$mac" | awk -F'|' '{print $1}')
            notify-send "Bluetooth" "Pairing with $device..."
            bluetoothctl pair "$mac"
            sleep 2
            notify-send "Bluetooth" "Connecting to $device..."
            bluetoothctl connect "$mac"
            notify-send "Bluetooth" "Connected to $device"
        fi
    fi

    bluetoothctl discoverable off
    bluetoothctl pairable off
elif [ -n "$mac" ]; then
    # Clicked on a paired device → connect it
    name=$(echo "$choice" | sed 's/^[^ ]* //; s/ *([^)]*)$//')
    notify-send "Bluetooth" "Connecting to $name..."
    bluetoothctl connect "$mac" && notify-send "Bluetooth" "Connected to $name"
fi
