-- Static defaults. Changes made through the power menu's "Displays" entry
-- (scripts/displays.sh) are written to ~/.config/hypr/monitors.generated.lua,
-- which is loaded last so it wins and is never overwritten by deploy.sh.
hl.monitor({ output = "eDP-1", mode = "1920x1080@144", position = "auto", scale = "1" })
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "1" })

local generated = os.getenv("HOME") .. "/.config/hypr/monitors.generated.lua"
local f = io.open(generated, "r")
if f then
	f:close()
	dofile(generated)
end
