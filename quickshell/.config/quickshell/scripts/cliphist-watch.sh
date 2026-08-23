#!/bin/sh
# Clipboard history watcher: feed X11 CLIPBOARD into cliphist
# Replaces `greenclip daemon` — Clipboard.qml reads the store via `cliphist list`.

last=""
while true; do
    cur=$(xsel -o -b 2>/dev/null | tr -d '\000')
    if [ -n "$cur" ] && [ "$cur" != "$last" ]; then
        printf '%s' "$cur" | cliphist store 2>/dev/null
        last="$cur"
    fi
    sleep 1
done
