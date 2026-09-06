#!/bin/bash
# stopwatch state helper — writes ~/.cache/waybar/stopwatch_state
# ("running:start_epoch:accumulated"). custom/uptime wires its clicks straight here:
#   toggle → start / pause   (on-click)
#   reset  → reset            (on-click-right)
# Display is uptime.sh, which reads the state file directly.

STATE="$HOME/.cache/waybar/stopwatch_state"
mkdir -p "$(dirname "$STATE")"
[[ -f "$STATE" ]] || echo "0:0:0" > "$STATE"

IFS=: read -r running start acc < "$STATE"
running=${running:-0}; start=${start:-0}; acc=${acc:-0}
now=$(date +%s)

case "$1" in
    toggle)
        if [[ "$running" == "1" ]]; then
            echo "0:0:$(( acc + now - start ))" > "$STATE"
        else
            echo "1:${now}:${acc}" > "$STATE"
        fi ;;
    reset)
        echo "0:0:0" > "$STATE" ;;
    *)
        echo "usage: stopwatch.sh {toggle|reset}" >&2; exit 1 ;;
esac
