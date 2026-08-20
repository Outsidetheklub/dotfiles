#!/bin/sh
# Power profile picker (rofi)
# Lists available profiles from powerprofilesctl (performance, balanced,
# power-saver + Dell-specific quiet/cool) and switches via D-Bus.

profiles=$(powerprofilesctl list | sed -n 's/^[* ] \([a-zA-Z0-9-]*\):$/\1/p')

[ -z "$profiles" ] && exit 1

chosen=$(printf '%s\n' "$profiles" | rofi -dmenu -p "Power Profile" \
    -theme "$HOME/.config/rofi/power.rasi")

[ -n "$chosen" ] && powerprofilesctl set "$chosen"
