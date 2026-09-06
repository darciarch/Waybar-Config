#!/bin/bash
# custom/stopwatch — a stopwatch next to the clock. Only visible while running, or when
# paused but non-zero (`hide-empty-text: true`).
#   no args  → returns the current time as mm:ss (or h:mm:ss) JSON  (interval: 1)
#   toggle   → start / pause   (on-click)
#   reset    → reset           (on-click-right)
# State file: ~/.cache/waybar/stopwatch_state  →  "running:start_epoch:accumulated"
# Dependency: jq.

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
        fi
        exit 0 ;;
    reset)
        echo "0:0:0" > "$STATE"
        exit 0 ;;
esac

if [[ "$running" == "1" ]]; then
    e=$(( acc + now - start ))
else
    e=$acc
fi

if [[ "$running" != "1" && "$e" -eq 0 ]]; then
    exit 0
fi

if (( e >= 3600 )); then
    printf -v out '%d:%02d:%02d' $(( e/3600 )) $(( e%3600/60 )) $(( e%60 ))
else
    printf -v out '%02d:%02d' $(( e/60 )) $(( e%60 ))
fi

cls=$([[ "$running" == "1" ]] && echo running || echo paused)
jq -cn --arg text "$(printf '\uf252') $out" --arg class "$cls" '{text:$text, class:$class}'
