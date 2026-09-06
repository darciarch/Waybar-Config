# Waybar config

A personal [Waybar](https://github.com/Alexays/Waybar) (v0.15.x) status bar for **Hyprland on Arch**,
themed [Catppuccin Mocha](https://catppuccin.com/). Paired with [swaync](https://github.com/ErikReider/SwayNotificationCenter)
as the notification center (replacing dunst).

This is a config, not a software project: no build, no tests, no package manager.
**"Deploying" a change means restarting Waybar.**

## Commands

```bash
# Apply changes — kills a running bar, otherwise starts one (manual restart tool)
~/.config/waybar/scripts/launch.sh

# Validate config + watch runtime errors in the foreground (Ctrl-C to quit).
# Waybar silently drops a module whose JSON is malformed, so always check here after editing.
killall waybar; waybar

# Reload style.css only, without restarting
killall -SIGUSR2 waybar

# One-time system setup (swaync install, power-profiles-daemon enable, dunst mask) — needs sudo
~/.config/waybar/scripts/first_time_setup.sh
```

## Layout

- `config.jsonc` — module placement and per-module config (JSONC: comments OK, trailing commas not)
- `style.css` — GTK3 CSS (not web CSS: no flexbox, no `gap`)
- `scripts/` — the `custom/*` module backends and helpers (see below)
- `~/.config/swaync/{config.json,style.css}` — notification center, themed to match the bar

### Modules

| Position | Modules |
|----------|---------|
| left     | clock, power-profiles-daemon, window title |
| center   | workspaces |
| right    | battery, backlight, volume (wireplumber), uptime, wifi, sysinfo, swaync |

- **clock** — `H:M`, calendar in the tooltip
- **custom/window** — active window title, cleaned (leading status glyphs and a trailing ` — App`
  suffix stripped) and scaled down in steps so it always fits, with a fixed window glyph prefix
  (`scripts/window.py`)
- **power-profiles-daemon** — click cycles the power profile
- **battery** — icon + %, color-only warning/critical (no blink)
- **volume** — scroll to change; left click mutes output; right click opens `pavucontrol`.
  A mic-off glyph appears after the % when the microphone is muted.
- **custom/uptime** — shows `uptime -p`; also a stopwatch (left click start/pause, right click reset),
  state shown in the tooltip (`scripts/uptime.sh` + `scripts/stopwatch.sh`)
- **custom/wifi** — WiFi signal + Bluetooth merged into one tooltip (`scripts/wifi_bt.sh`,
  interface hardcoded to `wlo1`)
- **custom/sysinfo** — CPU + RAM in one icon, exact numbers in the tooltip. The capsule pulses to
  show it is clickable; **clicking it is destructive** — it closes every Hyprland window, then
  relaunches a fixed app set onto workspaces 1/3/4/5 (`scripts/sysinfo.sh` + `scripts/focus.sh`)
- **custom/swaync** — notification counter; click toggles the panel, right click toggles DND

### Mic mute

Not on the bar. Toggle with `XF86AudioMicMute` / F9. The volume capsule shows the muted state.

## Per-workspace bar hiding

**SUPER+A** toggles the bar *for the current workspace*: it marks the workspace in
`~/.cache/waybar/hidden_workspaces` and kills/relaunches Waybar immediately
(`scripts/toggle_workspace_bar.sh`).

`scripts/workspace_bar_daemon.py` runs in the background (Hyprland autostart), listens on Hyprland's
socket2, and kills/relaunches Waybar on every workspace switch to match that file.

So a bar that "won't start" may just be a hidden-marked workspace — check
`~/.cache/waybar/hidden_workspaces`.

## Dependencies

- `jq` — all `custom/*` JSON modules
- `nmcli` + `bluetoothctl` — `custom/wifi`
- `swaync-client` — `custom/swaync` and notifications
- `powerprofilesctl` (power-profiles-daemon, active + enabled) — power profile module;
  Waybar must be built with the module or it is silently dropped
- `wpctl` (WirePlumber) — volume and mute
- `JetBrainsMono Nerd Font` — glyphs in the bar

swaync must start **before** Waybar (it does, from the Hyprland autostart), or `custom/swaync`
renders empty.
