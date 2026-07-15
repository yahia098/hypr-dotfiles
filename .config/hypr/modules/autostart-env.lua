-------------------
---- AUTOSTART ----
-------------------
hl.on("hyprland.start", function()
	hl.exec_cmd("$HOME/.config/hypr/scripts/prelock.sh")
	hl.exec_cmd("hyprpaper")
	hl.exec_cmd("swaync")
	hl.exec_cmd("$HOME/.config/waybar/scripts/launch.sh")
end)
hl.exec_cmd("qs")
os.execute("$HOME/.config/waybar/scripts/launch.sh")
-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
