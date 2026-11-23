---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER" -- Sets "Windows" key as main modifier

hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(Programs.Terminal))
hl.bind(mainMod .. " +SHIFT+ Q", hl.dsp.window.close())
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd(Scripts .. "lock.sh"))
hl.bind(mainMod .. " + ESCAPE", hl.dsp.exec_cmd(Scripts .. "powermenu.sh"))
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd(Scripts .. "power-profile-toggle.sh"))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd(Programs.Menu))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(Programs.Browser))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(Programs.FileManager))
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd(Programs.Notes))
hl.bind(mainMod .. " + Z", hl.dsp.exec_cmd(Programs.Pdf))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd(Programs.Discord))
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(Programs.Telegram))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd(Programs.Whatsie))
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd(Scripts .. "cliphist-wofi-img.sh"))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.exec_cmd(Programs.Games))
hl.bind(mainMod .. " + SHIFT + SPACE", hl.dsp.exec_cmd(Scripts .. "keyboard-layout-toggle.sh"))

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
	local key = i % 10 -- 10 maps to key 0
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
	hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Special workspace (scratchpad)
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(Scripts .. "volume.sh up"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(Scripts .. "volume.sh down"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(Scripts .. "volume.sh toggle"), { locked = true, repeating = true })
hl.bind(
	"XF86AudioMicMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
	{ locked = true, repeating = true }
)
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(Scripts .. "brightness.sh up"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(Scripts .. "brightness.sh down"), { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

-- Screenshots
hl.bind("Print", hl.dsp.exec_cmd(Scripts .. "screenshot.sh full"))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd(Scripts .. "screenshot.sh area"))
hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd(Scripts .. "record.sh full"))
hl.bind(mainMod .. " + SHIFT + Print", hl.dsp.exec_cmd(Scripts .. "record.sh area"))

-- Moving windows
local function smart_move(dx, dy, direction)
	return function()
		local w = hl.get_active_window()
		if not w then
			return
		end

		if w.floating then
			hl.dispatch(hl.dsp.window.move({
				x = dx,
				y = dy,
				relative = true,
			}))
		else
			hl.dispatch(hl.dsp.window.move({
				direction = direction,
			}))
		end
	end
end
hl.bind(mainMod .. " + SHIFT + left", smart_move(-15, 0, "left"), { repeating = true })
hl.bind(mainMod .. " + SHIFT + right", smart_move(15, 0, "right"), { repeating = true })
hl.bind(mainMod .. " + SHIFT + up", smart_move(0, -15, "up"), { repeating = true })
hl.bind(mainMod .. " + SHIFT + down", smart_move(0, 15, "down"), { repeating = true })
