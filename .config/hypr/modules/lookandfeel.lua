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
		rounding_power = 4.0,

		active_opacity = 1.0,
		inactive_opacity = 0.94,

		dim_inactive = true,
		dim_strength = 0.12,
		dim_special = 0.22,

		shadow = {
			enabled = true,
			range = 24,
			render_power = 3,
			color = colors.shadow,
		},

		glow = {
			enabled = false,
			color = colors.primary,
			range = 6,
			render_power = 3,
		},

		blur = {
			enabled = true,
			size = 8,
			passes = 2,

			vibrancy = 0.17,
			noise = 0.015,

			new_optimizations = true,
			xray = true,

			popups = true,
			popups_ignorealpha = 0.2,

			special = false,
			variant = "kawase",
		},

		wobble = {
			enabled = true,
			mesh = 12,
			stiffness = 220,
			damping = 18,
			mass = 1,
			intensity = 0.08,
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
	damping = 15.8273644,
})

hl.curve("snappy", {
	type = "spring",
	mass = 1,
	stiffness = 220,
	damping = 22,
})

hl.curve("bouncy", {
	type = "spring",
	mass = 1,
	stiffness = 140,
	damping = 13,
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

-- Animate the gradient once instead of continuously.
hl.animation({
	leaf = "borderangle",
	enabled = true,
	speed = speed.borders,
	bezier = "linear",
	style = "once",
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

hl.animation({
	leaf = "fadeSwitch",
	enabled = true,
	speed = speed.fast,
	bezier = "almostLinear",
})

hl.animation({
	leaf = "fadeDim",
	enabled = true,
	speed = speed.normal,
	bezier = "easeOutQuint",
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

hl.animation({
	leaf = "specialWorkspace",
	enabled = true,
	speed = speed.smooth,
	spring = "snappy",
	style = "slidefade 12%",
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

	master = {
		new_status = "slave",
		new_on_top = false,
	},

	scrolling = {
		fullscreen_on_one_column = true,
	},
})
