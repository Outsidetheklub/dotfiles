#!/bin/sh

# ── Power menu: shutdown / reboot / logout / lock ──
entries="⏻ Shutdown\n Reboot\n󰍃 Logout\n󰨑 Lock\n󰌾 Sleep"

chosen=$(echo -e "$entries" | rofi -dmenu -p "Power" -lines 5 -theme ~/.config/rofi/power.rasi)

case "$chosen" in
    "⏻ Shutdown")
        systemctl poweroff
        ;;
    " Reboot")
        systemctl reboot
        ;;
    "󰍃 Logout")
        i3-msg exit
        ;;
    "󰨑 Lock")
        ~/.config/i3/lock.sh 2>/dev/null || i3lock 2>/dev/null || loginctl lock-session
        ;;
    "󰌾 Sleep")
        systemctl suspend
        ;;
esac
