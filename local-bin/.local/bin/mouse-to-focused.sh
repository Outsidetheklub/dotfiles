#!/bin/sh
# Move cursor to center of the currently focused window

wid=$(xdotool getactivewindow)

# Skip desktop/root windows
if [ "$wid" = "$(xdotool getrootwindow)" ]; then
    exit 0
fi

eval $(xdotool getwindowgeometry --shell "$wid")

# Calculate center
cx=$((X + WIDTH / 2))
cy=$((Y + HEIGHT / 2))

xdotool mousemove "$cx" "$cy"
