#!/bin/bash
# custom/uptime — kutu HER ZAMAN uptime gösterir; kronometre durumu tooltip'te.
#   argümansız → {text,tooltip,class} JSON döner  (interval: 1)
# Kronometre tık'ları config.jsonc'de doğrudan stopwatch.sh'e bağlı
# (on-click → toggle, on-click-right → reset). Bu script yalnızca gösterim.
# State dosyası: ~/.cache/waybar/stopwatch_state  →  "running:start_epoch:accumulated"
# Bağımlılık: jq.

STATE="$HOME/.cache/waybar/stopwatch_state"

# Kutu metni: mevcut config'teki sed ifadesi birebir korunuyor.
up=$(uptime -p | sed 's/up //; s/ days,/d/; s/ day,/d/; s/ hours,/h/; s/ hour,/h/; s/ minutes/m/; s/ minute/m/')

# Kronometre glyph'i — CLAUDE.md kuralı: kırılgan glyph'i printf ile üret.
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
    tip="$sw $mmss çalışıyor  ·  sol tık: duraklat  ·  sağ tık: sıfırla"
elif (( e > 0 )); then
    cls="paused"
    tip="$sw $mmss duraklatıldı  ·  sol tık: devam  ·  sağ tık: sıfırla"
else
    cls="idle"
    tip="Kronometre  ·  sol tık: başlat"
fi

jq -cn --arg text "$up" --arg tooltip "$tip" --arg class "$cls" \
    '{text:$text, tooltip:$tooltip, class:$class}'
