-- Park / restore floating windows (workspaces 1-5)
local floating_workspaces = {
	[1] = "special:floating-1",
	[2] = "special:floating-2",
	[3] = "special:floating-3",
	[4] = "special:floating-4",
	[5] = "special:floating-5",
}

local parking = {}
local state_file = "/tmp/hypr-floating-parking"

local function move_windows(windows, destination)
	for _, window in ipairs(windows) do
		hl.dispatch(hl.dsp.window.move({
			window = window,
			workspace = destination,
			follow = false,
		}))
	end
end

local function write_state()
	local ids = {}
	for id, on in pairs(parking) do
		if on then
			table.insert(ids, tostring(id))
		end
	end
	local f = io.open(state_file, "w")
	if f then
		f:write(table.concat(ids, "\n"))
		f:close()
	end
	hl.exec_cmd("pkill -RTMIN+8 waybar")
end

local function toggle_floating()
	local workspace = hl.get_active_workspace()
	if not workspace then
		return
	end

	local special_name = floating_workspaces[workspace.id]
	if not special_name then
		return
	end

	if parking[workspace.id] then
		parking[workspace.id] = nil
		local special_workspace = hl.get_workspace(special_name)
		if special_workspace then
			move_windows(hl.get_windows({ workspace = special_workspace }), workspace)
		end
	else
		parking[workspace.id] = true
		local floating = {}
		for _, window in ipairs(hl.get_windows({ workspace = workspace })) do
			if window.floating then
				table.insert(floating, window)
			end
		end
		move_windows(floating, special_name)
	end

	write_state()
end

hl.bind("SUPER + Tab", toggle_floating)

function _G.toggle_floating_parking()
	toggle_floating()
end

hl.on("window.open", function(window)
	local ws = window.workspace
	if not ws or not window.floating then
		return
	end

	local special_name = floating_workspaces[ws.id]
	if special_name and parking[ws.id] then
		move_windows({ window }, special_name)
	end
end)

write_state()
