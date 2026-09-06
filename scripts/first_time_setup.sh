#!/bin/bash
# Bir kereye mahsus sistem kurulumu — waybar yenilemesinin sudo/systemd gerektiren
# parçaları. Elle de çalıştırabilirsin; bu script sadece sırayı toparlıyor.
set -e

echo ":: swaync kuruluyor (bildirim merkezi, dunst yerine)"
sudo pacman -S --needed swaync

echo ":: power-profiles-daemon boot'ta kalıcı olsun"
sudo systemctl enable --now power-profiles-daemon

echo ":: dunst maskeleniyor (dbus-activated olduğu için 'stop' yetmez)"
systemctl --user mask --now dunst.service

# swaync kendi systemd user servisiyle geliyorsa onu kullan, gelmiyorsa
# hyprland.lua autostart'ındaki 'swaync &' satırı devreye girer.
if systemctl --user list-unit-files swaync.service &>/dev/null; then
    echo ":: swaync.service enable ediliyor"
    systemctl --user enable --now swaync.service
    echo "   → hyprland.lua'daki 'swaync &' autostart satırını silebilirsin (opsiyonel)"
else
    echo ":: swaync.service yok — hyprland.lua autostart'ı kullanılacak"
    swaync &
fi

echo ":: bitti. Bar'ı yeniden başlat:  ~/.config/waybar/scripts/launch.sh"
