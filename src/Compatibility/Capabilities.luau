--[[
	NEVAHEXUI - Compatibility/Capabilities
	Runtime feature detection. This is the only place in the framework allowed to
	touch executor / Roblox globals directly; every other module goes through the
	host back end.
]]

local Capabilities = {}

local function probe(fn)
	local ok, value = pcall(fn)
	if ok then
		return value
	end
	return nil
end

local function globalFunction(name)
	local value = probe(function()
		return _G[name]
	end)
	return type(value) == "function", value
end

function Capabilities.detect()
	local caps = {
		roblox = false,
		executor = false,
		gethui = false,
		protectGui = false,
		clipboard = false,
		filesystem = false,
		http = false,
		tweenService = false,
		inputService = false,
		runService = false,
		textService = false,
		localPlayer = false,
	}

	local gameValue = probe(function()
		return game
	end)
	local instanceValue = probe(function()
		return Instance
	end)
	caps.roblox = gameValue ~= nil and instanceValue ~= nil

	if not caps.roblox then
		return caps
	end

	local services = {}
	local function getService(name)
		if services[name] == nil then
			services[name] = probe(function()
				return game:GetService(name)
			end)
		end
		return services[name]
	end

	caps.tweenService = getService("TweenService") ~= nil
	caps.inputService = getService("UserInputService") ~= nil
	caps.runService = getService("RunService") ~= nil
	caps.textService = getService("TextService") ~= nil

	local players = getService("Players")
	local player = players and probe(function()
		return players.LocalPlayer
	end)
	caps.localPlayer = player ~= nil
	caps.playerGui = player and probe(function()
		return player:WaitForChild("PlayerGui", 5)
	end) or nil
	caps.coreGui = getService("CoreGui")

	local hasGethui, gethuiFn = globalFunction("gethui")
	caps.gethui = hasGethui and gethuiFn ~= nil
	local hasProtect = globalFunction("protect_gui")
	caps.protectGui = hasProtect
	local synProtect = probe(function()
		return syn and syn.protect_gui
	end)
	if type(synProtect) == "function" then
		caps.protectGui = true
	end

	caps.clipboard = select(1, globalFunction("setclipboard"))
	local hasWrite = select(1, globalFunction("writefile"))
	local hasRead = select(1, globalFunction("readfile"))
	caps.filesystem = hasWrite and hasRead
	caps.http = select(1, globalFunction("request"))
		or select(1, globalFunction("http_request"))
		or select(1, globalFunction("HttpGet"))

	for _, marker in ipairs({ "getgenv", "hookfunction", "getscriptbytecode", "getrawmetatable", "identifyexecutor" }) do
		if select(1, globalFunction(marker)) then
			caps.executor = true
			break
		end
	end

	return caps
end

function Capabilities.resolveParent(caps)
	if caps.gethui then
		local protected = probe(function()
			return gethui()
		end)
		if protected then
			return protected, "gethui"
		end
	end
	if caps.coreGui then
		return caps.coreGui, "CoreGui"
	end
	if caps.playerGui then
		return caps.playerGui, "PlayerGui"
	end
	return nil, "none"
end

function Capabilities.summary(caps)
	local parts = {}
	for _, key in ipairs({ "roblox", "executor", "gethui", "protectGui", "clipboard", "filesystem", "http" }) do
		table.insert(parts, ("%s=%s"):format(key, tostring(caps[key])))
	end
	return table.concat(parts, " ")
end

return Capabilities
