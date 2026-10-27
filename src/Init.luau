--[[
	NEVAHEXUI - Init
	The single-file build entry point. Loading NEVAHEXUI returns the runtime table
	already loaded, so callers can simply do:

	    local NEVAHEXUI = loadstring(game:HttpGet(url))()
	    local Window = NEVAHEXUI:CreateWindow({ Name = "My Interface" })

	Under a plain Luau interpreter (tests, CI) the same entry returns the runtime
	with the mock host back end.
]]

local Runtime = require("NEVA:Runtime")

-- Environment probe: Roblox has `game`, executors add `gethui`. When neither is
-- present the runtime loads with the headless mock back end.
local environment = "headless"
if type(getfenv) == "function" then
	local ok, roblox = pcall(function()
		return rawget(getfenv(0), "game") ~= nil
	end)
	if ok and roblox then
		environment = "roblox"
	end
end

Runtime.Environment = environment
return Runtime:Load()
