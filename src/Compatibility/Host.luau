--[[
	NEVAHEXUI - Compatibility/Host
	Selects and constructs the runtime back end. Every other module receives the
	host by dependency injection, so the whole framework can execute headless.
]]

local Capabilities = require("NEVA:Compatibility/Capabilities")
local MockHost = require("NEVA:Compatibility/MockHost")
local RobloxHost = require("NEVA:Compatibility/RobloxHost")

local Host = {}

Host.Contract = {
	"new",
	"set",
	"get",
	"connect",
	"destroy",
	"tween",
	"defer",
	"delay",
	"heartbeat",
	"inputBind",
	"newRoot",
	"onViewportChanged",
	"children",
	"findAll",
	"findFirst",
	"clipboardSet",
	"color",
	"udim2",
	"udim",
	"vector2",
	"rect",
	"font",
	"tweenInfo",
	"enumItem",
}

-- options.Backend = "mock"   forces the headless back end (tests, tooling).
-- options.Backend = "roblox" forces the Roblox back end (Studio / executor).
-- options.Backend = nil      detects the runtime.
function Host.create(options)
	options = options or {}
	local capabilities = options.Capabilities or Capabilities.detect()
	local requested = options.Backend
	local backend

	if requested == "mock" then
		backend = MockHost.new({ Capabilities = options.MockCapabilities })
	elseif requested == "roblox" then
		if not capabilities.roblox then
			error("NEVAHEXUI: the Roblox back end was requested but no Roblox runtime was detected")
		end
		backend = RobloxHost.new(capabilities)
	elseif capabilities.roblox then
		backend = RobloxHost.new(capabilities)
	else
		backend = MockHost.new({ Capabilities = options.MockCapabilities })
	end

	backend.Capabilities = capabilities
	return backend
end

function Host.verify(backend)
	local missing = {}
	for _, method in ipairs(Host.Contract) do
		if backend[method] == nil then
			table.insert(missing, method)
		end
	end
	return missing
end

return Host
