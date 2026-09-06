#!/bin/bash
# custom/uptime — the box ALWAYS shows uptime; the stopwatch state lives in the tooltip.
#   no args → returns {text,tooltip,class} JSON  (interval: 1)
# Stopwatch clicks are wired straight to stopwatch.sh in config.jsonc
# (on-click → toggle, on-click-right → reset). This script is display only.
# State file: ~/.cache/waybar/stopwatch_state  →  "running:start_epoch:accumulated"
# Dependency: jq.

STATE="$HOME/.cache/waybar/stopwatch_state"

# Box text: the sed expression from the old config is kept verbatim.
up=$(uptime -p | sed 's/up //; s/ days,/d/; s/ day,/d/; s/ hours,/h/; s/ hour,/h/; s/ minutes/m/; s/ minute/m/')

# Stopwatch glyph — CLAUDE.md rule: build fragile glyphs with printf.
sw=$(printf '\U000F13AB')   # 󱎫  nf-md-timer

running=0; start=0; acc=0
if [[ -f "$STATE" ]]; then
    IFS=: read -r running start acc < "$STATE"
    running=${running:-0}; start=${start:-0}; acc=${acc:-0}
fi
now=$(date +%s)

if [[ "$running" == "1" ]]; then
    e=$(( acc + now - start ))
else
    e=$acc
fi
printf -v mmss '%02d:%02d' $(( e/60 )) $(( e%60 ))

if [[ "$running" == "1" ]]; then
    cls="running"
    tip="$sw $mmss running  ·  left click: pause  ·  right click: reset"
elif (( e > 0 )); then
    cls="paused"
    tip="$sw $mmss paused  ·  left click: resume  ·  right click: reset"
else
    cls="idle"
    tip="Stopwatch  ·  left click: start"
fi

jq -cn --arg text "$up" --arg tooltip "$tip" --arg class "$cls" \
    '{text:$text, tooltip:$tooltip, class:$class}'
