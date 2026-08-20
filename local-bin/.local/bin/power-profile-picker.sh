#!/bin/sh
# Power profile picker (rofi)
# Lists available profiles from powerprofilesctl (performance, balanced,
# power-saver + Dell-specific quiet/cool when exposed) and switches via D-Bus.
# The active profile is shown in the prompt and highlighted in the list.

profiles=$(powerprofilesctl list | sed -n 's/^[* ] \([a-zA-Z0-9-]*\):$/\1/p')
[ -z "$profiles" ] && exit 1

current=$(powerprofilesctl get)

# 0-based index of the active profile, for rofi -a (active-line highlight)
idx=0
i=0
for p in $profiles; do
    [ "$p" = "$current" ] && idx=$i
    i=$((i + 1))
done

chosen=$(printf '%s\n' "$profiles" | rofi -dmenu -p "Power Profile: $current" \
    -a "$idx" -theme "$HOME/.config/rofi/power.rasi")

[ -n "$chosen" ] && powerprofilesctl set "$chosen"
