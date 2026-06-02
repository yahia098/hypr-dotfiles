hl.on("hyprland.start", function()
	hl.exec_cmd("$HOME/.config/waybar/scripts/launch.sh")
	hl.exec_cmd("hyprpaper")
end)

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
