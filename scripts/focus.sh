#!/bin/bash
# custom/focus tık handler — OTURUM SIFIRLAMA butonu.
# Tüm Hyprland pencerelerini kapatır, sonra sabit uygulama setini 1/3/4/5'e açar.
#
# NOT: Bu makinede Hyprland Lua config ile çalışıyor; `hyprctl dispatch` artık düz
# string ("closewindow address:0x..", "exec [workspace 1 silent] app") KABUL ETMİYOR,
# argümanı Lua ifadesi olarak yorumluyor. Doğru biçim: `hl.dsp...(...)`
# (örnek: ~/.config/hypr/swap_workspace.sh).

for addr in $(hyprctl clients -j | jq -r '.[].address'); do
    hyprctl dispatch "hl.dsp.window.close({ window = hl.get_window('address:$addr') })"
done

sleep 1

hyprctl dispatch 'hl.dsp.exec_cmd("[workspace 1 silent] firefox --enable-features=UseOzonePlatform --ozone-platform=wayland")'
sleep 1
hyprctl dispatch 'hl.dsp.exec_cmd("[workspace 3 silent] brave --password-store=gnome --enable-features=UseOzonePlatform --ozone-platform=wayland")'
hyprctl dispatch 'hl.dsp.exec_cmd("[workspace 4 silent] dolphin")'
hyprctl dispatch 'hl.dsp.exec_cmd("[workspace 5 silent] kitty")'
