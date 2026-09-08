#!/bin/bash
# One-time setup for this waybar config: installs every dependency and does the
# systemd bits in order. Run as your normal user, NOT with sudo — the script
# calls sudo itself where it needs root. Safe to re-run.
set -e

if [ "$EUID" -eq 0 ]; then
    echo "Run this as your normal user, not with sudo." >&2
    exit 1
fi

echo ":: installing packages"
sudo pacman -S --needed \
    waybar \
    jq \
    networkmanager bluez bluez-utils \
    swaync \
    power-profiles-daemon \
    wireplumber pavucontrol \
    ttf-jetbrains-mono-nerd

echo ":: enabling system services at boot"
sudo systemctl enable --now NetworkManager
sudo systemctl enable --now bluetooth.service
sudo systemctl enable --now power-profiles-daemon

echo ":: masking dunst ('stop' is not enough since it is dbus-activated)"
systemctl --user mask --now dunst.service

# If swaync ships its own systemd user service, use it; otherwise the
# 'swaync &' line in the hyprland autostart takes over.
if systemctl --user cat swaync.service &>/dev/null; then
    echo ":: enabling swaync.service"
    systemctl --user enable --now swaync.service
    echo "   -> you can drop the 'swaync &' autostart line from hyprland.lua (optional)"
else
    echo ":: no swaync.service — the 'swaync &' hyprland autostart will be used"
fi

echo ":: done. Start the bar:  ~/.config/waybar/scripts/launch.sh"