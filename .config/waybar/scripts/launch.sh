#!/usr/bin/env bash

pkill -TERM -x waybar 2>/dev/null || true
sleep 0.2
exec waybar
