#!/usr/bin/env python3
"""
window.py — the custom/window backend.

Shows the focused window's APPLICATION name (not its title). It is prefixed with
the app's real icon when one can be resolved from its `.desktop` entry, and with
a fixed window glyph (U+F05AF, 󰖯) as the fallback when it cannot.

The real icon reaches waybar through AIconLabel's embedded-icon escape: a label
shaped  \\0icon\\1f<icon-name-or-path>\\n<text>  makes waybar render the icon as a
Gtk::Image and show <text> beside it (see waybar `src/AIconLabel.cpp`,
`extractIcon`). Those `\\0` `\\1f` `\\n` are the LITERAL two-character sequences
backslash-zero / backslash-one-f / backslash-n, not control bytes.

waybar re-runs the icon extraction on every module update and strips the escape
out of the label on the first pass, so re-emitting an unchanged payload makes it
re-run extraction against the already-cleaned label and drop the image. This
script therefore DEDUPES — one JSON line per actual change, nothing on a repeat.

Bar transparency on an empty workspace is handled separately by a hidden
built-in `hyprland/window` module (it toggles `window#waybar.empty`, which
`style.css` styles); this script only draws the `#custom-window` capsule.

socket2 connect/parse pattern matches `workspace_bar_daemon.py`; own connection,
independent of that daemon.
"""

import configparser
import html
import json
import os
import re
import socket
import subprocess
import sys
import time

# waybar may start us with an ASCII locale; force UTF-8 or the glyph write crashes.
try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace", line_buffering=True)
except Exception:
    pass

RUNTIME = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
SIG = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE", "")
SOCK_PATH = os.path.join(RUNTIME, "hypr", SIG, ".socket2.sock")

GLYPH = "\U000F05AF"  # 󰖯 — fallback window glyph (see CLAUDE.md: escape fragile glyphs)
EMPTY_TEXT = "OH HEEL NA!"

# waybar AIconLabel embedded-icon markers — LITERAL "\0icon\1f" <name> "\n" <text>
ICON_HEAD = "\\0icon\\1f"
ICON_TAIL = "\\n"

# app-name prettifier: strip a reverse-DNS prefix (org.kde.dolphin -> dolphin)
RDNS = re.compile(r"^(?:[A-Za-z0-9-]+\.)+([A-Za-z0-9-]+)$")

HEARTBEAT = 5.0  # re-check on this timeout too, in case a socket2 event was missed
                 # (deduped, so a no-op unless the window actually changed)


def sh(*args):
    try:
        return subprocess.check_output(args, text=True)
    except Exception:
        return ""


def active_window():
    try:
        data = json.loads(sh("hyprctl", "activewindow", "-j"))
    except Exception:
        return None
    if not isinstance(data, dict) or not data.get("class"):
        return None
    return data


def app_dirs():
    base = os.environ.get("XDG_DATA_DIRS", "/usr/local/share:/usr/share").split(":")
    home = os.environ.get("XDG_DATA_HOME") or os.path.expanduser("~/.local/share")
    out, seen = [], set()
    for d in (home, *base):
        p = os.path.join(d, "applications")
        if p not in seen and os.path.isdir(p):
            seen.add(p)
            out.append(p)
    return out


def desktop_entry(*app_ids):
    """[Desktop Entry] section for the first app id that has a .desktop file.

    Matches `<id>.desktop` exactly (case-insensitively) or as a filename suffix
    (`footclient` -> `org.codeberg.dnkl.footclient.desktop`)."""
    wants = [f"{a.lower()}.desktop" for a in app_ids if a]
    if not wants:
        return None
    for d in app_dirs():
        try:
            files = os.listdir(d)
        except OSError:
            continue
        hit = None
        for f in files:
            fl = f.lower()
            if fl in wants:
                hit = os.path.join(d, f)
                break
            if any(fl.endswith("." + w) for w in wants):
                hit = os.path.join(d, f)
        if not hit:
            continue
        cp = configparser.RawConfigParser(interpolation=None, strict=False)
        cp.optionxform = str
        try:
            cp.read(hit, encoding="utf-8")
        except Exception:
            continue
        if cp.has_section("Desktop Entry"):
            return cp["Desktop Entry"]
    return None


def resolve(win):
    cls = (win.get("class") or "").strip()
    icls = (win.get("initialClass") or "").strip()
    ent = desktop_entry(cls, icls)

    name = (ent.get("Name") or "").strip() if ent is not None else ""
    icon = (ent.get("Icon") or "").strip() if ent is not None else ""
    if not name:
        m = RDNS.match(cls)
        name = m.group(1) if m else (cls or icls or "?")
    return name, icon


def payload(win):
    if win is None:
        return {"text": f"{GLYPH} {EMPTY_TEXT}", "class": "empty", "tooltip": ""}
    name, icon = resolve(win)
    esc = html.escape(name, quote=False)
    if icon:
        text = f"{ICON_HEAD}{icon}{ICON_TAIL}{esc}"
    else:
        text = f"{GLYPH} {esc}"
    return {
        "text": text,
        "class": (win.get("class") or "").lower(),
        "tooltip": win.get("title") or "",
    }


_last = None


def emit(win):
    global _last
    # ensure_ascii=False: waybar's JSON parser wants literal UTF-8, not \u escapes
    line = json.dumps(payload(win), ensure_ascii=False)
    if line == _last:
        return
    _last = line
    sys.stdout.write(line + "\n")
    sys.stdout.flush()


def refresh():
    emit(active_window())


def main():
    refresh()

    while True:
        try:
            sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            sock.connect(SOCK_PATH)
        except (FileNotFoundError, ConnectionRefusedError, OSError):
            refresh()
            time.sleep(2)
            continue

        sock.settimeout(HEARTBEAT)
        refresh()  # re-check on (re)connect
        buf = b""
        try:
            while True:
                try:
                    chunk = sock.recv(4096)
                except socket.timeout:
                    refresh()
                    continue
                if not chunk:
                    break
                buf += chunk
                while b"\n" in buf:
                    raw, buf = buf.split(b"\n", 1)
                    line = raw.decode("utf-8", "replace")
                    if line.startswith(("activewindow>>", "activewindowv2>>")):
                        refresh()
        except OSError:
            pass
        finally:
            sock.close()
        time.sleep(1)


if __name__ == "__main__":
    main()
