#!/bin/bash
# SUPER+A → aktif workspace'i "barsız" işaretle / işareti kaldır ve DEĞİŞİKLİĞİ
# ANINDA uygula (daemon'u beklemeden). workspace_bar_daemon.py sonraki geçişleri
# otomatik takip eder. Bağımlılıklar: hyprctl, jq.

HIDDEN="$HOME/.cache/waybar/hidden_workspaces"
mkdir -p "$(dirname "$HIDDEN")"
touch "$HIDDEN"

ws=$(hyprctl activeworkspace -j | jq -r '.id')
[[ -z "$ws" || "$ws" == "null" ]] && exit 1

if grep -qxF "$ws" "$HIDDEN"; then
    grep -vxF "$ws" "$HIDDEN" > "$HIDDEN.tmp" || true
    mv "$HIDDEN.tmp" "$HIDDEN"
    pgrep -x waybar >/dev/null || setsid -f waybar >/dev/null 2>&1
else
    echo "$ws" >> "$HIDDEN"
    pgrep -x waybar >/dev/null && killall waybar
fi
