-----------------------
---- LOOK AND FEEL ----
-----------------------

------------------------------------------------------------
-- Design System
------------------------------------------------------------

local colors = {
	base = "rgb(1e1e2e)",
	mantle = "rgb(181825)",
	crust = "rgb(11111b)",

	surface0 = "rgb(313244)",
	surface1 = "rgb(45475a)",
	surface2 = "rgb(585b70)",

	text = "rgb(cdd6f4)",
	subtext0 = "rgb(a6adc8)",
	subtext1 = "rgb(bac2de)",

	rosewater = "rgb(f5e0dc)",
	flamingo = "rgb(f2cdcd)",
	pink = "rgb(f5c2e7)",
	mauve = "rgb(cba6f7)",
	red = "rgb(f38ba8)",
	maroon = "rgb(eba0ac)",
	peach = "rgb(fab387)",
	yellow = "rgb(f9e2af)",
	green = "rgb(a6e3a1)",
	teal = "rgb(94e2d5)",
	sky = "rgb(89dceb)",
	sapphire = "rgb(74c7ec)",
	blue = "rgb(89b4fa)",
	lavender = "rgb(b4befe)",
}

local spacing = {
	gaps_in = 2,
	gaps_out = 3,
	border_size = 0,
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
					colors.surface1,
					colors.blue,
				},
				angle = 45,
			},

			inactive_border = colors.surface0,
		},

		resize_on_border = false,
		allow_tearing = false,

		layout = "dwindle",
	},

	decoration = {
		rounding = 0,
		rounding_power = 0,

		active_opacity = 1.0,
		inactive_opacity = 0.95,

		shadow = {
			enabled = true,
			range = 6,
			render_power = 2,

			-- If your wrapper accepts the original integer format,
			-- you can change this back to:
			-- color = 0xdd11111b
			color = "rgba(11111bdd)",
		},

		blur = {
			enabled = true,
			size = 1,
			passes = 1,
			vibrancy = 0,
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

------------------------------------------------------------
-- Animations
------------------------------------------------------------

hl.animation({
	leaf = "global",
	enabled = true,
	speed = speed.global,
	bezier = "default",
})

hl.animation({
	leaf = "border",
	enabled = true,
	speed = speed.borders,
	bezier = "easeOutQuint",
})

hl.animation({
	leaf = "windows",
	enabled = true,
	speed = speed.smooth,
	spring = "easy",
})

hl.animation({
	leaf = "windowsIn",
	enabled = true,
	speed = speed.smooth,
	spring = "easy",
	style = "popin 90%",
})

hl.animation({
	leaf = "windowsOut",
	enabled = true,
	speed = speed.fast,
	bezier = "linear",
	style = "popin 90%",
})

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
	leaf = "layers",
	enabled = true,
	speed = speed.normal,
	bezier = "easeOutQuint",
})

hl.animation({
	leaf = "layersIn",
	enabled = true,
	speed = speed.normal,
	bezier = "easeOutQuint",
	style = "fade",
})

hl.animation({
	leaf = "layersOut",
	enabled = true,
	speed = speed.fast,
	bezier = "linear",
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

hl.animation({
	leaf = "workspaces",
	enabled = true,
	speed = speed.fast,
	bezier = "almostLinear",
	style = "fade",
})

hl.animation({
	leaf = "workspacesIn",
	enabled = true,
	speed = speed.fast,
	bezier = "almostLinear",
	style = "fade",
})

hl.animation({
	leaf = "workspacesOut",
	enabled = true,
	speed = speed.fast,
	bezier = "almostLinear",
	style = "fade",
})

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
		new_status = "master",
	},
})

hl.config({
	scrolling = {
		fullscreen_on_one_column = true,
	},
})
