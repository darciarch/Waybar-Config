#!/bin/bash
# One-time system setup — the parts of the waybar rework that need sudo/systemd.
# You can also run these by hand; this script just puts them in order.
set -e

echo ":: installing swaync (notification center, replaces dunst)"
sudo pacman -S --needed swaync

echo ":: make power-profiles-daemon persistent at boot"
sudo systemctl enable --now power-profiles-daemon

echo ":: masking dunst ('stop' is not enough since it is dbus-activated)"
systemctl --user mask --now dunst.service

# If swaync ships its own systemd user service, use it; otherwise the
# 'swaync &' line in the hyprland.lua autostart takes over.
if systemctl --user list-unit-files swaync.service &>/dev/null; then
    echo ":: enabling swaync.service"
    systemctl --user enable --now swaync.service
    echo "   → you can remove the 'swaync &' autostart line in hyprland.lua (optional)"
else
    echo ":: no swaync.service — the hyprland.lua autostart will be used"
    swaync &
fi

echo ":: done. Restart the bar:  ~/.config/waybar/scripts/launch.sh"
