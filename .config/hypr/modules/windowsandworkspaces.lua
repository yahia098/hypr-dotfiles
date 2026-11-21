--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

-- Positions and sizes below are written in pixels on a 1920x1080 screen and
-- converted to fractions of the monitor, so they scale to any 16:9 resolution.
local function px(x, y)
	return string.format("monitor_w*%.4f monitor_h*%.4f", x / 1920, y / 1080)
end

local suppressMaximizeRule = hl.window_rule({
	-- Ignore maximize requests from all apps. You'll probably like this.
	name = "suppress-maximize-events",
	match = { class = ".*" },

	suppress_event = "maximize",
})
-- suppressMaximizeRule:set_enabled(false)

hl.window_rule({
	-- Fix some dragging issues with XWayland
	name = "fix-xwayland-drags",
	match = {
		class = "^$",
		title = "^$",
		xwayland = true,
		float = true,
		fullscreen = false,
		pin = false,
	},

	no_focus = true,
})

-- Hyprland-run windowrule
hl.window_rule({
	name = "move-hyprland-run",
	match = { class = "hyprland-run" },

	move = px(20, 1080 - 120),
	float = true,
})
-- OpenGL learning window
hl.window_rule({
	name = "opengl-float",
	match = { title = "^LearnOpenGL$" },
	float = true,
	center = true,
})
hl.window_rule({
	name = "lutris-float",
	match = { class = "net.lutris.Lutris" },
	float = true,
	size = px(900, 900),
	move = px(100, 100),
	border_size = 5,
})

hl.window_rule({
	name = "network-editor-float",
	match = { class = "nm-connection-editor" },
	move = px(1300, 30),
	float = true,
})
hl.window_rule({
	name = "volume-control-float",
	match = { title = "Volume Control" },
	move = px(1200, 30),
	size = px(720, 500),
	float = true,
})
hl.window_rule({
	name = "steam-float",
	match = { class = "steam_class_default" },
	float = true,
})
hl.window_rule({
	name = "polymc-float",
	match = { class = "org.polymc.PolyMC" },
	float = true,
	size = px(900, 600),
})

hl.window_rule({
	name = "nautilus-float",
	match = { class = "org.gnome.Nautilus" },
	float = true,
	size = px(1100, 800),
	move = px(50, 140),
})

hl.window_rule({
	name = "xarchiver-float",
	match = { class = "xarchiver" },
	float = true,
	size = px(750, 800),
	move = px(1160, 140),
})

hl.window_rule({
	name = "portal-file-chooser-float",
	match = { class = "^xdg-desktop-portal-gtk$" },
	float = true,
	center = true,
	size = px(1000, 700),
})

hl.window_rule({
	name = "librewolf-library-float",
	match = {
		class = "librewolf",
		title = "Library",
	},
	float = true,
	center = true,
	size = px(1000, 700),
})
