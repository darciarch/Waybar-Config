#!/bin/bash
# custom/wifi — compact WiFi indicator (icon + signal %), with WiFi + Bluetooth
# merged into a single tooltip on hover. The native `network` module cannot carry BT
# data, so nmcli (NetworkManager) and bluetoothctl output are combined here.
# Dependencies: nmcli, bluetoothctl, jq.

IFACE="wlo1"   # hardcoded on this machine (the old config wrongly used wlan0)

state=$(nmcli -t -f DEVICE,STATE dev status | awk -F: -v i="$IFACE" '$1==i{print $2}')

if [[ "$state" == connected* ]]; then
    # --rescan no: plain `nmcli dev wifi` rescans if the last scan is >30s old, so
    # polling it every 10s kept the radio off-channel ~5s of every ~36s (big throughput dips).
    line=$(nmcli -t -f ACTIVE,SSID,SIGNAL dev wifi list --rescan no | awk -F: '$1=="yes"{print; exit}')
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
    wifi_tip="<b>WiFi</b>  not connected"
fi

# --- Bluetooth ---
powered=$(bluetoothctl show 2>/dev/null | awk '/Powered:/{print $2; exit}')
if [[ "$powered" != "yes" ]]; then
    bt_tip="<b>Bluetooth</b>  off"
else
    connected=$(bluetoothctl devices Connected 2>/dev/null)
    if [[ -z "$connected" ]]; then
        bt_tip="<b>Bluetooth</b>  no connected devices"
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
