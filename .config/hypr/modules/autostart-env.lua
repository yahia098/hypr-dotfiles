-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
	local scripts = os.getenv("HOME") .. "/.config/hypr/scripts/"

	-- Session services
	hl.exec_cmd("systemctl --user start hyprpolkitagent")
	hl.exec_cmd("awww-daemon")
	hl.exec_cmd("dunst")
	hl.exec_cmd("hypridle")
	hl.exec_cmd(scripts .. "displays.sh --watch") -- Re-applies monitor rules on hotplug
	hl.exec_cmd(scripts .. "battery-watch.sh")
	-- Theme: lock-screen background, GTK settings, bar and widgets
	hl.exec_cmd(scripts .. "prelock.sh")
	hl.exec_cmd(scripts .. "apply-gtk-settings.sh")
	hl.exec_cmd("$HOME/.config/waybar/scripts/launch.sh")
	hl.exec_cmd("eww open-many datetime statscard")

	-- Clipboard history (wiped each session, then watchers for text, images and files)
	hl.exec_cmd(
		"cliphist wipe && (wl-paste --type text --watch cliphist store >/dev/null 2>&1 & "
			.. "wl-paste --type image --watch cliphist store >/dev/null 2>&1 & "
			.. "wl-paste --type x-special/gnome-copied-files --watch cliphist store >/dev/null 2>&1 &)"
	)

	-- Messaging apps, started minimized to the tray
	hl.exec_cmd(Programs.Telegram .. " -startintray")
	hl.exec_cmd(Programs.Discord .. " --start-minimized")
	hl.exec_cmd(Programs.Whatsie .. " -minimized")
end)

--------------------------------
---- ENVIRONMENT VARIABLES ----
--------------------------------

hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XCURSOR_SIZE", "24")

hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("CLUTTER_BACKEND", "wayland")

hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
