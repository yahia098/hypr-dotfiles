hl.monitor({
	output = "eDP-2",
	mode = "highres",
	position = "auto",
	scale = "auto",
})
hl.config({
	xwayland = {
		force_zero_scaling = true,
	},
})
