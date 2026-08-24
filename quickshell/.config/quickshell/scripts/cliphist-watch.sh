#!/bin/sh
# Clipboard history watcher: feed X11 CLIPBOARD into cliphist
# Replaces `greenclip daemon` — Clipboard.qml reads the store via `cliphist list`.

# Only one watcher per session: startup.sh re-runs on every i3 restart.
[ "$(pgrep -fc 'cliphist-watch\.sh')" -gt 1 ] && exit 0

last=""
while true; do
    cur=$(xsel -o -b 2>/dev/null | tr -d '\000')
    if [ -n "$cur" ] && [ "$cur" != "$last" ]; then
        printf '%s' "$cur" | cliphist store 2>/dev/null
        last="$cur"
    fi
    sleep 1
done
