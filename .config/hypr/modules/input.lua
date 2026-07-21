---------------
---- INPUT ----
---------------

hl.config({
	input = {
		-- Keyboard
		kb_layout = "us,ara,ru,jp",
		kb_variant = ",qwerty",
		kb_model = "",
		kb_options = "",
		kb_rules = "",

		-- Mouse
		follow_mouse = 1,
		sensitivity = 0, -- -1.0 to 1.0

		touchpad = {
			natural_scroll = false,
			-- tap_to_click = true,
			-- disable_while_typing = true,
			-- clickfinger_behavior = true,
		},
	},
})

-- Three-finger swipe to change workspaces.
hl.gesture({
	fingers = 3,
	direction = "horizontal",
	action = "workspace",
})

-- Example per-device configuration.
hl.device({
	name = "epic-mouse-v1",
	sensitivity = -0.5,
})
