--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

-- Example window rules that are useful

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

-- Layer rules also return a handle.
-- local overlayLayerRule = hl.layer_rule({
--     name  = "no-anim-overlay",
--     match = { namespace = "^my-overlay$" },
--     no_anim = true,
-- })
-- overlayLayerRule:set_enabled(false)

-- Hyprland-run windowrule
hl.window_rule({
	name = "move-hyprland-run",
	match = { class = "hyprland-run" },

	move = "20 monitor_h-120",
	float = true,
})
--for opengl learning
hl.window_rule({
	name = "opengl floating",
	match = { title = "^LearnOpenGL$" },
	float = true,
	center = true,
})
hl.window_rule({
	name = "lutris floating",
	match = { class = "net.lutris.Lutris" },
	float = true,
	size = { 900, 900 },
	move = { 100, 100 },
	border_size = 5,
})

hl.window_rule({
	name = "network floating",
	match = { class = "nm-connection-editor" },
	move = { 1300, 30 },
	float = true,
})
hl.window_rule({
	name = "audio floating",
	match = { title = "Volume Control" },
	move = { 1200, 30 },
	size = { 720, 500 },
	float = true,
})

hl.window_rule({
	name = "PolyMC floating",
	match = { class = "org.polymc.PolyMC" },
	float = true,
	size = { 900, 600 },
})

hl.window_rule({
	name = "nautilus float",
	match = { class = "org.gnome.Nautilus" },
	float = true,
	size = { 1100, 800 },
	move = { 50, 140 },
})

hl.window_rule({
	name = "Xarchiver float",
	match = { class = "xarchiver" },
	float = true,
	size = { 750, 800 },
	move = { 1160, 140 },
})

hl.window_rule({
	name = "portal file chooser",
	match = { class = "^xdg-desktop-portal-gtk$" },
	float = true,
	center = true,
	size = { 1000, 700 },
})

hl.window_rule({
	name = "floating downloads",
	match = {
		class = "librewolf",
		title = "Library",
	},
	float = true,
	center = true,
	size = { 1000, 700 },
})
