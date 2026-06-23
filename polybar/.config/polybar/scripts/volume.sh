#!/bin/sh
# Get volume and mute status via wpctl
vol=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)
if echo "$vol" | grep -q "MUTED"; then
    echo "🔇 muted"
else
    pct=$(echo "$vol" | awk '{printf "%.0f", $2 * 100}')
    if [ "$pct" -gt 50 ]; then
        icon="🔊"
    elif [ "$pct" -gt 0 ]; then
        icon="🔉"
    else
        icon="🔈"
    fi
    echo "$icon $pct%"
fi
