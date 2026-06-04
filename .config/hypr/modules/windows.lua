-- =========================
-- Global behavior rules
-- =========================

-- Prevent maximize requests (keeps tiling consistent)
hl.window_rule({
	name = "suppress-maximize-events",
	match = {
		class = ".*",
	},
	suppress_event = "maximize",
})

-- Fix broken XWayland drag behavior (safe rule)
hl.window_rule({
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

-- =========================
-- Launcher / UI consistency
-- =========================

-- Wofi = modern floating launcher
hl.window_rule({
	name = "wofi-modern",
	match = {
		class = "wofi",
	},
	float = true,
	center = true,
	opacity = 0.95,
})
-- Optional: make wlogout match same aesthetic later
hl.window_rule({
	name = "wlogout-modern",
	match = {
		class = "wlogout",
	},
	float = true,
	center = true,
	opacity = 0.92,
})

hl.window_rule({
	name = "move-hyprland-run",
	match = {
		class = "hyprland-run",
	},
	move = "20 monitor_h-120",
	float = true,
})
