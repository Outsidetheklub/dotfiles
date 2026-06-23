#!/bin/sh
rofi -modi emoji -show emoji -theme ~/.config/rofi/emoji.rasi "$@" &
ROFI_PID=$!
sleep 0.1
i3-msg '[title=".*rofi.*"] move position 1920 0, resize set 33% 100%' 2>/dev/null
wait $ROFI_PID
