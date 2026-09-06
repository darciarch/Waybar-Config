#!/bin/bash
# custom/wifi — kompakt WiFi göstergesi (ikon + sinyal %), hover'da WiFi + Bluetooth
# birlikte tek tooltip'te. Native `network` modülü BT verisi taşıyamadığı için nmcli
# (NetworkManager) ile bluetoothctl çıktısı burada birleştiriliyor.
# Bağımlılıklar: nmcli, bluetoothctl, jq.

IFACE="wlo1"   # bu makinede sabit (eski config'te yanlışlıkla wlan0 yazıyordu)

state=$(nmcli -t -f DEVICE,STATE dev status | awk -F: -v i="$IFACE" '$1==i{print $2}')

if [[ "$state" == connected* ]]; then
    line=$(nmcli -t -f ACTIVE,SSID,SIGNAL dev wifi | awk -F: '$1=="yes"{print; exit}')
    ssid=${line#yes:}; ssid=${ssid%:*}
    signal=${line##*:}
    [[ -z "$signal" ]] && signal=0
    class="connected"
    if   (( signal >= 75 )); then icon="󰤨"
    elif (( signal >= 50 )); then icon="󰤢"
    elif (( signal >= 25 )); then icon="󰤟"
    else                          icon="󰤯"
    fi
    text="$icon ${signal}%"
    wifi_tip="<b>WiFi</b>  ${ssid}  ·  ${signal}%"
else
    class="disconnected"
    text="󰤭"
    wifi_tip="<b>WiFi</b>  bağlı değil"
fi

# --- Bluetooth ---
powered=$(bluetoothctl show 2>/dev/null | awk '/Powered:/{print $2; exit}')
if [[ "$powered" != "yes" ]]; then
    bt_tip="<b>Bluetooth</b>  kapalı"
else
    connected=$(bluetoothctl devices Connected 2>/dev/null)
    if [[ -z "$connected" ]]; then
        bt_tip="<b>Bluetooth</b>  bağlı cihaz yok"
    else
        bt_tip="<b>Bluetooth</b>"
        while read -r _ mac name; do
            [[ -z "$mac" ]] && continue
            batt=$(bluetoothctl info "$mac" 2>/dev/null \
                   | grep -oP 'Battery Percentage:.*\(\K[0-9]+(?=\))')
            if [[ -n "$batt" ]]; then
                bt_tip+=$'\n'"  ${name}  ·  ${batt}%"
            else
                bt_tip+=$'\n'"  ${name}"
            fi
        done <<< "$connected"
    fi
fi

tooltip="${wifi_tip}"$'\n'"${bt_tip}"

jq -cn --arg text "$text" --arg tooltip "$tooltip" --arg class "$class" \
    '{text:$text, tooltip:$tooltip, class:$class}'
