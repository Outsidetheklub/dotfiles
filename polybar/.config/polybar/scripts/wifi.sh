#!/bin/sh
# WiFi network selector — shows available networks via rofi

current=$(nmcli -t -f NAME,DEVICE con show --active 2>/dev/null | grep -E ":wlan0$|:wlp" | cut -d: -f1)

networks=$(nmcli -t -f SSID,SECURITY,SIGNAL device wifi list --rescan yes 2>/dev/null | \
  awk -F: '{ if($1) printf "%-25s %s %s%%\n", $1, ($2==""?"open":"🔒"), $3 }' | sort -t' ' -k3 -rn)

[ -z "$networks" ] && notify-send "WiFi" "No networks found" && exit 0

if [ -n "$current" ]; then
  networks="📶 $current (connected)\n───\n$networks"
fi

chosen=$(echo "$networks" | rofi -dmenu -p "WiFi" \
  -yoffset 28 -width 25 \
  -theme-str 'window { location: center; width: 25%; }' \
  -theme ~/.config/rofi/drun.rasi 2>/dev/null) || exit

[ -z "$chosen" ] && exit 0

ssid=$(echo "$chosen" | sed 's/^ *//' | sed 's/(connected)//' | \
  sed 's/ [🔒] *[0-9]*%$//' | sed 's/  *$//' | head -1)

if [ "$ssid" = "$current" ]; then
  notify-send "WiFi" "Already connected to $ssid"
elif [ "$ssid" != "───" ]; then
  notify-send "WiFi" "Connecting to $ssid..."
  nmcli device wifi connect "$ssid" 2>/dev/null && \
    notify-send "WiFi" "Connected to $ssid" || \
    notify-send "WiFi" "Failed to connect to $ssid"
fi
