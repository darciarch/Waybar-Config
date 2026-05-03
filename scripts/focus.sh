#!/bin/bash

for window in $(hyprctl clients -j | jq -r '.[].address'); do
    hyprctl dispatch closewindow address:$window
done

sleep 1

hyprctl dispatch exec "[workspace 1 silent] firefox --enable-features=UseOzonePlatform --ozone-platform=wayland"
sleep 1
hyprctl dispatch exec "[workspace 3 silent] brave --password-store=gnome --enable-features=UseOzonePlatform --ozone-platform=wayland"
hyprctl dispatch exec "[workspace 4 silent] dolphin"
hyprctl dispatch exec "[workspace 5 silent] kitty"
