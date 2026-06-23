#!/bin/sh
# Launch rofi and position on the left third of the screen
rofi -show drun -theme ~/.config/rofi/drun.rasi "$@" &
ROFI_PID=$!
sleep 0.15
# Rofi opens as a floating window, try to move it
i3-msg '[instance="rofi"] move position 0 0' 2>/dev/null
i3-msg '[instance="rofi"] resize set 640 1080' 2>/dev/null
wait $ROFI_PID
