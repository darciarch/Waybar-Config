#!/bin/bash
# custom/sysinfo on-click handler — SESSION RESET button.
# Closes every Hyprland window, then opens a fixed app set onto workspaces 1/2/3/4/5/6.
#
# NOTE: Hyprland runs a Lua config on this machine; `hyprctl dispatch` no longer accepts
# plain strings ("closewindow address:0x..", "exec [workspace 1 silent] app") — it parses
# the argument as a Lua expression. Correct form: `hl.dsp...(...)`
# (see ~/.config/hypr/swap_workspace.sh).

for addr in $(hyprctl clients -j | jq -r '.[].address'); do
    hyprctl dispatch "hl.dsp.window.close({ window = hl.get_window('address:$addr') })"
done

# Wait until all windows are gone and browsers have exited (max 5 s)
for i in {1..100}; do
    if [ "$(hyprctl clients -j | jq length)" -eq 0 ] \
       && ! pgrep -x firefox >/dev/null \
       && ! pgrep -x brave >/dev/null; then
        break
    fi
    sleep 0.05
done

# Launch everything at once
hyprctl dispatch 'hl.dsp.exec_cmd("[workspace 1 silent] firefox --enable-features=UseOzonePlatform --ozone-platform=wayland")'
hyprctl dispatch 'hl.dsp.exec_cmd("[workspace 3 silent] brave --password-store=gnome --enable-features=UseOzonePlatform --ozone-platform=wayland")'
hyprctl dispatch 'hl.dsp.exec_cmd("[workspace 4 silent] obsidian")'
hyprctl dispatch 'hl.dsp.exec_cmd("[workspace 5 silent] kitty")'
hyprctl dispatch 'hl.dsp.exec_cmd("[workspace 6 silent] dolphin")'

# Open the second Firefox window in the background so nothing else waits for it
(
    ff_windows() { hyprctl clients -j | jq -r '.[] | select(.class=="firefox") | .address'; }
    wait_ff() {
        for i in {1..200}; do
            [ "$(ff_windows | wc -l)" -ge "$1" ] && return
            sleep 0.05
        done
    }

    wait_ff 1
    first=$(ff_windows | head -n1)
    hyprctl dispatch 'hl.dsp.exec_cmd("firefox --new-window")'
    wait_ff 2
    second=$(ff_windows | grep -v "$first" | head -n1)
    hyprctl dispatch "hl.dsp.window.move({ workspace = 2, follow = false, window = 'address:$second' })"
) &
