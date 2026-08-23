#!/bin/sh
# Wait for X to settle, then configure displays
sleep 1

# Force 240Hz on main monitor
xrandr --output DP-4 --primary --mode 1920x1080 --rate 240 --pos 0x0

# Secondary monitor with offset (power cycle to wake up)
xrandr --output HDMI-0 --off
sleep 0.5
xrandr --output HDMI-0 --mode 1920x1080 --rate 60 --pos 1920x80

# Set background across both monitors using fill mode
feh --bg-fill $HOME/Pictures/Wallpapers/Wallpaper.png 2>/dev/null || xsetroot -solid "#1e1e2e"

# Disable mouse acceleration
# (removed — see 99-mouse-noaccel.conf)
# mouse accel handled by /etc/X11/xorg.conf.d/99-mouse-noaccel.conf

# Polkit authentication agent (so Thunar can ask for password to mount drives etc)
/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &

# Clipboard history watcher (cliphist)
~/.config/quickshell/scripts/cliphist-watch.sh &

# Flameshot (screenshot tool)
flameshot &

