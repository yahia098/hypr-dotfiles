-------------------
---- AUTOSTART ----
-------------------
hl.on("hyprland.start", function()
	hl.exec_cmd("$HOME/.config/hypr/scripts/prelock.sh")
	hl.exec_cmd("swaync")
	hl.exec_cmd("$HOME/.config/waybar/scripts/wallpaper.sh")
	hl.exec_cmd("$HOME/.config/waybar/scripts/launch.sh")
	hl.exec_cmd("hypridle")
end)
os.execute("$HOME/.config/waybar/scripts/launch.sh")
-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
