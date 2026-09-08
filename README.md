![Showcase](images/waybar.png)

# Waybar config

A personal [Waybar](https://github.com/Alexays/Waybar) status bar for **Hyprland on Arch**,
themed [Catppuccin Mocha](https://catppuccin.com/). Paired with [swaync](https://github.com/ErikReider/SwayNotificationCenter)
as the notification center (replacing dunst).

Built against `waybar-git` (AUR), not the official `waybar` package. The setup
script installs it — and `yay` too, if you have no AUR helper. Note that
`waybar-git` rebuilds on every system update, which takes a few minutes.

## Installation

For Arch (or an Arch derivative).

- First, get the config (back up any existing `~/.config/waybar`) -

```
$ git clone https://github.com/darciarch/Waybar-Config ~/.config/waybar
```

- Then, install packages, system services and swaync/dunst setup -

```
$ ~/.config/waybar/scripts/first_time_setup.sh
```

- Finally, start the bar -

```
$ ~/.config/waybar/scripts/launch.sh
```


## Autostart / Hyprland setup

Add to `~/.config/hypr/hyprland.lua`:

```lua
-- Autostart — swaync must come before waybar
hl.exec_once("swaync &")
hl.exec_once("waybar &")
hl.exec_once("python ~/.config/waybar/scripts/workspace_bar_daemon.py &")

-- Toggle the bar on the current workspace
hl.bind("SUPER", "A", hl.dsp.exec("~/.config/waybar/scripts/toggle_workspace_bar.sh"))
```

Log out and back in.

Python scripts use the standard library only — no `pip install` required.


## Restarting the bar

After editing the config, restart the bar:

```
$ ~/.config/waybar/scripts/launch.sh
```

Kills a running instance if there is one, otherwise starts a new one.



## Layout

- `config.jsonc` — module placement and per-module config (JSONC: comments OK, trailing commas not)
- `style.css` — GTK3 CSS (not web CSS: no flexbox, no `gap`)
- `scripts/` — the `custom/*` module backends and helpers
- `~/.config/swaync/{config.json,style.css}` — notification center, themed to match the bar

### Modules

| Position | Modules |
|----------|---------|
| left     | clock, battery, window (app name + icon) |
| center   | workspaces |
| right    | backlight, volume (wireplumber), uptime, wifi, power-profile, sysinfo, swaync |

- **clock** — `H:M`, calendar in the tooltip
- **custom/window** — the focused app's name (not its title), prefixed with the app's real icon
  when one resolves from its `.desktop` entry, otherwise a `󰖯` glyph (`scripts/window.py`).
  The bar background turns transparent when the active workspace has no windows
- **battery** — icon + %, color-only warning/critical (no blink)
- **backlight** — icon + %
- **volume** — scroll to change, left click mutes output, right click opens `pavucontrol`.
  A mic-off glyph appears after the % when the microphone is muted
- **custom/uptime** — shows `uptime -p`, doubles as a stopwatch (left click start/pause,
  right click reset), state in the tooltip (`scripts/uptime.sh` + `scripts/stopwatch.sh`)
- **custom/wifi** — WiFi signal + Bluetooth merged into one tooltip (`scripts/wifi_bt.sh`)
- **power-profiles-daemon** — click cycles the power profile
- **custom/sysinfo** — CPU + RAM in one icon, exact numbers in the tooltip.
  **Clicking it closes every Hyprland window**, then relaunches a fixed app set onto
  workspaces 1/3/4/5 (`scripts/sysinfo.sh` + `scripts/focus.sh`)
- **custom/swaync** — notification counter, click toggles the panel, right click toggles DND

Mic mute is not on the bar. Toggle it with `XF86AudioMicMute` / F9 — the volume capsule
shows the muted state.

## Per-workspace bar hiding

`SUPER + A` toggles the bar for the current workspace only. It marks the workspace in
`~/.cache/waybar/hidden_workspaces`, then kills and relaunches Waybar
(`scripts/toggle_workspace_bar.sh`).

`scripts/workspace_bar_daemon.py` runs in the background, listens on Hyprland's socket2,
and relaunches Waybar on every workspace switch to match that file.

If the bar won't come up, check `~/.cache/waybar/hidden_workspaces` — the workspace may
be marked hidden.

## Dependencies

All installed by `first_time_setup.sh`. This list is just what each one does.

| Tool | Used by |
|---------|---------|
| `jq` | all `custom/*` JSON modules |
| `nmcli` + `bluetoothctl` | `custom/wifi` |
| `swaync-client` | `custom/swaync`, notifications |
| `powerprofilesctl` | power profile module |
| `wpctl` (WirePlumber) | volume and mute |
| `JetBrainsMono Nerd Font` | glyphs in the bar |

`waybar-git` builds with Meson auto-features, so a module is silently dropped
if its library is missing at build time. If the power profile icon does not
show up, rebuild waybar-git after the packages above are installed.