# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A personal Waybar (v0.15.x) status bar config for Hyprland on Arch. Not a software project — there is
no build, no tests, no package manager, and no git repo. "Deploying" a change means restarting Waybar.

## Commands

```bash
# Apply changes (kills a running bar, otherwise starts one). Manual restart tool.
~/.config/waybar/scripts/launch.sh

# Validate config + see runtime errors in the foreground (Ctrl-C to quit).
# Waybar silently drops a module whose JSON is malformed, so always check here after editing.
killall waybar; waybar

# Reload style.css only, without restarting:
killall -SIGUSR2 waybar

# One-time system setup (swaync install, ppd enable, dunst mask) — needs sudo:
~/.config/waybar/scripts/first_time_setup.sh
```

**SUPER+A** is bound (in `hyprland.lua`) to `scripts/toggle_workspace_bar.sh`, not `launch.sh`.
It toggles the bar *per workspace*: it marks the active workspace in
`~/.cache/waybar/hidden_workspaces` and kills/relaunches immediately.
`scripts/workspace_bar_daemon.py` runs in the background (hyprland autostart), listens on
Hyprland's socket2, and kills/relaunches Waybar on every workspace switch to match that file.
So a bar that "won't start" may just be a hidden-marked workspace — check that cache file.

## Layout

- `config.jsonc` — module placement (`modules-left`/`-center`/`-right`) plus per-module config. JSONC:
  comments are legal, trailing commas are not.
- `style.css` — GTK3 CSS (not web CSS: no flexbox, no `gap`, limited selectors).
- `scripts/focus.sh` — the `custom/focus` click handler. **Destructive**: closes every Hyprland client
  via `hyprctl clients -j | jq`, then relaunches a fixed app set onto workspaces 1/3/4/5. Treat edits
  to it as changes to the user's session-wipe button.
- `scripts/launch.sh` — the manual toggle/restart wrapper.
- `scripts/toggle_workspace_bar.sh` — SUPER+A handler; per-workspace hide via
  `~/.cache/waybar/hidden_workspaces`.
- `scripts/workspace_bar_daemon.py` — long-running (hyprland autostart); enforces that cache file on
  every workspace switch by killing/relaunching Waybar.
- `scripts/wifi_bt.sh` — `custom/wifi` exec: nmcli + bluetoothctl merged into one JSON blob.
- `scripts/sysinfo.sh` — `custom/sysinfo` exec: CPU% (from `/proc/stat`) + RAM, one icon, `class`
  flips normal/warning/critical.
- `scripts/uptime.sh` — `custom/uptime` exec: always shows `uptime -p` (same sed as the old inline
  `exec`); the stopwatch state lives in the **tooltip** and drives `class` (`idle`/`running`/`paused`).
- `scripts/stopwatch.sh` — stopwatch **state helper** only: `toggle`/`reset` args write
  `~/.cache/waybar/stopwatch_state` (`running:start_epoch:accumulated`). `custom/uptime`'s
  `on-click`/`on-click-right` call it directly; display is `uptime.sh`. Its arg-less JSON path is
  now dead code (harmless).
- `scripts/first_time_setup.sh` — one-time sudo/systemd setup (swaync, ppd, dunst mask).
- `~/.config/swaync/{config.json,style.css}` — notification centre (replaces dunst), Mocha-themed to
  match the bar's capsule language. `widgets`: title, dnd, `mpris` (media — replaces the old
  `custom/media` bar box), `buttons-grid` (one mic-mute toggle), notifications.

## Conventions that matter when editing

- **`hyprctl dispatch` takes Lua here, not plain strings.** This machine's Hyprland runs a Lua
  config (`~/.config/hypr/hyprland.lua`), so `hyprctl dispatch` parses its argument as a Lua
  expression — the old `hyprctl dispatch closewindow address:0x…` / `hyprctl dispatch exec
  "[workspace 1 silent] app"` forms fail with a Lua parse error and the dispatch silently does
  nothing. Use `hl.dsp.*`: `hyprctl dispatch "hl.dsp.window.close({ window =
  hl.get_window('address:0x…') })"`, `hyprctl dispatch 'hl.dsp.exec_cmd("[workspace 1 silent]
  app")'` (window-rule prefix still goes inside the string), `hl.dsp.focus({ workspace = N })`,
  `hl.dsp.window.move({ workspace = N })`. `~/.config/hypr/swap_workspace.sh` is the reference.

- **Module id → CSS selector**: a module named `custom/uptime` in the config is styled as
  `#custom-uptime` in CSS (slash becomes a dash); built-ins map straight across (`cpu` → `#cpu`).
  Adding a module means touching both files, or it renders unstyled.
- **Palette is Catppuccin Mocha** (`#1e1e2e` surface, `#11111b` crust, `#cdd6f4` text, `#f38ba8`,
  `#94e2d5`, `#cba6f7`, `#74c7ec`, `#f9e2af`, `#a6e3a1`). Match these rather than introducing new hues.
- Module chrome is uniform: `padding: 0.15rem 1rem; margin: 0.5rem 0.2rem 0.7rem 0rem;
  border-radius: 1rem; background-color: #1e1e2e`, with only the text `color` differing per module.
  New modules should join the shared selector list, not get their own block.
- Glyphs in `format` strings are Nerd Font icons rendered with `JetBrainsMono NFP` — they look like
  blank/garbled characters in a plain editor. Don't "clean up" or normalize them. In `config.jsonc`,
  prefer the 4-byte Material-Design range (`󰂄`, `U+F0xxx`) over the 3-byte FontAwesome range
  (`U+Exxx`/`U+F1xx`–`U+F2xx`) — some editors/tools silently drop the 3-byte ones. In shell scripts,
  build fragile glyphs with `$'\uXXXX'` or `printf '\uXXXX'` so they survive editing (see
  `scripts/sysinfo.sh`, `stopwatch.sh`, `uptime.sh`).
- The `*` rule in `style.css` deliberately carries no padding/margin — a comment there notes the effect
  compounds across every widget. Set spacing on individual `#module` selectors instead.
- Tooltip and calendar strings use Pango markup (`<span color=…>`), not CSS.
- The Wi-Fi interface on this machine is **`wlo1`** (hardcoded in `scripts/wifi_bt.sh`). The old
  `network` module was pinned to `wlan0`, which was already wrong — don't reintroduce it.
- **Script `custom/*` modules depend on**: `jq` (all JSON modules), `nmcli` + `bluetoothctl`
  (`custom/wifi`), `swaync-client` (`custom/swaync` — `exec-if` is `swaync-client -c -sw`, which
  waits for the daemon and reconnects on a waybar restart).
- **Media** is not a bar module — it lives in the swaync panel as the `mpris` widget
  (`~/.config/swaync/config.json`). YouTube/Netflix in the browser publish MPRIS, so they show there.
- **Power profile**: native `power-profiles-daemon` module (needs `powerprofilesctl` active +
  enabled; waybar must be built with the module or it silently drops — check `killall waybar; waybar`
  foreground). Click cycles the profile. CSS makes it butt against `#battery` as one capsule
  (`#battery` gets `border-radius: 1rem 0 0 1rem; margin-right: 0`, `#power-profiles-daemon` the
  mirror + `margin-left: -2px` to close the `spacing: 2` seam).
- **Mic mute** is not on the bar. It's the single `buttons-grid` toggle in the swaync panel
  (`wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle`, `update-command` echoes `true` when MUTED →
  `button:checked` turns red). The `wireplumber` capsule's `format-source*` are blanked.
- **`XF86AudioMicMute`** → mic mute (was wrongly double-bound to `hyprshot -m region` in
  `hyprland.lua`; that line was removed). Region screenshot is now **`SUPER + Print`**.
- Notifications: **`swaync`**, not dunst. `dunst.service` is dbus-activated, so it must be
  `systemctl --user mask`ed (plain stop lets the next notification revive it) — `first_time_setup.sh`
  does this. swaync starts from `hyprland.lua` autostart (`swaync &`) — **before `waybar`**, or
  `custom/swaync` renders empty.
- CSS-class-driven color modules: `#battery` (`.warning`/`.critical` from `states`), `#custom-sysinfo`
  (`.warning`/`.critical` from the script's `class` field), `#custom-wifi` (`.disconnected`),
  `#custom-uptime` (`.running`/`.paused` from `uptime.sh`). **No blink/animation anywhere** — low
  states change color only, deliberately.
- Scripts are referenced by absolute path via `$HOME` in `config.jsonc` and must stay executable.

## Language note

Inline comments in `style.css` are in Turkish (the user's language). Keep new comments consistent with
the surrounding file and don't translate existing ones away.
