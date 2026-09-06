#!/usr/bin/env python3
"""
workspace_bar_daemon — the persistent background half of the SUPER+A "per-workspace bar
hiding" mechanism. Listens on Hyprland's socket2; on every workspace switch it checks the
~/.cache/waybar/hidden_workspaces list and, if that workspace is marked "bar-less", kills
waybar, otherwise (if not running) starts it.

Waybar has no runtime "hide" IPC, so the mechanism is kill/relaunch based. SUPER+A also
applies the change directly in toggle_workspace_bar.sh for instant feedback; this daemon
then tracks switches automatically. Runs from the hyprland.lua autostart.
"""

import json
import os
import socket
import subprocess
import time

RUNTIME = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
SIG = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE", "")
SOCK_PATH = os.path.join(RUNTIME, "hypr", SIG, ".socket2.sock")
HIDDEN_FILE = os.path.expanduser("~/.cache/waybar/hidden_workspaces")


def hidden_workspaces():
    try:
        with open(HIDDEN_FILE) as fh:
            return {line.strip() for line in fh if line.strip()}
    except FileNotFoundError:
        return set()


def waybar_running():
    return subprocess.run(["pgrep", "-x", "waybar"],
                          capture_output=True).returncode == 0


def apply(workspace):
    want_hidden = str(workspace) in hidden_workspaces()
    running = waybar_running()
    if want_hidden and running:
        subprocess.run(["killall", "waybar"])
    elif not want_hidden and not running:
        subprocess.Popen(["waybar"],
                         stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def current_workspace():
    try:
        out = subprocess.check_output(["hyprctl", "activeworkspace", "-j"],
                                      text=True)
        return str(json.loads(out)["id"])
    except Exception:
        return None


def main():
    ws = current_workspace()
    if ws is not None:
        apply(ws)

    while True:
        try:
            sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            sock.connect(SOCK_PATH)
        except (FileNotFoundError, ConnectionRefusedError, OSError):
            time.sleep(2)
            continue

        buf = b""
        try:
            for chunk in iter(lambda: sock.recv(4096), b""):
                buf += chunk
                while b"\n" in buf:
                    raw, buf = buf.split(b"\n", 1)
                    line = raw.decode("utf-8", "replace")
                    if line.startswith(("workspace>>", "workspacev2>>")):
                        val = line.split(">>", 1)[1]
                        if line.startswith("workspacev2>>"):
                            val = val.split(",", 1)[0]
                        apply(val.strip())
        except OSError:
            pass
        finally:
            sock.close()
        time.sleep(1)


if __name__ == "__main__":
    main()
