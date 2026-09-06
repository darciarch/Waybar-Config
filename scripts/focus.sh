#!/bin/bash
# custom/focus click handler — SESSION RESET button.
# Closes every Hyprland window, then opens a fixed app set onto workspaces 1/3/4/5.
#
# NOTE: Hyprland runs a Lua config on this machine; `hyprctl dispatch` no longer accepts
# plain strings ("closewindow address:0x..", "exec [workspace 1 silent] app") — it parses
# the argument as a Lua expression. Correct form: `hl.dsp...(...)`
# (see ~/.config/hypr/swap_workspace.sh).

for addr in $(hyprctl clients -j | jq -r '.[].address'); do
    hyprctl dispatch "hl.dsp.window.close({ window = hl.get_window('address:$addr') })"
done

sleep 1

hyprctl dispatch 'hl.dsp.exec_cmd("[workspace 1 silent] firefox --enable-features=UseOzonePlatform --ozone-platform=wayland")'
sleep 1
hyprctl dispatch 'hl.dsp.exec_cmd("[workspace 3 silent] brave --password-store=gnome --enable-features=UseOzonePlatform --ozone-platform=wayland")'
hyprctl dispatch 'hl.dsp.exec_cmd("[workspace 4 silent] dolphin")'
hyprctl dispatch 'hl.dsp.exec_cmd("[workspace 5 silent] kitty")'
