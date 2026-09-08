#!/bin/bash
# One-time setup / repair tool for this waybar config. Run as your normal user,
# NOT with sudo — the script calls sudo itself where it needs root.
#
# Safe to re-run at any time, including on a machine where everything is already
# installed and running. Only the package install is treated as fatal; every
# other step is tolerant and collects a warning instead of aborting the run, so
# a single hiccup can never leave the rest of the setup half-applied.
set -uo pipefail

if [ "$EUID" -eq 0 ]; then
    echo "Run this as your normal user, not with sudo." >&2
    exit 1
fi

SCRIPTS="$HOME/.config/waybar/scripts"
WARNINGS=()
warn() {
    echo "   !! $1" >&2
    WARNINGS+=("$1")
}

echo ":: installing packages"
if ! sudo pacman -S --needed \
    jq \
    networkmanager bluez bluez-utils \
    swaync \
    power-profiles-daemon \
    wireplumber pavucontrol \
    ttf-jetbrains-mono-nerd
then
    echo "Package install failed — nothing else can be trusted, aborting." >&2
    exit 1
fi

if ! command -v yay &>/dev/null && ! command -v paru &>/dev/null; then
    echo ":: no AUR helper found, installing yay"
    if sudo pacman -S --needed git base-devel; then
        tmp=$(mktemp -d)
        trap 'rm -rf "$tmp"' EXIT
        if git clone https://aur.archlinux.org/yay.git "$tmp/yay"; then
            (cd "$tmp/yay" && makepkg -si --noconfirm) || warn "yay build failed — install an AUR helper manually"
        else
            warn "could not clone yay from the AUR (network?)"
        fi
        rm -rf "$tmp"
        trap - EXIT
    else
        warn "could not install git/base-devel, skipping yay"
    fi
fi

echo ":: installing waybar-git from the AUR"
if pacman -Q waybar-git &>/dev/null; then
    echo "   -> waybar-git already installed, skipping the rebuild"
elif ! command -v yay &>/dev/null && ! command -v paru &>/dev/null; then
    warn "no AUR helper available — install waybar-git manually"
else
    # The official 'waybar' package conflicts with waybar-git; the helper will
    # ask to replace it. Flag it up front so the prompt is not a surprise.
    if pacman -Q waybar &>/dev/null; then
        echo "   -> official 'waybar' is installed; the AUR helper will ask to replace it"
    fi
    if command -v yay &>/dev/null; then
        yay -S --needed waybar-git || warn "waybar-git install failed"
    else
        paru -S --needed waybar-git || warn "waybar-git install failed"
    fi
fi

echo ":: making the module scripts executable"
# config.jsonc calls these by absolute path; a clone that lost its exec bits
# (zip/tarball, a copy across filesystems) makes every custom/* module die
# silently, with no error anywhere.
chmod +x "$SCRIPTS"/*.sh "$SCRIPTS"/*.py || warn "could not chmod +x $SCRIPTS/*"

echo ":: creating the runtime cache dir"
mkdir -p "$HOME/.cache/waybar" || warn "could not create ~/.cache/waybar"

echo ":: enabling system services at boot"
sudo systemctl enable --now NetworkManager || warn "NetworkManager did not start"
sudo systemctl enable --now bluetooth.service || warn "bluetooth.service did not start"
if ! sudo systemctl enable --now power-profiles-daemon; then
    if systemctl is-active --quiet tlp; then
        warn "power-profiles-daemon did not start — tlp is active and conflicts with it"
    else
        warn "power-profiles-daemon did not start — the #power-profiles-daemon module will be empty"
    fi
fi

if pacman -Q dunst &>/dev/null; then
    echo ":: masking dunst ('stop' is not enough since it is dbus-activated)"
    systemctl --user mask --now dunst.service || warn "could not mask dunst.service"
else
    echo ":: dunst not installed, nothing to mask"
fi

# swaync is started by the 'swaync &' line in the hyprland autostart, which runs
# it BEFORE waybar — custom/swaync renders empty otherwise. Do NOT enable
# swaync.service: it is WantedBy=graphical-session.target, a target this
# Hyprland session never activates, so the unit would never start at boot; and
# 'enable --now' against an already-running swaync just fails with
# "An instance of SwayNotificationCenter is already running!".
echo ":: leaving swaync to the hyprland autostart"
if systemctl --user cat swaync.service &>/dev/null; then
    systemctl --user disable swaync.service &>/dev/null
    systemctl --user reset-failed swaync.service &>/dev/null
    echo "   -> swaync.service disabled + failed state cleared (autostart owns swaync)"
fi

echo
echo ":: verify"
missing=0
for cmd in jq nmcli bluetoothctl swaync-client powerprofilesctl wpctl waybar hyprctl python3; do
    if command -v "$cmd" &>/dev/null; then
        printf '   ok      %s\n' "$cmd"
    else
        printf '   MISSING %s\n' "$cmd"
        missing=1
    fi
done

for f in "$SCRIPTS"/*.sh "$SCRIPTS"/*.py; do
    [ -x "$f" ] || { printf '   NOT EXECUTABLE %s\n' "$f"; missing=1; }
done

for f in "$HOME/.config/swaync/config.json" "$HOME/.config/swaync/style.css"; do
    [ -f "$f" ] || { printf '   MISSING %s\n' "$f"; missing=1; }
done

# NOTE: no `grep -q` here — it exits on the first match, SIGPIPEs fc-list, and
# `set -o pipefail` then reports the pipeline as failed even though the font exists.
if fc-list 2>/dev/null | grep -i "JetBrainsMono Nerd Font Propo" >/dev/null; then
    printf '   ok      JetBrainsMono NFP font\n'
else
    printf '   MISSING JetBrainsMono NFP font — glyphs will render as boxes\n'
    missing=1
fi

echo
if [ "${#WARNINGS[@]}" -gt 0 ]; then
    echo ":: ${#WARNINGS[@]} warning(s) during setup:"
    for w in "${WARNINGS[@]}"; do echo "   - $w"; done
    echo
fi

if [ "$missing" -eq 0 ] && [ "${#WARNINGS[@]}" -eq 0 ]; then
    echo ":: all checks passed."
else
    echo ":: setup finished with issues above — re-running this script is safe."
fi

echo
echo ":: start the bar:  $SCRIPTS/launch.sh"
echo "   If a module is missing from the bar, run 'killall waybar; waybar' and read the"
echo "   foreground output — waybar drops a broken module silently. A missing"
echo "   #power-profiles-daemon usually means waybar was built without that module."
