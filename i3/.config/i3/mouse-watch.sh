#!/bin/sh
# Watchdog: keeps mouse acceleration off
# Proton games love to mess with these — this fixes it every 5s

while true; do
    # Reset accel speed to 0 every 5 seconds
    xinput set-prop 12 "libinput Accel Speed" 0
    # Ensure flat profile (no acceleration)
    xinput set-prop 12 "libinput Accel Profile Enabled" 0, 1, 0
    sleep 5
done
