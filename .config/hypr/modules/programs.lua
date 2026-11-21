------------------------------------------------------------
-- Programs and script paths
--
-- Every command that keybinds.lua or autostart-env.lua launches is
-- defined here, so swapping an app is a one-line change.
------------------------------------------------------------

local home = os.getenv("HOME")

Scripts = home .. "/.config/hypr/scripts/"

Programs = {
	Terminal = "kitty",
	FileManager = "nautilus",
	Menu = "wofi --show drun",
	Browser = "librewolf",
	Pdf = "evince",
	Notes = "helixnotes",
	Discord = "discord",
	Telegram = "Telegram",
	Whatsie = "whatsie",
	Games = "lutris",
}
