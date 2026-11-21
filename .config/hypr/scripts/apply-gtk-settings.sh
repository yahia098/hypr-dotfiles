#!/usr/bin/env bash
# Single source of truth for the GTK/desktop appearance settings.
# Run at session start and by Matugen after each palette change.
set -u

gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'

# Resetting first forces GTK apps to re-read the regenerated colors.css.
gsettings set org.gnome.desktop.interface gtk-theme ''
gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
