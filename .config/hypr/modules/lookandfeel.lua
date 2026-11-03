-----------------------
---- LOOK AND FEEL ----
-----------------------

------------------------------------------------------------
-- Design System
------------------------------------------------------------

local colors = dofile(os.getenv("HOME") .. "/.config/hypr/lua/matugen-colors.lua")

local spacing = {
	gaps_in = 5,
	gaps_out = 10,
	border_size = 2,
	rounding = 14,
}

local speed = {
	fast = 2,
	normal = 3,
	smooth = 4,
	borders = 5,
	global = 6,
	zoom = 7,
}

------------------------------------------------------------
-- General
------------------------------------------------------------

hl.config({
	general = {
		gaps_in = spacing.gaps_in,
		gaps_out = spacing.gaps_out,
		border_size = spacing.border_size,

		col = {
			active_border = {
				colors = {
					colors.primary,
					colors.tertiary,
					colors.primary,
				},
				angle = 45,
			},

			inactive_border = colors.surface_container_low,
		},

		resize_on_border = true,
		allow_tearing = false,

		layout = "master",
	},

	decoration = {
		rounding = spacing.rounding,
		rounding_power = 4.0, -- squircle corners; use 2.0 for plain circular arcs

		active_opacity = 1.0,
		inactive_opacity = 0.94,

		shadow = {
			enabled = true,
			range = 24,
			render_power = 3,
			color = colors.shadow,
		},

		blur = {
			enabled = true,
			size = 8,
			passes = 3, -- drop to 2 if you notice GPU lag
			vibrancy = 0.17,
			noise = 0.015,
			new_optimizations = true,
		},
	},

	animations = {
		enabled = true,
	},
})

------------------------------------------------------------
-- Curves
------------------------------------------------------------

hl.curve("easeOutQuint", {
	type = "bezier",
	points = {
		{ 0.23, 1.00 },
		{ 0.32, 1.00 },
	},
})

hl.curve("easeInOutCubic", {
	type = "bezier",
	points = {
		{ 0.65, 0.05 },
		{ 0.36, 1.00 },
	},
})

hl.curve("linear", {
	type = "bezier",
	points = {
		{ 0, 0 },
		{ 1, 1 },
	},
})

hl.curve("almostLinear", {
	type = "bezier",
	points = {
		{ 0.5, 0.5 },
		{ 0.75, 1 },
	},
})

hl.curve("quick", {
	type = "bezier",
	points = {
		{ 0.15, 0 },
		{ 0.10, 1 },
	},
})

hl.curve("easy", {
	type = "spring",
	mass = 1,
	stiffness = 71.2633,
	dampening = 15.8273644,
})

hl.curve("snappy", {
	type = "spring",
	mass = 1,
	stiffness = 220,
	dampening = 22,
})

hl.curve("bouncy", {
	type = "spring",
	mass = 1,
	stiffness = 140,
	dampening = 13, -- under-damped: slight overshoot on open
})

------------------------------------------------------------
-- Animations
------------------------------------------------------------

hl.animation({
	leaf = "global",
	enabled = true,
	speed = speed.global,
	bezier = "default",
})

-- Borders
hl.animation({
	leaf = "border",
	enabled = true,
	speed = speed.borders,
	bezier = "easeOutQuint",
})

hl.animation({
	leaf = "borderangle",
	enabled = true,
	speed = 60,
	bezier = "linear",
	style = "loop", -- slowly rotating gradient border
})

-- Windows
hl.animation({
	leaf = "windows",
	enabled = true,
	speed = speed.smooth,
	spring = "snappy",
})

hl.animation({
	leaf = "windowsIn",
	enabled = true,
	speed = speed.smooth,
	spring = "bouncy",
	style = "popin 80%",
})

hl.animation({
	leaf = "windowsOut",
	enabled = true,
	speed = speed.fast,
	bezier = "quick",
	style = "popin 85%",
})

hl.animation({
	leaf = "windowsMove",
	enabled = true,
	speed = speed.smooth,
	spring = "snappy",
})

-- Fades
hl.animation({
	leaf = "fadeIn",
	enabled = true,
	speed = speed.fast,
	bezier = "almostLinear",
})

hl.animation({
	leaf = "fadeOut",
	enabled = true,
	speed = speed.fast,
	bezier = "almostLinear",
})

hl.animation({
	leaf = "fade",
	enabled = true,
	speed = speed.normal,
	bezier = "quick",
})

-- Layers
hl.animation({
	leaf = "layers",
	enabled = true,
	speed = speed.normal,
	bezier = "easeOutQuint",
})

hl.animation({
	leaf = "layersIn",
	enabled = true,
	speed = speed.normal,
	spring = "snappy",
	style = "popin 92%",
})

hl.animation({
	leaf = "layersOut",
	enabled = true,
	speed = speed.fast,
	bezier = "quick",
	style = "fade",
})

hl.animation({
	leaf = "fadeLayersIn",
	enabled = true,
	speed = speed.fast,
	bezier = "almostLinear",
})

hl.animation({
	leaf = "fadeLayersOut",
	enabled = true,
	speed = speed.fast,
	bezier = "almostLinear",
})

-- Workspaces
hl.animation({
	leaf = "workspaces",
	enabled = true,
	speed = speed.smooth,
	spring = "snappy",
	style = "slide",
})

hl.animation({
	leaf = "workspacesIn",
	enabled = true,
	speed = speed.smooth,
	spring = "snappy",
	style = "slide",
})

hl.animation({
	leaf = "workspacesOut",
	enabled = true,
	speed = speed.smooth,
	spring = "snappy",
	style = "slide",
})

-- Zoom
hl.animation({
	leaf = "zoomFactor",
	enabled = true,
	speed = speed.zoom,
	bezier = "quick",
})

------------------------------------------------------------
-- Layouts
------------------------------------------------------------

hl.config({
	dwindle = {
		preserve_split = true,
	},
})

hl.config({
	master = {
		new_status = "slave", -- first window stays master; new windows go to the stack
		new_on_top = false, -- new slaves are added at the bottom of the stack
	},
})

hl.config({
	scrolling = {
		fullscreen_on_one_column = true,
	},
})
