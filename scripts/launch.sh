#!/bin/bash

pgrep -x waybar >/dev/null && killall waybar || waybar &
