#!/bin/sh
name=$(nmcli -t -f NAME,DEVICE con show --active 2>/dev/null | grep -E "wlan0|wlp" | cut -d: -f1 | head -1)
if [ -n "$name" ]; then
    echo "  $name"
else
    echo ""
fi
