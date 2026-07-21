local mainMod = "SUPER"
hl.bind(mainMod .. "+ R", hl.dsp.submap("resize"))
hl.bind(mainMod .. "+ SHIFT + RETURN", hl.dsp.exec_cmd("~/.config/hypr/scripts/apps.sh"))
-- Start a submap called "resize".
hl.define_submap("resize", function()
	-- Set repeating binds for resizing the active window.
	hl.bind("right", hl.dsp.window.resize({ x = 15, y = 0, relative = true }), { repeating = true })
	hl.bind("left", hl.dsp.window.resize({ x = -15, y = 0, relative = true }), { repeating = true })
	hl.bind("up", hl.dsp.window.resize({ x = 0, y = 15, relative = true }), { repeating = true })
	hl.bind("down", hl.dsp.window.resize({ x = 0, y = -15, relative = true }), { repeating = true })
	hl.bind("escape", hl.dsp.submap("reset"))
	hl.bind("Return", hl.dsp.submap("reset"))
end)
local function app(cmd)
	return function()
		hl.dispatch(hl.dsp.exec_cmd(cmd))
		hl.dispatch(hl.dsp.submap("reset"))
	end
end
hl.define_submap("󰀻 apps", function()
	hl.bind("B", app(Programs.Browser))
	hl.bind("E", app(Programs.FileManager))
	hl.bind("SHIFT + E", app(Programs.FileManagerTUI))
	hl.bind("H", app(Programs.Notes))
	hl.bind("T", app("Telegram"))
	hl.bind("L", app("lutris"))
	hl.bind("escape", hl.dsp.submap("reset"))
	hl.bind("Return", hl.dsp.submap("reset"))
end)
