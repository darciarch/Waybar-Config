#!/usr/bin/env python3
"""
window.py — the custom/window backend.

Replaces the built-in hyprland/window module: that one cannot scale the font to
the title length or strip the app-name suffix. This one listens on Hyprland's
socket2 (same connect/parse pattern as workspace_bar_daemon.py) and on every
active-window change re-reads `hyprctl activewindow -j`, cleans the title (drops
leading status glyphs and a trailing " — App" / " - App" suffix), scales it down
in steps with Pango <span size=...>, and prefixes a single fixed window glyph
(U+F05AF). Empty title keeps the "OH HEEL NA!" easter egg. The module is always
visible (glyph at minimum). One JSON line per event, flushed.

Font sizes are expressed in px and converted to Pango units; MIN_PX is a hard
floor, so no step can render smaller than that regardless of the ladder below.

Opens its own socket2 connection, independent of workspace_bar_daemon.py
(socket2 is multi-client); that daemon is not touched.
"""

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
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass

RUNTIME = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
SIG = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE", "")
SOCK_PATH = os.path.join(RUNTIME, "hypr", SIG, ".socket2.sock")

GLYPH = "\U000F05AF"  # 󰖯 — fixed window prefix (see CLAUDE.md: escape fragile glyphs)
EMPTY_TEXT = "OH HEEL NA!"

LEADING_MARKS = re.compile(r"^[\s✳●○◆▶*•‣–—]+")
TRAILING_APP = re.compile(r"\s[—-]\s[^—-]{1,30}$")

# Font sizing. BASE_PX must match `#custom-window { font-size: ... }` in
# style.css, otherwise the "no span needed" shortcut in px_span() misfires.
BASE_PX = 13
MIN_PX = 10  # hard floor — never render smaller than this
PX_TO_PANGO = 0.75 * 1024  # px -> pt (at 96 DPI) -> Pango units (1/1024 pt)


def active_window():
    try:
        out = subprocess.check_output(["hyprctl", "activewindow", "-j"], text=True)
        data = json.loads(out)
    except Exception:
        return None
    if not isinstance(data, dict) or not data.get("class"):
        return None
    return data


def clean_title(title):
    t = LEADING_MARKS.sub("", title)
    t = TRAILING_APP.sub("", t)
    return t.strip()


def px_span(esc, px):
    px = max(px, MIN_PX)
    if px >= BASE_PX:
        return esc  # base size, no markup needed
    return f"<span size='{round(px * PX_TO_PANGO)}'>{esc}</span>"


def sized(text):
    esc = html.escape(text)
    n = len(text)
    if n <= 32:
        return px_span(esc, BASE_PX)
    if n <= 46:
        return px_span(esc, 11)
    return px_span(esc, 10)


def emit(win):
    if win is None:
        text = EMPTY_TEXT
        klass = ""
        tooltip = ""
    else:
        raw = win.get("title", "") or ""
        cleaned = clean_title(raw)
        text = sized(cleaned) if cleaned else EMPTY_TEXT
        klass = (win.get("class", "") or "").lower()
        tooltip = raw
    payload = {"text": f"{GLYPH} {text}", "class": klass, "tooltip": tooltip}
    # ensure_ascii=False: waybar's JSON parser wants literal UTF-8, not \u
    # surrogate-pair escapes for the 4-byte glyph (matches the jq-based scripts).
    sys.stdout.write(json.dumps(payload, ensure_ascii=False) + "\n")
    sys.stdout.flush()


def refresh():
    emit(active_window())


HEARTBEAT = 2.0  # re-emit current state every N s (covers a missed first line
                 # on waybar startup and keeps the module populated)


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
        refresh()  # emit on (re)connect
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