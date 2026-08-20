#!/bin/sh
# Polybar battery module
# FontAwesome icons (full → empty) + percentage, bolt while charging.
# Click → power profile picker (see click-left in [module/battery]).

battery_dir() {
    for d in /sys/class/power_supply/BAT*; do
        [ -d "$d" ] && { echo "$d"; return; }
    done
    return 1
}

dir=$(battery_dir)
if [ -z "$dir" ]; then
    echo " ?"
    exit 0
fi

cap=$(cat "$dir/capacity" 2>/dev/null)
status=$(cat "$dir/status" 2>/dev/null)

[ -z "$cap" ] && { echo " ?"; exit 0; }

# Battery icons: full , 3/4 , half , 1/4 , empty 
if   [ "$cap" -ge 95 ]; then icon=""
elif [ "$cap" -ge 70 ]; then icon=""
elif [ "$cap" -ge 45 ]; then icon=""
elif [ "$cap" -ge 20 ]; then icon=""
else                         icon=""
fi

# Bolt while charging
[ "$status" = "Charging" ] && icon=" $icon"

echo "$icon $cap%"
