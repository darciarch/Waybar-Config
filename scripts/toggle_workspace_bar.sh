#!/bin/bash
# SUPER+A → mark / unmark the active workspace as "bar-less" and apply the change
# IMMEDIATELY (without waiting for the daemon). workspace_bar_daemon.py then tracks
# subsequent switches automatically. Dependencies: hyprctl, jq.

HIDDEN="$HOME/.cache/waybar/hidden_workspaces"
mkdir -p "$(dirname "$HIDDEN")"
touch "$HIDDEN"

ws=$(hyprctl activeworkspace -j | jq -r '.id')
[[ -z "$ws" || "$ws" == "null" ]] && exit 1

if grep -qxF "$ws" "$HIDDEN"; then
    grep -vxF "$ws" "$HIDDEN" > "$HIDDEN.tmp" || true
    mv "$HIDDEN.tmp" "$HIDDEN"
    pgrep -x waybar >/dev/null || setsid -f waybar >/dev/null 2>&1
else
    echo "$ws" >> "$HIDDEN"
    pgrep -x waybar >/dev/null && killall waybar
fi
