--[[ NEVAHEXUI generated test bundle - do not edit. ]]
--[[
	NEVAHEXUI test harness.
	Defines the global `NevaTest` used by the generated test bundle. Assertion
	failures are collected per test rather than aborting the run, and the harness
	exits non-zero (via error) when anything failed.
]]

local NevaTest = {}
NevaTest.__index = NevaTest

NevaTest.Cases = {}
NevaTest.CurrentSuite = "general"
NevaTest.Results = {}
NevaTest.Verbose = false

function NevaTest:suite(name)
	self.CurrentSuite = name
end

function NevaTest:test(name, fn)
	table.insert(self.Cases, { suite = self.CurrentSuite, name = name, fn = fn })
end

function NevaTest:fail(message)
	error(message or "assertion failed", 2)
end

function NevaTest:assert(condition, message)
	if not condition then
		self:fail(message or ("expected a truthy value, received " .. tostring(condition)))
	end
	return condition
end

function NevaTest:equals(actual, expected, message)
	if actual ~= expected then
		self:fail(("%s: expected %s, received %s"):format(
			message or "equals",
			tostring(expected),
			tostring(actual)
		))
	end
	return actual
end

function NevaTest:near(actual, expected, tolerance, message)
	tolerance = tolerance or 1e-6
	if type(actual) ~= "number" or math.abs(actual - expected) > tolerance then
		self:fail(("%s: expected %s +/- %s, received %s"):format(
			message or "near",
			tostring(expected),
			tostring(tolerance),
			tostring(actual)
		))
	end
	return actual
end

function NevaTest:deepEquals(actual, expected, message)
	local function same(a, b, seen)
		if a == b then
			return true
		end
		if type(a) ~= "table" or type(b) ~= "table" then
			return false
		end
		seen = seen or {}
		if seen[a] == b then
			return true
		end
		seen[a] = b
		for key, value in pairs(a) do
			if not same(value, b[key], seen) then
				return false
			end
		end
		for key in pairs(b) do
			if a[key] == nil then
				return false
			end
		end
		return true
	end
	if not same(actual, expected) then
		self:fail(("%s: values are not deeply equal"):format(message or "deepEquals"))
	end
	return actual
end

function NevaTest:throws(fn, message)
	local ok, err = pcall(fn)
	if ok then
		self:fail(message or "expected the call to raise an error")
	end
	return err
end

function NevaTest:contains(haystack, needle, message)
	if type(haystack) == "string" then
		if not haystack:find(needle, 1, true) then
			self:fail(("%s: %q does not contain %q"):format(message or "contains", haystack, tostring(needle)))
		end
		return
	end
	if type(haystack) == "table" then
		for _, item in ipairs(haystack) do
			if item == needle then
				return
			end
		end
		self:fail(("%s: array does not contain %s"):format(message or "contains", tostring(needle)))
		return
	end
	self:fail("contains: unsupported container type " .. type(haystack))
end

function NevaTest:runAll()
	local failures = {}
	local passed = 0
	local startedAt = os.clock()
	for _, case in ipairs(self.Cases) do
		local ok, err = pcall(case.fn)
		if ok then
			passed += 1
			if self.Verbose then
				print(("  PASS  [%s] %s"):format(case.suite, case.name))
			end
		else
			table.insert(failures, { suite = case.suite, name = case.name, error = tostring(err) })
			print(("  FAIL  [%s] %s"):format(case.suite, case.name))
			print(("        %s"):format(tostring(err)))
		end
	end
	local elapsed = os.clock() - startedAt
	print("")
	print(("NEVAHEXUI tests: %d passed, %d failed, %d total (%.3fs)"):format(
		passed,
		#failures,
		#self.Cases,
		elapsed
	))
	if #failures > 0 then
		error(("NEVAHEXUI test suite failed: %d of %d tests failed"):format(#failures, #self.Cases), 0)
	end
	return passed, failures
end


NEVAHEXUI = (function()
local __NEVA_Animation_Presets = (function()
--[[
	NEVAHEXUI - Animation/Presets
	Named animation presets shared by every component so that timing and easing
	stay consistent across styles and can be overridden per component.
]]

local Presets = {}

Presets.Definitions = {
	none = {
		Name = "None",
		Description = "Apply the target values instantly.",
		Duration = 0,
		Easing = "Linear",
		Direction = "Out",
	},
	fade = {
		Name = "Fade",
		Description = "Cross-fade transparency only.",
		Duration = 0.18,
		Easing = "Sine",
		Direction = "Out",
	},
	quick = {
		Name = "Quick",
		Description = "Short transition for small affordances.",
		Duration = 0.1,
		Easing = "Quad",
		Direction = "Out",
	},
	smooth = {
		Name = "Smooth",
		Description = "Default interface transition.",
		Duration = 0.2,
		Easing = "Quad",
		Direction = "Out",
	},
	pop = {
		Name = "Pop",
		Description = "Overshoot used for toggles and selections.",
		Duration = 0.24,
		Easing = "Back",
		Direction = "Out",
	},
	springy = {
		Name = "Springy",
		Description = "Elastic settle for large movement.",
		Duration = 0.35,
		Easing = "Elastic",
		Direction = "Out",
	},
	bounce = {
		Name = "Bounce",
		Description = "Bouncy settle for value changes.",
		Duration = 0.3,
		Easing = "Bounce",
		Direction = "Out",
	},
	slide = {
		Name = "Slide",
		Description = "Directional movement preset.",
		Duration = 0.22,
		Easing = "Cubic",
		Direction = "Out",
	},
	slow = {
		Name = "Slow",
		Description = "Deliberate transition for large panels.",
		Duration = 0.4,
		Easing = "Sine",
		Direction = "InOut",
	},
}

Presets.Names = {
	"none",
	"fade",
	"quick",
	"smooth",
	"pop",
	"springy",
	"bounce",
	"slide",
	"slow",
}

function Presets.get(name)
	if name == nil then
		return Presets.Definitions.smooth, "smooth"
	end
	if type(name) == "table" then
		local duration = name.Duration or Presets.Definitions.smooth.Duration
		local easing = name.Easing or Presets.Definitions.smooth.Easing
		local direction = name.Direction or Presets.Definitions.smooth.Direction
		return { Name = name.Name or "Custom", Description = "Inline animation specification.", Duration = duration, Easing = easing, Direction = direction }, "custom"
	end
	local preset = Presets.Definitions[name]
	if preset then
		return preset, name
	end
	return Presets.Definitions.smooth, "smooth"
end

function Presets.info(host, spec)
	local resolved = Presets.get(spec)
	return host.tweenInfo(resolved.Duration, resolved.Easing, resolved.Direction)
end

-- Tweens `goal` on `instance` using the resolved preset.
function Presets.play(host, instance, goal, spec)
	local resolved = Presets.get(spec)
	if resolved.Duration <= 0 then
		return host.set(instance, goal)
	end
	return host.tween(instance, goal, Presets.info(host, resolved))
end

function Presets.list()
	local out = {}
	for _, name in ipairs(Presets.Names) do
		local preset = Presets.Definitions[name]
		table.insert(out, {
			Name = name,
			Label = preset.Name,
			Description = preset.Description,
			Duration = preset.Duration,
			Easing = preset.Easing,
			Direction = preset.Direction,
		})
	end
	return out
end

function Presets.register(name, definition)
	assert(type(name) == "string" and name ~= "", "Presets.register expects a name")
	assert(not Presets.Definitions[name], ("animation preset %q already exists"):format(name))
	assert(type(definition) == "table", "Presets.register expects a definition table")
	Presets.Definitions[name] = {
		Name = definition.Name or name,
		Description = definition.Description or "",
		Duration = definition.Duration or 0.2,
		Easing = definition.Easing or "Quad",
		Direction = definition.Direction or "Out",
	}
	table.insert(Presets.Names, name)
	return name
end

return Presets
end)()

local __NEVA_Compatibility_Capabilities = (function()
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
end)()

local __NEVA_Compatibility_PressEvents = (function()
--[[
	NEVAHEXUI - Compatibility/PressEvents

	Button events (MouseButton1Down/Up/Click, Activated) exist on GuiButton
	instances only. Indexing a Frame with one of them does not return nil in
	Roblox, it raises:

		MouseButton1Down is not a valid member of Frame "..."

	so the event lookup has to be guarded, and a request for a button event on a
	non-button instance has to be translated into what that instance really
	offers: InputBegan / InputEnded, which every GuiObject has. Both host back
	ends share this rule so the headless model behaves like the real one.
]]

local PressEvents = {}

-- Events that only GuiButton (TextButton / ImageButton) instances own.
PressEvents.ButtonOnly = {
	MouseButton1Down = true,
	MouseButton1Up = true,
	MouseButton1Click = true,
	MouseButton2Down = true,
	MouseButton2Up = true,
	MouseButton2Click = true,
	Activated = true,
}

-- How each button event is satisfied on an instance that lacks it. "Press" is
-- resolved to an InputBegan/InputEnded pair so a click still needs a release.
PressEvents.Fallback = {
	MouseButton1Down = "InputBegan",
	MouseButton2Down = "InputBegan",
	MouseButton1Up = "InputEnded",
	MouseButton2Up = "InputEnded",
	MouseButton1Click = "Press",
	MouseButton2Click = "Press",
	Activated = "Press",
}

-- Which input a fallback connection reacts to. A left-click fallback also
-- accepts touch, so press handling keeps working on mobile.
PressEvents.InputType = {
	MouseButton1Down = "MouseButton1",
	MouseButton1Up = "MouseButton1",
	MouseButton1Click = "MouseButton1",
	Activated = "MouseButton1",
	MouseButton2Down = "MouseButton2",
	MouseButton2Up = "MouseButton2",
	MouseButton2Click = "MouseButton2",
}

local function inputTypeName(input)
	if input == nil then
		return nil
	end
	local value = input.UserInputType
	if value == nil then
		return nil
	end
	-- Roblox hands back an EnumItem (tostring "Enum.UserInputType.MouseButton1"),
	-- the mock hands back the same string shape.
	return tostring(value):match("([%w]+)$")
end

-- connect: function(instance, event, callback) -> connection, provided by the
-- host so the fallback itself is implemented once per back end surface.
function PressEvents.fallback(connect, instance, event, callback)
	local target = PressEvents.Fallback[event]
	if not target then
		return nil, ("%s is not available on this instance"):format(tostring(event))
	end

	local expected = PressEvents.InputType[event]
	local function matches(input)
		if expected == nil then
			return true
		end
		local name = inputTypeName(input)
		if name == expected then
			return true
		end
		return expected == "MouseButton1" and name == "Touch"
	end

	if target == "InputBegan" or target == "InputEnded" then
		return connect(instance, target, function(input)
			if matches(input) then
				callback(input)
			end
		end)
	end

	-- Click: require a press and a release on the same instance.
	local pending = false
	local begin = connect(instance, "InputBegan", function(input)
		if matches(input) then
			pending = true
		end
	end)
	local finish = connect(instance, "InputEnded", function(input)
		if pending and matches(input) then
			pending = false
			callback(input)
		end
	end)
	local handle = {}
	function handle:Disconnect()
		if begin then
			begin:Disconnect()
		end
		if finish then
			finish:Disconnect()
		end
	end
	return handle
end

return PressEvents
end)()

local __NEVA_Compatibility_MockHost = (function()
--[[
	NEVAHEXUI - Compatibility/MockHost
	Headless back end. Implements the same host contract as the Roblox back end
	using plain tables, an in-memory filesystem and deterministic tween / input
	stubs. Every NEVAHEXUI module is host agnostic, which is what makes the
	framework's behaviour verifiable without a Roblox runtime.
]]

local PressEvents = __NEVA_Compatibility_PressEvents

local MockHost = {}

local MockInstance = {}
MockInstance.__index = function(self, key)
	if key == "Parent" then
		return rawget(self, "_parent")
	end
	local props = rawget(self, "_props")
	local value = props[key]
	if value ~= nil then
		return value
	end
	local events = rawget(self, "_events")
	if events and events[key] then
		return events[key]
	end
	-- Class methods (GetChildren, FindFirstChild, IsA, Destroy, ...) live on
	-- MockInstance. Without this fallback the metatable would answer instance
	-- properties only and every method call on a mock instance would fail.
	local method = rawget(MockInstance, key)
	if method ~= nil then
		return method
	end
	return nil
end

MockInstance.__newindex = function(self, key, value)
	if key == "Parent" then
		local previous = rawget(self, "_parent")
		if previous then
			local children = rawget(previous, "_children")
			for index, child in ipairs(children) do
				if child == self then
					table.remove(children, index)
					break
				end
			end
		end
		rawset(self, "_parent", value)
		if value then
			table.insert(rawget(value, "_children"), self)
			MockInstance._emit(value, "ChildAdded", self)
		elseif previous then
			MockInstance._emit(previous, "ChildRemoved", self)
		end
		return
	end
	local props = rawget(self, "_props")
	local previous = props[key]
	props[key] = value
	if previous ~= value then
		MockInstance._emit(self, "Changed", key)
	end
end

function MockInstance:GetPropertyChangedSignal(property)
	local host = rawget(self, "_host")
	local signal = {}
	function signal:Connect(callback)
		return host.connect(self, "Changed:" .. property, callback)
	end
	return signal
end

function MockInstance:Destroy()
	return rawget(self, "_host").destroy(self)
end

function MockInstance:FindFirstChild(name)
	for _, child in ipairs(rawget(self, "_children")) do
		if child.Name == name then
			return child
		end
	end
	return nil
end

function MockInstance:GetChildren()
	local copy = {}
	for _, child in ipairs(rawget(self, "_children")) do
		table.insert(copy, child)
	end
	return copy
end

function MockInstance:IsA(className)
	return rawget(self, "_props").ClassName == className
end

function MockInstance._signal(self, event)
	local events = rawget(self, "_events")
	local signal = events[event]
	if not signal then
		signal = MockHost.newSignal(event)
		events[event] = signal
	end
	return signal
end

function MockInstance._emit(self, event, ...)
	local events = rawget(self, "_events")
	local exact = events[event]
	if exact then
		exact:Fire(...)
	end
	local colon = event .. ":"
	for key, signal in pairs(events) do
		if type(key) == "string" and key:sub(1, #colon) == colon then
			signal:Fire(...)
		end
	end
end

function MockHost.newSignal(name)
	local signal = { Name = name, _handlers = {}, _destroyed = false }
	function signal:Connect(callback)
		local handler = { callback = callback, connected = true }
		table.insert(self._handlers, handler)
		local connection = {}
		function connection:Disconnect()
			handler.connected = false
		end
		connection._handler = handler
		return connection
	end
	function signal:Fire(...)
		if self._destroyed then
			return 0
		end
		local fired = 0
		local snapshot = {}
		for _, handler in ipairs(self._handlers) do
			if handler.connected then
				table.insert(snapshot, handler)
			end
		end
		for _, handler in ipairs(snapshot) do
			if handler.connected then
				fired += 1
				handler.callback(...)
			end
		end
		return fired
	end
	function signal:GetConnectionCount()
		local total = 0
		for _, handler in ipairs(self._handlers) do
			if handler.connected then
				total += 1
			end
		end
		return total
	end
	function signal:DisconnectAll()
		for _, handler in ipairs(self._handlers) do
			handler.connected = false
		end
		self._handlers = {}
	end
	function signal:Destroy()
		self:DisconnectAll()
		self._destroyed = true
	end
	return signal
end

local DEFAULT_CAPABILITIES = {
	roblox = false,
	executor = false,
	gethui = false,
	protectGui = false,
	clipboard = true,
	filesystem = true,
	http = false,
	tweenService = false,
	inputService = false,
	runService = false,
	localPlayer = false,
}

function MockHost.new(options)
	options = options or {}
	local host = {}
	host.Kind = "mock"
	host.Root = nil
	host.AppliedTweens = {}
	host.Instances = {}
	host.InputHandlers = {}
	host.Heartbeats = {}
	host.DestroyedInstances = {}
	host.Clipboard = nil
	host.Files = {}
	host.Folders = {}
	host.UnsupportedPressConnections = {}

	local capabilities = {}
	for key, value in pairs(DEFAULT_CAPABILITIES) do
		capabilities[key] = value
	end
	if options.Capabilities then
		for key, value in pairs(options.Capabilities) do
			capabilities[key] = value
		end
	end
	host.Capabilities = capabilities

	local function clamp01(value)
		return math.max(0, math.min(1, value))
	end

	host.color = function(r, g, b, a)
		local scale = 1
		if (r or 0) > 1 or (g or 0) > 1 or (b or 0) > 1 then
			scale = 255
		end
		return {
			__nevaMockColor = true,
			R = clamp01((r or 0) / scale),
			G = clamp01((g or 0) / scale),
			B = clamp01((b or 0) / scale),
			A = a == nil and 1 or clamp01(a),
		}
	end

	host.udim2 = function(xScale, xOffset, yScale, yOffset)
		return {
			__nevaMockUDim2 = true,
			X = { Scale = xScale or 0, Offset = xOffset or 0 },
			Y = { Scale = yScale or 0, Offset = yOffset or 0 },
		}
	end

	host.udim = function(scale, offset)
		return { __nevaMockUDim = true, Scale = scale or 0, Offset = offset or 0 }
	end

	host.vector2 = function(x, y)
		return { __nevaMockVector2 = true, X = x or 0, Y = y or 0 }
	end

	host.rect = function(minX, minY, maxX, maxY)
		return { __nevaMockRect = true, Min = host.vector2(minX, minY), Max = host.vector2(maxX, maxY) }
	end

	host.font = function(name)
		return "Font." .. tostring(name)
	end

	host.tweenInfo = function(duration, easing, direction)
		return {
			__nevaMockTweenInfo = true,
			Time = duration or 0,
			EasingStyle = easing or "Quad",
			EasingDirection = direction or "Out",
		}
	end

	host.enumItem = function(enumName, itemName)
		return "Enum." .. tostring(enumName) .. "." .. tostring(itemName)
	end

	host.new = function(className, props, parent)
		local instance = setmetatable({
			ClassName = className,
			_parent = parent,
			_props = { Name = className, ClassName = className },
			_children = {},
			_events = {},
			_destroyed = false,
			_host = host,
		}, MockInstance)
		table.insert(host.Instances, instance)
		if parent then
			table.insert(rawget(parent, "_children"), instance)
		end
		if props then
			for key, value in pairs(props) do
				if key ~= "Parent" then
					rawget(instance, "_props")[key] = value
				end
			end
		end
		return instance
	end

	host.set = function(instance, props)
		for key, value in pairs(props) do
			instance[key] = value
		end
		return instance
	end

	host.get = function(instance, prop)
		return instance[prop]
	end

	-- Mirrors Roblox: button events live on GuiButton instances only. Asking a
	-- Frame for one is an error there, not an event that never fires, so the mock
	-- is strict about it -- that strictness is what lets the headless tests catch
	-- a button event wired to the wrong instance class.
	local BUTTON_CLASSES = { TextButton = true, ImageButton = true }

	local function supportsEvent(instance, event)
		if not PressEvents.ButtonOnly[event] then
			return true
		end
		return BUTTON_CLASSES[rawget(instance, "_props").ClassName] == true
	end

	host.connect = function(instance, event, callback)
		if supportsEvent(instance, event) then
			return MockInstance._signal(instance, event):Connect(callback)
		end
		table.insert(host.UnsupportedPressConnections, {
			Instance = instance,
			ClassName = rawget(instance, "_props").ClassName,
			Event = event,
		})
		local handle = PressEvents.fallback(host.connect, instance, event, callback)
		return handle or { Disconnect = function() end }
	end

	-- A real click, routed the way Roblox routes it: button events where they
	-- exist, InputBegan / InputEnded everywhere else.
	host.click = function(instance, position)
		local input = {
			UserInputType = "Enum.UserInputType.MouseButton1",
			Position = position or host.vector2(0, 0),
			KeyCode = "Enum.KeyCode.Unknown",
		}
		MockInstance._emit(instance, "InputBegan", input)
		if supportsEvent(instance, "MouseButton1Down") then
			MockInstance._emit(instance, "MouseButton1Down", input)
		end
		MockInstance._emit(instance, "InputEnded", input)
		if supportsEvent(instance, "MouseButton1Up") then
			MockInstance._emit(instance, "MouseButton1Up", input)
		end
		if supportsEvent(instance, "MouseButton1Click") then
			MockInstance._emit(instance, "MouseButton1Click", input)
		end
		return true
	end

	host.destroy = function(instance)
		if rawget(instance, "_destroyed") then
			return
		end
		rawset(instance, "_destroyed", true)
		table.insert(host.DestroyedInstances, instance)
		for _, child in ipairs(rawget(instance, "_children")) do
			host.destroy(child)
		end
		rawset(instance, "_children", {})
		for _, signal in pairs(rawget(instance, "_events")) do
			signal:Destroy()
		end
		rawset(instance, "_events", {})
		local parent = rawget(instance, "_parent")
		if parent then
			local siblings = rawget(parent, "_children")
			for index, child in ipairs(siblings) do
				if child == instance then
					table.remove(siblings, index)
					break
				end
			end
		end
		rawset(instance, "_parent", nil)
	end

	host.emit = function(instance, event, ...)
		MockInstance._emit(instance, event, ...)
	end

	host.tween = function(instance, goal, info)
		local record = { Instance = instance, Goal = goal, Info = info }
		table.insert(host.AppliedTweens, record)
		for key, value in pairs(goal) do
			local props = rawget(instance, "_props")
			local previous = props[key]
			props[key] = value
			if previous ~= value then
				MockInstance._emit(instance, "Changed", key)
			end
		end
		local handle = { Completed = true }
		handle.Cancel = function()
			record.Cancelled = true
		end
		return handle
	end

	host.defer = function(callback)
		callback()
	end

	host.delay = function(seconds, callback)
		callback()
	end

	host.heartbeat = function(callback)
		table.insert(host.Heartbeats, callback)
		local connection = {}
		function connection:Disconnect()
			for index, candidate in ipairs(host.Heartbeats) do
				if candidate == callback then
					table.remove(host.Heartbeats, index)
					break
				end
			end
		end
		return connection
	end

	host.step = function(delta)
		local snapshot = {}
		for _, callback in ipairs(host.Heartbeats) do
			table.insert(snapshot, callback)
		end
		for _, callback in ipairs(snapshot) do
			callback(delta or 1 / 60)
		end
	end

	host.inputBind = function(key, callback)
		local handler = { Key = key, Callback = callback, Connected = true }
		table.insert(host.InputHandlers, handler)
		local connection = {}
		function connection:Disconnect()
			handler.Connected = false
		end
		return connection
	end

	host.inputFire = function(key, state)
		local fired = 0
		for _, handler in ipairs(host.InputHandlers) do
			if handler.Connected and tostring(handler.Key):lower() == tostring(key):lower() then
				fired += 1
				handler.Callback(state or "Begin")
			end
		end
		return fired
	end

	host.newRoot = function(props)
		local gui = host.new("ScreenGui", props or {}, nil)
		host.Root = gui
		return gui
	end

	host.children = function(instance)
		return instance:GetChildren()
	end

	host.findFirst = function(instance, className)
		for _, child in ipairs(rawget(instance, "_children")) do
			if child.ClassName == className then
				return child
			end
		end
		return nil
	end

	host.findAll = function(instance, className, results)
		results = results or {}
		for _, child in ipairs(rawget(instance, "_children")) do
			if child.ClassName == className then
				table.insert(results, child)
			end
			host.findAll(child, className, results)
		end
		return results
	end

	host.clipboardSet = function(text)
		host.Clipboard = text
		return true
	end

	host.PointerTrackers = {}
	host.PointerPosition = host.vector2(0, 0)
	host.Viewport = host.vector2(1920, 1080)

	local function readAxis(value)
		if value == nil then
			return 0
		end
		if type(value) == "number" then
			return value
		end
		if type(value) == "table" then
			if value.Offset ~= nil then
				return value.Offset
			end
			if value.Scale ~= nil then
				return value.Scale
			end
		end
		return 0
	end

	-- Mirrors GuiObject.AbsolutePosition / AbsoluteSize. Styles and tests set
	-- AbsolutePosition / AbsoluteSize directly; Position / Size are the fallback.
	host.bounds = function(instance)
		local props = rawget(instance, "_props")
		local position = props.AbsolutePosition or props.Position
		local size = props.AbsoluteSize or props.Size
		return {
			X = position and readAxis(position.X) or 0,
			Y = position and readAxis(position.Y) or 0,
			Width = size and readAxis(size.X) or 0,
			Height = size and readAxis(size.Y) or 0,
		}
	end

	host.trackPointer = function(callback)
		table.insert(host.PointerTrackers, callback)
		local connection = {}
		function connection:Disconnect()
			for index, candidate in ipairs(host.PointerTrackers) do
				if candidate == callback then
					table.remove(host.PointerTrackers, index)
					break
				end
			end
		end
		return connection
	end

	host.pointerMove = function(x, y)
		host.PointerPosition = host.vector2(x, y)
		local snapshot = {}
		for _, callback in ipairs(host.PointerTrackers) do
			table.insert(snapshot, callback)
		end
		for _, callback in ipairs(snapshot) do
			callback(host.PointerPosition)
		end
		return host.PointerPosition
	end

	host.pointerPosition = function()
		return host.PointerPosition
	end

	host.KeyCapture = nil

	host.captureKeys = function(callback)
		host.KeyCapture = callback
		local connection = {}
		function connection:Disconnect()
			if host.KeyCapture == callback then
				host.KeyCapture = nil
			end
		end
		return connection
	end

	-- Test/programmatic key press: feeds capture handlers and bound handlers.
	host.pressKey = function(key)
		local delivered = 0
		if host.KeyCapture then
			delivered += 1
			host.KeyCapture(key)
		end
		delivered += host.inputFire(key, "Begin")
		return delivered
	end

	host.viewportSize = function()
		return host.Viewport
	end

	host.fs = {}
	host.fs.isfile = function(path)
		return host.Files[path] ~= nil
	end
	host.fs.isfolder = function(path)
		return host.Folders[path] == true
	end
	host.fs.readfile = function(path)
		if host.Files[path] == nil then
			error(("mock filesystem: no such file %q"):format(tostring(path)))
		end
		return host.Files[path]
	end
	host.fs.writefile = function(path, contents)
		host.Files[path] = contents
	end
	host.fs.appendfile = function(path, contents)
		host.Files[path] = (host.Files[path] or "") .. contents
	end
	host.fs.makefolder = function(path)
		host.Folders[path] = true
	end
	host.fs.delfile = function(path)
		host.Files[path] = nil
	end
	host.fs.listfiles = function(path)
		local out = {}
		local prefix = path .. "/"
		for key in pairs(host.Files) do
			if key:sub(1, #prefix) == prefix then
				table.insert(out, key)
			end
		end
		table.sort(out)
		return out
	end

	return host
end

return MockHost
end)()

local __NEVA_Compatibility_RobloxHost = (function()
--!nonstrict
--[[
	NEVAHEXUI - Compatibility/RobloxHost
	Roblox back end. Wraps Instances, TweenService, UserInputService and the
	optional executor APIs behind the same contract the mock back end implements.
	This module is only constructed when a Roblox runtime is detected.
]]

local PressEvents = __NEVA_Compatibility_PressEvents

local RobloxHost = {}

local function safeCall(fn, ...)
	local ok, result = pcall(fn, ...)
	if ok then
		return result
	end
	return nil
end

local function globalFunction(name)
	local value = safeCall(function()
		return _G[name]
	end)
	if type(value) == "function" then
		return value
	end
	return nil
end

function RobloxHost.new(capabilities)
	local host = {}
	host.Kind = "roblox"
	host.Capabilities = capabilities
	host.Root = nil
	host.ParentSource = "none"
	host.AppliedTweens = {}

	local function service(name)
		return safeCall(function()
			return game:GetService(name)
		end)
	end

	local tweenService = service("TweenService")
	local userInputService = service("UserInputService")
	local runService = service("RunService")
	local players = service("Players")

	host.color = function(r, g, b, a)
		local scale = 1
		if (r or 0) > 1 or (g or 0) > 1 or (b or 0) > 1 then
			scale = 255
		end
		-- Color3 carries no alpha; styles manage transparency separately.
		return Color3.new((r or 0) / scale, (g or 0) / scale, (b or 0) / scale)
	end

	host.udim2 = function(xScale, xOffset, yScale, yOffset)
		return UDim2.new(xScale or 0, xOffset or 0, yScale or 0, yOffset or 0)
	end

	host.udim = function(scale, offset)
		return UDim.new(scale or 0, offset or 0)
	end

	host.vector2 = function(x, y)
		return Vector2.new(x or 0, y or 0)
	end

	host.rect = function(minX, minY, maxX, maxY)
		return Rect.new(minX or 0, minY or 0, maxX or 0, maxY or 0)
	end

	host.font = function(name)
		local item = safeCall(function()
			return Enum.Font[name]
		end)
		if item then
			return item
		end
		return safeCall(function()
			return Enum.Font.GothamBold
		end)
	end

	host.tweenInfo = function(duration, easing, direction)
		local style = safeCall(function()
			return Enum.EasingStyle[easing or "Quad"]
		end)
		local dir = safeCall(function()
			return Enum.EasingDirection[direction or "Out"]
		end)
		return TweenInfo.new(
			duration or 0.2,
			style or Enum.EasingStyle.Quad,
			dir or Enum.EasingDirection.Out
		)
	end

	host.enumItem = function(enumName, itemName)
		return safeCall(function()
			return Enum[enumName][itemName]
		end)
	end

	host.new = function(className, props, parent)
		local instance = safeCall(function()
			return Instance.new(className)
		end)
		if not instance then
			error(("NEVAHEXUI: could not create %s"):format(tostring(className)))
		end
		if parent then
			instance.Parent = parent
		end
		if props then
			for key, value in pairs(props) do
				if key ~= "Parent" and value ~= nil then
					safeCall(function()
						instance[key] = value
					end)
				end
			end
		end
		return instance
	end

	host.set = function(instance, props)
		for key, value in pairs(props) do
			if key ~= "Parent" and value ~= nil then
				safeCall(function()
					instance[key] = value
				end)
			end
		end
		return instance
	end

	host.get = function(instance, prop)
		return instance[prop]
	end

	-- Indexing an instance with an event it does not own raises in Roblox, so
	-- the event lookup is guarded; a button event asked of a non-button instance
	-- is translated into the GuiObject input events (see Compatibility/PressEvents).
	local function nativeSignal(instance, event)
		local ok, signal = pcall(function()
			return instance[event]
		end)
		if ok and signal ~= nil and type(signal.Connect) == "function" then
			return signal
		end
		return nil
	end

	host.connect = function(instance, event, callback)
		local signal = nativeSignal(instance, event)
		if signal then
			local connection = safeCall(function()
				return signal:Connect(callback)
			end)
			return connection or { Disconnect = function() end }
		end
		if PressEvents.ButtonOnly[event] then
			local handle = PressEvents.fallback(host.connect, instance, event, callback)
			if handle then
				return handle
			end
		end
		return { Disconnect = function() end }
	end

	host.destroy = function(instance)
		safeCall(function()
			instance:Destroy()
		end)
	end

	host.tween = function(instance, goal, info)
		if not tweenService then
			host.set(instance, goal)
			return { Cancel = function() end, Completed = true }
		end
		local tween = tweenService:Create(instance, info, goal)
		table.insert(host.AppliedTweens, { Instance = instance, Goal = goal, Info = info, Tween = tween })
		local handle = { Tween = tween, Cancelled = false }
		function handle.Cancel()
			handle.Cancelled = true
			safeCall(function()
				tween:Cancel()
			end)
		end
		safeCall(function()
			tween:Play()
		end)
		return handle
	end

	host.defer = function(callback)
		if safeCall(function()
			return task
		end) then
			task.defer(callback)
		else
			callback()
		end
	end

	host.delay = function(seconds, callback)
		if safeCall(function()
			return task
		end) then
			task.delay(seconds, callback)
		else
			callback()
		end
	end

	host.heartbeat = function(callback)
		if not runService then
			return { Disconnect = function() end }
		end
		return runService.Heartbeat:Connect(callback)
	end

	host.inputBind = function(key, callback)
		if not userInputService then
			return { Disconnect = function() end }
		end
		local keyCode = safeCall(function()
			return Enum.KeyCode[key]
		end)
		if not keyCode then
			return { Disconnect = function() end }
		end
		return userInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed then
				return
			end
			if input.KeyCode == keyCode then
				callback("Begin", input)
			end
		end)
	end

	host.inputFire = function()
		error("NEVAHEXUI: inputFire is only available on the mock back end")
	end

	host.captureKeys = function(callback)
		if not userInputService then
			return { Disconnect = function() end }
		end
		local keyboard = safeCall(function()
			return Enum.UserInputType.Keyboard
		end)
		return userInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed then
				return
			end
			if input.UserInputType == keyboard then
				local name = safeCall(function()
					return input.KeyCode.Name
				end)
				callback(name or "Unknown")
			end
		end)
	end

	host.pressKey = function()
		error("NEVAHEXUI: pressKey is only available on the mock back end")
	end

	host.emit = function()
		error("NEVAHEXUI: emit is only available on the mock back end; drive real input instead")
	end

	host.newRoot = function(props)
		local parent
		local source = "none"
		local gethuiFn = globalFunction("gethui")
		if gethuiFn then
			local candidate = safeCall(gethuiFn)
			if candidate then
				parent, source = candidate, "gethui"
			end
		end
		if not parent then
			parent = service("CoreGui")
			source = "CoreGui"
		end
		if not parent then
			local player = players and safeCall(function()
				return players.LocalPlayer
			end)
			if player then
				parent = safeCall(function()
					return player:WaitForChild("PlayerGui", 5)
				end)
				source = "PlayerGui"
			end
		end
		local gui = host.new("ScreenGui", props or {}, parent)
		host.Root = gui
		host.ParentSource = source
		if capabilities and capabilities.protectGui then
			local synTable = safeCall(function()
				return syn
			end)
			if synTable and type(synTable.protect_gui) == "function" then
				safeCall(function()
					synTable.protect_gui(gui)
				end)
			else
				local protect = globalFunction("protect_gui")
				if protect then
					safeCall(protect, gui)
				end
			end
		end
		return gui
	end

	host.children = function(instance)
		return safeCall(function()
			return instance:GetChildren()
		end) or {}
	end

	host.findFirst = function(instance, className)
		for _, child in ipairs(host.children(instance)) do
			if child.ClassName == className then
				return child
			end
		end
		return nil
	end

	host.findAll = function(instance, className, results)
		results = results or {}
		for _, child in ipairs(host.children(instance)) do
			if child.ClassName == className then
				table.insert(results, child)
			end
			host.findAll(child, className, results)
		end
		return results
	end

	host.clipboardSet = function(text)
		local setter = globalFunction("setclipboard") or globalFunction("toclipboard")
		if not setter then
			return false
		end
		return safeCall(setter, text) ~= nil or true
	end

	host.bounds = function(instance)
		local position = safeCall(function()
			return instance.AbsolutePosition
		end)
		local size = safeCall(function()
			return instance.AbsoluteSize
		end)
		return {
			X = position and position.X or 0,
			Y = position and position.Y or 0,
			Width = size and size.X or 0,
			Height = size and size.Y or 0,
		}
	end

	host.trackPointer = function(callback)
		if not userInputService then
			return { Disconnect = function() end }
		end
		local mouseMovement = safeCall(function()
			return Enum.UserInputType.MouseMovement
		end)
		local touch = safeCall(function()
			return Enum.UserInputType.Touch
		end)
		return userInputService.InputChanged:Connect(function(input)
			if input.UserInputType == mouseMovement or input.UserInputType == touch then
				callback({ X = input.Position.X, Y = input.Position.Y })
			end
		end)
	end

	host.pointerPosition = function()
		if not userInputService then
			return { X = 0, Y = 0 }
		end
		local location = safeCall(function()
			return userInputService:GetMouseLocation()
		end)
		if location then
			return { X = location.X, Y = location.Y }
		end
		return { X = 0, Y = 0 }
	end

	host.viewportSize = function()
		local camera = safeCall(function()
			return workspace.CurrentCamera.ViewportSize
		end)
		if camera then
			return { X = camera.X, Y = camera.Y }
		end
		return { X = 1920, Y = 1080 }
	end

	host.fs = {}
	host.fs.isfile = function(path)
		local fn = globalFunction("isfile")
		if not fn then
			return false
		end
		return safeCall(fn, path) == true
	end
	host.fs.isfolder = function(path)
		local fn = globalFunction("isfolder")
		if not fn then
			return false
		end
		return safeCall(fn, path) == true
	end
	host.fs.readfile = function(path)
		local fn = globalFunction("readfile")
		if not fn then
			error("NEVAHEXUI: readfile is unavailable in this runtime")
		end
		return fn(path)
	end
	host.fs.writefile = function(path, contents)
		local fn = globalFunction("writefile")
		if not fn then
			error("NEVAHEXUI: writefile is unavailable in this runtime")
		end
		fn(path, contents)
	end
	host.fs.appendfile = function(path, contents)
		local fn = globalFunction("appendfile")
		if fn then
			fn(path, contents)
		else
			host.fs.writefile(path, host.fs.readfile(path) .. contents)
		end
	end
	host.fs.makefolder = function(path)
		local fn = globalFunction("makefolder")
		if fn then
			safeCall(fn, path)
		end
	end
	host.fs.delfile = function(path)
		local fn = globalFunction("delfile")
		if fn then
			safeCall(fn, path)
		end
	end
	host.fs.listfiles = function(path)
		local fn = globalFunction("listfiles")
		if not fn then
			return {}
		end
		return safeCall(fn, path) or {}
	end

	return host
end

return RobloxHost
end)()

local __NEVA_Compatibility_Host = (function()
--[[
	NEVAHEXUI - Compatibility/Host
	Selects and constructs the runtime back end. Every other module receives the
	host by dependency injection, so the whole framework can execute headless.
]]

local Capabilities = __NEVA_Compatibility_Capabilities
local MockHost = __NEVA_Compatibility_MockHost
local RobloxHost = __NEVA_Compatibility_RobloxHost

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
end)()

local __NEVA_Core_Dependency = (function()
--[[
	NEVAHEXUI - Core/Dependency
	Dependency expressions and the dependency hub. A dependency is either a flag
	name (satisfied when the referenced component's value is truthy) or a spec
	table supporting Value/Operator/Matches/Any/All composition.
]]

local Dependency = {}

local OPERATORS = {
	["=="] = function(actual, expected)
		return actual == expected
	end,
	["~="] = function(actual, expected)
		return actual ~= expected
	end,
	[">"] = function(actual, expected)
		return type(actual) == "number" and actual > expected
	end,
	[">="] = function(actual, expected)
		return type(actual) == "number" and actual >= expected
	end,
	["<"] = function(actual, expected)
		return type(actual) == "number" and actual < expected
	end,
	["<="] = function(actual, expected)
		return type(actual) == "number" and actual <= expected
	end,
	["truthy"] = function(actual)
		return actual ~= nil and actual ~= false
	end,
	["falsy"] = function(actual)
		return actual == nil or actual == false
	end,
	contains = function(actual, expected)
		if type(actual) ~= "table" then
			return false
		end
		for _, item in ipairs(actual) do
			if item == expected then
				return true
			end
		end
		return false
	end,
}

function Dependency.matches(spec, getValue)
	if spec == nil then
		return true
	end
	if type(spec) == "string" then
		local value = getValue(spec)
		return value ~= nil and value ~= false
	end
	if type(spec) ~= "table" then
		return true
	end
	if spec.All then
		for _, child in ipairs(spec.All) do
			if not Dependency.matches(child, getValue) then
				return false
			end
		end
		return true
	end
	if spec.Any then
		for _, child in ipairs(spec.Any) do
			if Dependency.matches(child, getValue) then
				return true
			end
		end
		return false
	end
	if spec.Matches then
		return spec.Matches(getValue(spec.Flag)) == true
	end
	if spec.Not then
		return not Dependency.matches(spec.Not, getValue)
	end
	local actual = getValue(spec.Flag)
	local operator = spec.Operator
	if operator == nil then
		operator = spec.Value ~= nil and "==" or "truthy"
	end
	local handler = OPERATORS[operator]
	if not handler then
		return false
	end
	return handler(actual, spec.Value) == true
end

function Dependency.describe(spec)
	if type(spec) == "string" then
		return spec
	end
	if type(spec) ~= "table" then
		return tostring(spec)
	end
	if spec.All then
		local parts = {}
		for _, child in ipairs(spec.All) do
			table.insert(parts, Dependency.describe(child))
		end
		return "all(" .. table.concat(parts, ", ") .. ")"
	end
	if spec.Matches then
		return ("%s matches predicate"):format(tostring(spec.Flag))
	end
	return ("%s %s %s"):format(tostring(spec.Flag), tostring(spec.Operator or "=="), tostring(spec.Value))
end

function Dependency.flagsIn(spec, out)
	out = out or {}
	if type(spec) == "string" then
		table.insert(out, spec)
	elseif type(spec) == "table" then
		if spec.Flag then
			table.insert(out, spec.Flag)
		end
		if spec.All then
			for _, child in ipairs(spec.All) do
				Dependency.flagsIn(child, out)
			end
		end
		if spec.Any then
			for _, child in ipairs(spec.Any) do
				Dependency.flagsIn(child, out)
			end
		end
		if spec.Not then
			Dependency.flagsIn(spec.Not, out)
		end
	end
	return out
end

-- Subscription hub: components watch the flags they depend on and are notified
-- whenever any registered component's value changes.
function Dependency.newHub(store)
	local hub = { Store = store, Subscribers = {} }

	function hub:subscribe(flags, callback)
		local entry = { Flags = {}, Callback = callback, Connected = true }
		for _, flag in ipairs(flags) do
			entry.Flags[flag] = true
		end
		table.insert(self.Subscribers, entry)
		local connection = {}
		function connection:Disconnect()
			entry.Connected = false
		end
		return connection
	end

	function hub:publish(flag)
		if flag == nil then
			return 0
		end
		local notified = 0
		local snapshot = {}
		for _, entry in ipairs(self.Subscribers) do
			if entry.Connected and entry.Flags[flag] then
				table.insert(snapshot, entry)
			end
		end
		for _, entry in ipairs(snapshot) do
			if entry.Connected then
				notified += 1
				entry.Callback(flag)
			end
		end
		return notified
	end

	function hub:getValue(flag)
		local component = self.Store.get(flag)
		if not component then
			return nil
		end
		return component:GetValue()
	end

	return hub
end

Dependency.Operators = OPERATORS

return Dependency
end)()

local __NEVA_Core_Signal = (function()
--[[
	NEVAHEXUI - Core/Signal
	Minimal deterministic event emitter used for framework-internal signals.
]]

local Signal = {}
Signal.__index = Signal

function Signal.new(name)
	return setmetatable({
		Name = name or "Signal",
		_handlers = {},
		_destroyed = false,
	}, Signal)
end

function Signal:Connect(callback)
	assert(type(callback) == "function", "Signal:Connect expects a function")
	assert(not self._destroyed, "cannot connect to a destroyed signal")
	local handler = { callback = callback, connected = true, _owner = self }
	self._handlers[handler] = true
	local connection = {}
	function connection:Disconnect()
		if not handler.connected then
			return
		end
		handler.connected = false
		self._handlers[handler] = nil
	end
	-- keep a reference so Signal:Fire can iterate without exposing internals
	connection._handler = handler
	return connection
end

function Signal:Once(callback)
	local connection
	connection = self:Connect(function(...)
		connection:Disconnect()
		callback(...)
	end)
	return connection
end

function Signal:Fire(...)
	if self._destroyed then
		return 0
	end
	local fired = 0
	-- snapshot so handlers can disconnect during dispatch
	local snapshot = {}
	for handler in pairs(self._handlers) do
		if handler.connected then
			table.insert(snapshot, handler)
		end
	end
	for _, handler in ipairs(snapshot) do
		if handler.connected then
			fired += 1
			handler.callback(...)
		end
	end
	return fired
end

function Signal:GetConnectionCount()
	local total = 0
	for handler in pairs(self._handlers) do
		if handler.connected then
			total += 1
		end
	end
	return total
end

function Signal:DisconnectAll()
	for handler in pairs(self._handlers) do
		handler.connected = false
	end
	self._handlers = {}
end

function Signal:Destroy()
	self:DisconnectAll()
	self._destroyed = true
end

return Signal
end)()

local __NEVA_Core_Util = (function()
--[[
	NEVAHEXUI - Core/Util
	Table, value and validation helpers used across the framework.
]]

local Util = {}

function Util.deepCopy(value, seen)
	if type(value) ~= "table" then
		return value
	end
	seen = seen or {}
	if seen[value] then
		return seen[value]
	end
	local copy = {}
	seen[value] = copy
	for key, item in pairs(value) do
		copy[Util.deepCopy(key, seen)] = Util.deepCopy(item, seen)
	end
	return setmetatable(copy, getmetatable(value))
end

-- Merges `override` onto a deep copy of `base`. Never mutates either input.
function Util.deepMerge(base, override, seen)
	local result = Util.deepCopy(base)
	if type(override) ~= "table" then
		return result
	end
	seen = seen or {}
	if seen[result] then
		return seen[result]
	end
	seen[result] = true
	for key, item in pairs(override) do
		local existing = result[key]
		if type(existing) == "table" and type(item) == "table" then
			result[key] = Util.deepMerge(existing, item, seen)
		else
			result[key] = Util.deepCopy(item)
		end
	end
	return result
end

function Util.shallowCopy(source)
	local copy = {}
	for key, value in pairs(source) do
		copy[key] = value
	end
	return copy
end

function Util.count(source)
	local total = 0
	for _ in pairs(source) do
		total += 1
	end
	return total
end

function Util.keys(source)
	local out = {}
	for key in pairs(source) do
		table.insert(out, key)
	end
	table.sort(out, function(a, b)
		return tostring(a) < tostring(b)
	end)
	return out
end

function Util.clamp(value, min, max)
	if value < min then
		return min
	elseif value > max then
		return max
	end
	return value
end

function Util.round(value, precision)
	if not precision or precision <= 0 then
		return math.floor(value + 0.5)
	end
	local factor = 10 ^ precision
	return math.floor(value * factor + 0.5) / factor
end

function Util.isCallable(value)
	return type(value) == "function"
end

function Util.isSignalLike(value)
	return type(value) == "table" and Util.isCallable(value.Connect)
end

-- Safe invocation: returns ok, result. Reports failures through the logger.
function Util.safeCall(logger, label, fn, ...)
	local ok, result = pcall(fn, ...)
	if not ok and logger then
		logger:error(("%s failed: %s"):format(label, tostring(result)))
	end
	return ok, result
end

local counter = 0
function Util.uniqueId(prefix)
	counter += 1
	return ("%s#%d"):format(prefix or "id", counter)
end

function Util.resetUniqueIds()
	counter = 0
end

function Util.isFiniteNumber(value)
	return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

-- Validators return: ok(boolean), message(string?)
local validators = {}

function validators.number(value, spec)
	spec = spec or {}
	if not Util.isFiniteNumber(value) then
		return false, "expected a finite number"
	end
	if spec.min and value < spec.min then
		return false, ("must be >= %s"):format(tostring(spec.min))
	end
	if spec.max and value > spec.max then
		return false, ("must be <= %s"):format(tostring(spec.max))
	end
	if spec.positive and value <= 0 then
		return false, "must be greater than zero"
	end
	return true
end

function validators.boolean(value)
	if type(value) ~= "boolean" then
		return false, "expected a boolean"
	end
	return true
end

function validators.string(value, spec)
	if type(value) ~= "string" then
		return false, "expected a string"
	end
	spec = spec or {}
	if spec.nonEmpty and value == "" then
		return false, "must not be empty"
	end
	return true
end

function validators.enum(values)
	return function(value)
		for _, candidate in ipairs(values) do
			if candidate == value then
				return true
			end
		end
		return false, ("must be one of: %s"):format(table.concat(values, ", "))
	end
end

function validators.array(value, itemValidator)
	if type(value) ~= "table" then
		return false, "expected an array"
	end
	for index, item in ipairs(value) do
		local ok, message = itemValidator(item)
		if not ok then
			return false, ("index %d: %s"):format(index, message or "invalid")
		end
	end
	return true
end

Util.validators = validators

function Util.isArray(value)
	if type(value) ~= "table" then
		return false
	end
	local count = 0
	for key in pairs(value) do
		if type(key) ~= "number" then
			return false
		end
		count += 1
	end
	return count == #value
end

-- Structural equality used to decide whether a value actually changed. Colours
-- compare through their metatable __eq, everything else is compared field-wise.
function Util.deepEquals(a, b, seen)
	if a == b then
		return true
	end
	local typeA, typeB = type(a), type(b)
	if typeA ~= typeB or typeA ~= "table" then
		if typeA == "number" and typeB == "number" then
			return math.abs(a - b) < 1e-9
		end
		return false
	end
	local metaA = getmetatable(a)
	if metaA ~= nil and metaA == getmetatable(b) and metaA.__eq then
		return metaA.__eq(a, b) == true
	end
	seen = seen or {}
	if seen[a] == b then
		return true
	end
	seen[a] = b
	for key, value in pairs(a) do
		if not Util.deepEquals(value, b[key], seen) then
			return false
		end
	end
	for key in pairs(b) do
		if a[key] == nil then
			return false
		end
	end
	return true
end

function Util.formatValue(value)
	if type(value) == "string" then
		return ("%q"):format(value)
	elseif type(value) == "table" then
		if value.__nevaColor then
			return value:toHex()
		end
		local parts = {}
		for _, key in ipairs(Util.keys(value)) do
			table.insert(parts, ("%s = %s"):format(tostring(key), Util.formatValue(value[key])))
		end
		return "{" .. table.concat(parts, ", ") .. "}"
	end
	return tostring(value)
end

return Util
end)()

local __NEVA_Utilities_Color = (function()
--[[
	NEVAHEXUI - Utilities/Color
	Colour normalisation. Accepts real Roblox Color3 values, mock Color3 values,
	{ r, g, b, a } tables (0-1 or 0-255) and hex strings, and normalises them to a
	0-1 RGBA record that the host back end can convert back to its own colour type.
]]

local Color = {}
Color.__index = Color

local function detectColor3(value)
	if type(value) ~= "table" and type(value) ~= "userdata" then
		return nil
	end
	local ok, r = pcall(function()
		return value.R
	end)
	if not ok or type(r) ~= "number" then
		return nil
	end
	local g = value.G
	local b = value.B
	if type(g) ~= "number" or type(b) ~= "number" then
		return nil
	end
	return r, g, b
end

function Color.new(r, g, b, a)
	local normalised = setmetatable({}, Color)
	normalised.__nevaColor = true
	normalised:Set(r, g, b, a)
	return normalised
end

function Color.fromRGB(r, g, b, a)
	return Color.new((r or 0) / 255, (g or 0) / 255, (b or 0) / 255, a)
end

function Color:Set(r, g, b, a)
	local scale = 1
	if (r or 0) > 1 or (g or 0) > 1 or (b or 0) > 1 then
		scale = 255
	end
	self.R = math.max(0, math.min(1, (r or 0) / scale))
	self.G = math.max(0, math.min(1, (g or 0) / scale))
	self.B = math.max(0, math.min(1, (b or 0) / scale))
	self.A = a == nil and (self.A or 1) or math.max(0, math.min(1, a))
	return self
end

function Color:Clone()
	return Color.new(self.R, self.G, self.B, self.A)
end

function Color:ToRGB()
	return math.floor(self.R * 255 + 0.5), math.floor(self.G * 255 + 0.5), math.floor(self.B * 255 + 0.5)
end

function Color:ToHex()
	local r, g, b = self:ToRGB()
	local hex = ("%02X%02X%02X"):format(r, g, b)
	if self.A < 0.999 then
		hex = hex .. ("%02X"):format(math.floor(self.A * 255 + 0.5))
	end
	return "#" .. hex
end

function Color:ToHSV()
	local r, g, b = self.R, self.G, self.B
	local maxValue = math.max(r, g, b)
	local minValue = math.min(r, g, b)
	local delta = maxValue - minValue
	local hue = 0
	if delta > 0 then
		if maxValue == r then
			hue = ((g - b) / delta) % 6
		elseif maxValue == g then
			hue = (b - r) / delta + 2
		else
			hue = (r - g) / delta + 4
		end
		hue = hue / 6
		if hue < 0 then
			hue += 1
		end
	end
	local saturation = maxValue == 0 and 0 or delta / maxValue
	return hue, saturation, maxValue, self.A
end

function Color.fromHSV(h, s, v, a)
	h = (h or 0) % 1
	s = math.max(0, math.min(1, s or 0))
	v = math.max(0, math.min(1, v or 0))
	local i = math.floor(h * 6)
	local f = h * 6 - i
	local p = v * (1 - s)
	local q = v * (1 - f * s)
	local t = v * (1 - (1 - f) * s)
	i = i % 6
	local r, g, b
	if i == 0 then
		r, g, b = v, t, p
	elseif i == 1 then
		r, g, b = q, v, p
	elseif i == 2 then
		r, g, b = p, v, t
	elseif i == 3 then
		r, g, b = p, q, v
	elseif i == 4 then
		r, g, b = t, p, v
	else
		r, g, b = v, p, q
	end
	return Color.new(r, g, b, a)
end

local function parseHex(text)
	local cleaned = text:gsub("#", ""):gsub("%s", "")
	local length = #cleaned
	if length ~= 3 and length ~= 4 and length ~= 6 and length ~= 8 then
		return nil, "hex colours must have 3, 4, 6 or 8 digits"
	end
	if not cleaned:match("^%x+$") then
		return nil, "hex colours may only contain 0-9 and A-F"
	end
	if length == 3 or length == 4 then
		local expanded = ""
		for index = 1, length do
			expanded = expanded .. cleaned:sub(index, index):rep(2)
		end
		cleaned = expanded
		length = #cleaned
	end
	local r = tonumber(cleaned:sub(1, 2), 16) / 255
	local g = tonumber(cleaned:sub(3, 4), 16) / 255
	local b = tonumber(cleaned:sub(5, 6), 16) / 255
	local a = length == 8 and tonumber(cleaned:sub(7, 8), 16) / 255 or nil
	return Color.new(r, g, b, a)
end

-- Accepts anything the framework considers a colour and returns a NEVA colour.
function Color.normalize(value)
	if value == nil then
		return nil, "value is nil"
	end
	if getmetatable(value) == Color then
		return value
	end
	if type(value) == "string" then
		return parseHex(value)
	end
	local r, g, b = detectColor3(value)
	if r then
		local alpha
		local ok, a = pcall(function()
			return value.A
		end)
		if ok and type(a) == "number" then
			alpha = a
		end
		return Color.new(r, g, b, alpha)
	end
	if type(value) == "table" and type(value.r) == "number" and type(value.g) == "number" and type(value.b) == "number" then
		local scale = 1
		if value.r > 1 or value.g > 1 or value.b > 1 then
			scale = 255
		end
		return Color.new(value.r / scale, value.g / scale, value.b / scale, value.a)
	end
	return nil, ("unsupported colour value of type %s"):format(typeof and typeof(value) or type(value))
end

function Color.isColor(value)
	return Color.normalize(value) ~= nil
end

function Color.lerp(a, b, alpha)
	local left = Color.normalize(a)
	local right = Color.normalize(b)
	if not left or not right then
		return left or right
	end
	return Color.new(
		left.R + (right.R - left.R) * alpha,
		left.G + (right.G - left.G) * alpha,
		left.B + (right.B - left.B) * alpha,
		left.A + (right.A - left.A) * alpha
	)
end

function Color.equals(a, b)
	local left = Color.normalize(a)
	local right = Color.normalize(b)
	if not left or not right then
		return false
	end
	local tolerance = 0.002
	return math.abs(left.R - right.R) < tolerance
		and math.abs(left.G - right.G) < tolerance
		and math.abs(left.B - right.B) < tolerance
		and math.abs(left.A - right.A) < tolerance
end

function Color.__tostring(self)
	return ("Color(%s)"):format(self:ToHex())
end

function Color.__eq(a, b)
	return Color.equals(a, b)
end

return Color
end)()

local __NEVA_Styles_Schema = (function()
--[[
	NEVAHEXUI - Styles/Schema
	Property schemas describe what a style can be configured with. The schema is
	the single source of truth for: defaults, validation, the Style Studio
	inspector, generated documentation and Luau export.
]]

local Util = __NEVA_Core_Util
local Color = __NEVA_Utilities_Color

local Schema = {}

Schema.Types = {
	number = true,
	boolean = true,
	string = true,
	text = true,
	color = true,
	colorArray = true,
	enum = true,
	font = true,
	animation = true,
	keycode = true,
}

Schema.GroupOrder = {
	"Appearance",
	"Geometry",
	"Typography",
	"States",
	"Animation",
	"Behaviour",
	"Advanced",
}

local function groupRank(name)
	for index, candidate in ipairs(Schema.GroupOrder) do
		if candidate == name then
			return index
		end
	end
	return #Schema.GroupOrder + 1
end

-- Normalises a property descriptor, filling in labels and defaults.
function Schema.property(descriptor)
	assert(type(descriptor) == "table", "Schema.property expects a table")
	assert(type(descriptor.Key) == "string" and descriptor.Key ~= "", "property descriptors need a Key")
	local kind = descriptor.Type or "number"
	assert(Schema.Types[kind], ("unknown property type %q for %s"):format(tostring(kind), descriptor.Key))
	local record = {
		Key = descriptor.Key,
		Type = kind,
		Default = descriptor.Default,
		Label = descriptor.Label or descriptor.Key:gsub("(%l)(%u)", "%1 %2"),
		Group = descriptor.Group or "Appearance",
		Description = descriptor.Description or "",
		Min = descriptor.Min,
		Max = descriptor.Max,
		Step = descriptor.Step,
		Suffix = descriptor.Suffix,
		Options = descriptor.Options,
		Requires = descriptor.Requires,
		Hidden = descriptor.Hidden == true,
		Experimental = descriptor.Experimental == true,
	}
	if kind == "enum" then
		assert(type(record.Options) == "table" and #record.Options > 0, ("enum property %s needs Options"):format(record.Key))
	end
	if kind == "colorArray" then
		record.Min = record.Min or 0
		record.Max = record.Max or 12
	end
	return record
end

function Schema.validateProperties(descriptors)
	local errors = {}
	local seen = {}
	for _, descriptor in ipairs(descriptors or {}) do
		if type(descriptor.Key) ~= "string" or descriptor.Key == "" then
			table.insert(errors, "property descriptor is missing a Key")
		elseif seen[descriptor.Key] then
			table.insert(errors, ("duplicate property %q"):format(descriptor.Key))
		else
			seen[descriptor.Key] = true
		end
		if descriptor.Type and not Schema.Types[descriptor.Type] then
			table.insert(errors, ("unknown type %q on %s"):format(tostring(descriptor.Type), tostring(descriptor.Key)))
		end
	end
	return #errors == 0, errors
end

function Schema.index(descriptors)
	local map = {}
	for _, descriptor in ipairs(descriptors or {}) do
		map[descriptor.Key] = descriptor
	end
	return map
end

function Schema.defaults(descriptors)
	local out = {}
	for _, descriptor in ipairs(descriptors or {}) do
		if descriptor.Default ~= nil then
			out[descriptor.Key] = Util.deepCopy(descriptor.Default)
		end
	end
	return out
end

-- Merges descriptor lists, later entries overriding earlier ones by Key.
function Schema.merge(...)
	local byKey = {}
	local order = {}
	for _, list in ipairs({ ... }) do
		for _, descriptor in ipairs(list or {}) do
			if byKey[descriptor.Key] == nil then
				table.insert(order, descriptor.Key)
			end
			byKey[descriptor.Key] = descriptor
		end
	end
	local out = {}
	for _, key in ipairs(order) do
		table.insert(out, byKey[key])
	end
	return out
end

local function validateValue(descriptor, value)
	local kind = descriptor.Type
	if kind == "number" then
		local ok, message = Util.validators.number(value, { min = descriptor.Min, max = descriptor.Max })
		if not ok then
			return false, message
		end
		if descriptor.Step and descriptor.Step > 0 then
			local snapped = math.floor(value / descriptor.Step + 0.5) * descriptor.Step
			if math.abs(snapped - value) > 1e-9 then
				return true, nil, Util.round(snapped, 6)
			end
		end
		return true
	elseif kind == "boolean" then
		return Util.validators.boolean(value)
	elseif kind == "string" or kind == "text" then
		return Util.validators.string(value)
	elseif kind == "font" then
		return Util.validators.string(value, { nonEmpty = true })
	elseif kind == "color" then
		local normalised, message = Color.normalize(value)
		if not normalised then
			return false, message
		end
		return true, nil, normalised
	elseif kind == "colorArray" then
		if type(value) ~= "table" then
			return false, "expected an array of colours"
		end
		local out = {}
		for index, item in ipairs(value) do
			local normalised, message = Color.normalize(item)
			if not normalised then
				return false, ("index %d: %s"):format(index, message or "invalid colour")
			end
			table.insert(out, normalised)
		end
		local min = descriptor.Min or 0
		local max = descriptor.Max or 12
		if #out < min then
			return false, ("expected at least %d colours"):format(min)
		end
		if #out > max then
			return false, ("expected at most %d colours"):format(max)
		end
		return true, nil, out
	elseif kind == "enum" then
		if value == nil then
			return false, "value is nil"
		end
		return Util.validators.enum(descriptor.Options)(value)
	elseif kind == "animation" then
		if type(value) == "string" then
			return true
		end
		if type(value) == "table" then
			if value.Duration ~= nil and not Util.isFiniteNumber(value.Duration) then
				return false, "animation.Duration must be a number"
			end
			return true
		end
		return false, "expected an animation preset name or specification table"
	elseif kind == "keycode" then
		if value == false then
			return true
		end
		if type(value) == "string" then
			return true
		end
		return false, "expected a key name or false for unbound"
	end
	return false, ("unsupported property type %q"):format(tostring(kind))
end

-- Returns: ok, cleanedConfig, errors, warnings
function Schema.validate(descriptors, config, options)
	options = options or {}
	local index = Schema.index(descriptors)
	local cleaned = {}
	local errors = {}
	local warnings = {}

	for _, descriptor in ipairs(descriptors or {}) do
		if descriptor.Default ~= nil then
			cleaned[descriptor.Key] = Util.deepCopy(descriptor.Default)
		end
	end

	for key, value in pairs(config or {}) do
		local descriptor = index[key]
		if not descriptor then
			if options.AllowUnknown then
				cleaned[key] = value
			end
			table.insert(warnings, ("unknown property %q"):format(tostring(key)))
		else
			local ok, message, replaced = validateValue(descriptor, value)
			if ok then
				cleaned[key] = replaced ~= nil and replaced or value
			else
				table.insert(errors, ("%s: %s"):format(key, message or "invalid value"))
				if descriptor.Default ~= nil and not options.Strict then
					cleaned[key] = Util.deepCopy(descriptor.Default)
				end
			end
		end
	end

	if options.Strict and #errors > 0 then
		return false, cleaned, errors, warnings
	end
	return #errors == 0, cleaned, errors, warnings
end

function Schema.groups(descriptors)
	local seen = {}
	local out = {}
	for _, descriptor in ipairs(descriptors or {}) do
		if not seen[descriptor.Group] then
			seen[descriptor.Group] = true
			table.insert(out, descriptor.Group)
		end
	end
	table.sort(out, function(a, b)
		local ra, rb = groupRank(a), groupRank(b)
		if ra == rb then
			return a < b
		end
		return ra < rb
	end)
	return out
end

function Schema.describe(descriptors)
	local out = {}
	for _, descriptor in ipairs(descriptors or {}) do
		table.insert(out, {
			Key = descriptor.Key,
			Type = descriptor.Type,
			Label = descriptor.Label,
			Group = descriptor.Group,
			Description = descriptor.Description,
			Default = Util.deepCopy(descriptor.Default),
			Min = descriptor.Min,
			Max = descriptor.Max,
			Step = descriptor.Step,
			Suffix = descriptor.Suffix,
			Options = descriptor.Options and Util.deepCopy(descriptor.Options) or nil,
			Hidden = descriptor.Hidden,
			Experimental = descriptor.Experimental,
		})
	end
	table.sort(out, function(a, b)
		local ra, rb = groupRank(a.Group), groupRank(b.Group)
		if ra == rb then
			return a.Key < b.Key
		end
		return ra < rb
	end)
	return out
end

local function formatScalar(value, options, indent)
	local kind = type(value)
	if kind == "number" then
		if value == math.floor(value) then
			return tostring(value)
		end
		return (("%.4f"):format(value):gsub("0+$", ""):gsub("%.$", ""))
	elseif kind == "boolean" then
		return tostring(value)
	elseif kind == "string" then
		return ("%q"):format(value)
	elseif kind == "table" then
		if getmetatable(value) == Color then
			if options.Colors == "rgb" then
				local r, g, b = value:ToRGB()
				return ("Color3.fromRGB(%d, %d, %d)"):format(r, g, b)
			end
			return ("%q"):format(value:ToHex())
		end
		local parts = {}
		for _, key in ipairs(Util.keys(value)) do
			local rendered = formatScalar(value[key], options, indent .. "  ")
			if rendered ~= nil then
				table.insert(parts, ("%s = %s"):format(tostring(key), rendered))
			end
		end
		if #parts == 0 then
			return "{}"
		end
		return "{ " .. table.concat(parts, ", ") .. " }"
	end
	return nil
end

-- Serialises a configuration table as valid Luau source.
function Schema.exportLua(config, descriptors, options)
	options = options or {}
	options.Colors = options.Colors or "hex"
	local indent = options.Indent or "  "
	local level = options.Level or 0
	local index = Schema.index(descriptors)
	local keys = {}
	for _, descriptor in ipairs(descriptors or {}) do
		if config[descriptor.Key] ~= nil then
			table.insert(keys, descriptor.Key)
		end
	end
	for _, key in ipairs(Util.keys(config)) do
		if not index[key] then
			table.insert(keys, key)
		end
	end
	local pad = indent:rep(level)
	local childPad = indent:rep(level + 1)
	local lines = { "{" }
	for _, key in ipairs(keys) do
		local rendered = formatScalar(config[key], options, childPad)
		if rendered ~= nil then
			table.insert(lines, ("%s%s = %s,"):format(childPad, tostring(key), rendered))
		end
	end
	table.insert(lines, pad .. "}")
	return table.concat(lines, "\n")
end

-- Named-style export wrapper: produces a RegisterStyle-ready definition.
function Schema.exportStyle(style, options)
	options = options or {}
	options.Colors = options.Colors or "hex"
	local lines = {}
	table.insert(lines, "NEVAHEXUI:RegisterStyle({")
	table.insert(lines, ("  Id = %q,"):format(style.Id))
	table.insert(lines, ("  Name = %q,"):format(style.Name))
	table.insert(lines, ("  Component = %q,"):format(style.Component))
	if style.BasedOn then
		table.insert(lines, ("  BasedOn = %q,"):format(style.BasedOn))
	end
	if style.Description and style.Description ~= "" then
		table.insert(lines, ("  Description = %q,"):format(style.Description))
	end
	table.insert(lines, "  Configuration = " .. Schema.exportLua(style.Configuration or {}, style.Properties or {}, {
		Colors = options.Colors,
		Indent = "  ",
		Level = 1,
	}) .. ",")
	table.insert(lines, "})")
	return table.concat(lines, "\n")
end

return Schema
end)()

local __NEVA_Styles_Registry = (function()
--[[
	NEVAHEXUI - Styles/Registry
	The style registry owns component descriptors (built-in defaults plus a
	property schema per component category) and style implementations
	(a distinct renderer per style Id, optionally derived from another style).

	Registration rules:
	  * Style Ids must be "<component>.<name>" in lowercase.
	  * Duplicate Ids are rejected unless the caller passes Replace = true.
	  * Every registered style must supply a callable Render function, so the
	    catalogue can never contain a style without a real implementation.
]]

local Util = __NEVA_Core_Util
local Schema = __NEVA_Styles_Schema

local Registry = {}

Registry.Components = {}
Registry.ComponentOrder = {}
Registry.Styles = {}
Registry.StyleOrder = {}
Registry.Replacements = {}
Registry.Warnings = {}

local ID_PATTERN = "^[a-z0-9_]+%.[a-z0-9_%-%.]+$"

local function describeErrors(errors)
	return table.concat(errors, "; ")
end

function Registry.registerComponent(definition)
	assert(type(definition) == "table", "registerComponent expects a table")
	assert(type(definition.Name) == "string" and definition.Name ~= "", "component descriptors need a Name")
	local existing = Registry.Components[definition.Name]
	if existing then
		return existing
	end
	local properties = {}
	for _, descriptor in ipairs(definition.Properties or {}) do
		table.insert(properties, Schema.property(descriptor))
	end
	local ok, errors = Schema.validateProperties(properties)
	if not ok then
		error(("NEVAHEXUI: component %s has an invalid property schema: %s"):format(definition.Name, describeErrors(errors)))
	end
	local record = {
		Name = definition.Name,
		RegistryName = definition.RegistryName or (definition.Name .. "s"),
		Category = definition.Category or "Controls",
		Description = definition.Description or "",
		Defaults = Util.deepCopy(definition.Defaults or {}),
		Properties = properties,
	}
	Registry.Components[record.Name] = record
	table.insert(Registry.ComponentOrder, record.Name)
	return record
end

function Registry.registerStyle(definition)
	assert(type(definition) == "table", "registerStyle expects a table")
	local errors = {}
	if type(definition.Id) ~= "string" or not definition.Id:match(ID_PATTERN) then
		table.insert(errors, ("style Id %q must look like \"toggle.rounded\" in lowercase"):format(tostring(definition.Id)))
	end
	if type(definition.Name) ~= "string" or definition.Name == "" then
		table.insert(errors, "style Name must be a non-empty string")
	end
	local component = Registry.Components[definition.Component]
	if not component then
		table.insert(errors, ("unknown component %q for style %q"):format(tostring(definition.Component), tostring(definition.Id)))
	end
	if not Util.isCallable(definition.Render) then
		table.insert(errors, ("style %q must provide a callable Render function"):format(tostring(definition.Id)))
	end
	if definition.Id and Registry.Styles[definition.Id] and not definition.Replace then
		table.insert(errors, ("style %q is already registered; pass Replace = true to replace it deliberately"):format(definition.Id))
	end
	local basedOn = definition.BasedOn
	if basedOn then
		local base = Registry.Styles[basedOn]
		if not base then
			table.insert(errors, ("style %q is BasedOn unknown style %q"):format(tostring(definition.Id), tostring(basedOn)))
		elseif component and base.Component ~= component.Name then
			table.insert(errors, ("style %q cannot derive from %q: different component types"):format(definition.Id, basedOn))
		end
	end
	local properties = {}
	for _, descriptor in ipairs(definition.Properties or {}) do
		table.insert(properties, Schema.property(descriptor))
	end
	local schemaOk, schemaErrors = Schema.validateProperties(properties)
	if not schemaOk then
		for _, message in ipairs(schemaErrors) do
			table.insert(errors, ("style %q: %s"):format(tostring(definition.Id), message))
		end
	end
	if #errors > 0 then
		return nil, errors
	end
	if definition.Id and Registry.Styles[definition.Id] then
		table.insert(Registry.Replacements, {
			Id = definition.Id,
			Replaced = Registry.Styles[definition.Id],
		})
	end
	local record = {
		Id = definition.Id,
		Name = definition.Name,
		Component = definition.Component,
		Category = definition.Category or component.Category,
		Description = definition.Description or "",
		BasedOn = basedOn,
		Configuration = Util.deepCopy(definition.Configuration or {}),
		Properties = properties,
		Render = definition.Render,
		Animate = definition.Animate,
		Preview = definition.Preview,
		Validate = definition.Validate,
		Compatibility = Util.deepCopy(definition.Compatibility or {}),
		Tags = Util.deepCopy(definition.Tags or {}),
		Author = definition.Author,
		Experimental = definition.Experimental == true,
		BuiltIn = definition.BuiltIn == true,
		Replace = definition.Replace == true,
	}
	if not Registry.Styles[record.Id] then
		table.insert(Registry.StyleOrder, record.Id)
	end
	Registry.Styles[record.Id] = record
	return record
end

-- Registers many styles, collecting failures instead of aborting the build.
function Registry.registerMany(definitions, options)
	options = options or {}
	local registered = {}
	local failures = {}
	for _, definition in ipairs(definitions) do
		local copy = Util.shallowCopy(definition)
		if options.BuiltIn then
			copy.BuiltIn = true
		end
		local record, errors = Registry.registerStyle(copy)
		if record then
			table.insert(registered, record)
		else
			table.insert(failures, { Id = copy.Id, Errors = errors })
			for _, message in ipairs(errors or {}) do
				table.insert(Registry.Warnings, message)
			end
		end
	end
	return registered, failures
end

function Registry.get(id)
	return Registry.Styles[id]
end

function Registry.require(id)
	local style = Registry.Styles[id]
	if not style then
		error(("NEVAHEXUI: unknown style %q. Use NEVAHEXUI:GetStyleCatalog() to list registered styles."):format(tostring(id)), 2)
	end
	return style
end

function Registry.has(id)
	return Registry.Styles[id] ~= nil
end

function Registry.unregister(id)
	local style = Registry.Styles[id]
	if not style then
		return false
	end
	Registry.Styles[id] = nil
	for index, candidate in ipairs(Registry.StyleOrder) do
		if candidate == id then
			table.remove(Registry.StyleOrder, index)
			break
		end
	end
	return true
end

-- Ancestor chain from root base style to the requested style.
function Registry.chain(id, seen)
	local style = Registry.require(id)
	seen = seen or {}
	if seen[id] then
		error(("NEVAHEXUI: style inheritance cycle detected at %q"):format(id), 2)
	end
	seen[id] = true
	local chain = {}
	if style.BasedOn then
		for _, ancestor in ipairs(Registry.chain(style.BasedOn, seen)) do
			table.insert(chain, ancestor)
		end
	end
	table.insert(chain, style)
	return chain
end

function Registry.effectiveProperties(chain)
	local lists = {}
	for _, style in ipairs(chain) do
		table.insert(lists, style.Properties)
	end
	if #chain > 0 then
		local component = Registry.Components[chain[1].Component]
		if component and #component.Properties > 0 then
			table.insert(lists, 1, component.Properties)
		end
	end
	return Schema.merge(table.unpack(lists))
end

function Registry.list(component)
	local out = {}
	for _, id in ipairs(Registry.StyleOrder) do
		local style = Registry.Styles[id]
		if not component or style.Component == component then
			table.insert(out, style)
		end
	end
	return out
end

function Registry.styleIds(component)
	local out = {}
	for _, style in ipairs(Registry.list(component)) do
		table.insert(out, style.Id)
	end
	return out
end

function Registry.listComponents()
	local out = {}
	for _, name in ipairs(Registry.ComponentOrder) do
		table.insert(out, Registry.Components[name])
	end
	return out
end

function Registry.count()
	return #Registry.StyleOrder
end

-- The default style for a component category is the first style registered for
-- it, unless the library/window configuration selects another one.
function Registry.defaultStyleId(componentName)
	for _, id in ipairs(Registry.StyleOrder) do
		if Registry.Styles[id].Component == componentName then
			return id
		end
	end
	return nil
end

function Registry.componentNames()
	local out = {}
	for _, name in ipairs(Registry.ComponentOrder) do
		table.insert(out, name)
	end
	return out
end

-- Catalogue used by the Style Studio and the generated style showcase.
function Registry.catalog()
	local components = {}
	for _, name in ipairs(Registry.ComponentOrder) do
		local descriptor = Registry.Components[name]
		local styles = {}
		for _, style in ipairs(Registry.list(name)) do
			local chain = Registry.chain(style.Id)
			table.insert(styles, {
				Id = style.Id,
				Name = style.Name,
				Component = style.Component,
				Category = style.Category,
				Description = style.Description,
				BasedOn = style.BasedOn,
				BuiltIn = style.BuiltIn,
				Experimental = style.Experimental,
				Tags = style.Tags,
				Compatibility = style.Compatibility,
				Configuration = Util.deepCopy(style.Configuration),
				Properties = Schema.describe(Registry.effectiveProperties(chain)),
				Groups = Schema.groups(Registry.effectiveProperties(chain)),
				Chain = (function()
					local ids = {}
					for _, entry in ipairs(chain) do
						table.insert(ids, entry.Id)
					end
					return ids
				end)(),
			})
		end
		table.insert(components, {
			Name = descriptor.Name,
			RegistryName = descriptor.RegistryName,
			Category = descriptor.Category,
			Description = descriptor.Description,
			Defaults = Util.deepCopy(descriptor.Defaults),
			StyleCount = #styles,
			Styles = styles,
		})
	end
	return { Components = components, StyleCount = Registry.count(), ComponentCount = #components }
end

return Registry
end)()

local __NEVA_Styles_Resolver = (function()
--[[
	NEVAHEXUI - Styles/Resolver
	Configuration inheritance. Six layers are merged from lowest to highest
	precedence:

	  1. ComponentDefaults       built-in defaults for the component category
	  2. StyleDefaults           the selected style's own default configuration
	  3. PresetOverrides         configuration of every derived style in the chain
	  4. CategoryConfiguration   window level StyleConfiguration.<Category>
	  5. ComponentConfiguration  the individual component's Style.Configuration
	  6. RuntimeOverrides        SetStyleConfiguration / SetStyleProperty calls

	Every layer is deep-copied before merging, so a resolved configuration can
	never mutate a shared style preset and one component's overrides can never
	leak into another.
]]

local Util = __NEVA_Core_Util
local Schema = __NEVA_Styles_Schema
local Registry = __NEVA_Styles_Registry

local Resolver = {}

Resolver.Layers = {
	"ComponentDefaults",
	"StyleDefaults",
	"PresetOverrides",
	"CategoryConfiguration",
	"ComponentConfiguration",
	"RuntimeOverrides",
}

local function recordLayerKeys(effective, layerName, config)
	for key in pairs(config or {}) do
		effective[key] = layerName
	end
end

-- request = {
--   Component = "Toggle",
--   StyleId   = "toggle.compact",
--   CategoryConfiguration = { ... },
--   ComponentConfiguration = { ... },
--   RuntimeOverrides = { ... },
--   Strict = false,
-- }
function Resolver.resolve(request)
	assert(type(request) == "table", "Resolver.resolve expects a request table")
	local componentName = request.Component
	local component = Registry.Components[componentName]
	local style = Registry.get(request.StyleId or "")

	local result = {
		Ok = false,
		Component = componentName,
		StyleId = request.StyleId,
		Style = style,
		Chain = {},
		Schema = {},
		Configuration = {},
		Layers = {},
		Effective = {},
		Errors = {},
		Warnings = {},
	}

	if not component then
		table.insert(result.Errors, ("unknown component category %q"):format(tostring(componentName)))
		return result
	end

	if not style then
		-- Fall back to the first registered style for the component so a typo in
		-- a style id degrades safely instead of breaking the interface.
		local fallback = Registry.list(componentName)[1]
		if fallback then
			table.insert(result.Warnings, ("unknown style %q for %s; falling back to %q")
				:format(tostring(request.StyleId), componentName, fallback.Id))
			result.StyleId = fallback.Id
			result.Style = fallback
			style = fallback
		end
	end

	if not style then
		table.insert(result.Errors, ("no style is registered for component %q"):format(componentName))
		return result
	end

	if style.Component ~= componentName then
		table.insert(result.Errors, ("style %q renders %s, not %s")
			:format(style.Id, style.Component, componentName))
		return result
	end

	local chain = Registry.chain(style.Id)
	local properties = Registry.effectiveProperties(chain)
	result.Chain = chain
	result.Schema = properties

	local layers = {
		ComponentDefaults = Util.deepCopy(component.Defaults),
		StyleDefaults = Util.deepCopy(chain[1].Configuration),
		PresetOverrides = {},
		CategoryConfiguration = Util.deepCopy(request.CategoryConfiguration or {}),
		ComponentConfiguration = Util.deepCopy(request.ComponentConfiguration or {}),
		RuntimeOverrides = Util.deepCopy(request.RuntimeOverrides or {}),
	}
	for index = 2, #chain do
		layers.PresetOverrides = Util.deepMerge(layers.PresetOverrides, chain[index].Configuration)
	end

	local merged = {}
	local effective = {}
	for _, layerName in ipairs(Resolver.Layers) do
		local layerConfig = layers[layerName]
		if next(layerConfig) ~= nil then
			-- Validate each layer against the effective schema so unknown or
			-- mistyped properties are attributed to the layer that supplied them.
			local ok, cleanedLayer, errors, warnings = Schema.validate(properties, layerConfig, {
				-- ComponentDefaults belong to the component descriptor and are
				-- validated where they are declared; a style may legitimately ignore
				-- one (a Dialog's Dismissible flag), so re-checking them against
				-- every style schema only produced noise.
				AllowUnknown = layerName == "ComponentDefaults"
					or layerName == "ComponentConfiguration"
					or layerName == "RuntimeOverrides",
			})
			for _, message in ipairs(warnings) do
				table.insert(result.Warnings, ("%s: %s"):format(layerName, message))
			end
			for _, message in ipairs(errors) do
				table.insert(result.Errors, ("%s: %s"):format(layerName, message))
			end
			if not ok and request.Strict then
				result.Configuration = merged
				result.Layers = layers
				result.Effective = effective
				return result
			end
			recordLayerKeys(effective, layerName, layerConfig)
			merged = Util.deepMerge(merged, cleanedLayer)
		end
	end

	-- Final pass: guarantees every schema default is present and valid even if a
	-- layer was skipped entirely.
	local ok, finalConfig, errors, warnings = Schema.validate(properties, merged, {
		AllowUnknown = true,
	})
	for _, message in ipairs(warnings) do
		table.insert(result.Warnings, ("resolved: %s"):format(message))
	end
	for _, message in ipairs(errors) do
		table.insert(result.Errors, ("resolved: %s"):format(message))
	end

	local styleValidate = style.Validate
	if Util.isCallable(styleValidate) then
		local okValidation, message = styleValidate(finalConfig)
		if not okValidation then
			table.insert(result.Errors, ("style %q: %s"):format(style.Id, message or "configuration rejected by the style"))
		end
	end

	result.Ok = ok and #result.Errors == 0
	result.Configuration = finalConfig
	result.Layers = layers
	result.Effective = effective
	return result
end

-- Convenience wrapper that raises on failure, for callers that cannot proceed.
function Resolver.resolveOrError(request, logger)
	local result = Resolver.resolve(request)
	if not result.Ok then
		local message = ("NEVAHEXUI: could not resolve configuration for %s (%s): %s"):format(
			tostring(request.Component),
			tostring(request.StyleId),
			table.concat(result.Errors, "; ")
		)
		if logger then
			logger:Warn(message)
		end
	end
	return result
end

-- Human-readable description of which layer supplied each value.
function Resolver.explain(result)
	local lines = {}
	table.insert(lines, ("Style: %s (%s)"):format(result.Style and result.Style.Name or "?", tostring(result.StyleId)))
	for _, layerName in ipairs(Resolver.Layers) do
		local layer = result.Layers[layerName] or {}
		local keys = Util.keys(layer)
		table.insert(lines, ("  %s: %d value(s)%s"):format(
			layerName,
			#keys,
			#keys > 0 and (" [" .. table.concat(keys, ", ") .. "]") or ""
		))
	end
	local resolved = {}
	for key, layerName in pairs(result.Effective) do
		table.insert(resolved, ("%s <- %s"):format(key, layerName))
	end
	table.sort(resolved)
	table.insert(lines, "  resolved:")
	for _, line in ipairs(resolved) do
		table.insert(lines, "    " .. line)
	end
	return table.concat(lines, "\n")
end

return Resolver
end)()

local __NEVA_Core_Component = (function()
--[[
	NEVAHEXUI - Core/Component
	The base component class. Every NEVAHEXUI component is created by
	Component.define{ Type = ..., ... } and shares this lifecycle:

	  resolve configuration -> render the style's view -> apply state

	The base class owns: value + default, callbacks, flag identity, dependencies,
	visibility/enabled state, style and style-configuration replacement, event
	connection tracking, instance cleanup, serialization and destruction.

	Style changes never recreate the window and never touch the component's value,
	callback, flag, dependencies or connections: only the view is rebuilt.
]]

local Util = __NEVA_Core_Util
local Signal = __NEVA_Core_Signal
local Dependency = __NEVA_Core_Dependency
local Schema = __NEVA_Styles_Schema
local Registry = __NEVA_Styles_Registry
local Resolver = __NEVA_Styles_Resolver

local Component = {}
Component.__index = Component

-- Called by Component.define to create a component class.
function Component.define(definition)
	assert(type(definition) == "table", "Component.define expects a table")
	assert(type(definition.Type) == "string" and definition.Type ~= "", "Component.define needs a Type string")
	local class = setmetatable({}, { __index = Component })
	class.__index = class
	class.Type = definition.Type
	class.Definition = definition
	return class
end

function Component.create(class, context, container, spec, options)
	assert(context, "Component.create needs a context")
	spec = spec or {}
	options = options or {}
	local self = setmetatable({}, class)

	self.Id = Util.uniqueId(class.Type)
	self.Type = class.Type
	self.Definition = class.Definition
	self.Context = context
	self.Container = container
	self.Scope = container and container.Window or nil
	self.Flag = spec.Flag or spec.Name or self.Id
	self.Name = spec.Name or self.Flag
	self.Description = spec.Description or ""
	self.Callback = spec.Callback
	self.Internal = options.Internal == true
	self.FireOnLoad = spec.FireOnLoad == true
	self.Enabled = spec.Enabled ~= false
	self.Visible = spec.Visible ~= false
	self.Destroyed = false
	self.DestroyedAt = nil
	self.PlainInstances = {}
	self.Instances = {}
	self.Connections = {}
	self.Dependencies = {}
	self.Metadata = spec.Metadata and Util.deepCopy(spec.Metadata) or {}
	self.Spec = Util.deepCopy(spec)
	self.Spec.Callback = nil
	self.Spec.Style = nil

	local definition = class.Definition
	self.Default = spec.Default
	if self.Default == nil and definition.Default ~= nil then
		self.Default = definition.Default
	end
	self.Value = self:_coerce(self.Default)

	local styleSpec = spec.Style
	if type(styleSpec) == "string" then
		self.StyleId = styleSpec
		self.StyleConfiguration = {}
	elseif type(styleSpec) == "table" then
		self.StyleId = styleSpec.Id
		self.StyleConfiguration = Util.deepCopy(styleSpec.Configuration or {})
	else
		self.StyleId = nil
		self.StyleConfiguration = {}
	end
	self.RequestedStyle = self.StyleId
	self.RuntimeOverrides = {}
	self.Resolution = nil
	self.Configuration = {}
	self.Schema = {}
	self.Style = nil

	self.Changed = Signal.new(class.Type)
	self.DestroyedSignal = Signal.new(class.Type .. "Destroyed")
	self.LastError = nil
	self.LastValueError = nil
	self.DependenciesMet = true

	self:_build(define and nil)
	self:_wireHover()

	if definition.Wire then
		definition.Wire(self, self.View, self:_renderContext())
	end
	if definition.AfterBuild then
		definition.AfterBuild(self, self.View)
	end
	if spec.DependsOn or spec.Dependencies then
		local list = spec.DependsOn or spec.Dependencies
		if type(list) == "table" and list[1] ~= nil then
			for _, entry in ipairs(list) do
				self:AddDependency(entry)
			end
		else
			self:AddDependency(list)
		end
	end

	return self
end

-- Value coercion hook. Component modules override Definition.Coerce.
function Component:_coerce(value)
	local coerce = self.Definition.Coerce
	if Util.isCallable(coerce) then
		return coerce(value, self)
	end
	return value
end

function Component:GetDefault()
	return Util.deepCopy(self.Default)
end

function Component:GetValue()
	return self.Value
end

function Component:IsValueEqual(a, b)
	return Util.deepEquals(a, b)
end

-- options.Silent      -> do not fire the callback or the Changed signal
-- options.FromConfig  -> configuration load; callbacks only fire when FireOnLoad
-- options.FromInput   -> user interaction
function Component:SetValue(value, options)
	options = options or {}
	if self.Destroyed then
		return false, "component has been destroyed"
	end
	local coerced, err = self:_coerce(value)
	if err ~= nil then
		self.LastValueError = err
		if self.Context then
			self.Context:Diagnostic("Warn", ("%s (%s) rejected value: %s"):format(self.Name, self.Type, tostring(err)))
		end
		return false, err
	end
	local previous = self.Value
	local changed = not self:IsValueEqual(previous, coerced)
	self.Value = coerced
	self:_applyState()

	if changed and not options.Silent then
		self.Changed:Fire(coerced, self, previous)
		if self.Context and self.Context.DependencyHub then
			self.Context.DependencyHub:publish(self.Flag)
		end
	end

	local fire = false
	if options.Silent then
		fire = false
	elseif options.FromConfig then
		fire = self.FireOnLoad == true
	else
		fire = true
	end
	if fire and Util.isCallable(self.Callback) then
		self:_invoke(self.Callback, coerced, options)
	end
	return true, nil, changed
end

function Component:_invoke(callback, value, options)
	local ok, err = pcall(callback, value, self)
	if not ok then
		self.LastError = err
		if self.Context then
			self.Context:Diagnostic("Error", ("callback for %s (%s) failed: %s"):format(self.Name, self.Type, tostring(err)))
		end
		return false
	end
	return true
end

function Component:OnChanged(callback)
	return self.Changed:Connect(callback)
end

function Component:Reset(options)
	return self:SetValue(self.Default, options)
end

-- Connections and instances created by a component are tracked so that
-- Destroy can release every one of them.
function Component:Connect(instance, event, callback)
	local connection = self.Context.Host.connect(instance, event, callback)
	table.insert(self.Connections, connection)
	return connection
end

function Component:Track(instance)
	table.insert(self.Instances, instance)
	return instance
end

function Component:Create(className, props, parent)
	local instance = self.Context.Host.new(className, props, parent)
	return self:Track(instance)
end

function Component:_renderContext()
	return {
		Host = self.Context.Host,
		Tokens = self.Context.Tokens,
		Theme = self.Context.ThemeId,
		Configuration = self.Configuration,
		Defaults = Schema.defaults(self.Schema),
		Schema = self.Schema,
		Component = self,
		Type = self.Type,
		Props = {
			Name = self.Name,
			Description = self.Description,
			Flag = self.Flag,
			Enabled = self.Enabled,
			Visible = self.Visible,
			Icon = self.Spec.Icon,
		},
		State = self:_state(),
		Context = self.Context,
	}
end

function Component:_state()
	local state = {
		Value = self.Value,
		Enabled = self.Enabled,
		Visible = self:IsActuallyVisible(),
		Hovered = self.Hovered == true,
		Dragging = self.Dragging == true,
		Focused = self.Focused == true,
		Component = self,
	}
	local extra = self.Definition.State
	if Util.isCallable(extra) then
		local additional = extra(self)
		if type(additional) == "table" then
			for key, value in pairs(additional) do
				state[key] = value
			end
		end
	end
	return state
end

-- Generic hover tracking: every style gets hover state without implementing it.
function Component:_wireHover()
	local view = self.View
	if not view then
		return
	end
	local surface = view.Input or view.HoverTarget or view.Root
	if not surface then
		return
	end
	self:Connect(surface, "MouseEnter", function()
		self.Hovered = true
		self:_applyState()
	end)
	self:Connect(surface, "MouseLeave", function()
		self.Hovered = false
		self:_applyState()
	end)
end

function Component:_applyState()
	if not self.View then
		return
	end
	local state = self:_state()
	local apply = self.View.Apply
	if Util.isCallable(apply) then
		local ok, err = pcall(apply, self.View, state, self:_renderContext())
		if not ok then
			self.LastError = err
			self.Context:Diagnostic("Error", ("style %s Apply failed for %s: %s"):format(
				tostring(self.Style and self.Style.Id), self.Type, tostring(err)))
		end
	end
	if self.View.Root then
		self.View.Root.Visible = state.Visible
	end
end

function Component:_clearView()
	for _, connection in ipairs(self.Connections) do
		if connection and connection.Disconnect then
			pcall(function()
				connection:Disconnect()
			end)
		end
	end
	self.Connections = {}
	for _, instance in ipairs(self.Instances) do
		self.Context.Host.destroy(instance)
	end
	self.Instances = {}
	self.View = nil
end

function Component:_resolveStyle()
	local request = {
		Component = self.Type,
		StyleId = self.StyleId or self.Context:StyleDefaultFor(self.Type),
		CategoryConfiguration = self.Context:CategoryConfigurationFor(self.Type),
		ComponentConfiguration = self.StyleConfiguration,
		RuntimeOverrides = self.RuntimeOverrides,
	}
	local result = Resolver.resolve(request)
	self.Resolution = result
	self.EffectiveConfigurationSource = result.Effective
	if result.StyleId and result.StyleId ~= self.StyleId then
		self.StyleId = result.StyleId
	end
	for _, message in ipairs(result.Warnings) do
		self.Context:Diagnostic("Warn", ("%s (%s): %s"):format(self.Name, self.Type, message))
	end
	for _, message in ipairs(result.Errors) do
		self.Context:Diagnostic("Error", ("%s (%s): %s"):format(self.Name, self.Type, message))
	end
	self.Style = result.Style
	self.Configuration = result.Configuration
	self.Schema = result.Schema
	return result
end

function Component:_build()
	if self.Destroyed then
		return
	end
	local result = self:_resolveStyle()
	if not result.Ok or not result.Style then
		self.Context:Diagnostic("Error", ("%s (%s): no usable style; component not rendered"):format(self.Name, self.Type))
		return
	end
	local render = self.Style.Render
	local ok, view = pcall(render, self:_renderContext())
	if not ok then
		self.LastError = view
		self.Context:Diagnostic("Error", ("style %s failed to render %s: %s"):format(self.Style.Id, self.Type, tostring(view)))
		return
	end
	if type(view) ~= "table" or view.Root == nil then
		self.Context:Diagnostic("Error", ("style %s did not return a view with a Root for %s"):format(self.Style.Id, self.Type))
		return
	end
	self.View = view
	if view.Instances then
		for _, instance in ipairs(view.Instances) do
			table.insert(self.Instances, instance)
		end
	end
	table.insert(self.Instances, view.Root)
	local parent = self.Container and self.Container.Instance or nil
	if parent then
		view.Root.Parent = parent
	end
	self.StyleId = self.Style.Id
	self:_applyState()
end

-- Full rebuild: only used when the resolved style actually changes.
function Component:Refresh(reason)
	if self.Destroyed then
		return false, "component has been destroyed"
	end
	local previousValue = self.Value
	self:_clearView()
	self:_build()
	self.Value = previousValue
	self:_applyState()
	return true, nil
end

function Component:GetStyle()
	return self.StyleId
end

function Component:SetStyle(styleId, configuration)
	if self.Destroyed then
		return false, "component has been destroyed"
	end
	if type(styleId) == "table" then
		configuration = styleId.Configuration
		styleId = styleId.Id
	end
	assert(type(styleId) == "string" and styleId ~= "", "SetStyle expects a style id string")
	local style = Registry.get(styleId)
	if not style then
		return false, ("unknown style %q"):format(styleId)
	end
	if style.Component ~= self.Type then
		return false, ("style %q renders %s, not %s"):format(styleId, style.Component, self.Type)
	end
	local changed = self.StyleId ~= styleId
	self.StyleId = styleId
	self.RequestedStyle = styleId
	if type(configuration) == "table" then
		self.StyleConfiguration = Util.deepCopy(configuration)
		changed = true
	end
	if changed then
		return self:Refresh("SetStyle")
	end
	return true, nil
end

function Component:GetStyleInfo()
	return Registry.get(self.StyleId)
end

function Component:SetStyleConfiguration(configuration, options)
	if self.Destroyed then
		return false, "component has been destroyed"
	end
	assert(type(configuration) == "table", "SetStyleConfiguration expects a table")
	options = options or {}
	if options.Replace then
		self.StyleConfiguration = Util.deepCopy(configuration)
	else
		self.StyleConfiguration = Util.deepMerge(self.StyleConfiguration, configuration)
	end
	self.RuntimeOverrides = Util.deepCopy(configuration)
	if options.Replace then
		self.RuntimeOverrides = Util.deepCopy(configuration)
	end
	return self:Refresh("SetStyleConfiguration")
end

function Component:SetStyleProperty(key, value)
	if self.Destroyed then
		return false, "component has been destroyed"
	end
	assert(type(key) == "string", "SetStyleProperty expects a property name")
	return self:SetStyleConfiguration({ [key] = value })
end

function Component:GetStyleConfiguration()
	return Util.deepCopy(self.StyleConfiguration)
end

function Component:ResetStyleConfiguration()
	self.StyleConfiguration = {}
	self.RuntimeOverrides = {}
	return self:Refresh("ResetStyleConfiguration")
end

function Component:GetEffectiveConfiguration()
	return Util.deepCopy(self.Configuration)
end

function Component:GetSchema()
	return Schema.describe(self.Schema)
end

function Component:ExplainConfiguration()
	if not self.Resolution then
		return "no resolution recorded"
	end
	return Resolver.explain(self.Resolution)
end

function Component:SetEnabled(enabled)
	self.Enabled = enabled ~= false
	self:_applyState()
	return self.Enabled
end

function Component:IsEnabled()
	return self.Enabled ~= false
end

function Component:SetVisible(visible)
	self.Visible = visible ~= false
	self:_applyState()
	return self.Visible
end

function Component:IsVisible()
	return self.Visible ~= false
end

function Component:IsActuallyVisible()
	return self:IsVisible() and self.DependenciesMet ~= false
end

function Component:SetName(name)
	self.Name = tostring(name)
	if self.View and self.View.SetName then
		self.View.SetName(self.View, self.Name)
	end
	return self.Name
end

function Component:GetName()
	return self.Name
end

function Component:SetDescription(description)
	self.Description = tostring(description)
	return self.Description
end

function Component:SetCallback(callback)
	self.Callback = callback
	return true
end

function Component:AddDependency(spec, mode)
	assert(spec ~= nil, "AddDependency expects a dependency specification")
	local entry = {
		Spec = spec,
		Mode = mode or "Visible",
		Callback = nil,
	}
	if type(spec) == "table" and spec.Callback then
		entry.Callback = spec.Callback
		entry.Mode = spec.Mode or entry.Mode
		spec = Util.shallowCopy(spec)
		spec.Callback = nil
		spec.Mode = nil
		entry.Spec = spec
	end
	table.insert(self.Dependencies, entry)
	local flags = Dependency.flagsIn(entry.Spec, {})
	if self.Context and self.Context.DependencyHub then
		self._dependencyConnection = self.Context.DependencyHub:subscribe(flags, function(flag)
			if flag ~= self.Flag then
				self:EvaluateDependencies()
			end
		end)
		self:TrackConnection(self._dependencyConnection)
	end
	self:EvaluateDependencies()
	return entry
end

function Component:TrackConnection(connection)
	if connection then
		table.insert(self.Connections, connection)
	end
	return connection
end

function Component:EvaluateDependencies()
	if self.Destroyed then
		return true
	end
	local hub = self.Context and self.Context.DependencyHub
	local function getValue(flag)
		if hub then
			return hub:getValue(flag)
		end
		return nil
	end
	local met = true
	for _, entry in ipairs(self.Dependencies) do
		local satisfied = Dependency.matches(entry.Spec, getValue)
		entry.Satisfied = satisfied
		if not satisfied then
			met = false
		end
		if entry.Callback and entry.Triggered ~= satisfied then
			entry.Triggered = satisfied
			entry.Callback(satisfied, self)
		end
		if not satisfied and entry.Mode == "Enabled" then
			self.Enabled = false
		end
	end
	if self.DependenciesMet ~= met then
		self.DependenciesMet = met
	end
	local hideWhenUnmet = false
	for _, entry in ipairs(self.Dependencies) do
		if entry.Mode == "Visible" and not entry.Satisfied then
			hideWhenUnmet = true
			break
		end
	end
	self.DependenciesMet = not hideWhenUnmet
	self:_applyState()
	return met
end

function Component:GetDependencyState()
	local out = {}
	for _, entry in ipairs(self.Dependencies) do
		table.insert(out, {
			Description = Dependency.describe(entry.Spec),
			Mode = entry.Mode,
			Satisfied = entry.Satisfied == true,
		})
	end
	return out
end

function Component:SetOrder(order)
	self.Order = order
	if self.View and self.View.Root then
		self.View.Root.LayoutOrder = order
	end
	return order
end

function Component:GetOrder()
	return self.Order
end

function Component:Serialize()
	local value = self.Value
	if type(value) == "table" and getmetatable(value) ~= nil then
		local mode = getmetatable(value)
		local ok, text = pcall(function()
			return value:ToHex()
		end)
		if ok and text then
			value = text
		end
	end
	local style = self.StyleId
	local configuration = Util.deepCopy(self.StyleConfiguration)
	local hasStyleConfiguration = next(configuration) ~= nil
	return {
		Type = self.Type,
		Flag = self.Flag,
		Value = Util.deepCopy(value),
		Style = style,
		StyleConfiguration = hasStyleConfiguration and configuration or nil,
		Enabled = self.Enabled,
		Visible = self.Visible,
	}
end

function Component:Restore(data, options)
	options = options or {}
	if type(data) ~= "table" then
		return false, "Restore expects a serialized table"
	end
	if data.Style and Registry.get(data.Style) and data.Style ~= self.StyleId then
		self:SetStyle(data.Style, data.StyleConfiguration)
	elseif type(data.StyleConfiguration) == "table" then
		self:SetStyleConfiguration(data.StyleConfiguration, { Replace = true })
	end
	if data.Enabled ~= nil then
		self:SetEnabled(data.Enabled)
	end
	if data.Visible ~= nil then
		self:SetVisible(data.Visible)
	end
	if data.Value ~= nil then
		local value = data.Value
		local coerced, err = self:_coerce(value)
		if self.LastValueError ~= nil and coerced == self.Value and err ~= nil then
			return false, err
		end
		self:SetValue(value, {
			FromConfig = true,
			Silent = options.FireCallbacks == false,
		})
	end
	return true, nil
end

function Component:GetState()
	return {
		Id = self.Id,
		Type = self.Type,
		Flag = self.Flag,
		Name = self.Name,
		Value = self.Value,
		Default = self.Default,
		Style = self.StyleId,
		StyleConfiguration = Util.deepCopy(self.StyleConfiguration),
		EffectiveConfiguration = Util.deepCopy(self.Configuration),
		Enabled = self.Enabled,
		Visible = self.Visible,
		DependenciesMet = self.DependenciesMet,
		Dependencies = self:GetDependencyState(),
		Schema = self:GetSchema(),
		Diagnostics = {
			LastError = self.LastError,
			LastValueError = self.LastValueError,
			Warnings = self.Resolution and self.Resolution.Warnings or {},
			Errors = self.Resolution and self.Resolution.Errors or {},
		},
	}
end

function Component:Destroy()
	if self.Destroyed then
		return false
	end
	self.Destroyed = true
	self.DestroyedAt = os and os.clock and os.clock() or nil
	if self.Definition.BeforeDestroy then
		pcall(self.Definition.BeforeDestroy, self)
	end
	self.DestroyedSignal:Fire(self)
	self:_clearView()
	self.Changed:Destroy()
	self.DestroyedSignal:Destroy()
	if self.Context and self.Context.Store then
		self.Context.Store.unregister(self)
	end
	return true
end

function Component:OnDestroyed(callback)
	return self.DestroyedSignal:Connect(callback)
end

function Component:GetConnectionCount()
	return #self.Connections
end

function Component:GetInstanceCount()
	return #self.Instances
end

return Component
end)()

local __NEVA_Components_Controls = (function()
--[[
	NEVAHEXUI - Components/Controls
	Interactive component classes: Button, IconButton, Toggle, Checkbox, Radio,
	RadioGroup, Slider, RangeSlider, Textbox, NumberInput, CopyableInput,
	Keybind, ColorPicker and ColorPalette.

	Every class declares behaviour only. Visuals come from the style renderers, so
	each class works with every renderer registered for its type. Wiring uses the
	host contract: instance events through Component:Connect, pointer position
	through host.pointerPosition/host.bounds/host.trackPointer, and keyboard
	capture through host.captureKeys.
]]

local Component = __NEVA_Core_Component
local Util = __NEVA_Core_Util
local Color = __NEVA_Utilities_Color

local Controls = {}

local function inputSurface(view)
	return view.Input or view.HoverTarget or view.Root
end

local function clamp(value, min, max)
	if value < min then
		return min
	end
	if value > max then
		return max
	end
	return value
end

local function number(value, fallback)
	local parsed = tonumber(value)
	if parsed == nil then
		return fallback
	end
	return parsed
end

-- Button ---------------------------------------------------------------------

local function clickOnly(definition)
	definition.Default = definition.Default
	definition.Wire = function(self, view)
		local surface = inputSurface(view)
		if not surface then
			return
		end
		self:Connect(surface, "MouseButton1Click", function()
			self:Fire()
		end)
	end
	function definition.FireMethod(self)
		self.Clicks = (self.Clicks or 0) + 1
		return self:_invoke(self.Callback, self.Clicks, { Source = "Click" })
	end
	return definition
end

Controls.Button = Component.define(clickOnly({
	Type = "Button",
	Default = nil,
	Description = "Pressable action button; the callback receives the click count.",
}))

function Controls.Button:Fire()
	self.Clicks = (self.Clicks or 0) + 1
	return self:_invoke(self.Callback, self.Clicks, { Source = "Click" })
end

function Controls.Button:GetClicks()
	return self.Clicks or 0
end

Controls.IconButton = Component.define({
	Type = "IconButton",
	Default = nil,
	Description = "Square icon-only action button.",
})

function Controls.IconButton:Fire()
	self.Clicks = (self.Clicks or 0) + 1
	return self:_invoke(self.Callback, self.Clicks, { Source = "Click" })
end

function Controls.IconButton:SetIcon(imageId)
	self.Spec.Icon = imageId
	return self:Refresh("icon")
end

function Controls.IconButton:GetClicks()
	return self.Clicks or 0
end

-- Boolean controls -----------------------------------------------------------

local function wireToggleish(self, view)
	local surface = inputSurface(view)
	if not surface then
		return
	end
	self:Connect(surface, "MouseButton1Click", function()
		if not self.Enabled then
			return
		end
		self:SetValue(not self.Value, { Source = "User" })
	end)
end

Controls.Toggle = Component.define({
	Type = "Toggle",
	Default = false,
	Description = "On/off switch.",
	Coerce = function(value)
		return value == true
	end,
	Wire = wireToggleish,
})

Controls.Checkbox = Component.define({
	Type = "Checkbox",
	Default = false,
	Description = "Checkbox with tick mark.",
	Coerce = function(value)
		return value == true
	end,
	Wire = wireToggleish,
})

-- Radio and radio groups -----------------------------------------------------

local function radioGroupMembers(self)
	local members = {}
	for _, component in ipairs(self.Context:ComponentsOfType("Radio")) do
		if component ~= self and component.Group == self.Group and not component.Destroyed then
			table.insert(members, component)
		end
	end
	return members
end

Controls.Radio = Component.define({
	Type = "Radio",
	Default = false,
	Description = "Single-choice option; group members are mutually exclusive.",
	Coerce = function(value)
		return value == true
	end,
	State = function(self)
		return { Group = self.Group, Option = self.Option or self.Spec.Option }
	end,
	Wire = function(self, view)
		self.Group = self.Spec.Group or self.Container and self.Container.Id or "default"
		self.Option = self.Spec.Option or self.Spec.Name
		local surface = inputSurface(view)
		if not surface then
			return
		end
		self:Connect(surface, "MouseButton1Click", function()
			if not self.Enabled or self.Selecting then
				return
			end
			self:Select()
		end)
	end,
})

function Controls.Radio:Select()
	if self.Value then
		return self
	end
	self.Selecting = true
	self:SetValue(true, { Source = "User" })
	for _, member in ipairs(radioGroupMembers(self)) do
		member:SetValue(false, { Silent = true })
	end
	self.Selecting = false
	if self.Callback then
		self:_invoke(self.Callback, self.Option, { Source = "Group" })
	end
	return self
end

function Controls.Radio:GetOption()
	return self.Option
end

Controls.RadioGroup = Component.define({
	Type = "RadioGroup",
	Default = nil,
	Description = "List of mutually exclusive options with a shared selected value.",
	Coerce = function(value)
		if value == nil then
			return nil
		end
		return value
	end,
	State = function(self)
		return { Options = self.Spec.Options or {}, Value = self.Value }
	end,
	Wire = function(self, view)
		local entries = view.Options or view.Rows or view.Buttons or {}
		for _, entry in ipairs(entries) do
			local instance = entry.Instance or entry.Button or entry
			local optionValue = entry.Value
			if instance and optionValue ~= nil then
				self:Connect(instance, "MouseButton1Click", function()
					self:SetValue(optionValue, { Source = "User" })
				end)
			end
		end
	end,
})

function Controls.RadioGroup:SetOptions(options)
	self.Spec.Options = options
	return self:Refresh("options")
end

-- Sliders --------------------------------------------------------------------

local function sliderRange(self)
	local spec = self.Spec
	return number(spec.Min, 0), number(spec.Max, 100), number(spec.Step, 0)
end

local function quantize(value, step)
	if step == nil or step <= 0 then
		return value
	end
	local steps = math.floor(value / step + 0.5)
	return steps * step
end

Controls.Slider = Component.define({
	Type = "Slider",
	Default = nil,
	Description = "Continuous numeric input with optional step, suffix and named stops.",
	Coerce = function(value, self)
		local min, max, step = sliderRange(self)
		local parsed = number(value, min)
		if self.Spec.Step ~= nil and step > 0 then
			parsed = quantize(parsed, step)
		end
		return Util.round(clamp(parsed, min, max), 6)
	end,
	State = function(self)
		local min, max = sliderRange(self)
		return {
			Min = min,
			Max = max,
			Step = self.Spec.Step,
			Suffix = self.Spec.Suffix,
			Stops = self.Spec.Stops,
			Ratio = max > min and ((self.Value - min) / (max - min)) or 0,
			Format = self.Spec.Format,
		}
	end,
	Wire = function(self, view)
		local surface = inputSurface(view)
		if not surface then
			return
		end
		local function apply(position)
			local bounds = self.Context.Host.bounds(surface)
			if not bounds or bounds.Width <= 0 then
				return
			end
			local point = position or self.Context.Host.pointerPosition() or { X = bounds.X, Y = bounds.Y }
			local x = number(point.X, bounds.X)
			local ratio = clamp((x - bounds.X) / bounds.Width, 0, 1)
			local min, max, step = sliderRange(self)
			local value = min + ratio * (max - min)
			if self.Spec.Step ~= nil then
				value = quantize(value, step)
			end
			self:SetValue(Util.round(clamp(value, min, max), 6), { Source = "User" })
		end
		self:Connect(surface, "MouseButton1Down", function()
			self.Dragging = true
			apply()
			self:_applyState()
		end)
		self:Connect(surface, "MouseButton1Up", function()
			self.Dragging = false
			self:_applyState()
		end)
		if self.Context.Host.trackPointer then
			self:TrackConnection(self.Context.Host.trackPointer(function(position)
				if self.Dragging then
					apply(position)
				end
			end))
		end
	end,
})

function Controls.Slider:GetRatio()
	local min, max = sliderRange(self)
	if max <= min then
		return 0
	end
	return (self.Value - min) / (max - min)
end

function Controls.Slider:SetRatio(ratio, silent)
	local min, max = sliderRange(self)
	return self:SetValue(min + clamp(ratio, 0, 1) * (max - min), { Silent = silent })
end

function Controls.Slider:Step(direction)
	local min, max, step = sliderRange(self)
	local increment = step > 0 and step or (max - min) / 100
	return self:SetValue(self.Value + increment * (direction or 1), { Source = "Programmatic" })
end

Controls.RangeSlider = Component.define({
	Type = "RangeSlider",
	Default = { Lower = 25, Upper = 75 },
	Description = "Dual-handle range input. Value is { Lower = n, Upper = m }.",
	Coerce = function(value, self)
		local min, max, step = sliderRange(self)
		local lower, upper
		if type(value) == "table" then
			lower = number(value.Lower or value[1], min)
			upper = number(value.Upper or value[2], max)
		else
			lower, upper = min, max
		end
		if self.Spec.Step ~= nil and step > 0 then
			lower = quantize(lower, step)
			upper = quantize(upper, step)
		end
		lower = clamp(lower, min, max)
		upper = clamp(upper, min, max)
		if lower > upper then
			lower, upper = upper, lower
		end
		return { Lower = Util.round(lower, 6), Upper = Util.round(upper, 6) }
	end,
	State = function(self)
		local min, max = sliderRange(self)
		local span = max > min and (max - min) or 1
		return {
			Min = min,
			Max = max,
			Step = self.Spec.Step,
			Suffix = self.Spec.Suffix,
			LowerRatio = (self.Value.Lower - min) / span,
			UpperRatio = (self.Value.Upper - min) / span,
		}
	end,
	Wire = function(self, view)
		local surface = inputSurface(view)
		if not surface then
			return
		end
		local function apply(position, handle)
			local bounds = self.Context.Host.bounds(surface)
			if not bounds or bounds.Width <= 0 then
				return
			end
			local point = position or self.Context.Host.pointerPosition() or { X = bounds.X, Y = bounds.Y }
			local ratio = clamp((number(point.X, bounds.X) - bounds.X) / bounds.Width, 0, 1)
			local min, max, step = sliderRange(self)
			local raw = min + ratio * (max - min)
			if self.Spec.Step ~= nil then
				raw = quantize(raw, step)
			end
			raw = clamp(raw, min, max)
			local lower, upper = self.Value.Lower, self.Value.Upper
			local target = handle
			if target == nil then
				target = math.abs(raw - lower) <= math.abs(raw - upper) and "Lower" or "Upper"
			end
			if target == "Lower" then
				lower = math.min(raw, upper)
			else
				upper = math.max(raw, lower)
			end
			self:SetValue({ Lower = Util.round(lower, 6), Upper = Util.round(upper, 6) }, { Source = "User" })
		end
		self:Connect(surface, "MouseButton1Down", function()
			self.Dragging = true
			self.DraggingHandle = nil
			apply()
			self:_applyState()
		end)
		self:Connect(surface, "MouseButton1Up", function()
			self.Dragging = false
			self:_applyState()
		end)
		if self.Context.Host.trackPointer then
			self:TrackConnection(self.Context.Host.trackPointer(function(position)
				if self.Dragging then
					apply(position, self.DraggingHandle)
				end
			end))
		end
	end,
})

function Controls.RangeSlider:SetRange(lower, upper, silent)
	return self:SetValue({ Lower = lower, Upper = upper }, { Silent = silent })
end

-- Text inputs ----------------------------------------------------------------

Controls.Textbox = Component.define({
	Type = "Textbox",
	Default = "",
	Description = "Single or multi-line text entry.",
	Coerce = function(value)
		if value == nil then
			return ""
		end
		return tostring(value)
	end,
	State = function(self)
		return { Placeholder = self.Spec.Placeholder or "", Multiline = self.Spec.Multiline == true }
	end,
	Wire = function(self, view)
		local box = view.Box or view.TextBox or view.Input
		if not box then
			return
		end
		local function commit()
			local text = box.Text
			if text == nil then
				return
			end
			self:SetValue(text, { Source = "User" })
		end
		self:Connect(box, "FocusLost", function(enterPressed)
			commit()
			if enterPressed and self.Spec.ClearOnFocus == true then
				box.Text = self.Value
			end
		end)
		self:Connect(box, "ReturnPressedFromOnScreenKeyboard", commit)
	end,
})

function Controls.Textbox:GetText()
	return self.Value
end

function Controls.Textbox:SetText(text, silent)
	return self:SetValue(text, { Silent = silent })
end

Controls.NumberInput = Component.define({
	Type = "NumberInput",
	Default = 0,
	Description = "Numeric field with optional stepper buttons.",
	Coerce = function(value, self)
		local parsed = number(value, 0)
		if self.Spec.Min then
			parsed = math.max(self.Spec.Min, parsed)
		end
		if self.Spec.Max then
			parsed = math.min(self.Spec.Max, parsed)
		end
		if self.Spec.Precision then
			parsed = Util.round(parsed, self.Spec.Precision)
		end
		return parsed
	end,
	State = function(self)
		return { Min = self.Spec.Min, Max = self.Spec.Max, Step = self.Spec.Step or 1, Suffix = self.Spec.Suffix }
	end,
	Wire = function(self, view)
		local box = view.Box or view.Input
		if box and box.Text ~= nil then
			self:Connect(box, "FocusLost", function()
				self:SetValue(box.Text, { Source = "User" })
			end)
		end
		for _, entry in ipairs({ { view.StepUp, 1 }, { view.StepDown, -1 } }) do
			local button, direction = entry[1], entry[2]
			if button then
				self:Connect(button, "MouseButton1Click", function()
					self:Increment(direction)
				end)
			end
		end
	end,
})

function Controls.NumberInput:Increment(direction)
	local step = self.Spec.Step or 1
	return self:SetValue(self.Value + step * (direction or 1), { Source = "Programmatic" })
end

Controls.CopyableInput = Component.define({
	Type = "CopyableInput",
	Default = "",
	Description = "Read-only value with a copy-to-clipboard action.",
	Coerce = function(value)
		if value == nil then
			return ""
		end
		return tostring(value)
	end,
	State = function(self)
		return { CopyLabel = self.Spec.CopyLabel or "Copy" }
	end,
	Wire = function(self, view)
		local button = view.Copy
		if not button then
			return
		end
		self:Connect(button, "MouseButton1Click", function()
			self:Copy()
		end)
	end,
})

function Controls.CopyableInput:Copy()
	local host = self.Context.Host
	local ok = false
	if host.clipboardSet then
		ok = host.clipboardSet(self.Value) and true or false
	end
	self.LastCopySucceeded = ok
	return ok
end

Controls.Keybind = Component.define({
	Type = "Keybind",
	Default = "None",
	Description = "Key assignment with optional mode toggle and conflict reporting.",
	Coerce = function(value)
		if value == nil then
			return "None"
		end
		if type(value) == "table" then
			if value.Key then
				return tostring(value.Key)
			end
			return "None"
		end
		return tostring(value)
	end,
	State = function(self)
		return {
			Mode = self.Mode or self.Spec.Mode or "Toggle",
			Conflict = self.Conflict == true,
			Keys = self.Spec.Keys or {},
		}
	end,
	Wire = function(self, view)
		self.Mode = self.Spec.Mode or "Toggle"
		self.Conflict = self.Spec.Conflict == true
		local surface = inputSurface(view)
		if surface then
			self:Connect(surface, "MouseButton1Click", function()
				self:Capture()
			end)
		end
		local mode = view.ModeButton or view.Mode
		if mode then
			self:Connect(mode, "MouseButton1Click", function()
				self:SetMode(self.Mode == "Toggle" and "Hold" or "Toggle")
			end)
		end
	end,
})

function Controls.Keybind:Capture()
	local host = self.Context.Host
	if not host.captureKeys then
		self.Context:Diagnostic("Warn", "key capture is not supported by this host")
		return false
	end
	self.Listening = true
	self:_applyState()
	local capture
	capture = host.captureKeys(function(key)
		self.Listening = false
		self:SetValue(key, { Source = "User" })
		if capture and capture.Disconnect then
			capture:Disconnect()
		end
	end)
	if capture then
		self:TrackConnection(capture)
	end
	return true
end

function Controls.Keybind:SetMode(mode)
	self.Mode = mode
	return self:Refresh("mode")
end

function Controls.Keybind:SetConflict(conflict)
	self.Conflict = conflict == true
	return self:Refresh("conflict")
end

function Controls.Keybind:IsConflict()
	return self.Conflict == true
end

-- Colour controls ------------------------------------------------------------

Controls.ColorPicker = Component.define({
	Type = "ColorPicker",
	Default = nil,
	Description = "Colour selection with a swatch grid, hex readout and alpha.",
	Coerce = function(value, self)
		local fallback = self.Default
		if value == nil then
			return fallback
		end
		local ok, colour = pcall(Color.normalize, value)
		if not ok or colour == nil then
			return fallback
		end
		return colour
	end,
	State = function(self)
		return { Palette = self.Spec.Palette or {}, Value = self.Value }
	end,
	Wire = function(self, view)
		if self.Value == nil then
			self.Value = self:_coerce(self.Default or { 1, 0, 0 })
		end
		local surface = inputSurface(view)
		if surface then
			self:Connect(surface, "MouseButton1Click", function()
				view.Open = not view.Open
				self:_applyState()
			end)
		end
		for _, cell in ipairs(view.Cells or {}) do
			self:Connect(cell.Instance, "MouseButton1Click", function()
				view.Open = false
				self:SetValue(cell.Colour, { Source = "User" })
			end)
		end
	end,
})

function Controls.ColorPicker:SetColour(colour, silent)
	return self:SetValue(colour, { Silent = silent })
end

function Controls.ColorPicker:GetColour()
	return self.Value
end

function Controls.ColorPicker:ToHex()
	local ok, value = pcall(Color.normalize, self.Value)
	if not ok or value == nil then
		return nil
	end
	return value:ToHex()
end

Controls.ColorPalette = Component.define({
	Type = "ColorPalette",
	Default = nil,
	Description = "Row of colour chips for quick accent selection.",
	Coerce = function(value, self)
		if value == nil then
			return self.Spec.Palette and self.Spec.Palette[1] or nil
		end
		local ok, colour = pcall(Color.normalize, value)
		if not ok or colour == nil then
			return nil
		end
		return colour
	end,
	State = function(self)
		return { Palette = self.Spec.Palette or {}, Value = self.Value }
	end,
	Wire = function(self, view)
		for _, chip in ipairs(view.Chips or {}) do
			self:Connect(chip.Instance, "MouseButton1Click", function()
				self:SetValue(chip.Colour, { Source = "User" })
			end)
		end
	end,
})

function Controls.ColorPalette:SetOptions(colours)
	self.Spec.Palette = colours
	return self:Refresh("palette")
end

return Controls
end)()

local __NEVA_Components_Displays = (function()
--[[
	NEVAHEXUI - Components/Displays
	Component classes for the non-interactive surface: Label, Divider, Badge,
	ProgressBar, Loader, Image, Table, TreeView, LogView and Graph.

	A class only declares behaviour (defaults, coercion, extra state, methods).
	All visuals come from the style renderers in Styles/Defs, so the same class
	renders through every registered style for its type.
]]

local Component = __NEVA_Core_Component
local Util = __NEVA_Core_Util

local Displays = {}

local function text(value)
	if value == nil then
		return ""
	end
	return tostring(value)
end

Displays.Label = Component.define({
	Type = "Label",
	Default = "",
	Description = "Static or programmatic text.",
	Coerce = text,
})

Displays.Divider = Component.define({
	Type = "Divider",
	Default = "",
	Description = "Visual separator between sections.",
	Coerce = text,
})

Displays.Badge = Component.define({
	Type = "Badge",
	Default = "New",
	Description = "Short status label.",
	Coerce = text,
})

Displays.ProgressBar = Component.define({
	Type = "ProgressBar",
	Default = 0,
	Description = "Determinate progress from 0 to 1.",
	Coerce = function(value)
		local number = tonumber(value) or 0
		return math.max(0, math.min(1, number))
	end,
})

function Displays.ProgressBar:SetProgress(value, silent)
	local number = math.max(0, math.min(1, tonumber(value) or 0))
	return self:SetValue(number, { Silent = silent })
end

function Displays.ProgressBar:GetProgress()
	return self:GetValue()
end

Displays.Loader = Component.define({
	Type = "Loader",
	Default = true,
	Description = "Indeterminate activity indicator.",
	Coerce = function(value)
		return value ~= false
	end,
})

function Displays.Loader:Start()
	return self:SetValue(true)
end

function Displays.Loader:Stop()
	return self:SetValue(false)
end

Displays.Image = Component.define({
	Type = "Image",
	Default = "",
	Description = "Icon or texture display.",
	Coerce = text,
})

function Displays.Image:SetImage(imageId)
	return self:SetValue(imageId)
end

Displays.Table = Component.define({
	Type = "Table",
	Default = {},
	Description = "Columnar data list.",
	Coerce = function(value)
		if type(value) ~= "table" then
			return {}
		end
		return Util.deepCopy(value)
	end,
	State = function(self)
		local columns = self.Spec.Columns or self.Metadata.Columns or {}
		return { Columns = columns, Rows = self.Value }
	end,
})

function Displays.Table:SetRows(rows)
	return self:SetValue(rows)
end

function Displays.Table:SetRow(index, row)
	local rows = Util.deepCopy(self:GetValue()) or {}
	rows[index] = row
	return self:SetValue(rows)
end

Displays.TreeView = Component.define({
	Type = "TreeView",
	Default = nil,
	Description = "Expandable node hierarchy.",
	Coerce = function(value)
		if value == nil then
			return nil
		end
		return tostring(value)
	end,
	State = function(self)
		return { Nodes = self:FlattenNodes() }
	end,
})

function Displays.TreeView:Init()
	self.ExpandedNodes = {}
	self.SelectedNode = nil
end

function Displays.TreeView:SetNodes(nodes)
	self.TreeNodes = nodes or {}
	for index, node in ipairs(self.TreeNodes) do
		node.Id = node.Id or ("node" .. tostring(index))
		if node.Expanded == nil then
			node.Expanded = node.DefaultExpanded == true
		end
	end
	return self:Refresh("nodes")
end

function Displays.TreeView:FlattenNodes()
	local out = {}
	local function walk(nodes, depth)
		for _, node in ipairs(nodes or {}) do
			local id = node.Id
			local children = node.Children
			local expanded = self.ExpandedNodes and self.ExpandedNodes[id] == true
			table.insert(out, {
				Id = id,
				Label = node.Label or id,
				Depth = depth,
				HasChildren = children ~= nil and #children > 0,
				Expanded = expanded,
			})
			if expanded and children then
				walk(children, depth + 1)
			end
		end
	end
	walk(self.TreeNodes, 0)
	return out
end

function Displays.TreeView:SetExpanded(id, expanded)
	self.ExpandedNodes = self.ExpandedNodes or {}
	self.ExpandedNodes[id] = expanded == true
	return self:Refresh("expansion")
end

function Displays.TreeView:ToggleNode(id)
	self.ExpandedNodes = self.ExpandedNodes or {}
	return self:SetExpanded(id, not self.ExpandedNodes[id])
end

function Displays.TreeView:SelectNode(id)
	self.SelectedNode = id
	return self:SetValue(id)
end

Displays.LogView = Component.define({
	Type = "LogView",
	Default = {},
	Description = "Append-only console output.",
	Coerce = function(value)
		if type(value) ~= "table" then
			return {}
		end
		local out = {}
		for index, entry in ipairs(value) do
			out[index] = entry
		end
		return out
	end,
	State = function(self)
		return { Lines = self.Value }
	end,
})

function Displays.LogView:Push(message, level)
	local lines = {}
	for index, entry in ipairs(self:GetValue()) do
		lines[index] = entry
	end
	table.insert(lines, { Text = tostring(message), Level = level or "Info" })
	local max = (self.Configuration and self.Configuration.MaxLines) or 200
	while #lines > max do
		table.remove(lines, 1)
	end
	return self:SetValue(lines)
end

function Displays.LogView:Clear()
	return self:SetValue({})
end

Displays.Graph = Component.define({
	Type = "Graph",
	Default = {},
	Description = "Stepped line graph for a numeric series.",
	Coerce = function(value)
		if type(value) ~= "table" then
			return {}
		end
		local out = {}
		for index, entry in ipairs(value) do
			out[index] = math.max(0, math.min(1, tonumber(entry) or 0))
		end
		return out
	end,
	State = function(self)
		return { Series = self.Value }
	end,
})

function Displays.Graph:Push(value)
	local series = {}
	for index, entry in ipairs(self:GetValue()) do
		series[index] = entry
	end
	table.insert(series, math.max(0, math.min(1, tonumber(value) or 0)))
	local limit = (self.Configuration and self.Configuration.Points) or 24
	while #series > limit do
		table.remove(series, 1)
	end
	return self:SetValue(series)
end

function Displays.Graph:SetSeries(series)
	return self:SetValue(series)
end

return Displays
end)()

local __NEVA_Components_Transient = (function()
--[[
	NEVAHEXUI - Components/Transient
	Notification and Dialog are components like any other: they resolve styles and
	render through the style engine. They differ in ownership -- the window
	creates and destroys them in its overlay area rather than inside a tab.
]]

local Component = __NEVA_Core_Component
local Signal = __NEVA_Core_Signal

local Transient = {}

Transient.Notification = Component.define({
	Type = "Notification",
	Default = nil,
	Description = "Transient message card with a level, message and dismiss action.",
	Coerce = function(value)
		return type(value) == "table" and value or {}
	end,
	State = function(self)
		local body = self.Spec.Body or {}
		return {
			Body = body,
			Message = body.Message or self.Description,
			Level = body.Level or self.Spec.Level or "Info",
		}
	end,
	Wire = function(self, view)
		self.Dismissed = Signal.new("NotificationDismissed")
		if view.Dismiss then
			self:Connect(view.Dismiss, "MouseButton1Click", function()
				self:Dismiss("UserClosed")
			end)
		end
	end,
})

function Transient.Notification:Dismiss(reason)
	if self.Dismissed2 == true then
		return false
	end
	self.Dismissed2 = true
	self.Dismissing = true
	local view = self.View
	if view and view.Root then
		view.Root.Visible = false
	end
	if self.Dismissed then
		self.Dismissed:Fire(reason or "Dismissed")
	end
	self:Destroy()
	return true
end

Transient.Dialog = Component.define({
	Type = "Dialog",
	Default = nil,
	Description = "Modal dialog with a title, body text and action buttons.",
	Coerce = function(value)
		return type(value) == "table" and value or {}
	end,
	State = function(self)
		local body = self.Spec.Body or {}
		return {
			Body = body,
			Title = body.Title or self.Name,
			Message = body.Message or self.Description,
			Actions = body.Actions or { { Label = "OK", Value = true, Style = "Primary" } },
		}
	end,
	Wire = function(self, view)
		self.Answered = Signal.new("DialogAnswered")
		for _, entry in ipairs(view.ActionButtons or {}) do
			self:Connect(entry.Button, "MouseButton1Click", function()
				self:Answer(entry.Value, entry.Label)
			end)
		end
	end,
})

function Transient.Dialog:Answer(value, label)
	if self.Answered2 == true then
		return false
	end
	self.Answered2 = true
	if self.Answered then
		self.Answered:Fire(value, label)
	end
	if self.Spec.OnChoose then
		self:_invoke(self.Spec.OnChoose, value, { Source = "Dialog" })
	end
	self:Destroy()
	return true
end

Transient.classes = { Transient.Notification, Transient.Dialog }

return Transient
end)()

local __NEVA_Components_Index = (function()
--[[
	NEVAHEXUI - Components/Index
	The single place that knows every component class. Registering here wires the
	classes into a context's factory table, which is what gives every container
	its Create<Type> methods and the Style Studio its catalogue of live components.
]]

local Controls = __NEVA_Components_Controls
local Displays = __NEVA_Components_Displays
local Transient = __NEVA_Components_Transient

local Index = {}

-- Registration order defines the default style for a component type (the first
-- style registered for that type), so the order below is meaningful.
Index.Classes = {
	Buttons = {
		Controls.Button,
		Controls.IconButton,
	},
	Toggles = {
		Controls.Toggle,
		Controls.Checkbox,
		Controls.Radio,
		Controls.RadioGroup,
	},
	Sliders = {
		Controls.Slider,
		Controls.RangeSlider,
	},
	TextInputs = {
		Controls.Textbox,
		Controls.NumberInput,
		Controls.CopyableInput,
		Controls.Keybind,
	},
	Pickers = {
		Controls.ColorPicker,
		Controls.ColorPalette,
	},
	Displays = {
		Displays.Label,
		Displays.Divider,
		Displays.Badge,
		Displays.ProgressBar,
		Displays.Loader,
		Displays.Image,
		Displays.Table,
		Displays.TreeView,
		Displays.LogView,
		Displays.Graph,
	},
}

-- Components that are not created inside a tab: they are transient surfaces the
-- window owns (Notify, Dialog). They live in the same factory table so the
-- window creates them through the identical component pipeline.
Index.TransientClasses = Transient.classes

function Index.flatten()
	local out = {}
	for _, group in ipairs({ "Buttons", "Toggles", "Sliders", "TextInputs", "Pickers", "Displays" }) do
		for _, class in ipairs(Index.Classes[group] or {}) do
			table.insert(out, class)
		end
	end
	for _, class in ipairs(Index.TransientClasses) do
		table.insert(out, class)
	end
	return out
end

-- Installs the classes into context.Factories. Containers read this table to
-- create their Create<Type> methods, so a component added here appears in the
-- public API without touching any other file.
function Index.install(context)
	local installed = {}
	for _, class in ipairs(Index.flatten()) do
		context.Factories[class.Type] = class
		table.insert(installed, class.Type)
	end
	return installed
end

function Index.has(componentType)
	for _, class in ipairs(Index.flatten()) do
		if class.Type == componentType then
			return true
		end
	end
	return false
end

return Index
end)()

local __NEVA_Configuration_Json = (function()
--[[
	NEVAHEXUI - Configuration/Json
	Small, dependency-free JSON encoder/decoder used by the configuration system.
	Configuration is exchanged as JSON precisely so that imports never execute
	untrusted Luau: parsing is structural and cannot call functions.
]]

local Util = __NEVA_Core_Util

local Json = {}

local ESCAPES = {
	['"'] = '\\"',
	["\\"] = "\\\\",
	["\b"] = "\\b",
	["\f"] = "\\f",
	["\n"] = "\\n",
	["\r"] = "\\r",
	["\t"] = "\\t",
}

local UNESCAPES = {
	['"'] = '"',
	["\\"] = "\\",
	["/"] = "/",
	b = "\b",
	f = "\f",
	n = "\n",
	r = "\r",
	t = "\t",
}

local function encodeString(text)
	local escaped = text:gsub('[%z\1-\31\\"]', function(character)
		return ESCAPES[character] or ("\\u%04x"):format(character:byte())
	end)
	return '"' .. escaped .. '"'
end

local function encodeNumber(value)
	if value ~= value or value == math.huge or value == -math.huge then
		return "null"
	end
	if value == math.floor(value) and math.abs(value) < 1e15 then
		return ("%d"):format(value)
	end
	return (("%.10f"):format(value):gsub("0+$", ""):gsub("%.$", ""))
end

local encodeValue

local function encodeTable(value, options, depth)
	if depth > (options.MaxDepth or 32) then
		error("NEVAHEXUI json: structure is too deep (possible cycle)")
	end
	if getmetatable(value) == nil and value.__nevaColor then
		return encodeString(value:ToHex())
	end
	local meta = getmetatable(value)
	if meta and value.ToHex and value.__nevaColor then
		return encodeString(value:ToHex())
	end
	if Util.isArray(value) then
		local parts = {}
		for index = 1, #value do
			table.insert(parts, encodeValue(value[index], options, depth + 1))
		end
		return "[" .. table.concat(parts, ",") .. "]"
	end
	local parts = {}
	for _, key in ipairs(Util.keys(value)) do
		local encoded = encodeValue(value[key], options, depth + 1)
		if encoded ~= nil then
			table.insert(parts, encodeString(tostring(key)) .. ":" .. encoded)
		end
	end
	return "{" .. table.concat(parts, ",") .. "}"
end

encodeValue = function(value, options, depth)
	local kind = type(value)
	if value == nil then
		return "null"
	elseif kind == "boolean" then
		return tostring(value)
	elseif kind == "number" then
		return encodeNumber(value)
	elseif kind == "string" then
		return encodeString(value)
	elseif kind == "table" then
		return encodeTable(value, options, depth or 0)
	end
	-- functions, threads and userdata are not serialisable and are omitted
	return nil
end

function Json.encode(value, options)
	options = options or {}
	if options.Pretty then
		local compact = encodeValue(value, options, 0)
		return compact
	end
	return encodeValue(value, options, 0)
end

local function decodeError(text, position, message)
	local contextStart = math.max(1, position - 20)
	return nil, ("json error at position %d: %s (near %q)"):format(
		position,
		message,
		text:sub(contextStart, math.min(#text, position + 20))
	)
end

function Json.decode(text)
	if type(text) ~= "string" then
		return nil, "json input must be a string"
	end
	local position = 1
	local length = #text

	local function skipWhitespace()
		while position <= length do
			local character = text:sub(position, position)
			if character == " " or character == "\t" or character == "\n" or character == "\r" then
				position += 1
			else
				break
			end
		end
	end

	local parseValue

	local function parseString()
		position += 1 -- opening quote
		local parts = {}
		while position <= length do
			local character = text:sub(position, position)
			if character == '"' then
				position += 1
				return table.concat(parts)
			elseif character == "\\" then
				local escape = text:sub(position + 1, position + 1)
				if escape == "u" then
					local hex = text:sub(position + 2, position + 5)
					if not hex:match("^%x%x%x%x$") then
						return decodeError(text, position, "invalid unicode escape")
					end
					local code = tonumber(hex, 16)
					table.insert(parts, utf8.char(code))
					position += 6
				else
					local replacement = UNESCAPES[escape]
					if not replacement then
						return decodeError(text, position, "invalid escape sequence")
					end
					table.insert(parts, replacement)
					position += 2
				end
			else
				table.insert(parts, character)
				position += 1
			end
		end
		return decodeError(text, position, "unterminated string")
	end

	local function parseNumber()
		local start = position
		while position <= length and text:sub(position, position):match("[%d%.eE%+%-]") do
			position += 1
		end
		local literal = text:sub(start, position - 1)
		local value = tonumber(literal)
		if value == nil then
			return decodeError(text, start, "invalid number")
		end
		return value
	end

	local function parseArray()
		position += 1 -- [
		local out = {}
		skipWhitespace()
		if text:sub(position, position) == "]" then
			position += 1
			return out
		end
		while true do
			local value, err = parseValue()
			if err then
				return nil, err
			end
			table.insert(out, value)
			skipWhitespace()
			local character = text:sub(position, position)
			if character == "," then
				position += 1
				skipWhitespace()
			elseif character == "]" then
				position += 1
				return out
			else
				return decodeError(text, position, "expected ',' or ']' in array")
			end
		end
	end

	local function parseObject()
		position += 1 -- {
		local out = {}
		skipWhitespace()
		if text:sub(position, position) == "}" then
			position += 1
			return out
		end
		while true do
			skipWhitespace()
			if text:sub(position, position) ~= '"' then
				return decodeError(text, position, "expected a string key")
			end
			local key, err = parseString()
			if err then
				return nil, err
			end
			skipWhitespace()
			if text:sub(position, position) ~= ":" then
				return decodeError(text, position, "expected ':' after key")
			end
			position += 1
			skipWhitespace()
			local value, valueErr = parseValue()
			if valueErr then
				return nil, valueErr
			end
			out[key] = value
			skipWhitespace()
			local character = text:sub(position, position)
			if character == "," then
				position += 1
			elseif character == "}" then
				position += 1
				return out
			else
				return decodeError(text, position, "expected ',' or '}' in object")
			end
		end
	end

	parseValue = function()
		skipWhitespace()
		if position > length then
			return decodeError(text, position, "unexpected end of input")
		end
		local character = text:sub(position, position)
		if character == "{" then
			return parseObject()
		elseif character == "[" then
			return parseArray()
		elseif character == '"' then
			return parseString()
		elseif text:sub(position, position + 3) == "true" then
			position += 4
			return true
		elseif text:sub(position, position + 4) == "false" then
			position += 5
			return false
		elseif text:sub(position, position + 3) == "null" then
			position += 4
			return nil
		elseif character:match("[%d%-]") then
			return parseNumber()
		end
		return decodeError(text, position, ("unexpected character %q"):format(character))
	end

	local value, err = parseValue()
	if err then
		return nil, err
	end
	skipWhitespace()
	if position <= length then
		return decodeError(text, position, "unexpected trailing content")
	end
	return value
end

return Json
end)()

local __NEVA_Themes_Defs = (function()
--[[
	NEVAHEXUI - Themes/Defs
	Built-in theme catalogue. Every theme is a real token set validated by
	Themes/Registry; token tables are partial and are merged over Tokens.Defaults.
	The default accent colour across the framework is NEVA red (#EF4444).
]]

local Defs = {}

local DEFAULT_ACCENT = "#EF4444"

Defs.List = {
	{
		Id = "dark",
		Name = "Dark",
		Category = "Core",
		Description = "The framework default: neutral charcoal surfaces with the NEVA red accent.",
		Tokens = {
			Background = "#101014", Surface = "#17171E", SurfaceAlt = "#1F1F2A", Outline = "#2E2E3C",
			Text = "#F4F4F7", TextMuted = "#9C9CAC", Accent = DEFAULT_ACCENT, AccentText = "#FFFFFF",
			Positive = "#3DDC97", Warning = "#F5A524", Negative = "#FF5470",
			CornerRadius = 8, BackgroundTransparency = 0.06, SurfaceTransparency = 0.12,
		},
	},
	{
		Id = "neva",
		Name = "NEVA",
		Category = "Core",
		Description = "Signature NEVA palette: deep red-tinted surfaces with a hot accent.",
		Tokens = {
			Background = "#120A0C", Surface = "#1B0F12", SurfaceAlt = "#26151A", Outline = "#3D2026",
			Text = "#FFF3F4", TextMuted = "#C39AA0", Accent = DEFAULT_ACCENT, AccentText = "#FFFFFF",
			Positive = "#4ADE80", Warning = "#FBBF24", Negative = "#FB7185",
			CornerRadius = 10, BackgroundTransparency = 0.04, SurfaceTransparency = 0.08, AnimationDuration = 0.2,
		},
	},
	{
		Id = "light",
		Name = "Light",
		Category = "Core",
		Description = "Light neutral surfaces with strong text contrast.",
		Tokens = {
			Background = "#F5F5F7", Surface = "#FFFFFF", SurfaceAlt = "#ECECF1", Outline = "#D3D3DC",
			Text = "#16161C", TextMuted = "#5C5C6B", Accent = DEFAULT_ACCENT, AccentText = "#FFFFFF",
			Positive = "#0F9D63", Warning = "#B4690E", Negative = "#D92D5B",
			CornerRadius = 8, BackgroundTransparency = 0, SurfaceTransparency = 0,
		},
	},
	{
		Id = "modern",
		Name = "Modern",
		Category = "Styled",
		Description = "Large radii, generous spacing and soft elevation.",
		Tokens = {
			Background = "#0E1116", Surface = "#161B22", SurfaceAlt = "#1E242D", Outline = "#2B323D",
			Text = "#E6EDF3", TextMuted = "#8B949E", Accent = DEFAULT_ACCENT, AccentText = "#FFFFFF",
			CornerRadius = 14, Padding = 12, Spacing = 10, BackgroundTransparency = 0.03,
		},
	},
	{
		Id = "minimal",
		Name = "Minimal",
		Category = "Styled",
		Description = "Flat surfaces, hairline outlines and no elevation.",
		Tokens = {
			Background = "#0C0C0E", Surface = "#131316", SurfaceAlt = "#191920", Outline = "#26262E",
			Text = "#EDEDF2", TextMuted = "#8A8A99", Accent = DEFAULT_ACCENT, AccentText = "#FFFFFF",
			CornerRadius = 2, StrokeThickness = 1, Spacing = 6, BackgroundTransparency = 0,
			SurfaceTransparency = 0, AnimationDuration = 0.12,
		},
	},
	{
		Id = "classic",
		Name = "Classic",
		Category = "Styled",
		Description = "Squared corners and grey panels reminiscent of first-generation UIs.",
		Tokens = {
			Background = "#1B1B1B", Surface = "#262626", SurfaceAlt = "#333333", Outline = "#4D4D4D",
			Text = "#FFFFFF", TextMuted = "#A6A6A6", Accent = DEFAULT_ACCENT, AccentText = "#FFFFFF",
			CornerRadius = 0, StrokeThickness = 1, Font = "SourceSans", FontBold = "SourceSansBold",
			BackgroundTransparency = 0, SurfaceTransparency = 0,
		},
	},
	{
		Id = "glass",
		Name = "Glass",
		Category = "Styled",
		Description = "High-transparency panels designed to sit over 3D content.",
		Tokens = {
			Background = "#0A0F18", Surface = "#121926", SurfaceAlt = "#1A2333", Outline = "#3A4A66",
			Text = "#F0F6FF", TextMuted = "#9FB0C7", Accent = DEFAULT_ACCENT, AccentText = "#FFFFFF",
			CornerRadius = 16, BackgroundTransparency = 0.35, SurfaceTransparency = 0.4,
			AccentTransparency = 0.1, StrokeThickness = 1,
		},
	},
	{
		Id = "acrylic",
		Name = "Acrylic",
		Category = "Styled",
		Description = "Translucent blue-grey material with a soft rim light.",
		Tokens = {
			Background = "#141A22", Surface = "#1D2632", SurfaceAlt = "#27323F", Outline = "#42546B",
			Text = "#F2F7FD", TextMuted = "#A3B4C9", Accent = DEFAULT_ACCENT, AccentText = "#FFFFFF",
			CornerRadius = 12, BackgroundTransparency = 0.28, SurfaceTransparency = 0.32,
		},
	},
	{
		Id = "neon",
		Name = "Neon",
		Category = "Expressive",
		Description = "Saturated accents on near-black surfaces with fast transitions.",
		Tokens = {
			Background = "#05050A", Surface = "#0B0B16", SurfaceAlt = "#12122A", Outline = "#2A2A5C",
			Text = "#EAEAFE", TextMuted = "#8A8AC8", Accent = DEFAULT_ACCENT, AccentText = "#FFFFFF",
			Positive = "#39FF14", Warning = "#FFD300", Negative = "#FF2E63",
			CornerRadius = 6, AnimationDuration = 0.16, Easing = "Cubic",
		},
	},
	{
		Id = "voltage",
		Name = "Voltage",
		Category = "Expressive",
		Description = "Electric yellow accent with hard outlines.",
		Tokens = {
			Background = "#0B0B0B", Surface = "#151515", SurfaceAlt = "#1F1F1F", Outline = "#3A3A00",
			Text = "#FFFBE6", TextMuted = "#BDB68A", Accent = "#FACC15", AccentText = "#0B0B0B",
			Positive = "#A3E635", Warning = "#FB923C", Negative = "#EF4444",
			CornerRadius = 4, StrokeThickness = 2,
		},
	},
	{
		Id = "terminal",
		Name = "Terminal",
		Category = "Expressive",
		Description = "Monospace green-on-black console styling.",
		Tokens = {
			Background = "#000600", Surface = "#02120A", SurfaceAlt = "#04200F", Outline = "#0C3A1C",
			Text = "#8CFFB0", TextMuted = "#3FA968", Accent = "#3EE07F", AccentText = "#001A0A",
			Positive = "#3EE07F", Warning = "#E0D33E", Negative = "#E03E5A",
			CornerRadius = 0, Font = "Code", FontBold = "Code", AnimationDuration = 0.08,
			BackgroundTransparency = 0, SurfaceTransparency = 0,
		},
	},
	{
		Id = "highcontrast",
		Name = "High Contrast",
		Category = "Accessible",
		Description = "Maximum contrast for accessibility and readability.",
		Tokens = {
			Background = "#000000", Surface = "#0A0A0A", SurfaceAlt = "#141414", Outline = "#FFFFFF",
			Text = "#FFFFFF", TextMuted = "#D6D6D6", Accent = "#FF3B30", AccentText = "#FFFFFF",
			Positive = "#00FF7F", Warning = "#FFD400", Negative = "#FF1744",
			CornerRadius = 4, StrokeThickness = 2, FontSize = 14, BackgroundTransparency = 0,
			SurfaceTransparency = 0, AnimationDuration = 0.1,
		},
	},
	{
		Id = "paper",
		Name = "Paper",
		Category = "Accessible",
		Description = "Warm off-white paper surfaces with ink text.",
		Tokens = {
			Background = "#F7F3EA", Surface = "#FFFDF7", SurfaceAlt = "#EFE8DA", Outline = "#D6CBB5",
			Text = "#2A2418", TextMuted = "#6E6250", Accent = "#C2410C", AccentText = "#FFFFFF",
			Positive = "#15803D", Warning = "#B45309", Negative = "#B91C1C",
			CornerRadius = 6, BackgroundTransparency = 0, SurfaceTransparency = 0,
		},
	},
	{
		Id = "ocean",
		Name = "Ocean",
		Category = "Expressive",
		Description = "Deep teal depth with cyan highlights.",
		Tokens = {
			Background = "#04202B", Surface = "#07303F", SurfaceAlt = "#0B3F52", Outline = "#15607A",
			Text = "#E6FBFF", TextMuted = "#8FBFCC", Accent = "#22D3EE", AccentText = "#04202B",
			Positive = "#34D399", Warning = "#FBBF24", Negative = "#FB7185",
			CornerRadius = 10, BackgroundTransparency = 0.05,
		},
	},
	{
		Id = "grape",
		Name = "Grape",
		Category = "Expressive",
		Description = "Violet surfaces with a magenta accent.",
		Tokens = {
			Background = "#150A24", Surface = "#1F1035", SurfaceAlt = "#2B1747", Outline = "#4A2A78",
			Text = "#F5EDFF", TextMuted = "#B49AD6", Accent = "#D946EF", AccentText = "#FFFFFF",
			Positive = "#4ADE80", Warning = "#FCD34D", Negative = "#FB7185",
			CornerRadius = 10,
		},
	},
	{
		Id = "blood",
		Name = "Blood",
		Category = "Expressive",
		Description = "Dark crimson palette with a bright red accent.",
		Tokens = {
			Background = "#150505", Surface = "#210A0A", SurfaceAlt = "#2E1010", Outline = "#5C1A1A",
			Text = "#FFEDED", TextMuted = "#C58B8B", Accent = "#FF2D2D", AccentText = "#FFFFFF",
			Positive = "#65A30D", Warning = "#D97706", Negative = "#FF4D6D",
			CornerRadius = 6,
		},
	},
	{
		Id = "abyss",
		Name = "Abyss",
		Category = "Core",
		Description = "Very dark blue-black surfaces for low-light environments.",
		Tokens = {
			Background = "#04060D", Surface = "#0A0F1A", SurfaceAlt = "#111827", Outline = "#1F2A3D",
			Text = "#E2E8F5", TextMuted = "#7C8AA5", Accent = DEFAULT_ACCENT, AccentText = "#FFFFFF",
			Positive = "#34D399", Warning = "#F59E0B", Negative = "#F43F5E",
			CornerRadius = 8, BackgroundTransparency = 0.1,
		},
	},
	{
		Id = "midnight",
		Name = "Midnight",
		Category = "Core",
		Description = "Blue-tinted midnight surfaces with muted accents.",
		Tokens = {
			Background = "#0B1020", Surface = "#131A2E", SurfaceAlt = "#1B2440", Outline = "#2E3A5C",
			Text = "#EEF2FF", TextMuted = "#94A3C4", Accent = "#6366F1", AccentText = "#FFFFFF",
			Positive = "#22C55E", Warning = "#EAB308", Negative = "#EF4444",
			CornerRadius = 12,
		},
	},
	{
		Id = "marshmallow",
		Name = "Marshmallow",
		Category = "Expressive",
		Description = "Soft pastel surfaces with pink accents.",
		Tokens = {
			Background = "#FFF1F6", Surface = "#FFFFFF", SurfaceAlt = "#FFE4EE", Outline = "#F7C2D8",
			Text = "#3B1E2C", TextMuted = "#8A5D72", Accent = "#F472B6", AccentText = "#FFFFFF",
			Positive = "#10B981", Warning = "#F59E0B", Negative = "#E11D48",
			CornerRadius = 16, BackgroundTransparency = 0, SurfaceTransparency = 0,
		},
	},
	{
		Id = "ember",
		Name = "Ember",
		Category = "Expressive",
		Description = "Charcoal surfaces with a warm amber accent.",
		Tokens = {
			Background = "#141010", Surface = "#1E1815", SurfaceAlt = "#2A211C", Outline = "#453529",
			Text = "#FFF4E8", TextMuted = "#BFA98C",
			Accent = "#F97316", AccentText = "#1A0F05",
			CornerRadius = 8, Easing = "Sine",
		},
	},
	{
		Id = "cassette",
		Name = "Cassette",
		Category = "Expressive",
		Description = "Retro plastic grey with teal and orange highlights.",
		Tokens = {
			Background = "#20232A", Surface = "#2B2F38", SurfaceAlt = "#363B46", Outline = "#4C5361",
			Text = "#F2F5F9", TextMuted = "#A6AEBD", Accent = "#14B8A6", AccentText = "#04211E",
			Positive = "#22C55E", Warning = "#F59E0B", Negative = "#EF4444",
			CornerRadius = 4, Font = "SourceSans",
		},
	},
}

return Defs
end)()

local __NEVA_Themes_Tokens = (function()
--[[
	NEVAHEXUI - Themes/Tokens
	Design token schema. Theme tokens are the shared vocabulary every style reads
	from; styles never hardcode colours. Documented precedence (see
	docs/themes.md): style defaults < theme tokens < category configuration <
	component configuration.
]]

local Tokens = {}

Tokens.Colors = {
	"Background",
	"Surface",
	"SurfaceAlt",
	"Outline",
	"Text",
	"TextMuted",
	"Accent",
	"AccentText",
	"Positive",
	"Warning",
	"Negative",
}

Tokens.Numbers = {
	"CornerRadius",
	"Padding",
	"Spacing",
	"FontSize",
	"StrokeThickness",
	"BackgroundTransparency",
	"SurfaceTransparency",
	"AccentTransparency",
	"AnimationDuration",
}

Tokens.Strings = {
	"Name",
	"Id",
	"Description",
	"Icon",
}

Tokens.Fonts = {
	"Font",
	"FontBold",
}

Tokens.Enums = {
	Easing = { "Linear", "Sine", "Quad", "Cubic", "Quart", "Quint", "Bounce", "Elastic", "Exponential", "Circular", "Back" },
}

Tokens.Required = {
	"Background",
	"Surface",
	"Text",
	"TextMuted",
	"Accent",
	"AccentText",
	"Outline",
}

Tokens.Defaults = {
	Background = "#101014",
	Surface = "#17171E",
	SurfaceAlt = "#1F1F2A",
	Outline = "#2E2E3C",
	Text = "#F4F4F7",
	TextMuted = "#9C9CAC",
	Accent = "#EF4444",
	AccentText = "#FFFFFF",
	Positive = "#3DDC97",
	Warning = "#F5A524",
	Negative = "#FF5470",
	CornerRadius = 8,
	Padding = 10,
	Spacing = 8,
	FontSize = 13,
	StrokeThickness = 1,
	BackgroundTransparency = 0.06,
	SurfaceTransparency = 0.12,
	AccentTransparency = 0,
	AnimationDuration = 0.2,
	Font = "GothamMedium",
	FontBold = "GothamBold",
	Easing = "Quad",
}

function Tokens.schema()
	local schema = {}
	for _, key in ipairs(Tokens.Colors) do
		table.insert(schema, { Key = key, Type = "color", Required = Tokens.Required[#Tokens.Required] ~= nil and table.find(Tokens.Required, key) ~= nil })
	end
	for _, key in ipairs(Tokens.Numbers) do
		table.insert(schema, { Key = key, Type = "number", Min = 0 })
	end
	for _, key in ipairs(Tokens.Fonts) do
		table.insert(schema, { Key = key, Type = "font" })
	end
	for key, options in pairs(Tokens.Enums) do
		table.insert(schema, { Key = key, Type = "enum", Options = options })
	end
	table.sort(schema, function(a, b)
		return a.Key < b.Key
	end)
	return schema
end

function Tokens.isRequired(key)
	for _, candidate in ipairs(Tokens.Required) do
		if candidate == key then
			return true
		end
	end
	return false
end

return Tokens
end)()

local __NEVA_Themes_Registry = (function()
--[[
	NEVAHEXUI - Themes/Registry
	Theme registration, validation and token resolution. Themes are additive: a
	theme supplies only the tokens it decides to change and the registry merges
	them over the documented defaults.
]]

local Util = __NEVA_Core_Util
local Color = __NEVA_Utilities_Color
local Tokens = __NEVA_Themes_Tokens
local Defs = __NEVA_Themes_Defs

local Registry = {}

Registry.Byld = {} -- id -> definition (populated below)
Registry.Order = {} -- registration order, used by list/ids/count

local function colourKeys()
	local set = {}
	for _, key in ipairs(Tokens.Colors) do
		set[key] = true
	end
	return set
end

local COLOUR_KEYS = colourKeys()

function Registry.validate(definition)
	local errors = {}
	local warnings = {}
	if type(definition) ~= "table" then
		return false, { "theme definition must be a table" }, warnings
	end
	if type(definition.Id) ~= "string" or definition.Id == "" then
		table.insert(errors, "theme Id must be a non-empty string")
	end
	if definition.Id and not definition.Id:match("^[a-z0-9_%-]+$") then
		table.insert(errors, ("theme Id %q must use lowercase letters, digits, '-' or '_'"):format(definition.Id))
	end
	if type(definition.Tokens) ~= "table" then
		table.insert(errors, "theme Tokens must be a table")
		return false, errors, warnings
	end
	local known = {}
	for _, key in ipairs(Tokens.Colors) do
		known[key] = "color"
	end
	for _, key in ipairs(Tokens.Numbers) do
		known[key] = "number"
	end
	for _, key in ipairs(Tokens.Fonts) do
		known[key] = "font"
	end
	for key in pairs(Tokens.Enums) do
		known[key] = "enum"
	end
	for key in pairs(Tokens.Strings) do
		known[key] = "string"
	end
	for key, value in pairs(definition.Tokens) do
		local kind = known[key]
		if not kind then
			table.insert(warnings, ("unknown token %q"):format(tostring(key)))
		elseif kind == "color" then
			local normalised, message = Color.normalize(value)
			if not normalised then
				table.insert(errors, ("token %s: %s"):format(key, message or "invalid colour"))
			end
		elseif kind == "number" then
			if not Util.isFiniteNumber(value) then
				table.insert(errors, ("token %s must be a finite number"):format(key))
			elseif value < 0 and key ~= "TextMuted" then
				table.insert(errors, ("token %s must not be negative"):format(key))
			end
		elseif kind == "font" then
			if type(value) ~= "string" or value == "" then
				table.insert(errors, ("token %s must be a font name"):format(key))
			end
		elseif kind == "enum" then
			local options = Tokens.Enums[key]
			local found = false
			for _, option in ipairs(options) do
				if option == value then
					found = true
					break
				end
			end
			if not found then
				table.insert(errors, ("token %s must be one of: %s"):format(key, table.concat(options, ", ")))
			end
		end
	end
	return #errors == 0, errors, warnings
end

function Registry.register(definition, options)
	options = options or {}
	local ok, errors, warnings = Registry.validate(definition)
	if not ok then
		return nil, errors, warnings
	end
	local existing = Registry.Byld[definition.Id]
	if existing and not options.Replace then
		return nil, { ("theme %q is already registered; pass Replace = true to override it"):format(definition.Id) }, warnings
	end
	local record = {
		Id = definition.Id,
		Name = definition.Name or definition.Id,
		Category = definition.Category or "Custom",
		Description = definition.Description or "",
		Author = definition.Author,
		Tokens = Util.deepCopy(definition.Tokens),
		BuiltIn = options.BuiltIn == true,
		Replaces = existing and existing.BuiltIn or nil,
	}
	Registry.Byld[definition.Id] = record
	if not existing then
		table.insert(Registry.Order, definition.Id)
	end
	return record, errors, warnings
end

function Registry.unregister(id)
	local record = Registry.Byld[id]
	if not record then
		return false
	end
	Registry.Byld[id] = nil
	for index, candidate in ipairs(Registry.Order) do
		if candidate == id then
			table.remove(Registry.Order, index)
			break
		end
	end
	return true
end

function Registry.get(id)
	return Registry.Byld[id]
end

function Registry.has(id)
	return Registry.Byld[id] ~= nil
end

function Registry.list()
	local out = {}
	for _, id in ipairs(Registry.Order) do
		local record = Registry.Byld[id]
		table.insert(out, {
			Id = record.Id,
			Name = record.Name,
			Category = record.Category,
			Description = record.Description,
			Author = record.Author,
			BuiltIn = record.BuiltIn,
			TokenCount = Util.count(record.Tokens),
		})
	end
	return out
end

function Registry.ids()
	local out = {}
	for _, id in ipairs(Registry.Order) do
		table.insert(out, id)
	end
	return out
end

-- Full token set: defaults <- theme <- caller overrides, validated.
function Registry.resolve(id, overrides)
	local record = Registry.Byld[id or "dark"]
	local tokens = Util.deepMerge(Tokens.Defaults, record and record.Tokens or {})
	if type(overrides) == "table" then
		tokens = Util.deepMerge(tokens, overrides)
	end
	local errors = {}
	local warnings = {}
	for _, key in ipairs(Tokens.Required) do
		if tokens[key] == nil then
			table.insert(errors, ("required token %s is missing"):format(key))
		end
	end
	for _, key in ipairs(Tokens.Colors) do
		local value = tokens[key]
		if value ~= nil then
			local normalised, message = Color.normalize(value)
			if normalised then
				tokens[key] = normalised
			else
				table.insert(errors, ("token %s: %s"):format(key, message or "invalid colour"))
			end
		end
	end
	for _, key in ipairs(Tokens.Numbers) do
		local value = tokens[key]
		if value ~= nil and not Util.isFiniteNumber(value) then
			table.insert(errors, ("token %s must be a finite number"):format(key))
		elseif value ~= nil and value < 0 then
			table.insert(warnings, ("token %s clamped to 0"):format(key))
			tokens[key] = 0
		end
	end
	return tokens, record, errors, warnings
end

-- Converts a resolved token set into values the host back end accepts.
function Registry.forHost(host, tokens)
	local prepared = {}
	for key, value in pairs(tokens) do
		if COLOUR_KEYS[key] and getmetatable(value) == Color then
			prepared[key] = host.color(value.R * 255, value.G * 255, value.B * 255, value.A)
			prepared[key .. "Transparency"] = prepared[key .. "Transparency"] or (1 - value.A)
		elseif key == "Font" or key == "FontBold" then
			prepared[key] = host.font(value)
		else
			prepared[key] = value
		end
	end
	return prepared
end

function Registry.exportLua(id, overrides)
	local record = Registry.Byld[id]
	assert(record, ("unknown theme %q"):format(tostring(id)))
	local tokens = Util.deepMerge(record.Tokens, overrides or {})
	local lines = {}
	table.insert(lines, "{")
	table.insert(lines, ("\tId = %q,"):format(record.Id))
	table.insert(lines, ("\tName = %q,"):format(record.Name))
	table.insert(lines, ("\tCategory = %q,"):format(record.Category))
	table.insert(lines, "\tTokens = {")
	for _, key in ipairs(Util.keys(tokens)) do
		table.insert(lines, ("\t\t%s = %s,"):format(key, Util.formatValue(tokens[key])))
	end
	table.insert(lines, "\t},")
	table.insert(lines, "}")
	return table.concat(lines, "\n")
end

function Registry.count()
	return #Registry.Order
end

for _, definition in ipairs(Defs.List) do
	local _, errors = Registry.register(definition, { BuiltIn = true })
	if errors and #errors > 0 then
		error(("NEVAHEXUI: built-in theme %q failed validation: %s"):format(
			tostring(definition.Id),
			table.concat(errors, "; ")
		))
	end
end

return Registry
end)()

local __NEVA_Configuration_Config = (function()
--[[
	NEVAHEXUI - Configuration/Config
	Versioned configuration persistence. Files are written as JSON, so importing a
	configuration never executes Luau. When the runtime has no filesystem the
	system silently falls back to an in-memory store and reports that persistence
	is session-only.
]]

local Util = __NEVA_Core_Util
local Json = __NEVA_Configuration_Json
local Themes = __NEVA_Themes_Registry
local Styles = __NEVA_Styles_Registry

local Config = {}
Config.__index = Config

Config.Version = 2

local function now()
	local ok, value = pcall(function()
		return os.time()
	end)
	if ok and type(value) == "number" then
		return value
	end
	return nil
end

function Config.new(context, options)
	options = options or {}
	local self = setmetatable({}, Config)
	self.Context = context
	self.Host = context.Host
	self.Folder = options.Folder or "NEVAHEXUI"
	self.Persistent = context.Host.Capabilities.filesystem == true
	self.SaveEnabled = options.SaveConfigs ~= false
	self.Memory = {}
	self.AutoSaveKey = options.AutoSaveKey
	self.LastError = nil
	if self.Persistent then
		pcall(function()
			self.Host.fs.makefolder(self.Folder)
		end)
	end
	return self
end

function Config:_path(name)
	return ("%s/%s.json"):format(self.Folder, name)
end

function Config:IsPersistent()
	return self.Persistent
end

function Config:Describe()
	return {
		Folder = self.Folder,
		Persistent = self.Persistent,
		SaveEnabled = self.SaveEnabled,
		Version = Config.Version,
		Names = self:List(),
	}
end

function Config:Snapshot()
	local components = {}
	for _, component in ipairs(self.Context:AllComponents()) do
		if not component.Destroyed then
			components[component.Flag or component.Id] = component:Serialize()
		end
	end
	return {
		Version = Config.Version,
		CreatedAt = now(),
		Theme = self.Context.ThemeId,
		ThemeConfiguration = Util.deepCopy(self.Context.ThemeOverrides),
		Layout = self.Context.Options.Layout,
		Styles = Util.deepCopy(self.Context.StyleDefaults),
		StyleConfiguration = Util.deepCopy(self.Context.CategoryConfigurations),
		Components = components,
	}
end

function Config:Encode(name, payload)
	local document = Util.deepCopy(payload or {})
	document.Version = document.Version or Config.Version
	document.Name = name or document.Name
	document.CreatedAt = document.CreatedAt or now()
	document.UpdatedAt = now()
	return Json.encode(document)
end

function Config:Decode(text)
	local data, err = Json.decode(text)
	if not data then
		return nil, err
	end
	if type(data) ~= "table" then
		return nil, "configuration root must be an object"
	end
	return self:Migrate(data)
end

-- Upgrades payloads written by older versions and repairs missing sections.
function Config:Migrate(data)
	local version = tonumber(data.Version) or 1
	local migrated = data
	if version < Config.Version then
		migrated.Components = migrated.Components or {}
		migrated.Styles = migrated.Styles or {}
		migrated.StyleConfiguration = migrated.StyleConfiguration or {}
		migrated.SchemaVersion = Config.Version
		migrated.MigratedFrom = version
	end
	migrated.Version = Config.Version
	return migrated
end

function Config:Validate(data)
	local errors = {}
	local warnings = {}
	if type(data) ~= "table" then
		return false, { "configuration must be an object" }, warnings
	end
	if data.Theme ~= nil and not Themes.has(data.Theme) then
		table.insert(warnings, ("unknown theme %q; keeping the current theme"):format(tostring(data.Theme)))
	end
	if data.Styles ~= nil then
		if type(data.Styles) ~= "table" then
			table.insert(errors, "Styles must be a table of category -> style id")
		else
			for category, styleId in pairs(data.Styles) do
				local style = Styles.get(styleId)
				if not style then
					table.insert(warnings, ("unknown style %q for %s"):format(tostring(styleId), tostring(category)))
				elseif style.Component ~= category then
					table.insert(warnings, ("style %q does not render %s"):format(styleId, tostring(category)))
				end
			end
		end
	end
	if data.Components ~= nil and type(data.Components) ~= "table" then
		table.insert(errors, "Components must be a table of flag -> value")
	end
	return #errors == 0, errors, warnings
end

function Config:Save(name, payload)
	if not self.SaveEnabled then
		return false, "configuration saving is disabled"
	end
	assert(type(name) == "string" and name ~= "", "Config:Save expects a name")
	local document = payload or self:Snapshot()
	local text = self:Encode(name, document)
	if self.Persistent then
		local ok, err = pcall(function()
			self.Host.fs.writefile(self:_path(name), text)
		end)
		if not ok then
			self.LastError = err
			return false, err
		end
		return true, nil, text
	end
	self.Memory[name] = text
	return true, "session-only (no filesystem available)", text
end

function Config:Load(name)
	local text
	if self.Persistent then
		local path = self:_path(name)
		local exists = false
		pcall(function()
			exists = self.Host.fs.isfile(path)
		end)
		if not exists then
			return nil, ("configuration %q does not exist"):format(name)
		end
		local ok, contents = pcall(function()
			return self.Host.fs.readfile(path)
		end)
		if not ok then
			self.LastError = contents
			return nil, contents
		end
		text = contents
	else
		text = self.Memory[name]
		if not text then
			return nil, ("configuration %q does not exist in memory"):format(name)
		end
	end
	local data, err = self:Decode(text)
	if not data then
		return nil, err
	end
	local ok, errors = self:Validate(data)
	if not ok then
		return nil, table.concat(errors, "; ")
	end
	return data, nil
end

function Config:Exists(name)
	if self.Persistent then
		local exists = false
		pcall(function()
			exists = self.Host.fs.isfile(self:_path(name))
		end)
		return exists
	end
	return self.Memory[name] ~= nil
end

function Config:List()
	if self.Persistent then
		local files = {}
		local ok, listed = pcall(function()
			return self.Host.fs.listfiles(self.Folder)
		end)
		if ok and listed then
			files = listed
		end
		local names = {}
		local prefix = self.Folder .. "/"
		for _, path in ipairs(files) do
			if path:sub(1, #prefix) == prefix and path:sub(-5) == ".json" then
				table.insert(names, path:sub(#prefix + 1, -6))
			end
		end
		table.sort(names)
		return names
	end
	local names = {}
	for name in pairs(self.Memory) do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

function Config:Delete(name)
	if self.Persistent then
		local ok = pcall(function()
			self.Host.fs.delfile(self:_path(name))
		end)
		return ok
	end
	if self.Memory[name] == nil then
		return false
	end
	self.Memory[name] = nil
	return true
end

function Config:Export(payload)
	return self:Encode(payload and payload.Name, payload or self:Snapshot())
end

function Config:Import(text, name, options)
	options = options or {}
	local data, err = self:Decode(text)
	if not data then
		return false, err
	end
	local ok, errors = self:Validate(data)
	if not ok then
		return false, table.concat(errors, "; ")
	end
	if name then
		local saved, saveErr = self:Save(name, data)
		if not saved then
			return false, saveErr
		end
	end
	if options.Apply ~= false then
		return self:Apply(data, options), nil, data
	end
	return true, nil, data
end

-- Applies a configuration payload to the live interface. Component values are
-- restored without firing callbacks unless the payload requests it.
function Config:Apply(data, options)
	options = options or {}
	local applied = { Components = 0, Styles = 0, Theme = false }
	if type(data) ~= "table" then
		return false, "configuration must be a table"
	end
	if data.Theme and Themes.has(data.Theme) then
		local ok = self.Context:SetTheme(data.Theme, data.ThemeConfiguration)
		applied.Theme = ok == true
	end
	if type(data.Styles) == "table" then
		for category, styleId in pairs(data.Styles) do
			if Styles.get(styleId) then
				self.Context:SetStyleDefault(category, styleId)
				applied.Styles += 1
			end
		end
	end
	if type(data.StyleConfiguration) == "table" then
		for category, configuration in pairs(data.StyleConfiguration) do
			self.Context:SetCategoryConfiguration(category, configuration, { Replace = true })
		end
	end
	if type(data.Components) == "table" then
		for flag, entry in pairs(data.Components) do
			local component = self.Context.Store.get(flag)
			if component then
				local ok = component:Restore(entry, options)
				if ok then
					applied.Components += 1
				end
			end
		end
	end
	return true, nil, applied
end

function Config:Destroy()
	self.Memory = {}
	self.Context = nil
end

return Config
end)()

local __NEVA_Input_Keybinder = (function()
--[[
	NEVAHEXUI - Input/Keybinder
	Central keyboard manager. Owns every key binding in the library so conflicts
	can be detected, saved and restored, and so bindings are released when a
	component or window is destroyed.
]]

local Util = __NEVA_Core_Util

local Keybinder = {}
Keybinder.__index = Keybinder

Keybinder.Modes = { "Hold", "Toggle" }

function Keybinder.new(host, options)
	options = options or {}
	local self = setmetatable({}, Keybinder)
	self.Host = host
	self.Bindings = {}
	self.Order = {}
	self.Enabled = options.Enabled ~= false
	self.WarnOnConflict = options.WarnOnConflict ~= false
	self.OnConflict = options.OnConflict
	self.Conflicts = {}
	return self
end

function Keybinder:_connects(binding)
	local function handler(state)
		if not self.Enabled or not binding.Enabled or not binding.Bound then
			return
		end
		local mode = binding.Mode
		if mode == "Toggle" then
			if state == "Begin" then
				binding.Active = not binding.Active
				if binding.Callback then
					binding.Callback(binding.Active, "Toggle", binding)
				end
			end
		else
			if state == "Begin" then
				binding.Active = true
				if binding.Callback then
					binding.Callback(true, "Hold", binding)
				end
			end
		end
	end
	if binding.Connection then
		binding.Connection:Disconnect()
	end
	binding.Connection = self.Host.inputBind(binding.Key, handler)
end

function Keybinder:Bind(name, key, callback, options)
	options = options or {}
	assert(type(name) == "string" and name ~= "", "Keybinder:Bind expects a name")
	if self.Bindings[name] then
		self:Unbind(name)
	end
	local binding = {
		Name = name,
		Key = key,
		Callback = callback,
		Mode = options.Mode or "Hold",
		Enabled = options.Enabled ~= false,
		Bound = key ~= nil and key ~= false and key ~= "None",
		Active = false,
		Order = options.Order or #self.Order + 1,
		Owner = options.Owner,
	}
	self.Bindings[name] = binding
	table.insert(self.Order, name)
	if binding.Bound then
		self:_connects(binding)
	end
	self:_refreshConflicts()
	return binding
end

function Keybinder:Unbind(name)
	local binding = self.Bindings[name]
	if not binding then
		return false
	end
	if binding.Connection then
		binding.Connection:Disconnect()
		binding.Connection = nil
	end
	self.Bindings[name] = nil
	for index, candidate in ipairs(self.Order) do
		if candidate == name then
			table.remove(self.Order, index)
			break
		end
	end
	self:_refreshConflicts()
	return true
end

function Keybinder:SetKey(name, key)
	local binding = self.Bindings[name]
	if not binding then
		return false, ("unknown binding %q"):format(tostring(name))
	end
	binding.Key = key
	binding.Bound = key ~= nil and key ~= false and key ~= "None"
	if binding.Bound then
		self:_connects(binding)
	elseif binding.Connection then
		binding.Connection:Disconnect()
		binding.Connection = nil
	end
	self:_refreshConflicts()
	return true
end

function Keybinder:Get(name)
	return self.Bindings[name]
end

function Keybinder:List()
	local out = {}
	for _, name in ipairs(self.Order) do
		local binding = self.Bindings[name]
		table.insert(out, {
			Name = binding.Name,
			Key = binding.Key,
			Mode = binding.Mode,
			Enabled = binding.Enabled,
			Bound = binding.Bound,
			Active = binding.Active,
			Owner = binding.Owner,
		})
	end
	return out
end

function Keybinder:_refreshConflicts()
	local byKey = {}
	local duplicates = {}
	for _, name in ipairs(self.Order) do
		local binding = self.Bindings[name]
		if binding.Bound then
			local existing = byKey[binding.Key]
			if existing then
				if not duplicates[binding.Key] then
					duplicates[binding.Key] = { existing }
				end
				table.insert(duplicates[binding.Key], binding)
			else
				byKey[binding.Key] = binding
			end
		end
	end
	self.Conflicts = duplicates
	for key, list in pairs(duplicates) do
		if self.WarnOnConflict and self.OnConflict then
			self.OnConflict(key, list)
		end
	end
	return duplicates
end

function Keybinder:GetConflicts()
	local out = {}
	for key, list in pairs(self.Conflicts) do
		local names = {}
		for _, binding in ipairs(list) do
			table.insert(names, binding.Name)
		end
		table.insert(out, { Key = key, Names = names })
	end
	table.sort(out, function(a, b)
		return tostring(a.Key) < tostring(b.Key)
	end)
	return out
end

function Keybinder:SetEnabled(enabled)
	self.Enabled = enabled ~= false
	return self.Enabled
end

function Keybinder:IsKeyActive(key)
	for _, name in ipairs(self.Order) do
		local binding = self.Bindings[name]
		if binding.Key == key then
			return binding.Active == true
		end
	end
	return false
end

-- Programmatic trigger, used by tests and by custom component tooling.
function Keybinder:Fire(key, state)
	local fired = 0
	for _, name in ipairs(self.Order) do
		local binding = self.Bindings[name]
		if binding.Bound and binding.Enabled and binding.Key == key then
			fired += 1
			if binding.Mode == "Toggle" then
				binding.Active = not binding.Active
				if binding.Callback then
					binding.Callback(binding.Active, "Toggle", binding)
				end
			else
				binding.Active = state ~= "End"
				if binding.Callback then
					binding.Callback(binding.Active, "Hold", binding)
				end
			end
		end
	end
	return fired
end

function Keybinder:Save()
	local out = {}
	for _, name in ipairs(self.Order) do
		local binding = self.Bindings[name]
		out[name] = { Key = binding.Key, Mode = binding.Mode, Enabled = binding.Enabled }
	end
	return out
end

function Keybinder:Load(data)
	if type(data) ~= "table" then
		return false, "expected a table of bindings"
	end
	for name, entry in pairs(data) do
		if type(entry) == "table" and self.Bindings[name] then
			if entry.Key ~= nil then
				self:SetKey(name, entry.Key)
			end
			if entry.Mode ~= nil then
				self.Bindings[name].Mode = entry.Mode
			end
			if entry.Enabled ~= nil then
				self.Bindings[name].Enabled = entry.Enabled ~= false
			end
		end
	end
	return true
end

function Keybinder:Destroy()
	for _, name in ipairs(self.Order) do
		local binding = self.Bindings[name]
		if binding.Connection then
			binding.Connection:Disconnect()
		end
	end
	self.Bindings = {}
	self.Order = {}
	self.Conflicts = {}
end

return Keybinder
end)()

local __NEVA_Core_Container = (function()
--[[
	NEVAHEXUI - Core/Container
	Shared implementation for tabs, sections, group boxes, cards and other
	content holders. Containers get one Create<Type> method per registered
	component factory, so the public API surface always matches the component
	catalogue instead of a hand-maintained list.
]]

local Util = __NEVA_Core_Util
local Component = __NEVA_Core_Component
local Keybinder = __NEVA_Input_Keybinder

local Container = {}
Container.__index = Container

Container.Kinds = {
	Tab = "Tab",
	SubTab = "SubTab",
	Section = "Section",
	Groupbox = "Groupbox",
	Card = "Card",
	Column = "Column",
	Collapsible = "Collapsible",
	DependencyBox = "DependencyBox",
	Panel = "Panel",
}

-- options = {
--   Kind, Name, Icon, Parent (instance), Window, Layout = {Order, Padding},
--   Collapsible = bool, Collapsed = bool, Dependency = spec
-- }
function Container.new(context, options)
	options = options or {}
	assert(context, "Container.new expects a context")
	local self = setmetatable({}, Container)
	self.Context = context
	self.Kind = options.Kind or "Section"
	self.Name = options.Name or self.Kind
	self.Icon = options.Icon
	self.Id = Util.uniqueId(self.Kind)
	self.Window = options.Window or options.Scope
	self.Parent = options.Parent
	self.Order = options.Order or #(options.Siblings or {}) + 1
	self.Children = {}
	self.Subtabs = {}
	self.Subcontainers = {}
	self.Collapsed = options.Collapsed == true
	self.Collapsible = options.Collapsible == true
	self.Dependency = options.Dependency
	self.Destroyed = false
	self.Visible = options.Visible ~= false

	local host = context.Host
	self.Container = host.new("Frame", {
		Name = self.Kind .. "_" .. self.Name,
		BackgroundTransparency = 1,
		Size = host.udim2(1, 0, 1, 0),
		Visible = self.Visible,
		LayoutOrder = self.Order,
	}, self.Parent)

	self.Instance = host.new("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = host.udim2(1, 0, 1, 0),
		LayoutOrder = 2,
	}, self.Container)

	local padding = options.Padding
	if padding == nil then
		padding = context.Tokens.Padding or 10
	end
	if self.Kind == "Section" or self.Kind == "Groupbox" or self.Kind == "Card" or self.Kind == "Collapsible" then
		host.new("UIPadding", {
			PaddingLeft = host.udim(0, padding),
			PaddingRight = host.udim(0, padding),
			PaddingTop = host.udim(0, padding),
			PaddingBottom = host.udim(0, padding),
		}, self.Instance)
	end
	self.LayoutObject = host.new("UIListLayout", {
		FillDirection = host.enumItem("FillDirection", "Vertical"),
		Padding = host.udim(0, context.Tokens.Spacing or 8),
		SortOrder = host.enumItem("SortOrder", "LayoutOrder"),
	}, self.Instance)
	self.AutomaticCanvasSize = nil

	if options.Dependency then
		self:SetDependency(options.Dependency)
	end

	self:_installFactories()
	self:_installContainerFactories()
	return self
end

function Container:_installFactories()
	local factories = self.Context.Factories
	local names = Util.keys(factories)
	for _, typeName in ipairs(names) do
		local class = factories[typeName]
		if type(class) == "table" and class.Type == typeName then
			local methodName = "Create" .. typeName
			if self[methodName] == nil then
				self[methodName] = function(container, spec)
					return container.Context:Create(typeName, container, spec)
				end
			end
		end
	end
end

-- Container kinds, installable on any container. This is what makes
-- `Tab:CreateSection{...}`, `Section:CreateGroupbox{...}` and
-- `Tab:CreateDependencyBox{...}` work: nested containers are created with the
-- same lifecycle, parenting and dependency support as window-level ones.
local SubKinds = { "Section", "Groupbox", "Card", "Collapsible", "DependencyBox", "Column" }

function Container:_installContainerFactories()
	for _, kind in ipairs(SubKinds) do
		local methodName = "Create" .. kind
		if self[methodName] == nil then
			self[methodName] = function(container, options)
				options = options or {}
				local child = Container.new(container.Context, {
					Kind = kind,
					Name = options.Name or kind,
					Icon = options.Icon,
					Order = options.Order,
					Collapsible = options.Collapsible,
					Collapsed = options.Collapsed,
					Padding = options.Padding,
					Dependency = options.Dependency or options.DependsOn,
					Parent = options.Parent or container.Instance or container.Container,
					Window = container.Window,
				})
				table.insert(container.Subcontainers, child)
				return child
			end
		end
	end
end

function Container:Create(componentType, spec)
	return self.Context:Create(componentType, self, spec)
end

-- Optional containers may be collapsed; the window keeps the layout in sync.
function Container:SetCollapsed(collapsed)
	self.Collapsed = collapsed == true
	if self.Instance then
		self.Instance.Visible = not self.Collapsed
	end
	if self.Window and self.Window.RefreshLayout then
		self.Window:RefreshLayout()
	end
	return self.Collapsed
end

function Container:ToggleCollapsed()
	return self:SetCollapsed(not self.Collapsed)
end

function Container:SetDependency(spec)
	self.Dependency = spec
	local hub = self.Context.DependencyHub
	local Dependency = __NEVA_Core_Dependency
	local flags = Dependency.flagsIn(spec, {})
	self.DependencyConnection = hub:subscribe(flags, function()
		self:EvaluateDependency()
	end)
	self:EvaluateDependency()
	return self
end

function Container:EvaluateDependency()
	if not self.Dependency then
		self.DependenciesMet = true
		return true
	end
	local Dependency = __NEVA_Core_Dependency
	local hub = self.Context.DependencyHub
	local met = Dependency.matches(self.Dependency, function(flag)
		return hub:getValue(flag)
	end)
	self.DependenciesMet = met
	if self.Container then
		self.Container.Visible = met and self.Visible
	end
	if self.Window and self.Window.RefreshLayout then
		self.Window:RefreshLayout()
	end
	return met
end

function Container:SetVisible(visible)
	self.Visible = visible ~= false
	if self.Container then
		self.Container.Visible = self.Visible and self.DependenciesMet ~= false
	end
	if self.Window and self.Window.RefreshLayout then
		self.Window:RefreshLayout()
	end
	return self.Visible
end

function Container:IsVisible()
	return self.Visible and self.DependenciesMet ~= false
end

function Container:SetName(name)
	self.Name = tostring(name)
	if self.Label then
		self.Label.Text = self.Name
	end
	if self.Container then
		self.Container.Name = self.Kind .. "_" .. self.Name
	end
	return self.Name
end

function Container:GetComponentCount()
	local total = 0
	for _, child in ipairs(self.Children) do
		if not child.Destroyed then
			total += 1
		end
	end
	for _, child in ipairs(self.Subcontainers) do
		if not child.Destroyed then
			total += child:GetComponentCount()
		end
	end
	return total
end

function Container:GetComponents()
	return self.Children
end

function Container:AddChild(component)
	table.insert(self.Children, component)
end

function Container:GetSize()
	if not self.Instance then
		return 0
	end
	local layout = self.LayoutObject
	if layout and layout.AbsoluteContentSize then
		return layout.AbsoluteContentSize.Y
	end
	return 0
end

function Container:Destroy()
	if self.Destroyed then
		return false
	end
	self.Destroyed = true
	for _, component in ipairs(self.Children) do
		if not component.Destroyed then
			component:Destroy()
		end
	end
	for _, subtab in ipairs(self.Subtabs) do
		subtab:Destroy()
	end
	for _, child in ipairs(self.Subcontainers) do
		if not child.Destroyed then
			child:Destroy()
		end
	end
	if self.DependencyConnection then
		self.DependencyConnection:Disconnect()
	end
	local host = self.Context.Host
	if self.Container then
		host.destroy(self.Container)
	end
	self.Children = {}
	self.Subtabs = {}
	self.Subcontainers = {}
	return true
end

return Container
end)()

local __NEVA_Core_Logger = (function()
--[[
	NEVAHEXUI - Core/Logger
	Diagnostics, warnings and debug output.
]]

local Logger = {}
Logger.__index = Logger

Logger.Levels = {
	Debug = 10,
	Info = 20,
	Warn = 30,
	Error = 40,
	Silent = 100,
}

function Logger.new(options)
	options = options or {}
	return setmetatable({
		Level = options.Level or Logger.Levels.Info,
		Prefix = options.Prefix or "NEVAHEXUI",
		Sink = options.Sink,
		History = {},
		MaxHistory = options.MaxHistory or 200,
	}, Logger)
end

function Logger:_write(level, message)
	local line = ("[%s][%s] %s"):format(self.Prefix, level, message)
	table.insert(self.History, { level = level, message = message, line = line })
	while #self.History > self.MaxHistory do
		table.remove(self.History, 1)
	end
	if self.Sink then
		self.Sink(level, message, line)
		return line
	end
	if level == "Error" then
		-- `warn` exists in Roblox but not in every Luau runtime (the CLI test
		-- host included); logging must never be the thing that crashes a caller.
		if type(warn) == "function" then
			warn(line)
		else
			print(line)
		end
	elseif self.Level <= Logger.Levels[level] then
		print(line)
	end
	return line
end

function Logger:Debug(message)
	if self.Level <= Logger.Levels.Debug then
		return self:_write("Debug", message)
	end
	return nil
end

function Logger:Info(message)
	if self.Level <= Logger.Levels.Info then
		return self:_write("Info", message)
	end
	return nil
end

function Logger:Warn(message)
	if self.Level <= Logger.Levels.Warn then
		return self:_write("Warn", message)
	end
	return nil
end

function Logger:Error(message)
	return self:_write("Error", message)
end

function Logger:GetHistory()
	return self.History
end

function Logger:SetLevel(level)
	if type(level) == "string" then
		local resolved = Logger.Levels[level]
		assert(resolved, ("unknown log level %q"):format(level))
		self.Level = resolved
	else
		self.Level = level
	end
end

return Logger
end)()

local __NEVA_State_Store = (function()
--[[
	NEVAHEXUI - State/Store
	Component and flag registry. Component objects and registry entries stay
	synchronised because the component is the only thing that writes state: the
	store holds references, never copies of values.

	Duplicate flags are handled deterministically: the first component registered
	with a flag becomes the canonical registry entry, later duplicates stay
	reachable through Store.getAll(flag) and are reported as warnings.
]]

local Util = __NEVA_Core_Util

local Store = {}

Store.Components = {}
Store.ByFlag = {}
Store.ByFlagAll = {}
Store.ByType = {}
Store.Order = {}
Store.Duplicates = {}
Store.Warnings = {}

function Store.reset()
	Store.Components = {}
	Store.ByFlag = {}
	Store.ByFlagAll = {}
	Store.ByType = {}
	Store.Order = {}
	Store.Duplicates = {}
	Store.Warnings = {}
end

function Store.register(component)
	assert(component and component.Id, "Store.register expects a component with an Id")
	if Store.Components[component.Id] then
		return false, ("component id %q is already registered"):format(component.Id)
	end
	Store.Components[component.Id] = component
	table.insert(Store.Order, component.Id)

	local flag = component.Flag
	if flag and flag ~= "" then
		local list = Store.ByFlagAll[flag]
		if not list then
			list = {}
			Store.ByFlagAll[flag] = list
		end
		if Store.ByFlag[flag] == nil then
			Store.ByFlag[flag] = component
		else
			component.DuplicateOf = Store.ByFlag[flag]
			table.insert(Store.Duplicates, {
				Flag = flag,
				Canonical = Store.ByFlag[flag].Id,
				Duplicate = component.Id,
				Type = component.Type,
			})
			table.insert(Store.Warnings, ("duplicate flag %q registered by %s; the first component stays canonical")
				:format(flag, component.Type))
		end
		table.insert(list, component)
	end

	local typeTable = Store.ByType[component.Type]
	if not typeTable then
		typeTable = {}
		Store.ByType[component.Type] = typeTable
	end
	typeTable[flag or component.Id] = component

	return true, nil
end

function Store.unregister(component)
	if type(component) == "string" then
		component = Store.Components[component]
	end
	if not component then
		return false
	end
	if Store.Components[component.Id] ~= component then
		return false
	end
	Store.Components[component.Id] = nil
	for index, id in ipairs(Store.Order) do
		if id == component.Id then
			table.remove(Store.Order, index)
			break
		end
	end
	local flag = component.Flag
	if flag and Store.ByFlagAll[flag] then
		local list = Store.ByFlagAll[flag]
		for index, candidate in ipairs(list) do
			if candidate == component then
				table.remove(list, index)
				break
			end
		end
		if #list == 0 then
			Store.ByFlagAll[flag] = nil
		end
		if Store.ByFlag[flag] == component then
			Store.ByFlag[flag] = list[1]
			if Store.ByFlag[flag] then
				Store.ByFlag[flag].DuplicateOf = nil
			end
		end
	end
	local typeTable = Store.ByType[component.Type]
	if typeTable then
		if typeTable[flag or component.Id] == component then
			typeTable[flag or component.Id] = nil
		end
		if next(typeTable) == nil then
			Store.ByType[component.Type] = nil
		end
	end
	return true
end

function Store.get(flag)
	if flag == nil then
		return nil
	end
	return Store.ByFlag[flag] or Store.Components[flag]
end

function Store.getById(id)
	return Store.Components[id]
end

function Store.getAll(flag)
	local list = Store.ByFlagAll[flag]
	if not list then
		return {}
	end
	local copy = {}
	for _, component in ipairs(list) do
		table.insert(copy, component)
	end
	return copy
end

function Store.list(typeName)
	local typeTable = Store.ByType[typeName]
	if not typeTable then
		return {}
	end
	local out = {}
	for _, key in ipairs(Util.keys(typeTable)) do
		table.insert(out, typeTable[key])
	end
	return out
end

function Store.typeNames()
	return Util.keys(Store.ByType)
end

function Store.count()
	return #Store.Order
end

function Store.duplicates()
	return Store.Duplicates
end

function Store.flags()
	return Util.keys(Store.ByFlagAll)
end

function Store.snapshot()
	local values = {}
	for _, component in ipairs(Store.list("__all")) do
		values[component.Flag or component.Id] = component:GetValue()
	end
	return values
end

-- Reading every value pretty-prints through Component:Serialize so that config
-- persistence and diagnostics share one representation.
function Store.serialize(types)
	local out = {}
	local names = types or Store.typeNames()
	for _, typeName in ipairs(names) do
		for _, component in ipairs(Store.list(typeName)) do
			if Util.isCallable(component.Serialize) then
				out[component.Flag or component.Id] = component:Serialize()
			end
		end
	end
	return out
end

function Store.all()
	local out = {}
	for _, id in ipairs(Store.Order) do
		table.insert(out, Store.Components[id])
	end
	return out
end

return Store
end)()

local __NEVA_Core_Context = (function()
--[[
	NEVAHEXUI - Core/Context
	The render/lifecycle context handed to every window, container and component.
	It carries the host back end, resolved theme tokens, style/category defaults,
	registries, diagnostics and the factory table used by containers to create
	components.
]]

local Util = __NEVA_Core_Util
local Logger = __NEVA_Core_Logger
local Store = __NEVA_State_Store
local Dependency = __NEVA_Core_Dependency
local Themes = __NEVA_Themes_Registry
local Styles = __NEVA_Styles_Registry

local Context = {}
Context.__index = Context

function Context.new(options)
	options = options or {}
	local self = setmetatable({}, Context)
	self.Options = options
	self.Host = options.Host
	self.Logger = options.Logger or Logger.new({ Level = options.LogLevel or Logger.Levels.Warn })
	self.Store = options.Store or Store
	self.DependencyHub = Dependency.newHub(self.Store)
	self.ThemeRegistry = Themes
	self.StyleRegistry = Styles
	self.ThemeId = options.Theme or "dark"
	self.ThemeOverrides = Util.deepCopy(options.ThemeConfiguration or {})
	self.StyleDefaults = Util.deepCopy(options.Styles or {})
	self.CategoryConfigurations = Util.deepCopy(options.StyleConfiguration or {})
	self.GlobalDefaults = Util.deepCopy(options.GlobalDefaults or {})
	self.Factories = {}
	self.Singletons = {}
	self.Diagnostics = { Errors = {}, Warnings = {}, Log = {} }
	self.Components = {}
	self.Scopes = {}
	self.Destroyed = false
	-- A context is also a valid render context for window chrome and other
	-- library-owned surfaces, so the fields Surface helpers read always exist.
	self.Configuration = {}
	self.Props = { Name = options.Name or "NEVAHEXUI" }
	self.State = {}
	self.Type = "Context"
	self:RefreshTheme()
	return self
end

function Context:RefreshTheme()
	local tokens, record, errors, warnings = self.ThemeRegistry.resolve(self.ThemeId, self.ThemeOverrides)
	self.Tokens = self.ThemeRegistry.forHost(self.Host, tokens)
	self.RawTokens = tokens
	self.ThemeRecord = record
	for _, message in ipairs(errors or {}) do
		self:Diagnostic("Error", ("theme %s: %s"):format(tostring(self.ThemeId), message))
	end
	for _, message in ipairs(warnings or {}) do
		self:Diagnostic("Warn", ("theme %s: %s"):format(tostring(self.ThemeId), message))
	end
	return self.Tokens
end

function Context:SetTheme(themeId, overrides)
	if not self.ThemeRegistry.has(themeId) then
		return false, ("unknown theme %q"):format(tostring(themeId))
	end
	self.ThemeId = themeId
	if overrides ~= nil then
		self.ThemeOverrides = Util.deepCopy(overrides)
	end
	self:RefreshTheme()
	for _, component in ipairs(self:AllComponents()) do
		if not component.Destroyed then
			component:_applyState()
		end
	end
	return true
end

function Context:GetTheme()
	return self.ThemeId
end

function Context:Diagnostic(level, message)
	local entry = { Level = level, Message = message, At = os and os.clock and os.clock() or nil }
	table.insert(self.Diagnostics.Log, entry)
	if level == "Error" then
		table.insert(self.Diagnostics.Errors, message)
		self.Logger:Error(message)
	elseif level == "Warn" then
		table.insert(self.Diagnostics.Warnings, message)
		self.Logger:Warn(message)
	else
		self.Logger:Info(message)
	end
	if #self.Diagnostics.Log > 500 then
		table.remove(self.Diagnostics.Log, 1)
	end
	return entry
end

function Context:SetStyleDefault(category, styleId)
	self.StyleDefaults[category] = styleId
	return true
end

function Context:StyleDefaultFor(componentType)
	local configured = self.StyleDefaults[componentType]
	if configured then
		return configured
	end
	local global = self.GlobalDefaults.Styles and self.GlobalDefaults.Styles[componentType]
	if global then
		return global
	end
	local defaultId = self.StyleRegistry.defaultStyleId(componentType)
	return defaultId
end

function Context:CategoryConfigurationFor(componentType)
	local configured = self.CategoryConfigurations[componentType]
	local global = self.GlobalDefaults.StyleConfiguration and self.GlobalDefaults.StyleConfiguration[componentType]
	if configured and global then
		return Util.deepMerge(global, configured)
	end
	return Util.deepCopy(configured or global or {})
end

function Context:SetCategoryConfiguration(componentType, configuration, options)
	options = options or {}
	if options.Replace then
		self.CategoryConfigurations[componentType] = Util.deepCopy(configuration)
	else
		self.CategoryConfigurations[componentType] = Util.deepMerge(
			self.CategoryConfigurations[componentType] or {},
			configuration
		)
	end
	for _, component in ipairs(self:ComponentsOfType(componentType)) do
		if not component.Destroyed then
			component:Refresh("category-configuration")
		end
	end
	return self.CategoryConfigurations[componentType]
end

function Context:RegisterComponent(component)
	table.insert(self.Components, component)
	local ok, err = self.Store.register(component)
	if not ok then
		self:Diagnostic("Warn", err or "component registration failed")
	end
	component:EvaluateDependencies()
	return component
end

function Context:AllComponents()
	return self.Components
end

function Context:ComponentsOfType(componentType)
	local out = {}
	for _, component in ipairs(self.Components) do
		if component.Type == componentType then
			table.insert(out, component)
		end
	end
	return out
end

function Context:ComponentCount()
	return #self.Components
end

function Context:RegisterScope(scope)
	table.insert(self.Scopes, scope)
	return scope
end

function Context:FindComponent(flagOrId)
	return self.Store.get(flagOrId)
end

function Context:Factory(componentType)
	return self.Factories[componentType]
end

function Context:Create(componentType, container, spec)
	local class = self.Factories[componentType]
	assert(class, ("NEVAHEXUI: no component factory registered for %q"):format(tostring(componentType)))
	local Component = __NEVA_Core_Component
	local component = Component.create(class, self, container, spec)
	-- Registration is centralised here: every component is counted by its
	-- container and reachable through the synchronised store/registries.
	if container and container.AddChild then
		container:AddChild(component)
	end
	self:RegisterComponent(component)
	if spec and spec.DependsOn or (spec and spec.Dependencies) then
		component:EvaluateDependencies()
	end
	return component
end

function Context:Summary()
	return {
		Theme = self.ThemeId,
		Host = self.Host.Kind,
		Components = #self.Components,
		Scopes = #self.Scopes,
		Styles = self.StyleRegistry.count(),
		Themes = self.ThemeRegistry.count(),
		Errors = #self.Diagnostics.Errors,
		Warnings = #self.Diagnostics.Warnings,
	}
end

function Context:Destroy()
	if self.Destroyed then
		return
	end
	self.Destroyed = true
	for _, scope in ipairs(self.Scopes) do
		if scope.Destroy then
			pcall(function()
				scope:Destroy()
			end)
		end
	end
	for _, component in ipairs(self.Components) do
		if not component.Destroyed and component.Destroy then
			pcall(function()
				component:Destroy()
			end)
		end
	end
	self.Components = {}
	self.Store.reset()
end

return Context
end)()

local __NEVA_Core_Layouts = (function()
--[[
	NEVAHEXUI - Core/Layouts
	Window layout definitions. A layout owns the arrangement of the window chrome:
	where navigation lives, how the content area is sized, whether the window is
	draggable or resizable, and how touch friendly the spacing is. Components, tabs
	and styles are identical across layouts, so switching layout never recreates a
	single component.
]]

local Layouts = {}
local definitions = {}
local order = {}

function Layouts.register(definition)
	assert(type(definition) == "table", "Layouts.register expects a table")
	assert(type(definition.Id) == "string" and definition.Id ~= "", "layout definitions need an Id")
	if definitions[definition.Id] then
		return definitions[definition.Id]
	end
	local record = {
		Id = definition.Id,
		Name = definition.Name or definition.Id,
		Description = definition.Description or "",
		Nav = definition.Nav or "Left",
		NavWidth = definition.NavWidth or 156,
		Draggable = definition.Draggable ~= false,
		Resizable = definition.Resizable == true,
		TouchFriendly = definition.TouchFriendly == true,
		Density = definition.Density or 1,
		Chrome = definition.Chrome or "Standard",
		Sizing = definition.Sizing or {
			Size = { 0.62, 480, 0.68, 360 },
			MinSize = { 420, 300 },
			MaxSize = { 1100, 780 },
		},
		Build = definition.Build,
	}
	definitions[record.Id] = record
	table.insert(order, record.Id)
	return record
end

function Layouts.get(id)
	return definitions[id or "Sidebar"]
end

function Layouts.has(id)
	return definitions[id] ~= nil
end

function Layouts.ids()
	local out = {}
	for _, id in ipairs(order) do
		table.insert(out, id)
	end
	return out
end

function Layouts.list()
	local out = {}
	for _, id in ipairs(order) do
		local definition = definitions[id]
		table.insert(out, {
			Id = definition.Id,
			Name = definition.Name,
			Description = definition.Description,
			Nav = definition.Nav,
			Draggable = definition.Draggable,
			Resizable = definition.Resizable,
			TouchFriendly = definition.TouchFriendly,
		})
	end
	return out
end

Layouts.register({
	Id = "Sidebar",
	Name = "Sidebar",
	Description = "Vertical navigation column with grouped content on the right.",
	Nav = "Left",
	NavWidth = 156,
	Draggable = true,
	Resizable = true,
})

Layouts.register({
	Id = "TopTabs",
	Name = "Top tabs",
	Description = "Horizontal tab strip above the content, with overflow scrolling.",
	Nav = "Top",
	NavWidth = 0,
	Draggable = true,
	Resizable = true,
})

Layouts.register({
	Id = "Floating",
	Name = "Floating",
	Description = "Compact floating panel with minimal chrome and a header drag handle.",
	Nav = "Left",
	NavWidth = 132,
	Draggable = true,
	Resizable = true,
	Density = 0.9,
	Chrome = "Minimal",
})

Layouts.register({
	Id = "Compact",
	Name = "Compact / mobile",
	Description = "Touch friendly single-column layout with a horizontal nav strip.",
	Nav = "Top",
	NavWidth = 0,
	TouchFriendly = true,
	Resizable = false,
	Density = 1.15,
	Sizing = {
		Size = { 0.94, 0, 0.9, 0 },
		MinSize = { 300, 260 },
		MaxSize = { 720, 900 },
	},
})

Layouts.register({
	Id = "IconSidebar",
	Name = "Icon sidebar",
	Description = "Narrow icon-only navigation column that expands to reveal tab labels.",
	Nav = "Left",
	NavWidth = 52,
	Draggable = true,
	Resizable = true,
	Density = 0.95,
})

Layouts.register({
	Id = "MultiColumn",
	Name = "Multi-column dashboard",
	Description = "Sidebar navigation with a two-column card grid for dashboard content.",
	Nav = "Left",
	NavWidth = 148,
	Draggable = true,
	Resizable = true,
})

return Layouts
end)()

local __NEVA_Styles_Helpers = (function()
--[[
	NEVAHEXUI - Styles/Helpers
	Shared tree-building helpers used by every style renderer. Keeping instance
	creation here means styles never touch Roblox APIs directly, and it keeps the
	frameworks' style files small and readable.
]]

local Color = __NEVA_Utilities_Color

local Helpers = {}

function Helpers.new(host, className, props, parent)
	return host.new(className, props, parent)
end

function Helpers.corner(host, parent, radius)
	if radius == nil or radius <= 0 then
		return nil
	end
	return host.new("UICorner", { CornerRadius = host.udim(0, radius) }, parent)
end

function Helpers.stroke(host, parent, colour, thickness, transparency)
	if not colour then
		return nil
	end
	return host.new("UIStroke", {
		Color = colour,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = host.enumItem("ApplyStrokeMode", "Contextual"),
	}, parent)
end

function Helpers.gradient(host, parent, from, to, rotation, transparency)
	if not from or not to then
		return nil
	end
	return host.new("UIGradient", {
		Color = {
			__nevaColorSequence = true,
			From = from,
			To = to,
		},
		Rotation = rotation or 90,
		Transparency = transparency and {
			__nevaNumberSequence = true,
			From = transparency[1] or 0,
			To = transparency[2] or 0,
		} or nil,
	}, parent)
end

function Helpers.padding(host, parent, left, right, top, bottom)
	assert(parent, "Helpers.padding needs a parent")
	if parent.__nevaPaddingOwner ~= nil then
		return parent.__nevaPaddingOwner
	end
	local padding = host.new("UIPadding", {
		PaddingLeft = host.udim(0, left or 0),
		PaddingRight = host.udim(0, right or left or 0),
		PaddingTop = host.udim(0, top or 0),
		PaddingBottom = host.udim(0, bottom or top or 0),
	}, parent)
	return padding
end

function Helpers.column(host, parent, options)
	options = options or {}
	return host.new("UIListLayout", {
		FillDirection = host.enumItem("FillDirection", options.Horizontal and "Horizontal" or "Vertical"),
		Padding = host.udim(0, options.Padding or 0),
		SortOrder = host.enumItem("SortOrder", options.LayoutOrder and "LayoutOrder" or "Name"),
		HorizontalAlignment = host.enumItem("HorizontalAlignment", options.HorizontalAlignment or "Left"),
		VerticalAlignment = host.enumItem("VerticalAlignment", options.VerticalAlignment or "Top"),
	}, parent)
end

function Helpers.text(host, parent, props)
	local merged = { ClassName = "TextLabel", BackgroundTransparency = 1 }
	for key, value in pairs(props or {}) do
		merged[key] = value
	end
	merged.ClassName = nil
	return host.new("TextLabel", merged, parent)
end

function Helpers.button(host, parent, props)
	local merged = { AutoButtonColor = false, BorderSizePixel = 0 }
	for key, value in pairs(props or {}) do
		merged[key] = value
	end
	merged.ClassName = nil
	return host.new("TextButton", merged, parent)
end

function Helpers.frame(host, parent, props)
	local merged = { BorderSizePixel = 0 }
	for key, value in pairs(props or {}) do
		merged[key] = value
	end
	merged.ClassName = nil
	return host.new("Frame", merged, parent)
end

function Helpers.scroller(host, parent, props)
	local merged = {
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		CanvasSize = host.udim2(0, 0, 0, 0),
		BackgroundTransparency = 1,
	}
	for key, value in pairs(props or {}) do
		merged[key] = value
	end
	merged.ClassName = nil
	return host.new("ScrollingFrame", merged, parent)
end

-- Accepts NEVA colours, hex strings, real Color3 values or mock colours.
function Helpers.colour(host, value)
	local normalised, message = Color.normalize(value)
	if not normalised then
		return nil, message
	end
	return host.color(normalised.R * 255, normalised.G * 255, normalised.B * 255, normalised.A)
end

function Helpers.transparencyOf(value, fallback)
	local normalised = Color.normalize(value)
	if not normalised then
		return fallback or 0
	end
	return 1 - normalised.A
end

-- Reads a token that may be either a prepared host value or a raw token value.
function Helpers.token(host, tokens, key, fallback)
	local value = tokens[key]
	if value == nil then
		if fallback ~= nil then
			return Helpers.colour(host, fallback)
		end
		return fallback
	end
	if type(value) == "table" and value.R and not value.__nevaMockColor then
		return value
	end
	return value
end

function Helpers.colourToken(host, tokens, key, fallback)
	local value = tokens[key]
	if value == nil then
		value = fallback
	end
	if value == nil then
		return nil
	end
	if type(value) == "table" and (value.__nevaMockColor or value.R ~= nil) then
		return value
	end
	return Helpers.colour(host, value)
end

function Helpers.fontToken(host, tokens, key, fallback)
	local value = tokens[key]
	if type(value) == "table" and value.__nevaMockColor == nil and value.R == nil and value.EnumType == nil and value.Name == nil then
		return value
	end
	if type(value) == "string" then
		return host.font(value)
	end
	return host.font(fallback or "GothamMedium")
end

return Helpers
end)()

local __NEVA_Styles_Surface = (function()
--[[
	NEVAHEXUI - Styles/Surface
	Shared composition helpers used by every style renderer: rows, panels,
	labelled slots, hit areas and animation. Styles read colours through
	this module so a component's resolved configuration always beats the theme
	token fallback, which is the documented theme/style precedence.
]]

local Helpers = __NEVA_Styles_Helpers
local Color = __NEVA_Utilities_Color
local Presets = __NEVA_Animation_Presets

local Surface = {}

function Surface.color(ctx, value, tokenKey)
	if value ~= nil then
		local resolved = Helpers.colour(ctx.Host, value)
		if resolved ~= nil then
			return resolved
		end
	end
	if tokenKey ~= nil then
		local tokenValue = ctx.Tokens[tokenKey]
		if tokenValue ~= nil then
			return tokenValue
		end
	end
	return ctx.Tokens.SurfaceAlt or ctx.Tokens.Surface
end

function Surface.number(ctx, value, tokenKey, fallback)
	if type(value) == "number" then
		return value
	end
	if tokenKey ~= nil and type(ctx.Tokens[tokenKey]) == "number" then
		return ctx.Tokens[tokenKey]
	end
	return fallback or 0
end

function Surface.transparency(ctx, value, tokenKey, fallback)
	if type(value) == "number" then
		return value
	end
	if tokenKey ~= nil and type(ctx.Tokens[tokenKey]) == "number" then
		return ctx.Tokens[tokenKey]
	end
	return fallback or 0
end

function Surface.font(ctx, value)
	if type(value) == "string" then
		return ctx.Host.font(value)
	end
	return ctx.Tokens.Font
end

function Surface.animationSpec(ctx)
	local config = ctx.Configuration
	local preset = config.Animation
	if type(preset) == "string" then
		return preset
	end
	local duration = config.AnimationDuration
	if type(duration) == "number" then
		return {
			Name = "Inline",
			Duration = duration,
			Easing = config.Easing or ctx.Tokens.Easing or "Quad",
			Direction = config.AnimationDirection or "Out",
		}
	end
	return "smooth"
end

function Surface.animate(ctx, instance, goal)
	local resolved, name = Presets.get(Surface.animationSpec(ctx))
	if name == "none" or (type(resolved) == "table" and resolved.Duration <= 0) then
		return ctx.Host.set(instance, goal)
	end
	return ctx.Host.tween(instance, goal, ctx.Host.tweenInfo(resolved.Duration, resolved.Easing, resolved.Direction))
end

-- Labelled slot: the standard "name on the left, control on the right" row.
function Surface.slot(ctx, options)
	options = options or {}
	local host = ctx.Host
	local config = ctx.Configuration
	local height = options.Height or config.RowHeight or 28
	local root = host.new("Frame", {
		Name = options.Name or (ctx.Type .. "Row"),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = options.Size or host.udim2(1, 0, 0, height),
		LayoutOrder = options.Order or 0,
		ClipsDescendants = options.ClipsDescendants == true,
	}, options.Parent)
	local slot = { Root = root, Host = host }

	local hasLabel = options.Label ~= false and (options.LabelText or ctx.Props.Name)
	if hasLabel then
		local controlWidth = options.ControlWidth or 0
		local labelArea = host.new("Frame", {
			Name = "LabelArea",
			BackgroundTransparency = 1,
			Size = host.udim2(1, -controlWidth - (controlWidth > 0 and 12 or 0), 1, 0),
			Position = host.udim2(0, 0, 0, 0),
		}, root)
		slot.LabelArea = labelArea
		local description = options.Description
		if description == nil then
			description = ctx.Props.Description
		end
		local hasDescription = type(description) == "string" and description ~= ""
		slot.Label = host.new("TextLabel", {
			Name = "Label",
			BackgroundTransparency = 1,
			Size = hasDescription and host.udim2(1, 0, 0, math.max(12, height * 0.55)) or host.udim2(1, 0, 1, 0),
			Text = options.LabelText or ctx.Props.Name or "",
			TextColor3 = ctx.Tokens.Text,
			Font = ctx.Tokens.Font,
			TextSize = config.TextSize or ctx.Tokens.FontSize or 13,
			TextXAlignment = host.enumItem("TextXAlignment", "Left"),
			TextYAlignment = host.enumItem("TextYAlignment", hasDescription and "Top" or "Center"),
			TextTruncate = host.enumItem("TextTruncate", "AtEnd"),
		}, labelArea)
		if hasDescription then
			slot.Description = host.new("TextLabel", {
				Name = "Description",
				BackgroundTransparency = 1,
				Size = host.udim2(1, 0, 0, math.max(10, height * 0.4)),
				Position = host.udim2(0, 0, 1, -math.max(10, height * 0.4)),
				Text = description,
				TextColor3 = ctx.Tokens.TextMuted,
				Font = ctx.Tokens.Font,
				TextSize = config.DescriptionTextSize or math.max(10, (config.TextSize or ctx.Tokens.FontSize or 13) - 2),
				TextXAlignment = host.enumItem("TextXAlignment", "Left"),
				TextYAlignment = host.enumItem("TextYAlignment", "Bottom"),
				TextTruncate = host.enumItem("TextTruncate", "AtEnd"),
			}, labelArea)
		end
	end

	if options.ControlWidth and options.ControlWidth > 0 then
		slot.ControlArea = host.new("Frame", {
			Name = "ControlArea",
			BackgroundTransparency = 1,
			Size = host.udim2(0, options.ControlWidth, 1, 0),
			Position = host.udim2(1, -options.ControlWidth, 0, 0),
		}, root)
	end

	return slot
end

-- Panel with themed background, optional corner radius and stroke.
function Surface.panel(ctx, parent, options)
	options = options or {}
	local host = ctx.Host
	local config = ctx.Configuration
	-- `Button` makes the panel a real press surface. A Frame owns no
	-- MouseButton events, and an inactive Frame never receives InputBegan
	-- either, so anything clickable has to be a GuiButton.
	local props = {
		Name = options.Name or "Panel",
		BackgroundColor3 = Surface.color(ctx, options.Background, options.Token or "SurfaceAlt"),
		BackgroundTransparency = options.Transparency or 0,
		BorderSizePixel = 0,
		Size = options.Size or host.udim2(1, 0, 0, options.Height or 32),
		Position = options.Position,
		Visible = options.Visible ~= false,
		ClipsDescendants = options.ClipsDescendants == true,
		LayoutOrder = options.Order or 0,
	}
	if options.Button then
		props.Text = ""
		props.AutoButtonColor = false
	end
	local frame = host.new(options.Button and "TextButton" or "Frame", props, parent)
	local radius = options.CornerRadius
	if radius == nil then
		radius = config.CornerRadius
	end
	if radius == nil then
		radius = ctx.Tokens.CornerRadius
	end
	Helpers.corner(host, frame, radius)
	if options.Stroke then
		frame.__nevaStroke = Helpers.stroke(host, frame, options.Stroke, options.StrokeThickness or 1, options.StrokeTransparency or 0)
	end
	return frame
end

function Surface.text(ctx, parent, props)
	local merged = {
		BackgroundTransparency = 1,
		Font = ctx.Tokens.Font,
		TextColor3 = ctx.Tokens.Text,
		TextSize = ctx.Configuration.TextSize or ctx.Tokens.FontSize or 13,
		TextXAlignment = ctx.Host.enumItem("TextXAlignment", "Left"),
		TextYAlignment = ctx.Host.enumItem("TextYAlignment", "Center"),
	}
	for key, value in pairs(props or {}) do
		merged[key] = value
	end
	return ctx.Host.new("TextLabel", merged, parent)
end

-- Invisible clickable area used as the component's Input surface.
function Surface.hit(ctx, parent, props)
	local merged = {
		Name = "Input",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = ctx.Host.udim2(1, 0, 1, 0),
		AutoButtonColor = false,
		Text = "",
	}
	for key, value in pairs(props or {}) do
		merged[key] = value
	end
	return ctx.Host.new("TextButton", merged, parent)
end

-- Pressed state tracking. Styles call this once per Input surface; the flag is
-- read back by the style's Apply through renderCtx.Component.Pressed.
function Surface.wirePress(ctx, input)
	local component = ctx.Component
	if not component or not input then
		return
	end
	component:Connect(input, "MouseButton1Down", function()
		component.Pressed = true
		component:_applyState()
	end)
	component:Connect(input, "MouseButton1Up", function()
		component.Pressed = false
		component:_applyState()
	end)
end

function Surface.disabledColour(ctx, colour)
	local background = ctx.Tokens.Background
	if type(colour) ~= "table" or type(background) ~= "table" then
		return colour
	end
	return Color.lerp(colour, background, 0.55)
end

function Surface.disabledText(ctx, colour)
	local muted = ctx.Tokens.TextMuted
	if colour == nil then
		return muted
	end
	return Color.lerp(colour, muted, 0.6)
end

function Surface.rowColour(ctx, colour)
	return colour
end

return Surface
end)()

local __NEVA_Studio = (function()
--[[
	NEVAHEXUI - Studio
	The interactive Style Studio: a developer tool that browses the real style
	catalogue, renders two live previews of the same component type side by side,
	generates a configuration editor from the selected style's own schema, applies
	styles to a live component, saves presets and exports Luau.

	Every preview is a real component created through the normal pipeline with a
	sandboxed callback, so what the Studio shows is what the library renders.
]]

local Container = __NEVA_Core_Container
local Styles = __NEVA_Styles_Registry
local Schema = __NEVA_Styles_Schema
local Helpers = __NEVA_Styles_Helpers
local Surface = __NEVA_Styles_Surface

local Studio = {}
Studio.__index = Studio

-- Component types the Studio offers. Every entry is verified to have at least
-- one registered renderer at open time; anything without a renderer is skipped.
local CANDIDATE_TYPES = {
	"Button", "IconButton", "Toggle", "Checkbox", "Radio", "RadioGroup",
	"Slider", "RangeSlider", "Textbox", "NumberInput", "CopyableInput", "Keybind",
	"ColorPicker", "ColorPalette", "Label", "Badge", "ProgressBar", "Loader",
	"Image", "Divider", "Table", "TreeView", "LogView", "Graph",
	"Notification", "Dialog",
}

local CATEGORY_OF_TYPE = {
	Button = "Buttons",
	IconButton = "Buttons",
	Toggle = "Toggles",
	Checkbox = "Toggles",
	Radio = "Toggles",
	RadioGroup = "Toggles",
	Slider = "Sliders",
	RangeSlider = "Sliders",
	Textbox = "Text input",
	NumberInput = "Text input",
	CopyableInput = "Text input",
	Keybind = "Keybinds",
	ColorPicker = "Colour",
	ColorPalette = "Colour",
	Notification = "Feedback",
	Dialog = "Feedback",
}

local function categoryOf(componentType)
	return CATEGORY_OF_TYPE[componentType] or "Display"
end

-- Preview specifications give every type a sane, interactive demo value.
local function previewSpec(componentType, flag, styleId)
	local base = {
		Name = "Studio preview",
		Flag = flag,
		Style = { Id = styleId },
		Callback = function() end,
	}
	if componentType == "Slider" or componentType == "RangeSlider" then
		base.Min = 0
		base.Max = 100
		base.Default = componentType == "RangeSlider" and { Lower = 25, Upper = 70 } or 45
		base.Suffix = "%"
	elseif componentType == "Toggle" or componentType == "Checkbox" or componentType == "Radio" then
		base.Default = true
	elseif componentType == "RadioGroup" then
		base.Options = { "Small", "Medium", "Large" }
		base.Default = "Medium"
	elseif componentType == "Textbox" then
		base.Default = "Editable text"
	elseif componentType == "NumberInput" then
		base.Default = 12
		base.Min = 0
		base.Max = 100
	elseif componentType == "CopyableInput" then
		base.Default = "NEVAHEXUI"
	elseif componentType == "Keybind" then
		base.Default = "F"
		base.Keys = { "F", "G", "H", "LeftShift", "E" }
	elseif componentType == "ColorPicker" or componentType == "ColorPalette" then
		base.Default = { 0.94, 0.27, 0.27 }
	elseif componentType == "Label" then
		base.Default = "Preview label"
	elseif componentType == "Badge" then
		base.Default = "New"
	elseif componentType == "ProgressBar" then
		base.Default = 0.62
	elseif componentType == "Image" then
		base.Default = "rbxassetid://6031075931"
		base.Icon = "rbxassetid://6031075931"
	elseif componentType == "Table" then
		base.Columns = { "Name", "Value", "Unit" }
		base.Default = { { "Speed", 24, "studs" }, { "Jump", 50, "studs" }, { "Health", 100, "hp" } }
	elseif componentType == "TreeView" then
		base.Default = "Root"
	elseif componentType == "LogView" then
		base.Default = {
			{ Text = "[12:00:01] Studio preview", Level = "Info" },
			{ Text = "[12:00:02] Style applied", Level = "Warn" },
		}
	elseif componentType == "Graph" then
		base.Default = { 0.1, 0.35, 0.2, 0.6, 0.45, 0.8, 0.55, 0.9, 0.7, 0.95 }
	elseif componentType == "Notification" then
		base.Default = nil
		base.Body = { Message = "Preview notification", Level = "Info" }
		base.Duration = 0
	elseif componentType == "Dialog" then
		base.Default = nil
		base.Duration = 0
		base.Body = {
			Title = "Preview dialog",
			Message = "Actions are sandboxed inside the Studio.",
			Actions = {
				{ Label = "Confirm", Value = true, Style = "Primary" },
				{ Label = "Cancel", Value = false, Style = "Cancel" },
			},
		}
	end
	return base
end

local function typeIsAvailable(context, componentType)
	if not context:Factory(componentType) then
		return false
	end
	local ids = Styles.styleIds(componentType)
	return #ids > 0
end

function Studio.new(window, options)
	options = options or {}
	assert(window, "Studio.new expects a window")
	local self = setmetatable({}, Studio)
	self.Window = window
	self.Context = window.Context
	self.Host = window.Context.Host
	self.Options = options
	self.Destroyed = false
	self.SlotStyles = { "label.plain", "label.heading" }
	self.Editing = {}
	self.Search = ""
	self:BuildPanel()
	return self
end

-- Panel ----------------------------------------------------------------------

function Studio:BuildPanel()
	local host = self.Host
	local tokens = self.Context.Tokens
	self.Root = host.new("Frame", {
		Name = "NEVAHEXUI_StyleStudio",
		BackgroundColor3 = tokens.Background,
		BorderSizePixel = 0,
		Size = host.udim2(0.86, 0, 0.82, 0),
		Position = host.udim2(0.5, 0, 0.5, 0),
		AnchorPoint = host.vector2(0.5, 0.5),
		ZIndex = 80,
	}, self.Window.Root)
	Helpers.corner(host, self.Root, tokens.CornerRadius or 8)
	Helpers.stroke(host, self.Root, tokens.Outline, 1, 0.1)

	self.Header = host.new("Frame", {
		Name = "Header",
		BackgroundColor3 = tokens.Surface,
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		Size = host.udim2(1, 0, 0, 34),
		ZIndex = 81,
	}, self.Root)
	Helpers.corner(host, self.Header, tokens.CornerRadius or 8)
	Surface.text(self.Context, self.Header, {
		Name = "Title",
		Size = host.udim2(1, -120, 1, 0),
		Position = host.udim2(0, 12, 0, 0),
		Text = "NEVAHEXUI Style Studio",
		TextColor3 = tokens.Text,
		Font = tokens.FontBold,
		TextSize = 14,
	})
	local close = host.new("TextButton", {
		Name = "Close",
		BackgroundColor3 = tokens.SurfaceAlt,
		BorderSizePixel = 0,
		Size = host.udim2(0, 24, 0, 24),
		Position = host.udim2(1, -34, 0, 5),
		Text = "x",
		TextColor3 = tokens.Text,
		Font = tokens.FontBold,
		AutoButtonColor = false,
		ZIndex = 82,
	}, self.Header)
	Helpers.corner(host, close, 6)
	self:Connect(close, "MouseButton1Click", function()
		self:Destroy()
	end)

	local body = host.new("Frame", {
		Name = "Body",
		BackgroundTransparency = 1,
		Position = host.udim2(0, 0, 0, 34),
		Size = host.udim2(1, 0, 1, -34),
	}, self.Root)

	self.CatalogColumn = host.new("ScrollingFrame", {
		Name = "Catalog",
		BackgroundColor3 = tokens.SurfaceAlt,
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		Size = host.udim2(0, 260, 1, 0),
		CanvasSize = host.udim2(0, 0, 0, 0),
		ScrollBarThickness = 3,
	}, body)
	Helpers.corner(host, self.CatalogColumn, tokens.CornerRadius or 8)
	host.new("UIListLayout", {
		FillDirection = host.enumItem("FillDirection", "Vertical"),
		Padding = host.udim(0, 3),
		SortOrder = host.enumItem("SortOrder", "LayoutOrder"),
	}, self.CatalogColumn)
	host.new("UIPadding", {
		PaddingLeft = host.udim(0, 6),
		PaddingRight = host.udim(0, 6),
		PaddingTop = host.udim(0, 6),
		PaddingBottom = host.udim(0, 6),
	}, self.CatalogColumn)

	self.PreviewColumn = host.new("ScrollingFrame", {
		Name = "Previews",
		BackgroundColor3 = tokens.Surface,
		BackgroundTransparency = 0.6,
		BorderSizePixel = 0,
		Position = host.udim2(0, 266, 0, 0),
		Size = host.udim2(0, 340, 1, 0),
		CanvasSize = host.udim2(0, 0, 0, 0),
		ScrollBarThickness = 3,
	}, body)
	Helpers.corner(host, self.PreviewColumn, tokens.CornerRadius or 8)
	host.new("UIListLayout", {
		FillDirection = host.enumItem("FillDirection", "Vertical"),
		Padding = host.udim(0, 6),
		SortOrder = host.enumItem("SortOrder", "LayoutOrder"),
	}, self.PreviewColumn)
	host.new("UIPadding", {
		PaddingLeft = host.udim(0, 8),
		PaddingRight = host.udim(0, 8),
		PaddingTop = host.udim(0, 8),
		PaddingBottom = host.udim(0, 8),
	}, self.PreviewColumn)

	self.InspectorColumn = host.new("ScrollingFrame", {
		Name = "Inspector",
		BackgroundColor3 = tokens.SurfaceAlt,
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		Position = host.udim2(0, 612, 0, 0),
		Size = host.udim2(1, -618, 1, 0),
		CanvasSize = host.udim2(0, 0, 0, 0),
		ScrollBarThickness = 3,
	}, body)
	Helpers.corner(host, self.InspectorColumn, tokens.CornerRadius or 8)
	host.new("UIListLayout", {
		FillDirection = host.enumItem("FillDirection", "Vertical"),
		Padding = host.udim(0, 4),
		SortOrder = host.enumItem("SortOrder", "LayoutOrder"),
	}, self.InspectorColumn)
	host.new("UIPadding", {
		PaddingLeft = host.udim(0, 8),
		PaddingRight = host.udim(0, 8),
		PaddingTop = host.udim(0, 8),
		PaddingBottom = host.udim(0, 8),
	}, self.InspectorColumn)

	self.CatalogContainer = Container.new(self.Context, {
		Kind = "Panel",
		Name = "CatalogList",
		Parent = self.CatalogColumn,
		Window = self.Window,
	})
	self.PreviewContainer = Container.new(self.Context, {
		Kind = "Panel",
		Name = "PreviewList",
		Parent = self.PreviewColumn,
		Window = self.Window,
	})
	self.InspectorContainer = Container.new(self.Context, {
		Kind = "Panel",
		Name = "InspectorFields",
		Parent = self.InspectorColumn,
		Window = self.Window,
	})

	self:BuildTypeList()
	self:SelectType(self.Options.Component or "Toggle")
	return self.Root
end

function Studio:Connect(instance, event, callback)
	local host = self.Host
	local connection
	if host.connect then
		connection = host.connect(instance, event, callback)
	elseif instance[event] and instance[event].Connect then
		connection = instance[event]:Connect(callback)
	end
	self.Connections = self.Connections or {}
	if connection then
		table.insert(self.Connections, connection)
	end
	return connection
end

function Studio:BuildTypeList()
	local host = self.Host
	local tokens = self.Context.Tokens
	self.TypeButtons = {}
	local index = 0
	for _, componentType in ipairs(CANDIDATE_TYPES) do
		if typeIsAvailable(self.Context, componentType) then
			index += 1
			local count = #Styles.styleIds(componentType)
			local button = host.new("TextButton", {
				Name = "Type_" .. componentType,
				BackgroundColor3 = tokens.Surface,
				BackgroundTransparency = 0.4,
				BorderSizePixel = 0,
				Size = host.udim2(1, 0, 0, 26),
				Text = ("%s  [%s] (%d)"):format(componentType, categoryOf(componentType), count),
				TextColor3 = tokens.Text,
				TextSize = 12,
				TextXAlignment = host.enumItem("TextXAlignment", "Left"),
				AutoButtonColor = false,
				LayoutOrder = index,
			}, self.CatalogColumn)
			Helpers.corner(host, button, 6)
			host.new("UIPadding", {
				PaddingLeft = host.udim(0, 6),
			}, button)
			self:Connect(button, "MouseButton1Click", function()
				self:SelectType(componentType)
			end)
			self.TypeButtons[componentType] = button
		end
	end
	return self.TypeButtons
end

-- Selection ------------------------------------------------------------------

function Studio:SelectType(componentType)
	if not typeIsAvailable(self.Context, componentType) then
		return false, ("%s has no registered renderer"):format(tostring(componentType))
	end
	self.ComponentType = componentType
	self.StyleIds = Styles.styleIds(componentType)
	self.SlotStyles[1] = self.StyleIds[1]
	self.SlotStyles[2] = self.StyleIds[math.min(2, #self.StyleIds)] or self.StyleIds[1]
	self:HideAllPreviews()
	self:BuildPreviews()
	self:BuildStyleList()
	self:BuildInspector(1)
	return true
end

function Studio:HideAllPreviews()
	self.Previews = self.Previews or {}
	for _, preview in ipairs(self.Previews) do
		if preview.Root then
			preview.Root.Visible = false
		end
	end
end

function Studio:BuildStyleList()
	local host = self.Host
	local tokens = self.Context.Tokens
	for _, child in ipairs(self.PreviewColumn:GetChildren()) do
		if child:IsA("TextButton") and child.Name:sub(1, 10) == "StyleRow_" then
			host.destroy(child)
		end
	end
	self.StyleRows = {}
	local baseOrder = 1000
	for index, styleId in ipairs(self.StyleIds) do
		local record = Styles.get(styleId)
		local row = host.new("TextButton", {
			Name = "StyleRow_" .. tostring(index),
			BackgroundColor3 = tokens.SurfaceAlt,
			BackgroundTransparency = 0.35,
			BorderSizePixel = 0,
			Size = host.udim2(1, 0, 0, 22),
			Text = ("%s  -  %s"):format(styleId, record and record.Name or "?"),
			TextColor3 = tokens.Text,
			TextSize = 11,
			TextXAlignment = host.enumItem("TextXAlignment", "Left"),
			AutoButtonColor = false,
			LayoutOrder = baseOrder + index,
		}, self.PreviewColumn)
		Helpers.corner(host, row, 5)
		self.StyleRows[styleId] = row
		self:Connect(row, "MouseButton1Click", function()
			self:AssignStyle(styleId)
		end)
	end
	return self.StyleRows
end

function Studio:AssignStyle(styleId)
	local slot = self.Options.AlternateSlot and 2 or 1
	self.SlotStyles[slot] = styleId
	self:BuildPreviews()
	self:BuildInspector(slot)
	return styleId
end

function Studio:SelectedStyle(slot)
	return self.SlotStyles[slot or 1]
end


-- Live previews --------------------------------------------------------------

local SLOT_LABELS = { "Style 1", "Style 2" }

function Studio:BuildPreviews()
	local host = self.Host
	local tokens = self.Context.Tokens
	self.Previews = self.Previews or {}
	for slot, preview in ipairs(self.Previews) do
		if not preview.Destroyed then
			pcall(function()
				preview:Destroy()
			end)
		end
		self.Previews[slot] = nil
	end
	for slot = 1, 2 do
		local styleId = self.SlotStyles[slot]
		if styleId then
			local frame = host.new("Frame", {
				Name = ("Preview%s"):format(tostring(slot)),
				BackgroundColor3 = tokens.Surface,
				BackgroundTransparency = 0.55,
				BorderSizePixel = 0,
				Size = host.udim2(1, 0, 0, 0),
				AutomaticSize = host.enumItem("AutomaticSize", "Y"),
				LayoutOrder = slot,
			}, self.PreviewColumn)
			Helpers.corner(host, frame, tokens.CornerRadius or 8)
			local _layout = host.new("UIListLayout", {
				Name = "PreviewLayout",
				FillDirection = host.enumItem("FillDirection", "Vertical"),
				Padding = host.udim(0, 4),
				SortOrder = host.enumItem("SortOrder", "LayoutOrder"),
			}, frame)
			host.new("UIPadding", {
				PaddingLeft = host.udim(0, 6),
				PaddingRight = host.udim(0, 6),
				PaddingTop = host.udim(0, 6),
				PaddingBottom = host.udim(0, 6),
			}, frame)
			local _header = Surface.text(self.Context, frame, {
				Name = "SlotLabel",
				Size = host.udim2(1, 0, 0, 16),
				Text = ("%s: %s"):format(SLOT_LABELS[slot], styleId),
				TextColor3 = tokens.TextMuted,
				Font = tokens.FontBold,
				TextSize = 11,
				LayoutOrder = 0,
			})
			local _record = Styles.get(styleId)
			local container = Container.new(self.Context, {
				Kind = "Panel",
				Name = ("PreviewSlot%s"):format(tostring(slot)),
				Parent = frame,
				Window = self.Window,
				Padding = 0,
			})
			if container.LayoutObject then
				container.LayoutObject.Padding = host.udim(0, 4)
			end
			local spec = previewSpec(self.ComponentType, ("StudioPreview%s"):format(tostring(slot)), styleId)
			local ok, component = pcall(function()
				return container:Create(self.ComponentType, spec)
			end)
			if not ok then
				Surface.text(self.Context, frame, {
					Name = "PreviewError",
					Size = host.udim2(1, 0, 0, 20),
					Text = ("Preview failed: %s"):format(tostring(component)),
					TextColor3 = tokens.Negative,
					TextSize = 11,
					LayoutOrder = 2,
				})
			else
				component.Internal = true
				component.Metadata.Studio = true
				table.insert(self.Previews, component)
				self.Previews[slot] = component
				if component.View and component.View.Root then
					component.View.Root.Size = host.udim2(1, 0, 0, component.View.Root.Size.Y.Offset)
				end
			end
			frame.Name = ("Preview%s_%s"):format(tostring(slot), styleId)
		end
	end
	return self.Previews
end

-- Inspector ------------------------------------------------------------------

-- One inspector row: a labelled frame whose control is parented into it.
local function container_row(host, parent, order, label)
	local row = host.new("Frame", {
		Name = "Row_" .. tostring(label),
		BackgroundTransparency = 1,
		Size = host.udim2(1, 0, 0, 26),
		LayoutOrder = order,
	}, parent)
	return row
end

local FONT_CYCLE = { "Gotham", "GothamBold", "Code", "SourceSans", "Arial" }

local function propertyBounds(descriptor, configuration)
	local min = descriptor.Min or 0
	local max = descriptor.Max or 1
	if max <= min then
		max = min + 1
	end
	return min, max
end

function Studio:ClearInspector()
	local host = self.Host
	for index = #self.InspectorRows, 1, -1 do
		local entry = self.InspectorRows[index]
		if entry and not entry.Destroyed then
			pcall(function()
				entry:Destroy()
			end)
		end
		self.InspectorRows[index] = nil
	end
	for _, child in ipairs(self.InspectorColumn:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextButton") then
			host.destroy(child)
		end
	end
	self.InspectorRows = {}
	return true
end

function Studio:BuildInspector(slot)
	slot = slot or 1
	self.InspectorRows = self.InspectorRows or {}
	local host = self.Host
	local tokens = self.Context.Tokens
	local styleId = self.SlotStyles[slot]
	local preview = self.Previews and self.Previews[slot]
	if not styleId or not preview then
		return false
	end
	self.Editing = { Slot = slot, StyleId = styleId, Preview = preview }
	local record = Styles.get(styleId)
	local chain = Styles.chain(styleId)
	local properties = Styles.effectiveProperties(chain)
	local order = 0

	local function header(text, colour)
		order += 1
		return Surface.text(self.Context, self.InspectorColumn, {
			Name = "Label_" .. tostring(order),
			Size = host.udim2(1, 0, 0, 18),
			Text = text,
			TextColor3 = colour or tokens.Text,
			Font = tokens.FontBold,
			TextSize = 11,
			LayoutOrder = order,
		})
	end

	header(("Style %s  (%s)"):format(styleId, record and record.Name or "?"), tokens.Accent)
	header(record and record.Description or "", tokens.TextMuted)
	header(("Slot %d  -  %d propert%s"):format(slot, #properties, #properties == 1 and "y" or "ies"))

	for _, descriptor in ipairs(properties) do
		order += 1
		local value = preview:GetStyleConfiguration()[descriptor.Key]
		if value == nil then
			value = preview.Configuration[descriptor.Key]
		end
		local label = ("%s%s"):format(descriptor.Key, descriptor.Type == "number" and "  (number)" or "")
		local row = container_row(host, self.InspectorColumn, order, label)
		local property = descriptor.Key
		local kind = descriptor.Type

		local function apply(newValue)
			local configuration = preview:GetStyleConfiguration()
			configuration[property] = newValue
			preview:SetStyleConfiguration(configuration)
			return newValue
		end

		if kind == "number" then
			local min, max = propertyBounds(descriptor)
			local control = self.InspectorContainer:Create("Slider", {
				Name = label,
				Flag = ("Studio_%s_%d"):format(property, slot),
				RowHeight = 24,
				Min = min,
				Max = max,
				Step = descriptor.Step,
				Default = tonumber(value) or descriptor.Default or min,
				Style = { Id = "slider.minimal" },
				Callback = function(newValue)
					apply(newValue)
				end,
			})
			table.insert(self.InspectorRows, control)
			control.View.Root.Parent = row
		elseif kind == "boolean" then
			local control = self.InspectorContainer:Create("Toggle", {
				Name = label,
				Flag = ("Studio_%s_%d"):format(property, slot),
				Default = value == true,
				Style = { Id = "toggle.compact" },
				Callback = function(newValue)
					apply(newValue)
				end,
			})
			table.insert(self.InspectorRows, control)
			control.View.Root.Parent = row
		elseif kind == "color" then
			local control = self.InspectorContainer:Create("ColorPicker", {
				Name = label,
				Flag = ("Studio_%s_%d"):format(property, slot),
				SwatchSize = 14,
				Columns = 10,
				Default = value or "Accent",
				Palette = self.Context.Tokens.Palette,
				Style = { Id = "colorpicker.popup" },
				Callback = function(newValue)
					apply(newValue)
				end,
			})
			table.insert(self.InspectorRows, control)
			control.View.Root.Parent = row
		elseif kind == "string" then
			local control = self.InspectorContainer:Create("Textbox", {
				Name = label,
				Flag = ("Studio_%s_%d"):format(property, slot),
				Default = tostring(value or descriptor.Default or ""),
				Style = { Id = "textbox.outline" },
				Callback = function(newValue)
					apply(newValue)
				end,
			})
			table.insert(self.InspectorRows, control)
			control.View.Root.Parent = row
		else
			local choices = descriptor.Type == "enum" and descriptor.Options or (descriptor.Type == "font" and FONT_CYCLE or nil)
			if not choices and descriptor.Type == "animation" then
				choices = {}
				for _, entry in ipairs(__NEVA_Animation_Presets.list()) do
					table.insert(choices, entry.Name or entry.Id or entry)
				end
			end
			choices = choices or { "Default" }
			local control = self.InspectorContainer:Create("Button", {
				Name = label,
				Flag = ("Studio_%s_%d"):format(property, slot),
				Style = { Id = "button.flat" },
				Callback = function()
					-- The callback cycles, so it does not need the returned count.
				end,
			})
			table.insert(self.InspectorRows, control)
			control.View.Root.Parent = row
			local current = value
			control:OnChanged(function()
				local nextIndex = 1
				for index, choice in ipairs(choices) do
					if tostring(choice) == tostring(current) then
						nextIndex = index % #choices + 1
						break
					end
				end
				current = choices[nextIndex]
				apply(current)
			end)
		end
	end

	order += 1
	local actions = host.new("Frame", {
		Name = "Actions",
		BackgroundTransparency = 1,
		Size = host.udim2(1, 0, 0, 26),
		LayoutOrder = order,
	}, self.InspectorColumn)
	host.new("UIListLayout", {
		FillDirection = host.enumItem("FillDirection", "Horizontal"),
		Padding = host.udim(0, 4),
		SortOrder = host.enumItem("SortOrder", "LayoutOrder"),
	}, actions)
	local function actionButton(text, order2, callback)
		local button = host.new("TextButton", {
			Name = "Action_" .. text,
			BackgroundColor3 = tokens.SurfaceAlt,
			BorderSizePixel = 0,
			Size = host.udim2(0, 92, 1, 0),
			Text = text,
			TextColor3 = tokens.Text,
			Font = tokens.FontBold,
			TextSize = 11,
			AutoButtonColor = false,
			LayoutOrder = order2,
		}, actions)
		Helpers.corner(host, button, 6)
		self:Connect(button, "MouseButton1Click", callback)
		return button
	end
	actionButton("Apply", 1, function()
		self:ApplyToTarget()
	end)
	actionButton("Preset", 2, function()
		self:SavePreset()
	end)
	actionButton("Export", 3, function()
		self:ExportStyle()
	end)
	actionButton("Reset", 4, function()
		if self.Editing and self.Editing.Preview then
			self.Editing.Preview:ResetStyleConfiguration()
		end
	end)
	return true
end

-- Apply, preset, export ------------------------------------------------------

function Studio:SetTarget(component)
	self.Target = component
	return component
end

function Studio:GetTargets()
	local out = {}
	for _, component in ipairs(self.Context:ComponentsOfType(self.ComponentType)) do
		if component.Metadata and component.Metadata.Studio then
			continue
		end
		table.insert(out, component)
	end
	return out
end

function Studio:ApplyToTarget()
	if not self.Editing or not self.Editing.Preview then
		return false, "nothing selected"
	end
	local target = self.Target
	if not target then
		local candidates = self:GetTargets()
		target = candidates[1]
	end
	if not target then
		return false, ("no live %s component to apply to"):format(tostring(self.ComponentType))
	end
	local preview = self.Editing.Preview
	local configuration = preview:GetStyleConfiguration()
	local ok, err = target:SetStyle(self.Editing.StyleId, configuration)
	self.LastApply = { Component = target, Style = self.Editing.StyleId, Ok = ok ~= false, Error = err }
	return ok ~= false, err
end

function Studio:SavePreset(name)
	if not self.Editing or not self.Editing.Preview then
		return false, "nothing selected"
	end
	local preview = self.Editing.Preview
	local componentType = self.ComponentType
	local id = ("studio.%s.%d"):format(componentType:lower(), os.time and os.time() or 0)
	local definition = {
		Id = id,
		Name = name or ("Studio " .. componentType),
		Component = componentType,
		Category = "Studio",
		Description = ("Created in the Style Studio from %s"):format(self.Editing.StyleId),
		Requires = self.Editing.StyleId,
		Configuration = preview:GetStyleConfiguration(),
		Render = preview.Style and preview.Style.Render or nil,
	}
	if not definition.Render then
		return false, "the selected style has no renderer to copy"
	end
	local Styles2 = __NEVA_Styles_Registry
	local record, errors = Styles2.registerStyle(definition)
	if not record then
		return false, errors
	end
	table.insert(self.SavedPresets or {}, record.Id)
	self.SavedPresets = self.SavedPresets or {}
	return record.Id
end

function Studio:ExportStyle(slot)
	local styleId = self.SlotStyles[slot or (self.Editing and self.Editing.Slot) or 1]
	local record = Styles.get(styleId)
	if not record then
		return nil, "no style selected"
	end
	local preview = self.Previews and self.Previews[slot or (self.Editing and self.Editing.Slot) or 1]
	local configuration = preview and preview:GetStyleConfiguration() or {}
	local text = Schema.exportStyle({
		Id = record.Id .. ".exported",
		Name = record.Name .. " (exported)",
		Component = record.Component,
		Category = record.Category,
		Description = record.Description,
		Configuration = configuration,
	}, { Properties = Styles.effectiveProperties(Styles.chain(styleId)) })
	self.LastExport = text
	if self.Host.clipboardSet then
		pcall(function()
			self.Host.clipboardSet(text)
		end)
	end
	return text
end

function Studio:ExplainConfiguration()
	if not self.Editing or not self.Editing.Preview then
		return nil
	end
	local component = self.Editing.Preview
	return {
		StyleId = component:GetStyle(),
		Effective = component:GetEffectiveConfiguration(),
		Overrides = component:GetStyleConfiguration(),
		Explanation = component:ExplainConfiguration(),
	}
end

function Studio:Destroy()
	if self.Destroyed then
		return false
	end
	self.Destroyed = true
	for _, preview in ipairs(self.Previews or {}) do
		if not preview.Destroyed then
			pcall(function()
				preview:Destroy()
			end)
		end
	end
	self.Previews = {}
	for _, entry in ipairs(self.InspectorRows or {}) do
		if entry and not entry.Destroyed then
			pcall(function()
				entry:Destroy()
			end)
		end
	end
	self.InspectorRows = {}
	for _, container in ipairs({ self.CatalogContainer, self.PreviewContainer, self.InspectorContainer }) do
		if container and container.Destroy then
			pcall(function()
				container:Destroy()
			end)
		end
	end
	if self.Window and self.Window.Studio == self then
		self.Window.Studio = nil
	end
	for _, connection in ipairs(self.Connections or {}) do
		if connection and connection.Disconnect then
			pcall(function()
				connection:Disconnect()
			end)
		end
	end
	self.Connections = {}
	if self.Root then
		self.Host.destroy(self.Root)
		self.Root = nil
	end
	return true
end

return Studio
end)()

local __NEVA_Core_Window = (function()
--[[
	NEVAHEXUI - Core/Window  (part 1 of 2: construction and chrome)

	The window owns the chrome, navigation, page containers, the overlay used for
	notifications and dialogs, and the layout.

	Design rules enforced here:
	  * Changing layout or theme never recreates a component. A layout change only
	    re-parents the existing tab containers into the new content area.
	  * Tab containers are ordinary Containers, so every Create<Type> method comes
	    from the component factory table rather than a hand-written list here.
	  * Transient surfaces (Notify, Dialog) are components too, created through the
	    same pipeline and destroyed when dismissed.
]]

local Util = __NEVA_Core_Util
local Signal = __NEVA_Core_Signal
local Container = __NEVA_Core_Container
local Layouts = __NEVA_Core_Layouts
local Helpers = __NEVA_Styles_Helpers
local Surface = __NEVA_Styles_Surface

local Window = {}
Window.__index = Window

local function pointerOf(host)
	if not host.pointerPosition then
		return nil
	end
	local position = host.pointerPosition()
	if position == nil then
		return nil
	end
	return { X = position.X or position.x or 0, Y = position.Y or position.y or 0 }
end

local function viewportOf(host)
	if not host.viewportSize then
		return { X = 0, Y = 0 }
	end
	local size = host.viewportSize()
	return { X = size.X or size.x or 0, Y = size.Y or size.y or 0 }
end

function Window.new(context, options)
	options = options or {}
	assert(context, "Window.new expects a render context")
	local self = setmetatable({}, Window)
	self.Context = context
	self.Host = context.Host
	self.Options = options
	self.Name = tostring(options.Name or "NEVAHEXUI")
	self.Subtitle = options.Subtitle
	self.Icon = options.Icon
	self.Destroyed = false
	self.Minimized = false
	self.Dragging = false
	self.Tabs = {}
	self.Notifications = {}
	self.ConnectionList = {}
	self.CreatedAt = Util.uniqueId("Window")
	self.Closed = Signal.new("WindowClosed")
	self.TabChanged = Signal.new("TabChanged")
	self.LayoutChanged = Signal.new("LayoutChanged")

	self.LayoutId = options.Layout or "Sidebar"
	if not Layouts.has(self.LayoutId) then
		context:Diagnostic("Warn", ("unknown layout %q, falling back to Sidebar"):format(tostring(self.LayoutId)))
		self.LayoutId = "Sidebar"
	end
	self.Layout = Layouts.get(self.LayoutId)

	local configuration = options.Configuration or {}
	local theme = options.Theme or configuration.Theme
	if theme then
		context:SetTheme(theme)
	end
	local accent = options.Accent or configuration.Accent
	if accent then
		context.ThemeOverrides = context.ThemeOverrides or {}
		context.ThemeOverrides.Accent = accent
		context:RefreshTheme()
	end
	if options.Styles then
		for component, styleId in pairs(options.Styles) do
			context:SetStyleDefault(component, styleId)
		end
	end
	if options.StyleConfiguration then
		for component, categoryConfiguration in pairs(options.StyleConfiguration) do
			context:SetCategoryConfiguration(component, categoryConfiguration)
		end
	end

	self:BuildChrome()
	context:RegisterScope(self)
	return self
end

-- Chrome ---------------------------------------------------------------------

function Window:ComputeRootSize()
	local sizing = self.Layout.Sizing or {}
	local size = sizing.Size or { 0.62, 480, 0.68, 360 }
	return (size[1] or 0), (size[2] or 480), (size[3] or 0), (size[4] or 360)
end

function Window:BuildChrome()
	local host = self.Host
	local tokens = self.Context.Tokens
	local widthScale, widthOffset, heightScale, heightOffset = self:ComputeRootSize()
	local sizing = self.Layout.Sizing or {}

	if self.Root then
		host.destroy(self.Root)
		self.Root = nil
	end

	local parent = self.Options.Parent or host.Root
	self.Root = host.new("Frame", {
		Name = "NEVAHEXUI_" .. self.Name,
		BackgroundColor3 = tokens.Background,
		BorderSizePixel = 0,
		Size = host.udim2(widthScale, widthOffset, heightScale, heightOffset),
		Position = host.udim2(0.5, 0, 0.5, 0),
		AnchorPoint = host.vector2(0.5, 0.5),
		ClipsDescendants = false,
		ZIndex = 20,
	}, parent)
	if self.Options.Transparency ~= nil then
		self.Root.BackgroundTransparency = self.Options.Transparency
	end
	Helpers.corner(host, self.Root, tokens.CornerRadius or 8)
	Helpers.stroke(host, self.Root, tokens.Outline, 1, 0.25)

	if sizing.MinSize or sizing.MaxSize then
		local minimum = sizing.MinSize or { 320, 240 }
		local maximum = sizing.MaxSize or { 1200, 900 }
		host.new("UISizeConstraint", {
			MinSize = host.vector2(minimum[1], minimum[2]),
			MaxSize = host.vector2(maximum[1], maximum[2]),
		}, self.Root)
	end

	local chromeHeight = self.Layout.Chrome == "Minimal" and 34 or 40
	self.ChromeHeight = chromeHeight

	-- A TextButton, not a Frame: only GuiButton instances own MouseButton1Down/Up,
	-- and a Frame that is not Active never receives InputBegan either, so the
	-- title bar would neither drag nor report a press.
	self.TitleBar = host.new("TextButton", {
		Name = "TitleBar",
		BackgroundColor3 = tokens.Surface,
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
		Size = host.udim2(1, 0, 0, chromeHeight),
		Text = "",
		AutoButtonColor = false,
		ZIndex = 3,
	}, self.Root)
	Helpers.corner(host, self.TitleBar, tokens.CornerRadius or 8)

	self.TitleLabel = Surface.text(self.Context, self.TitleBar, {
		Name = "Title",
		Size = host.udim2(1, -210, 1, 0),
		Position = host.udim2(0, 14, 0, 0),
		Text = self.Name,
		TextColor3 = tokens.Text,
		Font = tokens.FontBold,
		TextSize = 15,
		TextTruncate = host.enumItem("TextTruncate", "AtEnd"),
	})
	if self.Subtitle then
		Surface.text(self.Context, self.TitleBar, {
			Name = "Subtitle",
			Size = host.udim2(1, -230, 1, 0),
			Position = host.udim2(0, 160, 0, 0),
			Text = tostring(self.Subtitle),
			TextColor3 = tokens.TextMuted,
			TextSize = 11,
			TextXAlignment = host.enumItem("TextXAlignment", "Right"),
		})
	end

	local buttonArea = host.new("Frame", {
		Name = "ChromeButtons",
		BackgroundTransparency = 1,
		Size = host.udim2(0, 148, 1, 0),
		Position = host.udim2(1, -156, 0, 0),
		ZIndex = 4,
	}, self.TitleBar)
	host.new("UIListLayout", {
		FillDirection = host.enumItem("FillDirection", "Horizontal"),
		HorizontalAlignment = host.enumItem("HorizontalAlignment", "Right"),
		VerticalAlignment = host.enumItem("VerticalAlignment", "Center"),
		Padding = host.udim(0, 6),
		SortOrder = host.enumItem("SortOrder", "LayoutOrder"),
	}, buttonArea)

	local function chromeButton(name, glyph, order, callback)
		local button = host.new("TextButton", {
			Name = name,
			BackgroundColor3 = tokens.SurfaceAlt,
			BackgroundTransparency = 0.25,
			BorderSizePixel = 0,
			Size = host.udim2(0, 26, 0, 26),
			Text = glyph,
			TextColor3 = tokens.Text,
			Font = tokens.FontBold,
			TextSize = 13,
			AutoButtonColor = false,
			LayoutOrder = order,
			ZIndex = 5,
		}, buttonArea)
		Helpers.corner(host, button, 6)
		self:Connect(button, "MouseButton1Click", callback)
		return button
	end

	self.StudioButton = chromeButton("Studio", "S", 1, function()
		self:OpenStudio()
	end)
	if self.Options.ToggleKey then
		self.ToggleButton = chromeButton("ToggleUI", "H", 2, function()
			self:Toggle()
		end)
	end
	self.MinimizeButton = chromeButton("Minimize", "-", 3, function()
		self:Minimize()
	end)
	self.CloseButton = chromeButton("Close", "x", 4, function()
		self:Close()
	end)

	self.Body = host.new("Frame", {
		Name = "Body",
		BackgroundTransparency = 1,
		Position = host.udim2(0, 0, 0, chromeHeight),
		Size = host.udim2(1, 0, 1, -chromeHeight),
	}, self.Root)

	local navHeight = self.Layout.Nav == "Top" and 34 or 0
	local navWidth = self.Layout.Nav == "Left" and (self.Layout.NavWidth or 156) or 0

	self.Nav = host.new("Frame", {
		Name = "Nav",
		BackgroundColor3 = tokens.SurfaceAlt,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		Size = self.Layout.Nav == "Top"
			and host.udim2(1, 0, 0, navHeight)
			or host.udim2(0, navWidth, 1, 0),
	}, self.Body)
	Helpers.corner(host, self.Nav, (tokens.CornerRadius or 8) - 2)
	host.new("UIPadding", {
		PaddingLeft = host.udim(0, 6),
		PaddingRight = host.udim(0, 6),
		PaddingTop = host.udim(0, 6),
		PaddingBottom = host.udim(0, 6),
	}, self.Nav)
	if self.Layout.Nav == "Top" then
		host.new("UIListLayout", {
			FillDirection = host.enumItem("FillDirection", "Horizontal"),
			Padding = host.udim(0, 4),
			SortOrder = host.enumItem("SortOrder", "LayoutOrder"),
		}, self.Nav)
	end

	self.Content = host.new("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		Position = self.Layout.Nav == "Top" and host.udim2(0, 0, 0, navHeight) or host.udim2(0, navWidth, 0, 0),
		Size = self.Layout.Nav == "Top"
			and host.udim2(1, 0, 1, -navHeight)
			or host.udim2(1, -navWidth, 1, 0),
	}, self.Body)

	self.PageHost = host.new("ScrollingFrame", {
		Name = "Pages",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = host.udim2(1, 0, 1, 0),
		CanvasSize = host.udim2(0, 0, 0, 0),
		ScrollBarThickness = 3,
		ScrollBarImageTransparency = 0.5,
	}, self.Content)
	self.PageLayout = host.new("UIListLayout", {
		Name = "PageLayout",
		FillDirection = host.enumItem("FillDirection", "Vertical"),
		Padding = host.udim(0, self.Context.Tokens.Spacing or 8),
		SortOrder = host.enumItem("SortOrder", "LayoutOrder"),
	}, self.PageHost)
	host.new("UIPadding", {
		PaddingLeft = host.udim(0, 10),
		PaddingRight = host.udim(0, 10),
		PaddingTop = host.udim(0, 10),
		PaddingBottom = host.udim(0, 10),
	}, self.PageHost)

	self.Overlay = host.new("Frame", {
		Name = "Overlay",
		BackgroundTransparency = 1,
		Size = host.udim2(1, 0, 1, 0),
		ZIndex = 60,
	}, self.Root)

	if self.Layout.Draggable then
		self:Connect(self.TitleBar, "MouseButton1Down", function()
			self:BeginDrag()
		end)
	end

	-- Existing tabs move into the new content area; nothing is recreated.
	for _, tab in ipairs(self.Tabs) do
		tab.Container.Parent = self.PageHost
	end
	self:BuildNav()
	self:RefreshLayout()
	return self.Root
end

function Window:BuildNav()
	local host = self.Host
	for _, child in ipairs(self.Nav:GetChildren()) do
		if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
			host.destroy(child)
		end
	end
	self.NavButtons = {}
	local iconOnly = self.LayoutId == "IconSidebar"
	for index, tab in ipairs(self.Tabs) do
		local compact = self.Layout.Nav == "Top"
		local button = host.new("TextButton", {
			Name = "Tab_" .. tab.Name,
			BackgroundColor3 = self.Context.Tokens.Surface,
			BackgroundTransparency = 0.5,
			BorderSizePixel = 0,
			Size = compact and host.udim2(0, 96, 1, 0) or host.udim2(1, 0, 0, 30),
			Text = iconOnly and "" or tab.Name,
			TextColor3 = self.Context.Tokens.Text,
			Font = self.Context.Tokens.Font,
			TextSize = 13,
			TextXAlignment = compact and host.enumItem("TextXAlignment", "Center") or host.enumItem("TextXAlignment", "Left"),
			AutoButtonColor = false,
			LayoutOrder = index,
			ZIndex = 4,
		}, self.Nav)
		Helpers.corner(host, button, 6)
		host.new("UIPadding", {
			PaddingLeft = host.udim(0, iconOnly and 0 or 8),
		}, button)
		tab.Button = button
		self.NavButtons[index] = button
		self:Connect(button, "MouseButton1Click", function()
			self:SelectTab(tab)
		end)
	end
	self:HighlightActiveTab()
end

-- Connection helpers ---------------------------------------------------------

function Window:Connect(instance, event, callback)
	local host = self.Host
	local connection
	if host.connect then
		connection = host.connect(instance, event, callback)
	elseif instance[event] and instance[event].Connect then
		connection = instance[event]:Connect(callback)
	end
	if connection then
		table.insert(self.ConnectionList, connection)
	end
	return connection
end

function Window:TrackConnection(connection)
	table.insert(self.ConnectionList, connection)
	return connection
end

-- Tabs -----------------------------------------------------------------------

function Window:CreateTab(options)
	options = options or {}
	assert(not self.Destroyed, "cannot create a tab on a destroyed window")
	local tab = Container.new(self.Context, {
		Kind = "Tab",
		Name = options.Name or ("Tab " .. tostring(#self.Tabs + 1)),
		Icon = options.Icon,
		Order = options.Order or (#self.Tabs + 1),
		Parent = self.PageHost,
		Window = self,
		Dependency = options.Dependency or options.DependsOn,
	})
	tab.Visible = false
	if tab.Container then
		tab.Container.Visible = false
	end
	self.Tabs[#self.Tabs + 1] = tab
	self:BuildNav()
	if #self.Tabs == 1 and options.Selected ~= false then
		self:SelectTab(tab)
	end
	return tab
end

function Window:GetTab(name)
	for _, tab in ipairs(self.Tabs) do
		if tab == name or tab.Name == name or tab.Id == name then
			return tab
		end
	end
	return nil
end

function Window:GetTabs()
	return self.Tabs
end

function Window:HighlightActiveTab()
	local tokens = self.Context.Tokens
	for _, tab in ipairs(self.Tabs) do
		if tab.Button then
			local active = tab == self.ActiveTab
			tab.Button.BackgroundTransparency = active and 0.05 or 0.5
			tab.Button.TextColor3 = active and tokens.Text or tokens.TextMuted
			local stroke = tab.Button.__nevaStroke
			if active and not stroke then
				tab.Button.__nevaStroke = Helpers.stroke(self.Host, tab.Button, tokens.Accent, 1, 0.15)
			elseif stroke then
				stroke.Transparency = active and 0.15 or 1
			end
		end
	end
end

function Window:SelectTab(target)
	local tab = self:GetTab(target) or target
	assert(tab, "SelectTab expects a tab or a tab name")
	self.ActiveTab = tab
	for _, candidate in ipairs(self.Tabs) do
		local active = candidate == tab
		candidate.Visible = active
		if candidate.Container then
			candidate.Container.Visible = active and candidate.DependenciesMet ~= false
		end
	end
	self:HighlightActiveTab()
	self:RefreshLayout()
	self.TabChanged:Fire(tab)
	return tab
end

function Window:GetActiveTab()
	return self.ActiveTab
end

-- Sections and cards ---------------------------------------------------------

local function sectionFactory(kind)
	return function(self, options)
		options = options or {}
		local parent = options.Parent or (self.ActiveTab and self.ActiveTab.Instance) or self.PageHost
		return Container.new(self.Context, {
			Kind = kind,
			Name = options.Name or kind,
			Icon = options.Icon,
			Order = options.Order,
			Collapsible = options.Collapsible,
			Collapsed = options.Collapsed,
			Padding = options.Padding,
			Dependency = options.Dependency or options.DependsOn,
			Parent = parent,
			Window = self,
		})
	end
end

Window.CreateSection = sectionFactory("Section")
Window.CreateGroupbox = sectionFactory("Groupbox")
Window.CreateCard = sectionFactory("Card")
Window.CreateCollapsible = sectionFactory("Collapsible")
Window.CreateDependencyBox = sectionFactory("DependencyBox")

function Window:CreateColumn(options)
	options = options or {}
	local parent = options.Parent or (self.ActiveTab and self.ActiveTab.Instance) or self.PageHost
	local column = Container.new(self.Context, {
		Kind = "Column",
		Name = options.Name or "Column",
		Parent = parent,
		Window = self,
		Order = options.Order,
	})
	if column.Container then
		column.Container.Size = self.Host.udim2(options.Width or 0.5, options.WidthOffset or -4, 0, options.Height or 0)
	end
	return column
end

-- Layout and theme -----------------------------------------------------------

function Window:SetLayout(layoutId)
	if not Layouts.has(layoutId) then
		return false, ("unknown layout %q"):format(tostring(layoutId))
	end
	self.LayoutId = layoutId
	self.Layout = Layouts.get(layoutId)
	self:BuildChrome()
	self.LayoutChanged:Fire(layoutId)
	return true
end

function Window:GetLayout()
	return self.LayoutId
end

function Window:RefreshLayout()
	if not self.PageHost or not self.PageLayout then
		return
	end
	if self.PageLayout.AbsoluteContentSize then
		self.PageHost.CanvasSize = self.Host.udim2(0, 0, 0, self.PageLayout.AbsoluteContentSize.Y + 20)
	end
	if self.Layout.TouchFriendly then
		local viewport = viewportOf(self.Host)
		if viewport.X > 0 and viewport.X < 420 then
			self.Root.Size = self.Host.udim2(0.98, 0, 0.94, 0)
		end
	end
end

function Window:SetTheme(themeId, overrides)
	local ok, err = self.Context:SetTheme(themeId, overrides)
	if not ok then
		return false, err
	end
	self:BuildChrome()
	return true
end

function Window:GetTheme()
	return self.Context:GetTheme()
end

function Window:SetStyleDefault(component, styleId)
	return self.Context:SetStyleDefault(component, styleId)
end

Window.SetComponentStyle = function(self, flagOrId, styleId)
	local component = self.Context:FindComponent(flagOrId)
	if not component then
		return false, ("no component registered for %q"):format(tostring(flagOrId))
	end
	return component:SetStyle(styleId)
end

function Window:SetCategoryStyle(component, styleId)
	return self.Context:SetStyleDefault(component, styleId)
end

function Window:SetCategoryConfiguration(component, categoryConfiguration, options)
	return self.Context:SetCategoryConfiguration(component, categoryConfiguration, options)
end

function Window:GetComponent(flagOrId)
	return self.Context:FindComponent(flagOrId)
end

-- Overlay surfaces -----------------------------------------------------------

function Window:Notify(options)
	if type(options) == "string" then
		options = { Message = options }
	else
		options = options or {}
	end
	local host = self.Host
	local holder = host.new("Frame", {
		Name = "NotificationHolder",
		BackgroundTransparency = 1,
		Size = host.udim2(1, -16, 1, -16),
		Position = host.udim2(0, 8, 0, 8),
		ZIndex = 61,
	}, self.Overlay)
	host.new("UIListLayout", {
		FillDirection = host.enumItem("FillDirection", "Vertical"),
		HorizontalAlignment = host.enumItem("HorizontalAlignment", "Right"),
		VerticalAlignment = host.enumItem("VerticalAlignment", "Top"),
		Padding = host.udim(0, 6),
		SortOrder = host.enumItem("SortOrder", "LayoutOrder"),
	}, holder)
	local proxy = {
		Id = Util.uniqueId("Overlay"),
		Window = self,
		Scope = self,
		Instance = holder,
		Kind = "Overlay",
		Context = self.Context,
		Name = "Overlay",
	}
	local spec = {
		Name = options.Title or options.Name or "Notification",
		Description = options.Message or "",
		Flag = options.Flag or Util.uniqueId("Notification"),
		Style = options.Style or { Id = options.StyleId or "notification.toast" },
		Level = options.Level,
		Body = {
			Message = options.Message,
			Level = options.Level or "Info",
		},
	}
	-- Context:Create registers the component exactly once; registering it again
	-- here would duplicate it in the store and inflate the component count.
	local component = self.Context:Create("Notification", proxy, spec)
	component.Window = self
	table.insert(self.Notifications, component)
	local duration = options.Duration
	if duration == nil then
		duration = component.Configuration and component.Configuration.Duration or 4
	end
	if duration and duration > 0 and host.delay then
		host.delay(duration, function()
			component:Dismiss("Timeout")
		end)
	end
	component.Dismissed:Connect(function()
		for index, entry in ipairs(self.Notifications) do
			if entry == component then
				table.remove(self.Notifications, index)
				break
			end
		end
		host.destroy(holder)
	end)
	return component
end

function Window:Dialog(options)
	options = options or {}
	local host = self.Host
	local actions = options.Actions or {
		{ Label = options.ConfirmLabel or "Confirm", Value = true, Style = "Primary" },
		{ Label = options.CancelLabel or "Cancel", Value = false, Style = "Cancel" },
	}
	local dim
	if options.Dim ~= false then
		dim = host.new("TextButton", {
			Name = "DialogDim",
			BackgroundColor3 = self.Context.Tokens.Background,
			BackgroundTransparency = 0.35,
			BorderSizePixel = 0,
			Size = host.udim2(1, 0, 1, 0),
			Text = "",
			AutoButtonColor = false,
			ZIndex = 62,
		}, self.Overlay)
	end
	local proxy = {
		Id = Util.uniqueId("Overlay"),
		Window = self,
		Scope = self,
		Instance = self.Overlay,
		Kind = "Overlay",
		Context = self.Context,
		Name = "Overlay",
	}
	local spec = {
		Name = options.Title or "Confirm",
		Description = options.Message or "",
		Flag = options.Flag or Util.uniqueId("Dialog"),
		Style = options.Style or { Id = options.StyleId or "dialog.modal" },
		Body = {
			Title = options.Title or "Confirm",
			Message = options.Message or "",
			Actions = actions,
		},
		OnChoose = options.OnChoose,
	}
	-- Registered by Context:Create; a second registration would double-count it.
	local component = self.Context:Create("Dialog", proxy, spec)
	component.Window = self
	local view = component.View
	if view and view.Root then
		view.Root.Position = host.udim2(0.5, 0, 0.5, 0)
		view.Root.AnchorPoint = host.vector2(0.5, 0.5)
		view.Root.ZIndex = 63
	end
	component.Answered:Connect(function()
		if dim then
			host.destroy(dim)
		end
	end)
	if dim and options.DimDismiss ~= false then
		self:Connect(dim, "MouseButton1Click", function()
			component:Answer(nil, "Cancelled")
		end)
	end
	return component
end

function Window:Confirm(options)
	return self:Dialog(options)
end

function Window:ClearNotifications()
	for _, component in ipairs(self.Notifications) do
		if not component.Destroyed then
			component:Dismiss("Cleared")
		end
	end
	self.Notifications = {}
	return true
end

-- Window behaviour -----------------------------------------------------------

function Window:BeginDrag()
	if not self.Layout.Draggable then
		return false
	end
	local host = self.Host
	if not host.trackPointer then
		return false
	end
	self.Dragging = true
	local startPointer = pointerOf(host)
	local startBounds = host.bounds(self.Root)
	self:TrackConnection(host.trackPointer(function()
		if not self.Dragging then
			return
		end
		local current = pointerOf(host)
		if not startPointer or not current then
			return
		end
		local viewport = viewportOf(host)
		local originX = viewport.X * 0.5 - ((startBounds.Width or 0) * 0.5)
		local originY = viewport.Y * 0.5 - ((startBounds.Height or 0) * 0.5)
		self.Root.AnchorPoint = host.vector2(0, 0)
		self.Root.Position = host.udim2(0, originX + (current.X - startPointer.X), 0, originY + (current.Y - startPointer.Y))
	end))
	self:Connect(self.TitleBar, "MouseButton1Up", function()
		self.Dragging = false
	end)
	return true
end

function Window:SetVisible(visible)
	self.Root.Visible = visible ~= false
	return self.Root.Visible
end

function Window:Show()
	return self:SetVisible(true)
end

function Window:Hide()
	return self:SetVisible(false)
end

function Window:IsVisible()
	return self.Root.Visible == true
end

function Window:Toggle()
	return self:SetVisible(not self:IsVisible())
end

function Window:Minimize()
	self.Minimized = not self.Minimized
	self.Body.Visible = not self.Minimized
	local widthScale, widthOffset = self.Root.Size.X.Scale, self.Root.Size.X.Offset
	self.Root.Size = self.Minimized
		and self.Host.udim2(widthScale, widthOffset, 0, self.ChromeHeight)
		or self.Host.udim2(widthScale, widthOffset, 0.68, 360)
	return self.Minimized
end

function Window:SetSize(widthScale, widthOffset, heightScale, heightOffset)
	self.Root.Size = self.Host.udim2(widthScale, widthOffset, heightScale, heightOffset)
	return self.Root.Size
end

function Window:SetPosition(x, y)
	self.Root.AnchorPoint = self.Host.vector2(0, 0)
	self.Root.Position = self.Host.udim2(0, x, 0, y)
	return self.Root.Position
end

function Window:Close()
	if self.Destroyed then
		return false
	end
	self.Closed:Fire()
	if self.Options.OnClose then
		self.Options.OnClose()
	end
	return self:Destroy()
end

-- Configuration --------------------------------------------------------------

-- The configuration manager lives on its own field: Context.Configuration is the
-- render-time table that the Surface helpers read while drawing window chrome.
function Window:Config()
	if not self.Context.ConfigManager then
		local Config = __NEVA_Configuration_Config
		self.Context.ConfigManager = Config.new(self.Context, {
			Folder = self.Options.ConfigFolder or (self.Options.Configuration and self.Options.Configuration.ConfigFolder) or "NEVAHEXUI",
			Enabled = self.Options.SaveConfigs ~= false,
		})
	end
	return self.Context.ConfigManager
end

function Window:SaveConfig(name)
	local config = self:Config()
	return config:Save(name or "default", config:Snapshot())
end

function Window:LoadConfig(name)
	local config = self:Config()
	local data = config:Load(name or "default")
	if not data then
		return false, "config not found"
	end
	return config:Apply(data)
end

function Window:ListConfigs()
	return self:Config():List()
end

function Window:DeleteConfig(name)
	return self:Config():Delete(name or "default")
end

function Window:ExportConfig()
	local config = self:Config()
	return config:Export(config:Snapshot())
end

function Window:ImportConfig(text, options)
	options = options or {}
	return self:Config():Import(text, options.Name or "imported", options)
end

-- Studio ---------------------------------------------------------------------

function Window:OpenStudio(options)
	local Studio = __NEVA_Studio
	self.Studio = self.Studio or Studio.new(self, options)
	return self.Studio
end

-- Lifecycle ------------------------------------------------------------------

function Window:GetComponentCount()
	local total = 0
	for _, tab in ipairs(self.Tabs) do
		total += tab:GetComponentCount()
	end
	return total
end

function Window:SetTitle(title)
	self.Name = tostring(title)
	if self.TitleLabel then
		self.TitleLabel.Text = self.Name
	end
	return self.Name
end

function Window:Summary()
	return {
		Name = self.Name,
		Layout = self.LayoutId,
		Theme = self:GetTheme(),
		Tabs = #self.Tabs,
		Components = self:GetComponentCount(),
		Notifications = #self.Notifications,
		Minimized = self.Minimized,
	}
end

function Window:Destroy()
	if self.Destroyed then
		return false
	end
	self.Destroyed = true
	self.Dragging = false
	for _, connection in ipairs(self.ConnectionList) do
		if connection and connection.Disconnect then
			pcall(function()
				connection:Disconnect()
			end)
		end
	end
	self.ConnectionList = {}
	for _, component in ipairs(self.Notifications) do
		if not component.Destroyed then
			pcall(function()
				component:Destroy()
			end)
		end
	end
	self.Notifications = {}
	for _, tab in ipairs(self.Tabs) do
		if not tab.Destroyed then
			pcall(function()
				tab:Destroy()
			end)
		end
	end
	self.Tabs = {}
	if self.Studio and self.Studio.Destroy then
		pcall(function()
			self.Studio:Destroy()
		end)
	end
	if self.Root then
		self.Host.destroy(self.Root)
		self.Root = nil
	end
	return true
end

return Window
end)()

local __NEVA_Styles_Defs_Buttons = (function()
--[[
	NEVAHEXUI - Styles/Defs/Buttons
	Button and IconButton component descriptors plus their style
	implementations. Each style builds its own instance tree; they are not
	parameter variations of one renderer.
]]

local Registry = __NEVA_Styles_Registry
local Surface = __NEVA_Styles_Surface
local Helpers = __NEVA_Styles_Helpers

local BUTTON_PROPERTIES = {
	{ Key = "RowHeight", Type = "number", Default = 30, Min = 16, Max = 120, Group = "Geometry", Description = "Total row height." },
	{ Key = "TextSize", Type = "number", Default = 13, Min = 8, Max = 32, Group = "Typography" },
	{ Key = "Font", Type = "font", Group = "Typography" },
	{ Key = "TextColor", Type = "color", Group = "Typography" },
	{ Key = "TextAlignment", Type = "enum", Options = { "Left", "Center", "Right" }, Default = "Center", Group = "Typography" },
	{ Key = "BackgroundColor", Type = "color", Group = "Appearance" },
	{ Key = "HoverColor", Type = "color", Group = "States" },
	{ Key = "PressedColor", Type = "color", Group = "States" },
	{ Key = "CornerRadius", Type = "number", Min = 0, Max = 32, Group = "Geometry" },
	{ Key = "Transparency", Type = "number", Min = 0, Max = 1, Step = 0.01, Group = "Appearance" },
	{ Key = "StrokeColor", Type = "color", Group = "Appearance" },
	{ Key = "StrokeThickness", Type = "number", Min = 0, Max = 8, Default = 1, Group = "Appearance" },
	{ Key = "Animation", Type = "animation", Default = "quick", Group = "Animation" },
	{ Key = "AnimationDuration", Type = "number", Min = 0, Max = 2, Group = "Animation" },
	{ Key = "Icon", Type = "string", Group = "Appearance" },
	{ Key = "IconSide", Type = "enum", Options = { "Left", "Right" }, Default = "Left", Group = "Appearance" },
}

local BUTTON_DEFAULTS = {
	RowHeight = 30,
	TextSize = 13,
	TextAlignment = "Center",
	StrokeThickness = 1,
	Transparency = 0,
	Animation = "quick",
	IconSide = "Left",
}

Registry.registerComponent({
	Name = "Button",
	RegistryName = "Buttons",
	Category = "Controls",
	Description = "Momentary action control. Its value is the number of activations.",
	Defaults = BUTTON_DEFAULTS,
	Properties = BUTTON_PROPERTIES,
})

Registry.registerComponent({
	Name = "IconButton",
	RegistryName = "IconButtons",
	Category = "Controls",
	Description = "Compact icon-only action control.",
	Defaults = {
		RowHeight = 28,
		ButtonSize = 28,
		StrokeThickness = 1,
		IconSize = 16,
		Transparency = 0,
		Animation = "quick",
	},
	Properties = {
		{ Key = "RowHeight", Type = "number", Default = 28, Min = 16, Max = 120, Group = "Geometry" },
		{ Key = "ButtonSize", Type = "number", Default = 28, Min = 16, Max = 96, Group = "Geometry" },
		{ Key = "IconSize", Type = "number", Default = 16, Min = 8, Max = 64, Group = "Appearance" },
		{ Key = "Icon", Type = "string", Group = "Appearance" },
		{ Key = "BackgroundColor", Type = "color", Group = "Appearance" },
		{ Key = "IconColor", Type = "color", Group = "Appearance" },
		{ Key = "HoverColor", Type = "color", Group = "States" },
		{ Key = "PressedColor", Type = "color", Group = "States" },
		{ Key = "CornerRadius", Type = "number", Min = 0, Max = 32, Group = "Geometry" },
		{ Key = "Transparency", Type = "number", Min = 0, Max = 1, Step = 0.01, Group = "Appearance" },
		{ Key = "StrokeColor", Type = "color", Group = "Appearance" },
		{ Key = "StrokeThickness", Type = "number", Min = 0, Max = 8, Default = 1, Group = "Appearance" },
		{ Key = "Animation", Type = "animation", Default = "quick", Group = "Animation" },
	},
})

local function cornerOf(ctx, config)
	local radius = config.CornerRadius
	if radius == nil then
		radius = ctx.Tokens.CornerRadius
	end
	if radius == nil then
		radius = 8
	end
	return radius
end

local styles = {}

styles[#styles + 1] = {
	Id = "button.modern",
	Name = "Modern",
	Component = "Button",
	Category = "Controls",
	Description = "Rounded surface button with hover tint and optional stroke.",
	Tags = { "filled", "default" },
	Render = function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local slot = Surface.slot(ctx, { Height = config.RowHeight or 30, Label = false })
		local base = Surface.color(ctx, config.BackgroundColor, "SurfaceAlt")
		local textColour = Surface.color(ctx, config.TextColor, "Text")
		local panel = Surface.panel(ctx, slot.Root, {
			Name = "Body",
			Background = config.BackgroundColor,
			Token = "SurfaceAlt",
			Transparency = Surface.transparency(ctx, config.Transparency, "SurfaceTransparency", 0),
			CornerRadius = cornerOf(ctx, config),
			Stroke = config.StrokeColor,
			StrokeThickness = config.StrokeThickness or 1,
		})
		panel.Size = host.udim2(1, 0, 1, 0)
		local label = Surface.text(ctx, panel, {
			Size = host.udim2(1, -20, 1, 0),
			Position = host.udim2(0, 10, 0, 0),
			Text = ctx.Props.Name or "",
			TextColor3 = textColour,
			Font = ctx.Tokens.FontBold,
			TextSize = config.TextSize or 13,
			TextXAlignment = host.enumItem("TextXAlignment", config.TextAlignment or "Center"),
		})
		local input = Surface.hit(ctx, panel)
		Surface.wirePress(ctx, input)
		local view = {
			Root = slot.Root,
			Input = input,
			Body = panel,
			Label = label,
			Base = base,
			BaseText = textColour,
			Hover = Surface.color(ctx, config.HoverColor, "Surface"),
		}
		view.Disabled = Surface.disabledColour(ctx, base)
		view.Apply = function(self, state, renderCtx)
			local configuration = renderCtx.Configuration
			if not state.Enabled then
				self.Body.BackgroundColor3 = self.Disabled
				self.Label.TextColor3 = Surface.disabledText(renderCtx, self.BaseText)
			elseif renderCtx.Component and renderCtx.Component.Pressed then
				self.Body.BackgroundColor3 = Surface.color(renderCtx, configuration.PressedColor, "Accent")
			elseif state.Hovered then
				self.Body.BackgroundColor3 = self.Hover
				self.Label.TextColor3 = self.BaseText
			else
				self.Body.BackgroundColor3 = self.Base
				self.Label.TextColor3 = self.BaseText
			end
		end
		return view
	end,
}

styles[#styles + 1] = {
	Id = "button.flat",
	Name = "Flat",
	Component = "Button",
	Category = "Controls",
	Description = "Borderless flat button with an accent underline on hover.",
	Tags = { "flat" },
	Render = function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local slot = Surface.slot(ctx, { Height = config.RowHeight or 30, Label = false })
		local panel = host.new("Frame", {
			Name = "Body",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = host.udim2(1, 0, 1, 0),
		}, slot.Root)
		local label = Surface.text(ctx, panel, {
			Size = host.udim2(1, 0, 1, 0),
			Text = ctx.Props.Name or "",
			TextColor3 = Surface.color(ctx, config.TextColor, "Text"),
			Font = ctx.Tokens.Font,
			TextSize = config.TextSize or 13,
			TextXAlignment = host.enumItem("TextXAlignment", config.TextAlignment or "Center"),
		})
		local underline = host.new("Frame", {
			Name = "Underline",
			BackgroundColor3 = ctx.Tokens.Accent,
			BorderSizePixel = 0,
			Size = host.udim2(0, 0, 0, 2),
			Position = host.udim2(0.5, 0, 1, -2),
			AnchorPoint = host.vector2(0.5, 0),
			BackgroundTransparency = 1,
		}, panel)
		local input = Surface.hit(ctx, panel)
		Surface.wirePress(ctx, input)
		local view = {
			Root = slot.Root,
			Input = input,
			Body = panel,
			Label = label,
			Underline = underline,
			BaseText = Surface.color(ctx, config.TextColor, "Text"),
			AccentText = Surface.color(ctx, config.HoverColor, "Accent"),
		}
		view.Apply = function(self, state, renderCtx)
			local width = 0
			if not state.Enabled then
				self.Label.TextColor3 = Surface.disabledText(renderCtx, self.BaseText)
			elseif renderCtx.Component and renderCtx.Component.Pressed then
				width = 1
				self.Label.TextColor3 = self.AccentText
			elseif state.Hovered then
				width = 1
				self.Label.TextColor3 = self.AccentText
			else
				self.Label.TextColor3 = self.BaseText
			end
			Surface.animate(renderCtx, self.Underline, {
				Size = self.Underline.Size and renderCtx.Host.udim2(width, 0, 0, 2) or renderCtx.Host.udim2(width, 0, 0, 2),
				BackgroundTransparency = width > 0 and 0 or 1,
			})
		end
		return view
	end,
}

styles[#styles + 1] = {
	Id = "button.glass",
	Name = "Glass",
	Component = "Button",
	Category = "Controls",
	Description = "Translucent gradient button with a bright rim, designed for overlays.",
	Tags = { "glass", "gradient" },
	Render = function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local slot = Surface.slot(ctx, { Height = config.RowHeight or 30, Label = false })
		local panel = Surface.panel(ctx, slot.Root, {
			Name = "Body",
			Background = config.BackgroundColor,
			Token = "Surface",
			Transparency = Surface.transparency(ctx, config.Transparency, "SurfaceTransparency", 0.35),
			CornerRadius = cornerOf(ctx, config),
			Stroke = config.StrokeColor or ctx.Tokens.Accent,
			StrokeThickness = config.StrokeThickness or 1,
			StrokeTransparency = 0.35,
		})
		panel.Size = host.udim2(1, 0, 1, 0)
		Helpers.gradient(host, panel, ctx.Tokens.Surface, ctx.Tokens.Accent, 90, { 0.15, 0.75 })
		local label = Surface.text(ctx, panel, {
			Size = host.udim2(1, -20, 1, 0),
			Position = host.udim2(0, 10, 0, 0),
			Text = ctx.Props.Name or "",
			TextColor3 = Surface.color(ctx, config.TextColor, "Text"),
			Font = ctx.Tokens.FontBold,
			TextSize = config.TextSize or 13,
			TextXAlignment = host.enumItem("TextXAlignment", config.TextAlignment or "Center"),
		})
		local input = Surface.hit(ctx, panel)
		Surface.wirePress(ctx, input)
		local view = {
			Root = slot.Root,
			Input = input,
			Body = panel,
			Label = label,
			BaseText = Surface.color(ctx, config.TextColor, "Text"),
			Base = Surface.transparency(ctx, config.Transparency, "SurfaceTransparency", 0.35),
		}
		view.Apply = function(self, state, renderCtx)
			if not state.Enabled then
				self.Label.TextColor3 = Surface.disabledText(renderCtx, self.BaseText)
				self.Body.BackgroundTransparency = math.min(1, self.Base + 0.3)
			elseif renderCtx.Component and renderCtx.Component.Pressed then
				self.Body.BackgroundTransparency = math.max(0, self.Base - 0.2)
			elseif state.Hovered then
				self.Body.BackgroundTransparency = math.max(0, self.Base - 0.1)
			else
				self.Body.BackgroundTransparency = self.Base
				self.Label.TextColor3 = self.BaseText
			end
		end
		return view
	end,
}

local function iconButtonRender(options)
	return function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local slot = Surface.slot(ctx, { Height = config.RowHeight or 28, ControlWidth = config.ButtonSize or 28 })
		local size = config.ButtonSize or 28
		local parent = slot.ControlArea or slot.Root
		local button = Surface.panel(ctx, parent, {
			Name = "Body",
			Background = config.BackgroundColor,
			Token = options.token,
			Transparency = Surface.transparency(ctx, config.Transparency, "SurfaceTransparency", options.transparency),
			CornerRadius = options.radius == "round" and size / 2 or (config.CornerRadius or ctx.Tokens.CornerRadius or 8),
			Stroke = config.StrokeColor,
			StrokeThickness = config.StrokeThickness or 1,
		})
		button.Size = host.udim2(0, size, 0, size)
		button.Position = host.udim2(1, -size, 0.5, -size / 2)
		local icon = Surface.text(ctx, button, {
			Name = "Icon",
			Size = host.udim2(1, 0, 1, 0),
			Text = config.Icon or ctx.Props.Icon or "\u{25CF}",
			TextColor3 = Surface.color(ctx, config.IconColor, "Text"),
			Font = ctx.Tokens.FontBold,
			TextSize = config.IconSize or 16,
			TextXAlignment = host.enumItem("TextXAlignment", "Center"),
			TextYAlignment = host.enumItem("TextYAlignment", "Center"),
		})
		local input = Surface.hit(ctx, button)
		Surface.wirePress(ctx, input)
		local view = {
			Root = slot.Root,
			Input = input,
			Body = button,
			Icon = icon,
			Base = Surface.color(ctx, config.BackgroundColor, options.token),
			BaseText = Surface.color(ctx, config.IconColor, "Text"),
			Hover = Surface.color(ctx, config.HoverColor, "SurfaceAlt"),
		}
		view.Disabled = Surface.disabledColour(ctx, view.Base)
		view.Apply = function(self, state, renderCtx)
			local configuration = renderCtx.Configuration
			if not state.Enabled then
				self.Body.BackgroundColor3 = self.Disabled
				self.Icon.TextColor3 = Surface.disabledText(renderCtx, self.BaseText)
			elseif renderCtx.Component and renderCtx.Component.Pressed then
				self.Body.BackgroundColor3 = Surface.color(renderCtx, configuration.PressedColor, "Accent")
			elseif state.Hovered then
				self.Body.BackgroundColor3 = self.Hover
			else
				self.Body.BackgroundColor3 = self.Base
				self.Icon.TextColor3 = self.BaseText
			end
		end
		return view
	end
end

styles[#styles + 1] = {
	Id = "iconbutton.rounded",
	Name = "Rounded icon",
	Component = "IconButton",
	Category = "Controls",
	Description = "Circular icon button with a filled surface.",
	Render = iconButtonRender({ token = "SurfaceAlt", radius = "round", transparency = 0 }),
}

styles[#styles + 1] = {
	Id = "iconbutton.ghost",
	Name = "Ghost icon",
	Component = "IconButton",
	Category = "Controls",
	Description = "Transparent icon button that only gains a surface on hover.",
	Render = iconButtonRender({ token = "Surface", radius = "square", transparency = 1 }),
}

local registered, failures = Registry.registerMany(styles, { BuiltIn = true })
for _, failure in ipairs(failures) do
	error(("NEVAHEXUI: buttons style %s failed to register: %s"):format(tostring(failure.Id), table.concat(failure.Errors, "; ")))
end

return registered
end)()

local __NEVA_Styles_Defs_DataViews = (function()
--[[
	NEVAHEXUI - Styles/Defs/DataViews
	Descriptors and renderers for the data-oriented display components: Table,
	TreeView, LogView and Graph. Each exposes a single renderer because these
	categories have one genuinely distinct presentation each (documented in the
	style catalog rather than padded with near-identical variants).
]]

local Registry = __NEVA_Styles_Registry
local Surface = __NEVA_Styles_Surface
local Helpers = __NEVA_Styles_Helpers

Registry.registerComponent({
	Name = "Table", RegistryName = "Tables", Category = "Display",
	Description = "Columnar data list with a header row.",
	Defaults = { RowHeight = 26, HeaderHeight = 28, MaxRows = 8, Stripe = true, TextSize = 12 },
	Properties = {
		{ Key = "RowHeight", Type = "number", Default = 26, Min = 16, Max = 80, Group = "Geometry" },
		{ Key = "HeaderHeight", Type = "number", Default = 28, Min = 16, Max = 80, Group = "Geometry" },
		{ Key = "MaxRows", Type = "number", Default = 8, Min = 1, Max = 100, Group = "Behaviour" },
		{ Key = "RowColor", Type = "color", Group = "Appearance" },
		{ Key = "AltRowColor", Type = "color", Group = "Appearance" },
		{ Key = "HeaderColor", Type = "color", Group = "Appearance" },
		{ Key = "TextColor", Type = "color", Group = "Typography" },
		{ Key = "TextSize", Type = "number", Default = 12, Min = 8, Max = 24, Group = "Typography" },
		{ Key = "Stripe", Type = "boolean", Default = true, Group = "Appearance" },
	},
})

Registry.registerComponent({
	Name = "TreeView", RegistryName = "TreeViews", Category = "Display",
	Description = "Expandable node hierarchy.",
	Defaults = { RowHeight = 24, Indent = 14, ExpandGlyph = "+", CollapseGlyph = "-", TextSize = 13 },
	Properties = {
		{ Key = "RowHeight", Type = "number", Default = 24, Min = 14, Max = 64, Group = "Geometry" },
		{ Key = "Indent", Type = "number", Default = 14, Min = 0, Max = 48, Group = "Geometry" },
		{ Key = "TextSize", Type = "number", Default = 13, Min = 8, Max = 24, Group = "Typography" },
		{ Key = "TextColor", Type = "color", Group = "Typography" },
		{ Key = "SelectedColor", Type = "color", Group = "States" },
		{ Key = "ExpandGlyph", Type = "string", Default = "+", Group = "Appearance" },
		{ Key = "CollapseGlyph", Type = "string", Default = "-", Group = "Appearance" },
	},
})

Registry.registerComponent({
	Name = "LogView", RegistryName = "LogViews", Category = "Display",
	Description = "Append-only console output.",
	Defaults = { RowHeight = 120, MaxLines = 6, Monospace = true, Transparency = 0.1, TextSize = 12 },
	Properties = {
		{ Key = "RowHeight", Type = "number", Default = 120, Min = 40, Max = 600, Group = "Geometry" },
		{ Key = "MaxLines", Type = "number", Default = 6, Min = 1, Max = 200, Group = "Behaviour" },
		{ Key = "BackgroundColor", Type = "color", Group = "Appearance" },
		{ Key = "Transparency", Type = "number", Min = 0, Max = 1, Step = 0.01, Default = 0.1, Group = "Appearance" },
		{ Key = "TextColor", Type = "color", Group = "Typography" },
		{ Key = "MutedColor", Type = "color", Group = "Typography" },
		{ Key = "TextSize", Type = "number", Default = 12, Min = 8, Max = 24, Group = "Typography" },
		{ Key = "Monospace", Type = "boolean", Default = true, Group = "Typography" },
	},
})

Registry.registerComponent({
	Name = "Graph", RegistryName = "Graphs", Category = "Display",
	Description = "Stepped line graph for a numeric series.",
	Defaults = { RowHeight = 120, Points = 24, LineHeight = 2, ShowGrid = true },
	Properties = {
		{ Key = "RowHeight", Type = "number", Default = 120, Min = 40, Max = 600, Group = "Geometry" },
		{ Key = "Points", Type = "number", Default = 24, Min = 4, Max = 200, Group = "Geometry" },
		{ Key = "LineColor", Type = "color", Group = "Appearance" },
		{ Key = "GridColor", Type = "color", Group = "Appearance" },
		{ Key = "LineHeight", Type = "number", Default = 2, Min = 1, Max = 8, Group = "Appearance" },
		{ Key = "ShowGrid", Type = "boolean", Default = true, Group = "Appearance" },
	},
})

local styles = {}

styles[#styles + 1] = {
	Id = "table.data", Name = "Data table", Component = "Table", Category = "Display",
	Description = "Header row plus striped data rows fed from the value array.",
	Tags = { "default" },
	Render = function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local columns = ctx.State.Columns or {}
		local rows = ctx.State.Value or {}
		local rowHeight = config.RowHeight or 26
		local headerHeight = config.HeaderHeight or 28
		local visible = math.max(1, math.min(#rows, config.MaxRows or 8))
		local slot = Surface.slot(ctx, { Height = headerHeight + visible * rowHeight + 8, Label = false })
		local holder = host.new("Frame", {
			Name = "Table",
			BackgroundColor3 = config.RowColor and Surface.color(ctx, config.RowColor, "SurfaceAlt") or ctx.Tokens.SurfaceAlt,
			BackgroundTransparency = 0.15,
			BorderSizePixel = 0,
			Size = host.udim2(1, 0, 1, 0),
			ClipsDescendants = true,
		}, slot.Root)
		Helpers.corner(host, holder, ctx.Tokens.CornerRadius)
		Helpers.stroke(host, holder, ctx.Tokens.Outline, 1, 0.4)
		local header = host.new("Frame", {
			Name = "Header",
			BackgroundColor3 = config.HeaderColor and Surface.color(ctx, config.HeaderColor, "Surface") or ctx.Tokens.Surface,
			BackgroundTransparency = 0.2,
			BorderSizePixel = 0,
			Size = host.udim2(1, 0, 0, headerHeight),
		}, holder)
		local columnWidth = 1 / math.max(1, #columns)
		for index, column in ipairs(columns) do
			Surface.text(ctx, header, {
				Name = "Header" .. tostring(index),
				Size = host.udim2(columnWidth, -8, 1, 0),
				Position = host.udim2(columnWidth * (index - 1), 4, 0, 0),
				Text = tostring(column),
				TextColor3 = ctx.Tokens.TextMuted,
				Font = ctx.Tokens.FontBold,
				TextSize = config.TextSize or 12,
				TextTruncate = host.enumItem("TextTruncate", "AtEnd"),
			})
		end
		local rowViews = {}
		for rowIndex = 1, visible do
			local row = host.new("Frame", {
				Name = "Row" .. tostring(rowIndex),
				BackgroundColor3 = (config.Stripe ~= false and rowIndex % 2 == 0)
					and (config.AltRowColor and Surface.color(ctx, config.AltRowColor, "Surface") or ctx.Tokens.Surface)
					or ctx.Tokens.SurfaceAlt,
				BackgroundTransparency = 0.35,
				BorderSizePixel = 0,
				Size = host.udim2(1, 0, 0, rowHeight),
				Position = host.udim2(0, 0, 0, headerHeight + (rowIndex - 1) * rowHeight),
			}, holder)
			local cells = {}
			for columnIndex = 1, math.max(1, #columns) do
				cells[columnIndex] = Surface.text(ctx, row, {
					Name = "Cell" .. tostring(columnIndex),
					Size = host.udim2(columnWidth, -8, 1, 0),
					Position = host.udim2(columnWidth * (columnIndex - 1), 4, 0, 0),
					Text = "",
					TextColor3 = Surface.color(ctx, config.TextColor, "Text"),
					TextSize = config.TextSize or 12,
					TextTruncate = host.enumItem("TextTruncate", "AtEnd"),
				})
			end
			rowViews[rowIndex] = { Row = row, Cells = cells }
		end
		local view = { Root = slot.Root, Holder = holder, Rows = rowViews }
		view.Apply = function(self, state)
			local data = type(state.Value) == "table" and state.Value or {}
			for rowIndex, entry in ipairs(self.Rows) do
				local row = data[rowIndex]
				entry.Row.Visible = row ~= nil
				for columnIndex, cell in ipairs(entry.Cells) do
					local value = row and row[columnIndex]
					cell.Text = value == nil and "" or tostring(value)
				end
			end
		end
		return view
	end,
}

styles[#styles + 1] = {
	Id = "treeview.plain", Name = "Plain tree", Component = "TreeView", Category = "Display",
	Description = "Flattened node list with expand and collapse glyphs.",
	Tags = { "default" },
	Render = function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local nodes = ctx.State.Nodes or {}
		local rowHeight = config.RowHeight or 24
		local indent = config.Indent or 14
		local slot = Surface.slot(ctx, { Height = math.max(rowHeight, math.max(1, #nodes) * rowHeight), Label = false })
		local holder = host.new("Frame", {
			Name = "Nodes",
			BackgroundTransparency = 1,
			Size = host.udim2(1, 0, 1, 0),
		}, slot.Root)
		local rows = {}
		for index, node in ipairs(nodes) do
			local depth = node.Depth or 0
			local row = Surface.hit(ctx, holder, {
				Name = "Node" .. tostring(index),
				Size = host.udim2(1, -(depth * indent), 0, rowHeight),
				Position = host.udim2(0, depth * indent, 0, (index - 1) * rowHeight),
				BackgroundTransparency = 1,
			})
			local glyph = Surface.text(ctx, row, {
				Name = "Glyph",
				Size = host.udim2(0, indent, 1, 0),
				Text = node.HasChildren
					and (node.Expanded and (config.CollapseGlyph or "-") or (config.ExpandGlyph or "+"))
					or "",
				TextColor3 = ctx.Tokens.TextMuted,
				TextSize = math.max(10, rowHeight - 12),
				TextXAlignment = host.enumItem("TextXAlignment", "Center"),
			})
			local label = Surface.text(ctx, row, {
				Name = "Label",
				Size = host.udim2(1, -(indent + 6), 1, 0),
				Position = host.udim2(0, indent + 4, 0, 0),
				Text = tostring(node.Label or ""),
				TextColor3 = Surface.color(ctx, config.TextColor, "Text"),
				TextSize = config.TextSize or 13,
				TextTruncate = host.enumItem("TextTruncate", "AtEnd"),
			})
			rows[index] = { Row = row, Glyph = glyph, Label = label, Node = node }
		end
		local view = {
			Root = slot.Root,
			Rows = rows,
			SelectedColour = Surface.color(ctx, config.SelectedColor, "Accent"),
			IdleColour = Surface.color(ctx, config.TextColor, "Text"),
		}
		view.Apply = function(self, state)
			local selected = state.Value
			for _, entry in ipairs(self.Rows) do
				entry.Label.TextColor3 = (selected ~= nil and entry.Node.Id == selected)
					and self.SelectedColour
					or self.IdleColour
			end
		end
		return view
	end,
}

styles[#styles + 1] = {
	Id = "logview.console", Name = "Console log", Component = "LogView", Category = "Display",
	Description = "Scrollable monospace console with level colouring.",
	Tags = { "default" },
	Render = function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local height = config.RowHeight or 120
		local slot = Surface.slot(ctx, { Height = height, Label = false })
		local panel = Surface.panel(ctx, slot.Root, {
			Name = "Console",
			Background = config.BackgroundColor,
			Token = "Background",
			Transparency = Surface.transparency(ctx, config.Transparency, "BackgroundTransparency", 0.1),
			CornerRadius = ctx.Tokens.CornerRadius,
			Stroke = ctx.Tokens.Outline,
			StrokeThickness = 1,
		})
		panel.Size = host.udim2(1, 0, 1, 0)
		local lines = host.new("ScrollingFrame", {
			Name = "Lines",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = host.udim2(1, -10, 1, -10),
			Position = host.udim2(0, 5, 0, 5),
			ScrollBarThickness = 2,
			CanvasSize = host.udim2(0, 0, 0, 0),
		}, panel)
		host.new("UIListLayout", {
			FillDirection = host.enumItem("FillDirection", "Vertical"),
			SortOrder = host.enumItem("SortOrder", "LayoutOrder"),
		}, lines)
		local rows = {}
		for index = 1, math.max(1, config.MaxLines or 6) do
			rows[index] = Surface.text(ctx, lines, {
				Name = "Line" .. tostring(index),
				Size = host.udim2(1, 0, 0, 15),
				Text = "",
				TextColor3 = Surface.color(ctx, config.TextColor, "Text"),
				Font = config.Monospace ~= false and host.font("Code") or ctx.Tokens.Font,
				TextSize = config.TextSize or 12,
				TextTruncate = host.enumItem("TextTruncate", "AtEnd"),
				LayoutOrder = index,
			})
		end
		local view = {
			Root = slot.Root,
			Lines = rows,
			InfoColour = Surface.color(ctx, config.TextColor, "Text"),
			MutedColour = Surface.color(ctx, config.MutedColor, "TextMuted"),
			WarnColour = ctx.Tokens.Warning,
			ErrorColour = ctx.Tokens.Negative,
		}
		view.Apply = function(self, state)
			local entries = type(state.Value) == "table" and state.Value or {}
			local offset = math.max(0, #entries - #self.Lines)
			for index, label in ipairs(self.Lines) do
				local entry = entries[offset + index]
				if entry then
					label.Text = tostring(entry.Text ~= nil and entry.Text or entry)
					local level = entry.Level or "Info"
					label.TextColor3 = level == "Error" and self.ErrorColour
						or level == "Warn" and self.WarnColour
						or level == "Muted" and self.MutedColour
						or self.InfoColour
					label.Visible = true
				else
					label.Text = ""
					label.Visible = false
				end
			end
		end
		return view
	end,
}

styles[#styles + 1] = {
	Id = "graph.line", Name = "Stepped graph", Component = "Graph", Category = "Display",
	Description = "Grid-backed stepped line graph drawn from bar segments.",
	Tags = { "default" },
	Render = function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local height = config.RowHeight or 120
		local lineHeight = config.LineHeight or 2
		local points = math.max(2, config.Points or 24)
		local steps = points - 1
		local slot = Surface.slot(ctx, { Height = height, Label = false })
		local panel = Surface.panel(ctx, slot.Root, {
			Name = "Graph",
			Background = config.GridColor,
			Token = "Background",
			Transparency = 0.2,
			CornerRadius = ctx.Tokens.CornerRadius,
			Stroke = ctx.Tokens.Outline,
			StrokeThickness = 1,
		})
		panel.Size = host.udim2(1, 0, 1, 0)
		panel.ClipsDescendants = true
		if config.ShowGrid ~= false then
			for index = 1, 3 do
				host.new("Frame", {
					Name = "GridLine" .. tostring(index),
					BackgroundColor3 = ctx.Tokens.Outline,
					BackgroundTransparency = 0.6,
					BorderSizePixel = 0,
					Size = host.udim2(1, 0, 0, 1),
					Position = host.udim2(0, 0, index / 4, 0),
				}, panel)
			end
		end
		local segments = {}
		for index = 1, steps do
			segments[index] = {
				Horizontal = host.new("Frame", {
					Name = "H" .. tostring(index),
					BackgroundColor3 = Surface.color(ctx, config.LineColor, "Accent"),
					BorderSizePixel = 0,
					Size = host.udim2(1 / steps, 0, 0, lineHeight),
					Position = host.udim2((index - 1) / steps, 0, 0, 0),
					AnchorPoint = host.vector2(0, 0.5),
				}, panel),
				Vertical = host.new("Frame", {
					Name = "V" .. tostring(index),
					BackgroundColor3 = Surface.color(ctx, config.LineColor, "Accent"),
					BackgroundTransparency = 0.3,
					BorderSizePixel = 0,
					Size = host.udim2(0, lineHeight, 0, 0),
					Position = host.udim2(index / steps, 0, 0, 0),
					AnchorPoint = host.vector2(0.5, 0.5),
				}, panel),
			}
		end
		local view = {
			Root = slot.Root,
			Panel = panel,
			Segments = segments,
			Steps = steps,
			LineHeight = lineHeight,
			Height = height,
		}
		view.Apply = function(self, state)
			local series = type(state.Value) == "table" and state.Value or {}
			local function sample(index)
				if #series == 0 then
					return 0
				end
				local position = ((index - 1) / self.Steps) * (#series - 1) + 1
				local low = math.floor(position)
				local high = math.min(#series, low + 1)
				local alpha = position - low
				local a = tonumber(series[low]) or 0
				local b = tonumber(series[high]) or a
				return math.max(0, math.min(1, a + (b - a) * alpha))
			end
			for index, segment in ipairs(self.Segments) do
				local value = sample(index)
				local delta = sample(index + 1) - value
				segment.Horizontal.Position = ctx.Host.udim2((index - 1) / self.Steps, 0, 1 - value, 0)
				segment.Vertical.Position = ctx.Host.udim2(index / self.Steps, 0, 1 - value - delta / 2, 0)
				segment.Vertical.Size = ctx.Host.udim2(0, self.LineHeight, 0, math.abs(delta) * self.Height)
			end
		end
		return view
	end,
}

local registered, failures = Registry.registerMany(styles, { BuiltIn = true })
for _, failure in ipairs(failures) do
	error(("NEVAHEXUI: data view style %s failed to register: %s"):format(tostring(failure.Id), table.concat(failure.Errors, "; ")))
end

return registered
end)()

local __NEVA_Styles_Defs_Display = (function()
--[[
	NEVAHEXUI - Styles/Defs/Display
	Component descriptors plus the first group of display renderers. Display
	components have no value the user sets directly, so they expose fewer styles
	than interactive categories; every one of them is a real renderer.
]]

local Registry = __NEVA_Styles_Registry
local Surface = __NEVA_Styles_Surface
local Helpers = __NEVA_Styles_Helpers

local function component(spec)
	Registry.registerComponent(spec)
end

component({
	Name = "Label", RegistryName = "Labels", Category = "Display",
	Description = "Static text with an optional description.",
	Defaults = { RowHeight = 22, TextSize = 13, Wrapped = false, Alignment = "Left" },
	Properties = {
		{ Key = "RowHeight", Type = "number", Default = 22, Min = 12, Max = 200, Group = "Geometry" },
		{ Key = "TextSize", Type = "number", Default = 13, Min = 8, Max = 40, Group = "Typography" },
		{ Key = "TextColor", Type = "color", Group = "Typography" },
		{ Key = "Font", Type = "font", Group = "Typography" },
		{ Key = "Alignment", Type = "enum", Options = { "Left", "Center", "Right" }, Default = "Left", Group = "Typography" },
		{ Key = "Wrapped", Type = "boolean", Default = false, Group = "Typography" },
	},
})

component({
	Name = "Divider", RegistryName = "Dividers", Category = "Display",
	Description = "Horizontal rule with an optional caption.",
	Defaults = { RowHeight = 14, Thickness = 1, Transparency = 0.4 },
	Properties = {
		{ Key = "RowHeight", Type = "number", Default = 14, Min = 4, Max = 80, Group = "Geometry" },
		{ Key = "Thickness", Type = "number", Default = 1, Min = 1, Max = 8, Group = "Geometry" },
		{ Key = "Color", Type = "color", Group = "Appearance" },
		{ Key = "Transparency", Type = "number", Min = 0, Max = 1, Step = 0.01, Default = 0.4, Group = "Appearance" },
		{ Key = "Caption", Type = "string", Default = "", Group = "Typography" },
	},
})

component({
	Name = "Badge", RegistryName = "Badges", Category = "Display",
	Description = "Small status pill.",
	Defaults = { RowHeight = 20, Height = 18, Padding = 8, TextSize = 12 },
	Properties = {
		{ Key = "RowHeight", Type = "number", Default = 20, Min = 12, Max = 80, Group = "Geometry" },
		{ Key = "Height", Type = "number", Default = 18, Min = 10, Max = 60, Group = "Geometry" },
		{ Key = "Padding", Type = "number", Default = 8, Min = 0, Max = 32, Group = "Geometry" },
		{ Key = "TextSize", Type = "number", Default = 12, Min = 8, Max = 28, Group = "Typography" },
		{ Key = "TextColor", Type = "color", Group = "Typography" },
		{ Key = "BackgroundColor", Type = "color", Group = "Appearance" },
		{ Key = "StrokeColor", Type = "color", Group = "Appearance" },
		{ Key = "StrokeThickness", Type = "number", Min = 0, Max = 4, Default = 1, Group = "Appearance" },
	},
})

component({
	Name = "ProgressBar", RegistryName = "ProgressBars", Category = "Display",
	Description = "Determinate progress bar from 0 to 1.",
	Defaults = { RowHeight = 26, Width = 180, Height = 8, ShowValue = false, Animation = "smooth" },
	Properties = {
		{ Key = "RowHeight", Type = "number", Default = 26, Min = 12, Max = 120, Group = "Geometry" },
		{ Key = "Width", Type = "number", Default = 180, Min = 40, Max = 700, Group = "Geometry" },
		{ Key = "Height", Type = "number", Default = 8, Min = 2, Max = 60, Group = "Geometry" },
		{ Key = "CornerRadius", Type = "number", Min = 0, Max = 32, Group = "Geometry" },
		{ Key = "TrackColor", Type = "color", Group = "Appearance" },
		{ Key = "FillColor", Type = "color", Group = "Appearance" },
		{ Key = "TextColor", Type = "color", Group = "Typography" },
		{ Key = "ShowValue", Type = "boolean", Default = false, Group = "Behaviour" },
		{ Key = "Segments", Type = "number", Default = 10, Min = 2, Max = 40, Group = "Appearance" },
		{ Key = "Animation", Type = "animation", Default = "smooth", Group = "Animation" },
	},
})

component({
	Name = "Loader", RegistryName = "Loaders", Category = "Display",
	Description = "Indeterminate activity indicator.",
	Defaults = { RowHeight = 24, Size = 16, Dots = 3, Speed = 1 },
	Properties = {
		{ Key = "RowHeight", Type = "number", Default = 24, Min = 10, Max = 120, Group = "Geometry" },
		{ Key = "Size", Type = "number", Default = 16, Min = 6, Max = 64, Group = "Geometry" },
		{ Key = "Dots", Type = "number", Default = 3, Min = 1, Max = 8, Group = "Geometry" },
		{ Key = "Color", Type = "color", Group = "Appearance" },
		{ Key = "Speed", Type = "number", Default = 1, Min = 0.1, Max = 5, Step = 0.1, Group = "Animation" },
	},
})

component({
	Name = "Image", RegistryName = "Images", Category = "Display",
	Description = "Icon or texture display.",
	Defaults = { RowHeight = 32, Size = 32, Transparency = 0 },
	Properties = {
		{ Key = "RowHeight", Type = "number", Default = 32, Min = 8, Max = 200, Group = "Geometry" },
		{ Key = "Size", Type = "number", Default = 32, Min = 8, Max = 200, Group = "Geometry" },
		{ Key = "CornerRadius", Type = "number", Min = 0, Max = 64, Group = "Geometry" },
		{ Key = "ImageColor", Type = "color", Group = "Appearance" },
		{ Key = "Transparency", Type = "number", Min = 0, Max = 1, Step = 0.01, Default = 0, Group = "Appearance" },
	},
})

local styles = {}

styles[#styles + 1] = {
	Id = "label.plain", Name = "Plain label", Component = "Label", Category = "Display",
	Description = "Single-line text bound to the component value.",
	Tags = { "default" },
	Render = function(ctx)
		local config = ctx.Configuration
		local slot = Surface.slot(ctx, { Height = config.RowHeight or 22, Label = false })
		local label = Surface.text(ctx, slot.Root, {
			Name = "Value",
			Size = ctx.Host.udim2(1, 0, 1, 0),
			Text = tostring(ctx.State.Value or ""),
			TextColor3 = Surface.color(ctx, config.TextColor, "Text"),
			Font = Surface.font(ctx, config.Font) or ctx.Tokens.Font,
			TextSize = config.TextSize or 13,
			TextXAlignment = ctx.Host.enumItem("TextXAlignment", config.Alignment or "Left"),
			TextWrapped = config.Wrapped == true,
		})
		local view = { Root = slot.Root, Value = label }
		view.Apply = function(self, state)
			self.Value.Text = tostring(state.Value or "")
			if not state.Enabled then
				self.Value.TextColor3 = ctx.Tokens.TextMuted
			end
		end
		view.SetName = function(self, name)
			self.Value.Text = name
		end
		return view
	end,
}

styles[#styles + 1] = {
	Id = "label.heading", Name = "Heading label", Component = "Label", Category = "Display",
	Description = "Emphasised heading with a muted caption underneath.",
	Tags = { "heading" },
	Render = function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local height = math.max(config.RowHeight or 22, 34)
		local slot = Surface.slot(ctx, { Height = height, Label = false })
		local title = Surface.text(ctx, slot.Root, {
			Name = "Value",
			Size = host.udim2(1, 0, 0, height * 0.6),
			Text = tostring(ctx.State.Value or ctx.Props.Name or ""),
			TextColor3 = Surface.color(ctx, config.TextColor, "Text"),
			Font = ctx.Tokens.FontBold,
			TextSize = (config.TextSize or 13) + 2,
			TextXAlignment = host.enumItem("TextXAlignment", config.Alignment or "Left"),
		})
		local caption = Surface.text(ctx, slot.Root, {
			Name = "Caption",
			Size = host.udim2(1, 0, 0, height * 0.4),
			Position = host.udim2(0, 0, 1, -height * 0.4),
			Text = tostring(ctx.Props.Description or ""),
			TextColor3 = ctx.Tokens.TextMuted,
			TextSize = math.max(10, (config.TextSize or 13) - 2),
		})
		local view = { Root = slot.Root, Value = title, Caption = caption }
		view.Apply = function(self, state)
			self.Value.Text = tostring(state.Value or "")
		end
		view.SetName = function(self, name)
			self.Value.Text = name
		end
		return view
	end,
}

styles[#styles + 1] = {
	Id = "divider.line", Name = "Line divider", Component = "Divider", Category = "Display",
	Description = "Rule split around an optional centred caption.",
	Tags = { "default" },
	Render = function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local thickness = config.Thickness or 1
		local transparency = config.Transparency == nil and 0.4 or config.Transparency
		local slot = Surface.slot(ctx, { Height = config.RowHeight or 14, Label = false })
		local colour = Surface.color(ctx, config.Color, "Outline")
		local captionText = (config.Caption ~= nil and config.Caption ~= "") and config.Caption or ctx.Props.Name
		local hasCaption = captionText ~= nil and captionText ~= ""
		local rule
		local caption
		if hasCaption then
			local measured = #tostring(captionText) * 6 + 16
			rule = host.new("Frame", {
				Name = "RuleLeft",
				BackgroundColor3 = colour,
				BackgroundTransparency = transparency,
				BorderSizePixel = 0,
				Size = host.udim2(1, -measured, 0, thickness),
				Position = host.udim2(0, 0, 0.5, -thickness / 2),
			}, slot.Root)
			host.new("Frame", {
				Name = "RuleRight",
				BackgroundColor3 = colour,
				BackgroundTransparency = transparency,
				BorderSizePixel = 0,
				Size = host.udim2(1, -measured, 0, thickness),
				Position = host.udim2(0, measured, 0.5, -thickness / 2),
			}, slot.Root)
			caption = Surface.text(ctx, slot.Root, {
				Name = "Caption",
				Size = host.udim2(1, 0, 1, 0),
				Text = tostring(captionText),
				TextColor3 = ctx.Tokens.TextMuted,
				TextSize = math.max(10, (config.RowHeight or 14) - 4),
				TextXAlignment = host.enumItem("TextXAlignment", "Center"),
			})
		else
			rule = host.new("Frame", {
				Name = "Rule",
				BackgroundColor3 = colour,
				BackgroundTransparency = transparency,
				BorderSizePixel = 0,
				Size = host.udim2(1, 0, 0, thickness),
				Position = host.udim2(0, 0, 0.5, -thickness / 2),
			}, slot.Root)
		end
		local view = { Root = slot.Root, Rule = rule, Caption = caption }
		view.Apply = function()
			-- Divider carries no interaction state.
		end
		view.SetName = function(self, name)
			if self.Caption then
				self.Caption.Text = name
			end
		end
		return view
	end,
}

styles[#styles + 1] = {
	Id = "badge.pill", Name = "Pill badge", Component = "Badge", Category = "Display",
	Description = "Filled pill sized to its label.",
	Tags = { "default" },
	Render = function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local height = config.Height or 18
		local padding = config.Padding or 8
		local slot = Surface.slot(ctx, { Height = config.RowHeight or 20, Label = false })
		local pill = host.new("Frame", {
			Name = "Pill",
			BackgroundColor3 = Surface.color(ctx, config.BackgroundColor, "Accent"),
			BorderSizePixel = 0,
			Size = host.udim2(0, 60, 0, height),
			Position = host.udim2(0, 0, 0.5, -height / 2),
		}, slot.Root)
		Helpers.corner(host, pill, height / 2)
		local label = Surface.text(ctx, pill, {
			Name = "Label",
			Size = host.udim2(1, -padding * 2, 1, 0),
			Position = host.udim2(0, padding, 0, 0),
			Text = tostring(ctx.State.Value or ctx.Props.Name or ""),
			TextColor3 = Surface.color(ctx, config.TextColor, "AccentText"),
			Font = ctx.Tokens.FontBold,
			TextSize = config.TextSize or 12,
			TextXAlignment = host.enumItem("TextXAlignment", "Center"),
			TextTruncate = host.enumItem("TextTruncate", "AtEnd"),
		})
		local view = { Root = slot.Root, Pill = pill, Label = label, Padding = padding, Height = height }
		view.Apply = function(self, state)
			self.Label.Text = tostring(state.Value or "")
			local estimate = #self.Label.Text * (self.Label.TextSize * 0.62) + self.Padding * 2
			self.Pill.Size = ctx.Host.udim2(0, math.max(self.Height, estimate), 0, self.Height)
		end
		view.SetName = function(self, name)
			self.Label.Text = name
		end
		return view
	end,
}

styles[#styles + 1] = {
	Id = "badge.outline", Name = "Outline badge", Component = "Badge", Category = "Display",
	Description = "Transparent badge with a coloured rim.",
	Tags = { "outline" },
	Render = function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local height = config.Height or 18
		local slot = Surface.slot(ctx, { Height = config.RowHeight or 20, Label = false })
		local pill = host.new("Frame", {
			Name = "Pill",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = host.udim2(0, 64, 0, height),
			Position = host.udim2(0, 0, 0.5, -height / 2),
		}, slot.Root)
		Helpers.corner(host, pill, height / 2)
		Helpers.stroke(host, pill, Surface.color(ctx, config.StrokeColor, "Accent"), config.StrokeThickness or 1, 0)
		local label = Surface.text(ctx, pill, {
			Name = "Label",
			Size = host.udim2(1, -18, 1, 0),
			Position = host.udim2(0, 9, 0, 0),
			Text = tostring(ctx.State.Value or ctx.Props.Name or ""),
			TextColor3 = Surface.color(ctx, config.TextColor, "Accent"),
			TextSize = config.TextSize or 12,
			TextXAlignment = host.enumItem("TextXAlignment", "Center"),
		})
		local view = { Root = slot.Root, Pill = pill, Label = label }
		view.Apply = function(self, state)
			self.Label.Text = tostring(state.Value or "")
		end
		view.SetName = function(self, name)
			self.Label.Text = name
		end
		return view
	end,
}

styles[#styles + 1] = {
	Id = "progressbar.bar", Name = "Progress bar", Component = "ProgressBar", Category = "Display",
	Description = "Rounded track with an animated fill and optional percentage.",
	Tags = { "default" },
	Render = function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local width = config.Width or 180
		local height = config.Height or 8
		local slot = Surface.slot(ctx, {
			Height = config.RowHeight or 26,
			ControlWidth = width + (config.ShowValue and 44 or 0),
		})
		local parent = slot.ControlArea or slot.Root
		local track = host.new("Frame", {
			Name = "Track",
			BackgroundColor3 = Surface.color(ctx, config.TrackColor, "Outline"),
			BackgroundTransparency = 0.55,
			BorderSizePixel = 0,
			Size = host.udim2(0, width, 0, height),
			Position = host.udim2(1, -width, 0.5, -height / 2),
		}, parent)
		Helpers.corner(host, track, config.CornerRadius or height / 2)
		local fill = host.new("Frame", {
			Name = "Fill",
			BackgroundColor3 = Surface.color(ctx, config.FillColor, "Accent"),
			BorderSizePixel = 0,
			Size = host.udim2(0, 0, 1, 0),
		}, track)
		Helpers.corner(host, fill, config.CornerRadius or height / 2)
		local valueLabel
		if config.ShowValue then
			valueLabel = Surface.text(ctx, parent, {
				Name = "Value",
				Size = host.udim2(0, 40, 1, 0),
				Position = host.udim2(1, -40, 0, 0),
				TextColor3 = Surface.color(ctx, config.TextColor, "Text"),
				TextXAlignment = host.enumItem("TextXAlignment", "Right"),
			})
		end
		local view = { Root = slot.Root, Track = track, Fill = fill, Value = valueLabel }
		view.Apply = function(self, state, renderCtx)
			local ratio = math.max(0, math.min(1, tonumber(state.Value) or 0))
			Surface.animate(renderCtx, self.Fill, { Size = renderCtx.Host.udim2(ratio, 0, 1, 0) })
			if self.Value then
				self.Value.Text = ("%d%%"):format(math.floor(ratio * 100 + 0.5))
			end
		end
		return view
	end,
}

styles[#styles + 1] = {
	Id = "progressbar.segmented", Name = "Segmented bar", Component = "ProgressBar", Category = "Display",
	Description = "Discrete segments that light up left to right.",
	Tags = { "segments" },
	Render = function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local width = config.Width or 180
		local height = config.Height or 10
		local count = math.max(2, config.Segments or 10)
		local slot = Surface.slot(ctx, { Height = config.RowHeight or 26, ControlWidth = width })
		local parent = slot.ControlArea or slot.Root
		local holder = host.new("Frame", {
			Name = "Track",
			BackgroundTransparency = 1,
			Size = host.udim2(0, width, 0, height),
			Position = host.udim2(1, -width, 0.5, -height / 2),
		}, parent)
		local segments = {}
		local cell = math.floor((width - (count - 1) * 2) / count)
		for index = 1, count do
			local segment = host.new("Frame", {
				Name = "Segment" .. tostring(index),
				BackgroundColor3 = Surface.color(ctx, config.FillColor, "Accent"),
				BackgroundTransparency = 0.75,
				BorderSizePixel = 0,
				Size = host.udim2(0, cell, 1, 0),
				Position = host.udim2(0, (index - 1) * (cell + 2), 0, 0),
			}, holder)
			Helpers.corner(host, segment, 2)
			segments[index] = segment
		end
		local view = { Root = slot.Root, Segments = segments, Count = count }
		view.Apply = function(self, state)
			local ratio = math.max(0, math.min(1, tonumber(state.Value) or 0))
			local active = math.floor(ratio * self.Count + 0.5)
			for index, segment in ipairs(self.Segments) do
				segment.BackgroundTransparency = index <= active and 0 or 0.75
			end
		end
		return view
	end,
}

styles[#styles + 1] = {
	Id = "loader.spinner", Name = "Spinner", Component = "Loader", Category = "Display",
	Description = "Rotating ring driven by one Heartbeat connection.",
	Tags = { "default" },
	Render = function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local size = config.Size or 16
		local slot = Surface.slot(ctx, { Height = config.RowHeight or 24, ControlWidth = size })
		local parent = slot.ControlArea or slot.Root
		local spinner = host.new("Frame", {
			Name = "Spinner",
			BackgroundTransparency = 1,
			Size = host.udim2(0, size, 0, size),
			Position = host.udim2(1, -size, 0.5, -size / 2),
		}, parent)
		local ring = host.new("Frame", {
			Name = "Ring",
			BackgroundTransparency = 1,
			Size = host.udim2(1, 0, 1, 0),
		}, spinner)
		Helpers.corner(host, ring, size / 2)
		Helpers.stroke(host, ring, Surface.color(ctx, config.Color, "Accent"), math.max(1, size / 8), 0.25)
		local dotSize = math.max(3, size / 4)
		local dot = host.new("Frame", {
			Name = "Dot",
			BackgroundColor3 = Surface.color(ctx, config.Color, "Accent"),
			BorderSizePixel = 0,
			Size = host.udim2(0, dotSize, 0, dotSize),
			Position = host.udim2(0.5, -dotSize / 2, 0, 0),
		}, spinner)
		Helpers.corner(host, dot, dotSize / 2)
		local rotation = 0
		local speed = config.Speed or 1
		local connection = host.heartbeat(function(delta)
			rotation = (rotation + delta * 180 * speed) % 360
			spinner.Rotation = rotation
		end)
		local view = { Root = slot.Root, Spinner = spinner, Connection = connection }
		view.Apply = function(self, state)
			self.Spinner.Visible = state.Enabled ~= false
		end
		view.Dispose = function(self)
			if self.Connection then
				self.Connection:Disconnect()
			end
		end
		return view
	end,
}

styles[#styles + 1] = {
	Id = "loader.dots", Name = "Dots", Component = "Loader", Category = "Display",
	Description = "Pulsing dots animated from one Heartbeat connection.",
	Tags = { "dots" },
	Render = function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local size = math.max(6, (config.Size or 16) * 0.6)
		local count = math.max(1, config.Dots or 3)
		local total = count * (size + 6)
		local slot = Surface.slot(ctx, { Height = config.RowHeight or 24, ControlWidth = total })
		local parent = slot.ControlArea or slot.Root
		local holder = host.new("Frame", {
			Name = "Dots",
			BackgroundTransparency = 1,
			Size = host.udim2(0, total, 0, size),
			Position = host.udim2(1, -total, 0.5, -size / 2),
		}, parent)
		local dots = {}
		for index = 1, count do
			local dot = host.new("Frame", {
				Name = "Dot" .. tostring(index),
				BackgroundColor3 = Surface.color(ctx, config.Color, "Accent"),
				BorderSizePixel = 0,
				Size = host.udim2(0, size, 0, size),
				Position = host.udim2(0, (index - 1) * (size + 6), 0, 0),
			}, holder)
			Helpers.corner(host, dot, size / 2)
			dots[index] = dot
		end
		local phase = 0
		local speed = config.Speed or 1
		local connection = host.heartbeat(function(delta)
			phase = (phase + delta * speed) % 1
			for index, dot in ipairs(dots) do
				local offset = (index - 1) / #dots
				local wave = math.abs(((phase + offset) % 1) - 0.5) * 2
				dot.BackgroundTransparency = 0.2 + wave * 0.6
			end
		end)
		local view = { Root = slot.Root, Dots = dots, Connection = connection }
		view.Apply = function()
			-- Animated entirely by the Heartbeat connection.
		end
		view.Dispose = function(self)
			if self.Connection then
				self.Connection:Disconnect()
			end
		end
		return view
	end,
}

styles[#styles + 1] = {
	Id = "image.plain", Name = "Plain image", Component = "Image", Category = "Display",
	Description = "Image asset with optional rounding and tint.",
	Tags = { "default" },
	Render = function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local size = config.Size or 32
		local slot = Surface.slot(ctx, { Height = config.RowHeight or 32, ControlWidth = size })
		local parent = slot.ControlArea or slot.Root
		local image = host.new("ImageLabel", {
			Name = "Image",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = host.udim2(0, size, 0, size),
			Position = host.udim2(1, -size, 0.5, -size / 2),
			Image = ctx.Props.Icon or "",
			ImageColor3 = Surface.color(ctx, config.ImageColor, "Text"),
			ImageTransparency = config.Transparency or 0,
			ScaleType = host.enumItem("ScaleType", "Fit"),
		}, parent)
		Helpers.corner(host, image, config.CornerRadius)
		local view = { Root = slot.Root, Image = image }
		view.Apply = function(self, state)
			self.Image.ImageTransparency = state.Enabled
				and (ctx.Configuration.Transparency or 0)
				or math.max(0, (ctx.Configuration.Transparency or 0) + 0.5)
		end
		view.SetName = function(self, name)
			self.Image.Image = name
		end
		return view
	end,
}

local registered, failures = Registry.registerMany(styles, { BuiltIn = true })
for _, failure in ipairs(failures) do
	error(("NEVAHEXUI: display style %s failed to register: %s"):format(tostring(failure.Id), table.concat(failure.Errors, "; ")))
end

return registered
end)()

local __NEVA_Styles_Defs_Feedback = (function()
--[[
	NEVAHEXUI - Styles/Defs/Feedback
	Notification and Dialog styles. These components are transient: the window
	creates them through Notify/Dialog, they render through the same style engine
	as every other component, and they destroy themselves when dismissed.
]]

local Registry = __NEVA_Styles_Registry
local Surface = __NEVA_Styles_Surface
local Helpers = __NEVA_Styles_Helpers

Registry.registerComponent({
	Name = "Notification",
	RegistryName = "Notifications",
	Category = "Feedback",
	Description = "Transient message card with an optional dismiss control.",
	Defaults = {
		Height = 48,
		Width = 260,
		TextSize = 13,
		Duration = 4,
		Dismissible = true,
		Animation = "smooth",
	},
	Properties = {
		{ Key = "Height", Type = "number", Default = 48, Min = 28, Max = 200, Group = "Geometry" },
		{ Key = "Width", Type = "number", Default = 260, Min = 120, Max = 520, Group = "Geometry" },
		{ Key = "TextSize", Type = "number", Default = 13, Min = 8, Max = 28, Group = "Typography" },
		{ Key = "CornerRadius", Type = "number", Min = 0, Max = 32, Group = "Geometry" },
		{ Key = "BackgroundColor", Type = "color", Group = "Appearance" },
		{ Key = "TextColor", Type = "color", Group = "Typography" },
		{ Key = "MutedColor", Type = "color", Group = "Typography" },
		{ Key = "AccentColor", Type = "color", Group = "Appearance" },
		{ Key = "StrokeColor", Type = "color", Group = "Appearance" },
		{ Key = "Transparency", Type = "number", Min = 0, Max = 1, Step = 0.01, Group = "Appearance" },
		{ Key = "Duration", Type = "number", Default = 4, Min = 0, Max = 60, Group = "Behaviour" },
		{ Key = "Dismissible", Type = "boolean", Default = true, Group = "Behaviour" },
		{ Key = "Animation", Type = "animation", Default = "smooth", Group = "Animation" },
	},
})

Registry.registerComponent({
	Name = "Dialog",
	RegistryName = "Dialogs",
	Category = "Feedback",
	Description = "Modal dialog with title, body text and action buttons.",
	Defaults = {
		Width = 320,
		ButtonHeight = 28,
		TextSize = 13,
		Dismissible = true,
		Animation = "smooth",
	},
	Properties = {
		{ Key = "Width", Type = "number", Default = 320, Min = 180, Max = 720, Group = "Geometry" },
		{ Key = "ButtonHeight", Type = "number", Default = 28, Min = 18, Max = 80, Group = "Geometry" },
		{ Key = "TextSize", Type = "number", Default = 13, Min = 8, Max = 28, Group = "Typography" },
		{ Key = "CornerRadius", Type = "number", Min = 0, Max = 32, Group = "Geometry" },
		{ Key = "BackgroundColor", Type = "color", Group = "Appearance" },
		{ Key = "TextColor", Type = "color", Group = "Typography" },
		{ Key = "MutedColor", Type = "color", Group = "Typography" },
		{ Key = "AccentColor", Type = "color", Group = "States" },
		{ Key = "ConfirmColor", Type = "color", Group = "States" },
		{ Key = "CancelColor", Type = "color", Group = "States" },
		{ Key = "StrokeColor", Type = "color", Group = "Appearance" },
		{ Key = "DimBackground", Type = "boolean", Default = true, Group = "Appearance" },
		{ Key = "Animation", Type = "animation", Default = "smooth", Group = "Animation" },
	},
})

local function notificationRender(options)
	return function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local body = ctx.State.Body or {}
		local width = config.Width or 260
		local height = config.Height or 48
		local radius = config.CornerRadius
		if radius == nil then
			radius = ctx.Tokens.CornerRadius
		end
		local root = host.new("Frame", {
			Name = "Notification",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = host.udim2(0, width, 0, height),
		}, nil)
		local card = Surface.panel(ctx, root, {
			Name = "Card",
			Background = config.BackgroundColor,
			Token = options.token,
			Transparency = Surface.transparency(ctx, config.Transparency, "SurfaceTransparency", options.transparency),
			CornerRadius = radius,
			Stroke = config.StrokeColor,
			StrokeThickness = 1,
		})
		card.Size = host.udim2(1, 0, 1, 0)
		local stripe = host.new("Frame", {
			Name = "Stripe",
			BackgroundColor3 = Surface.color(ctx, config.AccentColor, "Accent"),
			BorderSizePixel = 0,
			Size = host.udim2(0, 3, 1, -8),
			Position = host.udim2(0, 4, 0, 4),
		}, card)
		Helpers.corner(host, stripe, 2)
		local title = Surface.text(ctx, card, {
			Name = "Title",
			Size = host.udim2(1, -26, 0, 18),
			Position = host.udim2(0, 12, 0, 6),
			Text = tostring(ctx.Props.Name or ""),
			TextColor3 = Surface.color(ctx, config.TextColor, "Text"),
			Font = ctx.Tokens.FontBold,
			TextSize = config.TextSize or 13,
			TextTruncate = host.enumItem("TextTruncate", "AtEnd"),
		})
		local message = Surface.text(ctx, card, {
			Name = "Message",
			Size = host.udim2(1, -26, 0, math.max(14, height - 32)),
			Position = host.udim2(0, 12, 0, 22),
			Text = tostring(body.Message or ctx.Props.Description or ""),
			TextColor3 = Surface.color(ctx, config.MutedColor, "TextMuted"),
			TextSize = math.max(10, (config.TextSize or 13) - 1),
			TextWrapped = true,
			TextTruncate = host.enumItem("TextTruncate", "AtEnd"),
		})
		local dismiss
		if config.Dismissible ~= false then
			dismiss = Surface.hit(ctx, card, {
				Name = "Dismiss",
				Size = host.udim2(0, 18, 0, 18),
				Position = host.udim2(1, -22, 0, 6),
			})
			Surface.text(ctx, dismiss, {
				Name = "Glyph",
				Size = host.udim2(1, 0, 1, 0),
				Text = "x",
				TextColor3 = Surface.color(ctx, config.MutedColor, "TextMuted"),
				TextSize = math.max(10, (config.TextSize or 13) - 2),
				TextXAlignment = host.enumItem("TextXAlignment", "Center"),
			})
		end
		local view = {
			Root = root,
			Card = card,
			Title = title,
			Message = message,
			Dismiss = dismiss,
			Stripe = stripe,
		}
		view.SetName = function(self, name)
			self.Title.Text = name
		end
		view.Apply = function(self, state)
			local level = state.Level or "Info"
			local colour = level == "Error" and ctx.Tokens.Negative
				or level == "Warn" and ctx.Tokens.Warning
				or level == "Success" and ctx.Tokens.Positive
				or Surface.color(ctx, config.AccentColor, "Accent")
			self.Stripe.BackgroundColor3 = colour
			if state.Message then
				self.Message.Text = tostring(state.Message)
			end
		end
		return view
	end
end

local styles = {}

styles[#styles + 1] = {
	Id = "notification.toast",
	Name = "Toast",
	Component = "Notification",
	Category = "Feedback",
	Description = "Filled toast card with a level-coloured stripe.",
	Tags = { "default" },
	Render = notificationRender({ token = "Surface", transparency = 0 }),
}

styles[#styles + 1] = {
	Id = "notification.glass",
	Name = "Glass toast",
	Component = "Notification",
	Category = "Feedback",
	Description = "Translucent toast with a gradient wash for overlay interfaces.",
	Tags = { "glass" },
	Render = function(ctx)
		local view = notificationRender({ token = "Surface", transparency = 0.3 })(ctx)
		Helpers.gradient(ctx.Host, view.Card, ctx.Tokens.SurfaceAlt, ctx.Tokens.Accent, 90, { 0.25, 0.9 })
		return view
	end,
}

local function dialogRender(options)
	return function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local body = ctx.State.Body or {}
		local width = config.Width or 320
		local buttonHeight = config.ButtonHeight or 28
		local actions = body.Actions or {}
		local buttonCount = math.max(1, #actions)
		local height = options.compact and 128 or 160
		local root = host.new("Frame", {
			Name = "DialogRoot",
			BackgroundTransparency = 1,
			Size = host.udim2(0, width, 0, height),
		}, nil)
		local card = Surface.panel(ctx, root, {
			Name = "Card",
			Background = config.BackgroundColor,
			Token = "Surface",
			Transparency = options.transparency,
			CornerRadius = config.CornerRadius or ctx.Tokens.CornerRadius,
			Stroke = config.StrokeColor or ctx.Tokens.Outline,
			StrokeThickness = 1,
		})
		card.Size = host.udim2(1, 0, 1, 0)
		local accent = host.new("Frame", {
			Name = "Accent",
			BackgroundColor3 = Surface.color(ctx, config.AccentColor, "Accent"),
			BorderSizePixel = 0,
			Size = host.udim2(1, 0, 0, options.compact and 3 or 4),
		}, card)
		local title = Surface.text(ctx, card, {
			Name = "Title",
			Size = host.udim2(1, -32, 0, 22),
			Position = host.udim2(0, 16, 0, options.compact and 12 or 18),
			Text = tostring(ctx.Props.Name or ""),
			TextColor3 = Surface.color(ctx, config.TextColor, "Text"),
			Font = ctx.Tokens.FontBold,
			TextSize = (config.TextSize or 13) + 2,
			TextTruncate = host.enumItem("TextTruncate", "AtEnd"),
		})
		local message = Surface.text(ctx, card, {
			Name = "Message",
			Size = host.udim2(1, -32, 0, options.compact and 34 or 46),
			Position = host.udim2(0, 16, 0, options.compact and 36 or 44),
			Text = tostring(body.Message or ctx.Props.Description or ""),
			TextColor3 = Surface.color(ctx, config.MutedColor, "TextMuted"),
			TextWrapped = true,
			TextSize = math.max(10, (config.TextSize or 13) - 1),
		})
		local buttonArea = host.new("Frame", {
			Name = "Actions",
			BackgroundTransparency = 1,
			Size = host.udim2(1, -32, 0, buttonHeight),
			Position = host.udim2(0, 16, 1, -buttonHeight - 16),
		}, card)
		host.new("UIListLayout", {
			FillDirection = host.enumItem("FillDirection", "Horizontal"),
			Padding = host.udim(0, 8),
			HorizontalAlignment = host.enumItem("HorizontalAlignment", options.alignRight and "Right" or "Left"),
			VerticalAlignment = host.enumItem("VerticalAlignment", "Center"),
			SortOrder = host.enumItem("SortOrder", "LayoutOrder"),
		}, buttonArea)
		local buttons = {}
		local confirmColour = Surface.color(ctx, config.ConfirmColor, "Accent")
		local cancelColour = Surface.color(ctx, config.CancelColor, "SurfaceAlt")
		for index, action in ipairs(actions) do
			local isPrimary = action.Style == "Primary" or index == 1
			local button = Surface.panel(ctx, buttonArea, {
				Name = "Action" .. tostring(index),
				Background = isPrimary and (action.Style == "Cancel" and cancelColour or confirmColour) or cancelColour,
				Token = isPrimary and "Accent" or "SurfaceAlt",
				Transparency = 0,
				CornerRadius = math.max(0, (config.CornerRadius or 8) - 2),
			})
			button.Size = host.udim2(0, math.min(120, math.floor((width - 48) / buttonCount)), 0, buttonHeight)
			button.LayoutOrder = index
			Surface.text(ctx, button, {
				Name = "Label",
				Size = host.udim2(1, 0, 1, 0),
				Text = tostring(action.Label or ("Option " .. tostring(index))),
				TextColor3 = isPrimary and ctx.Tokens.AccentText or ctx.Tokens.Text,
				Font = ctx.Tokens.FontBold,
				TextSize = math.max(10, (config.TextSize or 13) - 1),
				TextXAlignment = host.enumItem("TextXAlignment", "Center"),
			})
			buttons[index] = { Value = action.Value or index, Button = button, Label = tostring(action.Label or "") }
		end
		local view = {
			Root = root,
			Card = card,
			Title = title,
			Message = message,
			ActionButtons = buttons,
			Accent = accent,
			ConfirmColour = confirmColour,
			CancelColour = cancelColour,
		}
		view.SetName = function(self, name)
			self.Title.Text = name
		end
		view.Apply = function(self, state)
			self.Title.Text = tostring(state.Title or ctx.Props.Name or "")
			self.Message.Text = tostring(state.Message or "")
		end
		return view
	end
end

styles[#styles + 1] = {
	Id = "dialog.modal",
	Name = "Modal dialog",
	Component = "Dialog",
	Category = "Feedback",
	Description = "Centred modal card with a title, body text and horizontal actions.",
	Tags = { "default" },
	Render = dialogRender({ transparency = 0, alignRight = false }),
}

styles[#styles + 1] = {
	Id = "dialog.compact",
	Name = "Compact dialog",
	Component = "Dialog",
	Category = "Feedback",
	Description = "Shorter dialog with right-aligned actions for confirmations.",
	Tags = { "compact" },
	Render = dialogRender({ transparency = 0.05, alignRight = true, compact = true }),
}

local registered, failures = Registry.registerMany(styles, { BuiltIn = true })
for _, failure in ipairs(failures) do
	error(("NEVAHEXUI: feedback style %s failed to register: %s"):format(tostring(failure.Id), table.concat(failure.Errors, "; ")))
end

return registered
end)()

local __NEVA_Styles_Defs_Pickers = (function()
--[[
	NEVAHEXUI - Styles/Defs/Pickers
	Colour and keybind components.

	Design note: every interaction in this file is click based (discrete grid
	cells, cycling key lists). Slider-style free dragging needs pointer position
	reporting, which is provided by the host back ends and used by the Slider
	styles instead. Keeping pickers click based means they behave identically on
	a touch device, in Studio and under the headless test host.
]]

local Registry = __NEVA_Styles_Registry
local Surface = __NEVA_Styles_Surface
local Helpers = __NEVA_Styles_Helpers
local Color = __NEVA_Utilities_Color

Registry.registerComponent({
	Name = "ColorPicker", RegistryName = "ColorPickers", Category = "Pickers",
	Description = "Colour selection with a swatch grid, hex field and alpha.",
	Defaults = { RowHeight = 30, SwatchSize = 18, Columns = 12, ShowHex = true, ShowAlpha = true, Animation = "smooth" },
	Properties = {
		{ Key = "RowHeight", Type = "number", Default = 30, Min = 18, Max = 120, Group = "Geometry" },
		{ Key = "SwatchSize", Type = "number", Default = 18, Min = 8, Max = 48, Group = "Geometry" },
		{ Key = "Spacing", Type = "number", Default = 3, Min = 0, Max = 16, Group = "Geometry" },
		{ Key = "Columns", Type = "number", Default = 12, Min = 2, Max = 24, Group = "Geometry" },
		{ Key = "CornerRadius", Type = "number", Min = 0, Max = 24, Group = "Geometry" },
		{ Key = "TextColor", Type = "color", Group = "Typography" },
		{ Key = "StrokeColor", Type = "color", Group = "Appearance" },
		{ Key = "ShowHex", Type = "boolean", Default = true, Group = "Behaviour" },
		{ Key = "ShowAlpha", Type = "boolean", Default = true, Group = "Behaviour" },
		{ Key = "Animation", Type = "animation", Default = "smooth", Group = "Animation" },
	},
})

Registry.registerComponent({
	Name = "ColorPalette", RegistryName = "ColorPalettes", Category = "Pickers",
	Description = "Named colour chips for quick theme and accent selection.",
	Defaults = { RowHeight = 26, ChipSize = 18, Spacing = 4, ShowLabels = false },
	Properties = {
		{ Key = "RowHeight", Type = "number", Default = 26, Min = 14, Max = 80, Group = "Geometry" },
		{ Key = "ChipSize", Type = "number", Default = 18, Min = 8, Max = 48, Group = "Geometry" },
		{ Key = "Spacing", Type = "number", Default = 4, Min = 0, Max = 16, Group = "Geometry" },
		{ Key = "CornerRadius", Type = "number", Min = 0, Max = 24, Group = "Geometry" },
		{ Key = "ShowLabels", Type = "boolean", Default = false, Group = "Behaviour" },
	},
})

-- The Keybind *component* is declared by Styles/Defs/TextInputs (keybind.classic
-- and keybind.pill live there). This file only contributes two more renderers for
-- the same component type, so the descriptor is registered once, guarded by an
-- existence check that keeps module load order irrelevant.
local function componentKnown(name)
	for _, entry in ipairs(Registry.listComponents() or {}) do
		local entryName = type(entry) == "table" and (entry.Name or entry.Component) or entry
		if entryName == name then
			return true
		end
	end
	return false
end

local keybindDescriptor = {
	Name = "Keybind", RegistryName = "Keybinds", Category = "Pickers",
	Description = "Key assignment control with conflict reporting.",
	Defaults = { RowHeight = 28, ChipWidth = 92, ShowToggle = true, Cyclable = true, Animation = "smooth" },
	Properties = {
		{ Key = "RowHeight", Type = "number", Default = 28, Min = 18, Max = 80, Group = "Geometry" },
		{ Key = "ChipWidth", Type = "number", Default = 92, Min = 40, Max = 240, Group = "Geometry" },
		{ Key = "CornerRadius", Type = "number", Min = 0, Max = 24, Group = "Geometry" },
		{ Key = "TextColor", Type = "color", Group = "Typography" },
		{ Key = "ChipColor", Type = "color", Group = "Appearance" },
		{ Key = "ConflictColor", Type = "color", Group = "States" },
		{ Key = "ShowToggle", Type = "boolean", Default = true, Group = "Behaviour" },
		{ Key = "Cyclable", Type = "boolean", Default = true, Group = "Behaviour" },
		{ Key = "Animation", Type = "animation", Default = "smooth", Group = "Animation" },
	},
}

if not componentKnown("Keybind") then
	Registry.registerComponent(keybindDescriptor)
end

-- Shared helpers ------------------------------------------------------------

local function hexText(colour)
	if type(colour) ~= "table" then
		return "--------"
	end
	local ok, value = pcall(function()
		return Color.normalize(colour):ToHex()
	end)
	if not ok then
		return "--------"
	end
	return value
end

local function paletteColours(state)
	local colours = {}
	if type(state.Palette) == "table" and #state.Palette > 0 then
		for index, entry in ipairs(state.Palette) do
			colours[index] = entry
		end
		return colours
	end
	local steps = { 0, 0.12, 0.25, 0.4, 0.55, 0.7, 0.85, 1 }
	local hues = { 0, 0.06, 0.11, 0.17, 0.25, 0.33, 0.42, 0.5, 0.58, 0.66, 0.75, 0.83, 0.92 }
	for _, hue in ipairs(hues) do
		for _, value in ipairs(steps) do
			local saturation = value > 0.85 and 1 or 0.85
			table.insert(colours, Color.fromHSV(hue, saturation, math.max(0.12, value)))
		end
	end
	for value = 0, 1, 0.125 do
		table.insert(colours, Color.fromRGB(value * 255, value * 255, value * 255))
	end
	return colours
end

-- ColorPicker styles --------------------------------------------------------

local function pickerGridRender(options)
	return function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local swatch = config.SwatchSize or 18
		local spacing = config.Spacing or 3
		local columns = math.max(2, config.Columns or 12)
		local colours = paletteColours(ctx.State)
		local rows = math.ceil(#colours / columns)
		local panelWidth = columns * (swatch + spacing) + 48
		local slot = Surface.slot(ctx, {
			Height = config.RowHeight or 30,
			ControlWidth = panelWidth,
		})
		local parent = slot.ControlArea or slot.Root
		local preview = Surface.panel(ctx, parent, {
			Name = "Preview",
			Button = true,
			Background = ctx.State.Value,
			Token = "Accent",
			Transparency = 0,
			CornerRadius = config.CornerRadius or (ctx.Tokens.CornerRadius or 6),
		})
		preview.Size = host.udim2(0, 30, 0, 30)
		preview.Position = host.udim2(1, -panelWidth + 18, 0.5, -15)
		if options.Inline then
			preview.Size = host.udim2(0, 26, 0, 26)
		end
		local popup = Surface.panel(ctx, parent, {
			Name = "Popup",
			Background = "Surface",
			Token = "Surface",
			Transparency = 0,
			CornerRadius = config.CornerRadius or 8,
			Stroke = config.StrokeColor or ctx.Tokens.Outline,
			StrokeThickness = 1,
			Visible = false,
		})
		popup.Size = host.udim2(0, columns * (swatch + spacing) + spacing, 0, rows * (swatch + spacing) + spacing)
		popup.Position = host.udim2(1, 0, 0, 34)
		popup.ZIndex = 40
		local cells = {}
		for index, colour in ipairs(colours) do
			local column = (index - 1) % columns
			local row = math.floor((index - 1) / columns)
			local cell = Surface.hit(ctx, popup, {
				Name = "Cell" .. tostring(index),
				BackgroundColor3 = colour,
				BackgroundTransparency = 0,
				BorderSizePixel = 0,
				Size = host.udim2(0, swatch, 0, swatch),
				Position = host.udim2(0, spacing + column * (swatch + spacing), 0, spacing + row * (swatch + spacing)),
			})
			Helpers.corner(host, cell, math.max(2, (config.CornerRadius or 6) / 3))
			cells[index] = { Instance = cell, Colour = colour }
		end
		local hexLabel
		if config.ShowHex ~= false then
			hexLabel = Surface.text(ctx, parent, {
				Name = "Hex",
				Size = host.udim2(0, 74, 0, 24),
				Position = host.udim2(1, -panelWidth + 54, 0.5, -12),
				Text = hexText(ctx.State.Value),
				TextColor3 = Surface.color(ctx, config.TextColor, "Text"),
				TextSize = 12,
				TextXAlignment = host.enumItem("TextXAlignment", "Left"),
			})
		end
		local alpha
		if config.ShowAlpha ~= false then
			alpha = Surface.text(ctx, parent, {
				Name = "Alpha",
				Size = host.udim2(0, 34, 0, 24),
				Position = host.udim2(1, -26, 0.5, -12),
				Text = "A1.00",
				TextColor3 = ctx.Tokens.TextMuted,
				TextSize = 11,
				TextXAlignment = host.enumItem("TextXAlignment", "Right"),
			})
		end
		local view = {
			Root = slot.Root,
			Input = preview,
			Preview = preview,
			Popup = popup,
			Cells = cells,
			Hex = hexLabel,
			Alpha = alpha,
			Open = false,
		}
		view.Apply = function(self, state)
			self.Preview.BackgroundColor3 = type(state.Value) == "table" and state.Value or ctx.Tokens.Accent
			self.Preview.BackgroundTransparency = 0
			if self.Hex then
				self.Hex.Text = hexText(state.Value)
			end
			if self.Alpha then
				local colour = state.Value
				local value = type(colour) == "table" and (colour.A or colour[4]) or nil
				self.Alpha.Text = ("A%.2f"):format(tonumber(value) or 1)
			end
			self.Popup.Visible = self.Open == true and state.Visible ~= false
			for _, cell in ipairs(self.Cells) do
				cell.Instance.BackgroundTransparency = 0
			end
		end
		return view
	end
end

local styles = {}

styles[#styles + 1] = {
	Id = "colorpicker.popup", Name = "Popup swatches", Component = "ColorPicker", Category = "Pickers",
	Description = "Swatch button that opens a grid of hues, tints and greys.",
	Tags = { "default" },
	Render = pickerGridRender({ Inline = false }),
}

styles[#styles + 1] = {
	Id = "colorpicker.inline", Name = "Inline swatches", Component = "ColorPicker", Category = "Pickers",
	Description = "Always-visible swatch grid for embedding directly in a row.",
	Tags = { "inline" },
	Render = pickerGridRender({ Inline = true }),
}

styles[#styles + 1] = {
	Id = "colorpalette.chips", Name = "Chips", Component = "ColorPalette", Category = "Pickers",
	Description = "Row of named or unlabelled colour chips with a selected outline.",
	Tags = { "default" },
	Render = function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local chip = config.ChipSize or 18
		local spacing = config.Spacing or 4
		local colours = paletteColours(ctx.State)
		local slot = Surface.slot(ctx, { Height = config.RowHeight or 26, ControlWidth = #colours * (chip + spacing) })
		local parent = slot.ControlArea or slot.Root
		local chips = {}
		for index, colour in ipairs(colours) do
			local instance = Surface.hit(ctx, parent, {
				Name = "Chip" .. tostring(index),
				BackgroundColor3 = colour,
				BackgroundTransparency = 0,
				BorderSizePixel = 0,
				Size = host.udim2(0, chip, 0, chip),
				Position = host.udim2(0, (index - 1) * (chip + spacing), 0.5, -chip / 2),
			})
			Helpers.corner(host, instance, config.CornerRadius or 4)
			chips[index] = { Instance = instance, Colour = colour }
		end
		local view = { Root = slot.Root, Chips = chips, Selected = {} }
		view.Apply = function(self, state)
			for _, entry in ipairs(self.Chips) do
				local selected = type(state.Value) == "table" and Color.equals(entry.Colour, state.Value)
				local stroke = entry.Instance.__nevaStroke
					or Helpers.stroke(host, entry.Instance, ctx.Tokens.Outline, 2, 0)
				entry.Instance.__nevaStroke = stroke
				stroke.Color = selected and ctx.Tokens.Text or ctx.Tokens.Outline
				stroke.Transparency = selected and 0 or 0.5
			end
		end
		return view
	end,
}

styles[#styles + 1] = {
	Id = "keybind.chip", Name = "Key chip", Component = "Keybind", Category = "Pickers",
	Description = "Single key chip that cycles through the assignable key list on click.",
	Tags = { "default" },
	Render = function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local width = config.ChipWidth or 92
		local slot = Surface.slot(ctx, { Height = config.RowHeight or 28, ControlWidth = width })
		local parent = slot.ControlArea or slot.Root
		local chip = Surface.hit(ctx, parent, {
			Name = "Chip",
			BackgroundColor3 = Surface.color(ctx, config.ChipColor, "SurfaceAlt"),
			BorderSizePixel = 0,
			Size = host.udim2(0, width, 0, 22),
			Position = host.udim2(1, -width, 0.5, -11),
		})
		Helpers.corner(host, chip, config.CornerRadius or 6)
		local stroke = Helpers.stroke(host, chip, ctx.Tokens.Outline, 1, 0.3)
		local label = Surface.text(ctx, chip, {
			Name = "Key",
			Size = host.udim2(1, 0, 1, 0),
			Text = tostring(ctx.State.Value or "None"),
			TextColor3 = Surface.color(ctx, config.TextColor, "Text"),
			Font = ctx.Tokens.FontBold,
			TextSize = 12,
			TextXAlignment = host.enumItem("TextXAlignment", "Center"),
		})
		local view = {
			Root = slot.Root,
			Input = chip,
			Chip = chip,
			Label = label,
			Stroke = stroke,
			ConflictColour = Surface.color(ctx, config.ConflictColor, "Negative"),
			IdleStroke = ctx.Tokens.Outline,
		}
		view.Apply = function(self, state)
			self.Label.Text = tostring(state.Value or "None")
			local conflict = state.Conflict == true
			self.Stroke.Color = conflict and self.ConflictColour or self.IdleStroke
			self.Stroke.Transparency = conflict and 0 or 0.3
			self.Chip.BackgroundTransparency = state.Enabled == false and 0.45 or 0
			self.Chip.Active = state.Enabled ~= false
		end
		return view
	end,
}

styles[#styles + 1] = {
	Id = "keybind.row", Name = "Key row", Component = "Keybind", Category = "Pickers",
	Description = "Mode toggle plus key chip, listing the bound key and its state.",
	Tags = { "row", "modes" },
	Render = function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local width = config.ChipWidth or 92
		local showToggle = config.ShowToggle ~= false
		local slot = Surface.slot(ctx, {
			Height = config.RowHeight or 28,
			ControlWidth = width + (showToggle and 108 or 4),
		})
		local parent = slot.ControlArea or slot.Root
		local mode
		if showToggle then
			mode = Surface.hit(ctx, parent, {
				Name = "Mode",
				BackgroundColor3 = Surface.color(ctx, config.ChipColor, "SurfaceAlt"),
				Size = host.udim2(0, 100, 0, 22),
				Position = host.udim2(1, -width - 108, 0.5, -11),
			})
			Helpers.corner(host, mode, config.CornerRadius or 6)
			Surface.text(ctx, mode, {
				Name = "ModeLabel",
				Size = host.udim2(1, 0, 1, 0),
				Text = "Toggle",
				TextColor3 = Surface.color(ctx, config.TextColor, "Text"),
				TextSize = 12,
				TextXAlignment = host.enumItem("TextXAlignment", "Center"),
			})
		end
		local chip = Surface.hit(ctx, parent, {
			Name = "Chip",
			BackgroundColor3 = Surface.color(ctx, config.ChipColor, "SurfaceAlt"),
			BorderSizePixel = 0,
			Size = host.udim2(0, width, 0, 22),
			Position = host.udim2(1, -width, 0.5, -11),
		})
		Helpers.corner(host, chip, config.CornerRadius or 6)
		local stroke = Helpers.stroke(host, chip, ctx.Tokens.Outline, 1, 0.3)
		local label = Surface.text(ctx, chip, {
			Name = "Key",
			Size = host.udim2(1, 0, 1, 0),
			Text = tostring(ctx.State.Value or "None"),
			TextColor3 = Surface.color(ctx, config.TextColor, "Text"),
			Font = ctx.Tokens.FontBold,
			TextSize = 12,
			TextXAlignment = host.enumItem("TextXAlignment", "Center"),
		})
		local view = {
			Root = slot.Root,
			Input = chip,
			Chip = chip,
			Label = label,
			Stroke = stroke,
			ModeButton = mode,
			ConflictColour = Surface.color(ctx, config.ConflictColor, "Negative"),
			IdleStroke = ctx.Tokens.Outline,
		}
		view.Apply = function(self, state)
			self.Label.Text = tostring(state.Value or "None")
			local conflict = state.Conflict == true
			self.Stroke.Color = conflict and self.ConflictColour or self.IdleStroke
			self.Stroke.Transparency = conflict and 0 or 0.3
			if self.ModeButton then
				local child = self.ModeButton:FindFirstChild("ModeLabel")
				if child then
					child.Text = tostring(state.Mode or "Toggle")
				end
			end
		end
		return view
	end,
}

local registered, failures = Registry.registerMany(styles, { BuiltIn = true })
for _, failure in ipairs(failures) do
	error(("NEVAHEXUI: picker style %s failed to register: %s"):format(tostring(failure.Id), table.concat(failure.Errors, "; ")))
end

return registered
end)()

local __NEVA_Styles_Defs_Sliders = (function()
--[[
	NEVAHEXUI - Styles/Defs/Sliders
	Slider and RangeSlider descriptors and styles. The filled, neon and minimal
	styles share the track + handle composition but differ in geometry, glow,
	value display and decoration; the stepped style is a separate implementation
	with tick marks and named stops.
]]

local Registry = __NEVA_Styles_Registry
local Surface = __NEVA_Styles_Surface
local Helpers = __NEVA_Styles_Helpers

local SLIDER_PROPERTIES = {
	{ Key = "RowHeight", Type = "number", Default = 34, Min = 20, Max = 120, Group = "Geometry" },
	{ Key = "Width", Type = "number", Default = 180, Min = 60, Max = 600, Group = "Geometry", Description = "Track width in pixels." },
	{ Key = "TrackHeight", Type = "number", Default = 6, Min = 1, Max = 32, Group = "Geometry" },
	{ Key = "HandleSize", Type = "number", Default = 14, Min = 4, Max = 48, Group = "Geometry" },
	{ Key = "TrackColor", Type = "color", Group = "Appearance" },
	{ Key = "FillColor", Type = "color", Group = "Appearance" },
	{ Key = "HandleColor", Type = "color", Group = "Appearance" },
	{ Key = "TextColor", Type = "color", Group = "Typography" },
	{ Key = "ShowValue", Type = "boolean", Default = true, Group = "Behaviour" },
	{ Key = "Suffix", Type = "string", Default = "", Group = "Behaviour" },
	{ Key = "ValueFormat", Type = "string", Default = "%s", Group = "Behaviour" },
	{ Key = "Glow", Type = "boolean", Default = false, Group = "Appearance" },
	{ Key = "StrokeColor", Type = "color", Group = "Appearance" },
	{ Key = "Step", Type = "number", Default = 0, Min = 0, Group = "Behaviour" },
	{ Key = "Precision", Type = "number", Default = 0, Min = 0, Max = 4, Group = "Behaviour" },
	{ Key = "Animation", Type = "animation", Default = "quick", Group = "Animation" },
	{ Key = "AnimationDuration", Type = "number", Min = 0, Max = 2, Group = "Animation" },
	{ Key = "Stops", Type = "colorArray", Group = "Advanced", Max = 8, Description = "Named colour stops rendered by the stepped style." },
}

Registry.registerComponent({
	Name = "Slider",
	RegistryName = "Sliders",
	Category = "Controls",
	Description = "Continuous numeric input. Value is a number between Min and Max.",
	Defaults = {
		RowHeight = 34,
		Width = 180,
		TrackHeight = 6,
		HandleSize = 14,
		ShowValue = true,
		Animation = "quick",
		Step = 0,
		Precision = 0,
	},
	Properties = SLIDER_PROPERTIES,
})

Registry.registerComponent({
	Name = "RangeSlider",
	RegistryName = "RangeSliders",
	Category = "Controls",
	Description = "Two-handed numeric range. Value is { Low = number, High = number }.",
	Defaults = {
		RowHeight = 34,
		Width = 180,
		TrackHeight = 6,
		HandleSize = 14,
		ShowValue = true,
		Animation = "quick",
	},
	Properties = SLIDER_PROPERTIES,
})

local function fraction(state, value)
	local minimum = state.Min or 0
	local maximum = state.Max or 100
	if maximum == minimum then
		return 0
	end
	return math.max(0, math.min(1, (value - minimum) / (maximum - minimum)))
end

local function buildTrack(ctx, options)
	local config = ctx.Configuration
	local host = ctx.Host
	local width = config.Width or 180
	local trackHeight = config.TrackHeight or 6
	local handleSize = config.HandleSize or 14
	local slot = Surface.slot(ctx, {
		Height = config.RowHeight or 34,
		ControlWidth = width + (config.ShowValue ~= false and 52 or 0),
	})
	local parent = slot.ControlArea or slot.Root
	local track = Surface.panel(ctx, parent, {
		Name = "Track",
		Background = config.TrackColor,
		Token = "Outline",
		Transparency = 0.25,
		CornerRadius = math.max(1, trackHeight / 2),
	})
	track.Size = host.udim2(0, width, 0, trackHeight)
	track.Position = host.udim2(0, 0, 0.5, -trackHeight / 2)
	local fill = host.new("Frame", {
		Name = "Fill",
		BackgroundColor3 = Surface.color(ctx, config.FillColor, "Accent"),
		BorderSizePixel = 0,
		Size = host.udim2(0, 0, 1, 0),
		ClipsDescendants = true,
	}, track)
	Helpers.corner(host, fill, math.max(1, trackHeight / 2))
	local handle = host.new("Frame", {
		Name = "Handle",
		BackgroundColor3 = Surface.color(ctx, config.HandleColor, "Text"),
		BorderSizePixel = 0,
		Size = host.udim2(0, handleSize, 0, handleSize),
		Position = host.udim2(0, -handleSize / 2, 0.5, -handleSize / 2),
		ZIndex = 3,
	}, track)
	Helpers.corner(host, handle, config.SquareHandle == true and math.max(1, handleSize / 4) or handleSize / 2)
	if config.StrokeColor then
		Helpers.stroke(host, handle, Surface.color(ctx, config.StrokeColor, "Outline"), 1, 0)
	end
	local glow
	if config.Glow then
		glow = host.new("Frame", {
			Name = "Glow",
			BackgroundColor3 = Surface.color(ctx, config.FillColor, "Accent"),
			BackgroundTransparency = 0.7,
			BorderSizePixel = 0,
			Size = host.udim2(0, handleSize + 8, 0, handleSize + 8),
			Position = host.udim2(0, -(handleSize + 8) / 2, 0.5, -(handleSize + 8) / 2),
			ZIndex = 2,
		}, track)
		Helpers.corner(host, glow, (handleSize + 8) / 2)
	end
	local valueLabel
	if config.ShowValue ~= false then
		valueLabel = Surface.text(ctx, parent, {
			Name = "Value",
			Size = host.udim2(0, 48, 1, 0),
			Position = host.udim2(1, -48, 0, 0),
			Text = "",
			TextColor3 = Surface.color(ctx, config.TextColor, "Text"),
			TextSize = math.max(10, (config.RowHeight or 34) - 22),
			TextXAlignment = host.enumItem("TextXAlignment", "Right"),
		})
	end
	local input = Surface.hit(ctx, track, {
		Name = "Input",
		Size = host.udim2(1, 0, 0, handleSize + 10),
		Position = host.udim2(0, 0, 0.5, -(handleSize + 10) / 2),
		ZIndex = 4,
	})
	local view = {
		Root = slot.Root,
		Input = input,
		Track = track,
		Fill = fill,
		Handle = handle,
		Glow = glow,
		Value = valueLabel,
		TrackWidth = width,
		HandleSize = handleSize,
	}
	return view, slot
end

local function paintSlider(view, state, ctx, suffix)
	local config = ctx.Configuration
	local position = fraction(state, state.Value)
	Surface.animate(ctx, view.Fill, { Size = ctx.Host.udim2(position, 0, 1, 0) })
	Surface.animate(ctx, view.Handle, {
		Position = ctx.Host.udim2(position, -view.HandleSize / 2, 0.5, -view.HandleSize / 2),
	})
	local colour = Surface.color(ctx, config.FillColor, "Accent")
	if not state.Enabled then
		colour = Surface.disabledColour(ctx, colour)
	end
	view.Fill.BackgroundColor3 = colour
	view.Handle.BackgroundColor3 = state.Enabled
		and Surface.color(ctx, config.HandleColor, "Text")
		or Surface.disabledText(ctx, Surface.color(ctx, config.HandleColor, "Text"))
	if view.Glow then
		view.Glow.BackgroundTransparency = state.Enabled and 0.55 or 0.85
	end
	if view.Value then
		local text = tostring(state.Value)
		if config.ValueFormat and config.ValueFormat ~= "%s" then
			local ok, formatted = pcall(string.format, config.ValueFormat, state.Value)
			text = ok and formatted or text
		end
		view.Value.Text = text .. (suffix or config.Suffix or "")
	end
end

local styles = {}

styles[#styles + 1] = {
	Id = "slider.filled",
	Name = "Filled slider",
	Component = "Slider",
	Category = "Controls",
	Description = "Rounded track filled with the accent colour and a circular handle.",
	Tags = { "default", "filled" },
	Render = function(ctx)
		local view = buildTrack(ctx)
		view.Apply = function(self, state, renderCtx)
			paintSlider(self, state, renderCtx)
		end
		return view
	end,
}

styles[#styles + 1] = {
	Id = "slider.neon",
	Name = "Neon slider",
	Component = "Slider",
	Category = "Controls",
	Description = "Glowing accent fill with a halo around the handle.",
	Tags = { "neon", "glow" },
	Render = function(ctx)
		local view = buildTrack(ctx)
		if not view.Glow then
			local host = ctx.Host
			view.Glow = host.new("Frame", {
				Name = "Glow",
				BackgroundColor3 = Surface.color(ctx, ctx.Configuration.FillColor, "Accent"),
				BackgroundTransparency = 0.7,
				BorderSizePixel = 0,
				Size = host.udim2(0, view.HandleSize + 10, 0, view.HandleSize + 10),
				Position = host.udim2(0, -(view.HandleSize + 10) / 2, 0.5, -(view.HandleSize + 10) / 2),
				ZIndex = 2,
			}, view.Track)
			Helpers.corner(host, view.Glow, (view.HandleSize + 10) / 2)
		end
		view.Apply = function(self, state, renderCtx)
			paintSlider(self, state, renderCtx)
			local position = fraction(state, state.Value)
			if self.Glow then
				Surface.animate(renderCtx, self.Glow, {
					Position = renderCtx.Host.udim2(position, -(self.HandleSize + 10) / 2, 0.5, -(self.HandleSize + 10) / 2),
				})
			end
		end
		return view
	end,
}

styles[#styles + 1] = {
	Id = "slider.minimal",
	Name = "Minimal slider",
	Component = "Slider",
	Category = "Controls",
	Description = "Hairline track with a small square handle and no fill gradient.",
	Tags = { "minimal" },
	Render = function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local width = config.Width or 180
		local slot = Surface.slot(ctx, {
			Height = config.RowHeight or 34,
			ControlWidth = width + (config.ShowValue ~= false and 44 or 0),
		})
		local parent = slot.ControlArea or slot.Root
		local line = host.new("Frame", {
			Name = "Track",
			BackgroundColor3 = Surface.color(ctx, config.TrackColor, "Outline"),
			BorderSizePixel = 0,
			Size = host.udim2(0, width, 0, 1),
			Position = host.udim2(0, 0, 0.5, 0),
		}, parent)
		local fill = host.new("Frame", {
			Name = "Fill",
			BackgroundColor3 = Surface.color(ctx, config.FillColor, "Accent"),
			BorderSizePixel = 0,
			Size = host.udim2(0, 0, 1, 0),
		}, line)
		local handle = host.new("Frame", {
			Name = "Handle",
			BackgroundColor3 = Surface.color(ctx, config.HandleColor, "Accent"),
			BorderSizePixel = 0,
			Size = host.udim2(0, 6, 0, 16),
			Position = host.udim2(0, -3, 0.5, -8),
			ZIndex = 2,
		}, line)
		Helpers.corner(host, handle, 1)
		local valueLabel
		if config.ShowValue ~= false then
			valueLabel = Surface.text(ctx, parent, {
				Name = "Value",
				Size = host.udim2(0, 40, 1, 0),
				Position = host.udim2(1, -40, 0, 0),
				TextColor3 = Surface.color(ctx, config.TextColor, "TextMuted"),
				TextXAlignment = host.enumItem("TextXAlignment", "Right"),
			})
		end
		local input = Surface.hit(ctx, line, {
			Name = "Input",
			Size = host.udim2(1, 0, 0, 24),
			Position = host.udim2(0, 0, 0.5, -12),
			ZIndex = 3,
		})
		local view = {
			Root = slot.Root,
			Input = input,
			Track = line,
			Fill = fill,
			Handle = handle,
			Value = valueLabel,
			TrackWidth = width,
			HandleSize = 6,
		}
		view.Apply = function(self, state, renderCtx)
			local position = fraction(state, state.Value)
			self.Fill.Size = renderCtx.Host.udim2(position, 0, 1, 0)
			Surface.animate(renderCtx, self.Handle, {
				Position = renderCtx.Host.udim2(position, -3, 0.5, -8),
			})
			if self.Value then
				self.Value.Text = tostring(state.Value)
			end
		end
		return view
	end,
}

styles[#styles + 1] = {
	Id = "slider.stepped",
	Name = "Stepped slider",
	Component = "Slider",
	Category = "Controls",
	Description = "Track with labelled tick stops and a discrete handle.",
	Tags = { "stops", "ticks" },
	Render = function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local width = config.Width or 180
		local trackHeight = config.TrackHeight or 8
		local handleSize = config.HandleSize or 16
		local stops = ctx.State.Stops or {}
		local slot = Surface.slot(ctx, {
			Height = config.RowHeight or 40,
			ControlWidth = width + (config.ShowValue ~= false and 56 or 0),
			Description = (config.Suffix ~= nil and config.Suffix ~= "") and ("Step: " .. tostring(config.Suffix)) or nil,
		})
		local parent = slot.ControlArea or slot.Root
		local track = Surface.panel(ctx, parent, {
			Name = "Track",
			Background = config.TrackColor,
			Token = "Outline",
			Transparency = 0.35,
			CornerRadius = trackHeight / 2,
		})
		track.Size = host.udim2(0, width, 0, trackHeight)
		track.Position = host.udim2(0, 0, 0.5, -trackHeight / 2)
		local fill = host.new("Frame", {
			Name = "Fill",
			BackgroundColor3 = Surface.color(ctx, config.FillColor, "Accent"),
			BorderSizePixel = 0,
			Size = host.udim2(0, 0, 1, 0),
		}, track)
		Helpers.corner(host, fill, trackHeight / 2)
		local tickCount = math.max(2, #stops > 0 and #stops or 5)
		local ticks = {}
		for index = 0, tickCount - 1 do
			local ratio = tickCount == 1 and 0 or index / (tickCount - 1)
			local tick = host.new("Frame", {
				Name = "Tick" .. tostring(index),
				BackgroundColor3 = Surface.color(ctx, config.HandleColor, "TextMuted"),
				BackgroundTransparency = 0.4,
				BorderSizePixel = 0,
				Size = host.udim2(0, 2, 0, 6),
				Position = host.udim2(ratio, -1, 0.5, trackHeight / 2 + 4),
			}, track)
			ticks[index + 1] = tick
			if #stops > 0 and stops[index + 1] then
				local label = Surface.text(ctx, track, {
					Name = "StopLabel" .. tostring(index),
					Size = host.udim2(0, 40, 0, 10),
					Position = host.udim2(ratio, -20, 1, 8),
					Text = stops[index + 1]:ToHex(),
					TextColor3 = stops[index + 1] and ctx.Host.color(stops[index + 1].R * 255, stops[index + 1].G * 255, stops[index + 1].B * 255) or ctx.Tokens.TextMuted,
					TextSize = 9,
					TextXAlignment = host.enumItem("TextXAlignment", "Center"),
				})
				label.Text = ""
			end
		end
		local handle = host.new("Frame", {
			Name = "Handle",
			BackgroundColor3 = Surface.color(ctx, config.HandleColor, "Accent"),
			BorderSizePixel = 0,
			Size = host.udim2(0, handleSize, 0, handleSize),
			Position = host.udim2(0, -handleSize / 2, 0.5, -handleSize / 2),
			ZIndex = 3,
		}, track)
		Helpers.corner(host, handle, 3)
		local valueLabel
		if config.ShowValue ~= false then
			valueLabel = Surface.text(ctx, parent, {
				Name = "Value",
				Size = host.udim2(0, 52, 1, 0),
				Position = host.udim2(1, -52, 0, 0),
				TextColor3 = Surface.color(ctx, config.TextColor, "Text"),
				TextXAlignment = host.enumItem("TextXAlignment", "Right"),
			})
		end
		local input = Surface.hit(ctx, track, {
			Name = "Input",
			Size = host.udim2(1, 0, 0, 24),
			Position = host.udim2(0, 0, 0.5, -12),
			ZIndex = 4,
		})
		local view = {
			Root = slot.Root,
			Input = input,
			Track = track,
			Fill = fill,
			Handle = handle,
			Value = valueLabel,
			TrackWidth = width,
			HandleSize = handleSize,
			Ticks = ticks,
		}
		view.Apply = function(self, state, renderCtx)
			local position = fraction(state, state.Value)
			self.Fill.Size = renderCtx.Host.udim2(position, 0, 1, 0)
			self.Handle.Position = renderCtx.Host.udim2(position, -self.HandleSize / 2, 0.5, -self.HandleSize / 2)
			if self.Value then
				self.Value.Text = tostring(state.Value) .. (renderCtx.Configuration.Suffix or "")
			end
		end
		return view
	end,
}

local function rangeRender(options)
	return function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local width = config.Width or 180
		local trackHeight = config.TrackHeight or 6
		local handleSize = config.HandleSize or 14
		local slot = Surface.slot(ctx, {
			Height = config.RowHeight or 34,
			ControlWidth = width + (config.ShowValue ~= false and 76 or 0),
		})
		local parent = slot.ControlArea or slot.Root
		local track = Surface.panel(ctx, parent, {
			Name = "Track",
			Background = config.TrackColor,
			Token = "Outline",
			Transparency = 0.25,
			CornerRadius = trackHeight / 2,
		})
		track.Size = host.udim2(0, width, 0, trackHeight)
		track.Position = host.udim2(0, 0, 0.5, -trackHeight / 2)
		local selection = host.new("Frame", {
			Name = "Selection",
			BackgroundColor3 = Surface.color(ctx, config.FillColor, "Accent"),
			BorderSizePixel = 0,
			Size = host.udim2(0, 0, 1, 0),
		}, track)
		Helpers.corner(host, selection, trackHeight / 2)
		local handles = {}
		for index = 1, 2 do
			local handle = host.new("Frame", {
				Name = index == 1 and "HandleLow" or "HandleHigh",
				BackgroundColor3 = Surface.color(ctx, config.HandleColor, "Text"),
				BorderSizePixel = 0,
				Size = host.udim2(0, handleSize, 0, handleSize),
				Position = host.udim2(0, -handleSize / 2, 0.5, -handleSize / 2),
				ZIndex = 3,
			}, track)
			Helpers.corner(host, handle, options.square and 2 or handleSize / 2)
			handles[index] = handle
		end
		local valueLabel
		if config.ShowValue ~= false then
			valueLabel = Surface.text(ctx, parent, {
				Name = "Value",
				Size = host.udim2(0, 72, 1, 0),
				Position = host.udim2(1, -72, 0, 0),
				TextColor3 = Surface.color(ctx, config.TextColor, "Text"),
				TextXAlignment = host.enumItem("TextXAlignment", "Right"),
			})
		end
		local input = Surface.hit(ctx, track, {
			Name = "Input",
			Size = host.udim2(1, 0, 0, handleSize + 10),
			Position = host.udim2(0, 0, 0.5, -(handleSize + 10) / 2),
			ZIndex = 4,
		})
		local view = {
			Root = slot.Root,
			Input = input,
			Track = track,
			Selection = selection,
			HandleLow = handles[1],
			HandleHigh = handles[2],
			Value = valueLabel,
			TrackWidth = width,
			HandleSize = handleSize,
		}
		view.Apply = function(self, state, renderCtx)
			local value = state.Value or {}
			local low = value.Low or state.Min or 0
			local high = value.High or state.Max or 100
			local lowFraction = fraction(state, low)
			local highFraction = fraction(state, math.max(high, low))
			self.Selection.Position = renderCtx.Host.udim2(lowFraction, 0, 0, 0)
			self.Selection.Size = renderCtx.Host.udim2(highFraction - lowFraction, 0, 1, 0)
			self.HandleLow.Position = renderCtx.Host.udim2(lowFraction, -self.HandleSize / 2, 0.5, -self.HandleSize / 2)
			self.HandleHigh.Position = renderCtx.Host.udim2(highFraction, -self.HandleSize / 2, 0.5, -self.HandleSize / 2)
			if self.Value then
				self.Value.Text = ("%s - %s"):format(tostring(low), tostring(high))
			end
		end
		return view
	end
end

styles[#styles + 1] = {
	Id = "rangeslider.dual",
	Name = "Dual range",
	Component = "RangeSlider",
	Category = "Controls",
	Description = "Two circular handles with an accent selection between them.",
	Render = rangeRender({}),
}

styles[#styles + 1] = {
	Id = "rangeslider.compact",
	Name = "Compact range",
	Component = "RangeSlider",
	Category = "Controls",
	Description = "Square handles for dense toolbars.",
	Render = rangeRender({ square = true }),
}

local registered, failures = Registry.registerMany(styles, { BuiltIn = true })
for _, failure in ipairs(failures) do
	error(("NEVAHEXUI: sliders style %s failed to register: %s"):format(tostring(failure.Id), table.concat(failure.Errors, "; ")))
end

return registered
end)()

local __NEVA_Styles_Defs_TextInputs = (function()
--[[
	NEVAHEXUI - Styles/Defs/TextInputs
	Textbox, NumberInput and CopyableInput descriptors plus the Keybind styles.
	Keybinds live here because they share the same inline input geometry.
]]

local Registry = __NEVA_Styles_Registry
local Surface = __NEVA_Styles_Surface
local Helpers = __NEVA_Styles_Helpers

local TEXTBOX_PROPERTIES = {
	{ Key = "RowHeight", Type = "number", Default = 30, Min = 18, Max = 200, Group = "Geometry" },
	{ Key = "Height", Type = "number", Default = 30, Min = 18, Max = 400, Group = "Geometry", Description = "Input height; raise it for multiline inputs." },
	{ Key = "Width", Type = "number", Default = 190, Min = 60, Max = 700, Group = "Geometry" },
	{ Key = "CornerRadius", Type = "number", Min = 0, Max = 32, Group = "Geometry" },
	{ Key = "BackgroundColor", Type = "color", Group = "Appearance" },
	{ Key = "TextColor", Type = "color", Group = "Typography" },
	{ Key = "PlaceholderColor", Type = "color", Group = "Typography" },
	{ Key = "StrokeColor", Type = "color", Group = "Appearance" },
	{ Key = "StrokeThickness", Type = "number", Min = 0, Max = 8, Default = 1, Group = "Appearance" },
	{ Key = "Transparency", Type = "number", Min = 0, Max = 1, Step = 0.01, Group = "Appearance" },
	{ Key = "TextSize", Type = "number", Default = 13, Min = 8, Max = 32, Group = "Typography" },
	{ Key = "Padding", Type = "number", Default = 8, Min = 0, Max = 32, Group = "Geometry" },
	{ Key = "MultiLine", Type = "boolean", Default = false, Group = "Behaviour" },
	{ Key = "Alignment", Type = "enum", Options = { "Left", "Center", "Right" }, Default = "Left", Group = "Typography" },
	{ Key = "Animation", Type = "animation", Default = "quick", Group = "Animation" },
}

Registry.registerComponent({
	Name = "Textbox",
	RegistryName = "Textboxes",
	Category = "Inputs",
	Description = "Text entry. Value is a string; supports validation and multiline input.",
	Defaults = {
		RowHeight = 30,
		Height = 30,
		Width = 190,
		TextSize = 13,
		Padding = 8,
		StrokeThickness = 1,
		Animation = "quick",
	},
	Properties = TEXTBOX_PROPERTIES,
})

Registry.registerComponent({
	Name = "NumberInput",
	RegistryName = "NumberInputs",
	Category = "Inputs",
	Description = "Numeric entry with stepper buttons. Value is a number.",
	Defaults = {
		RowHeight = 30,
		Height = 30,
		Width = 130,
		TextSize = 13,
		Step = 1,
		Precision = 0,
		StrokeThickness = 1,
		Animation = "quick",
	},
	Properties = {
		{ Key = "RowHeight", Type = "number", Default = 30, Min = 18, Max = 200, Group = "Geometry" },
		{ Key = "Height", Type = "number", Default = 30, Min = 18, Max = 200, Group = "Geometry" },
		{ Key = "Width", Type = "number", Default = 130, Min = 60, Max = 400, Group = "Geometry" },
		{ Key = "CornerRadius", Type = "number", Min = 0, Max = 32, Group = "Geometry" },
		{ Key = "BackgroundColor", Type = "color", Group = "Appearance" },
		{ Key = "TextColor", Type = "color", Group = "Typography" },
		{ Key = "ButtonColor", Type = "color", Group = "Appearance" },
		{ Key = "StrokeColor", Type = "color", Group = "Appearance" },
		{ Key = "StrokeThickness", Type = "number", Min = 0, Max = 8, Default = 1, Group = "Appearance" },
		{ Key = "Transparency", Type = "number", Min = 0, Max = 1, Step = 0.01, Group = "Appearance" },
		{ Key = "TextSize", Type = "number", Default = 13, Min = 8, Max = 32, Group = "Typography" },
		{ Key = "Suffix", Type = "string", Default = "", Group = "Behaviour" },
		{ Key = "Step", Type = "number", Default = 1, Min = 0, Group = "Behaviour" },
		{ Key = "Precision", Type = "number", Default = 0, Min = 0, Max = 4, Group = "Behaviour" },
		{ Key = "Animation", Type = "animation", Default = "quick", Group = "Animation" },
	},
})

Registry.registerComponent({
	Name = "CopyableInput",
	RegistryName = "CopyableInputs",
	Category = "Inputs",
	Description = "Read-only text with a copy button. Value is a string.",
	Defaults = {
		RowHeight = 30,
		Height = 30,
		Width = 200,
		ButtonWidth = 44,
		TextSize = 13,
		CopyLabel = "Copy",
		CopiedLabel = "Copied",
		StrokeThickness = 1,
		Animation = "quick",
	},
	Properties = {
		{ Key = "RowHeight", Type = "number", Default = 30, Min = 18, Max = 200, Group = "Geometry" },
		{ Key = "Height", Type = "number", Default = 30, Min = 18, Max = 200, Group = "Geometry" },
		{ Key = "Width", Type = "number", Default = 200, Min = 80, Max = 700, Group = "Geometry" },
		{ Key = "ButtonWidth", Type = "number", Default = 44, Min = 24, Max = 200, Group = "Geometry" },
		{ Key = "CornerRadius", Type = "number", Min = 0, Max = 32, Group = "Geometry" },
		{ Key = "BackgroundColor", Type = "color", Group = "Appearance" },
		{ Key = "TextColor", Type = "color", Group = "Typography" },
		{ Key = "ButtonColor", Type = "color", Group = "Appearance" },
		{ Key = "ButtonTextColor", Type = "color", Group = "Typography" },
		{ Key = "StrokeColor", Type = "color", Group = "Appearance" },
		{ Key = "StrokeThickness", Type = "number", Min = 0, Max = 8, Default = 1, Group = "Appearance" },
		{ Key = "Transparency", Type = "number", Min = 0, Max = 1, Step = 0.01, Group = "Appearance" },
		{ Key = "TextSize", Type = "number", Default = 13, Min = 8, Max = 32, Group = "Typography" },
		{ Key = "CopyLabel", Type = "string", Default = "Copy", Group = "Behaviour" },
		{ Key = "CopiedLabel", Type = "string", Default = "Copied", Group = "Behaviour" },
		{ Key = "Animation", Type = "animation", Default = "quick", Group = "Animation" },
	},
})

Registry.registerComponent({
	Name = "Keybind",
	RegistryName = "Keybinds",
	Category = "Inputs",
	Description = "Keyboard binding picker with conflict detection. Value is a key name or false.",
	Defaults = {
		RowHeight = 28,
		KeyWidth = 70,
		KeyHeight = 24,
		Mode = "Hold",
		Animation = "quick",
	},
	Properties = {
		{ Key = "RowHeight", Type = "number", Default = 28, Min = 18, Max = 120, Group = "Geometry" },
		{ Key = "KeyWidth", Type = "number", Default = 70, Min = 32, Max = 240, Group = "Geometry" },
		{ Key = "KeyHeight", Type = "number", Default = 24, Min = 16, Max = 80, Group = "Geometry" },
		{ Key = "CornerRadius", Type = "number", Min = 0, Max = 32, Group = "Geometry" },
		{ Key = "BackgroundColor", Type = "color", Group = "Appearance" },
		{ Key = "TextColor", Type = "color", Group = "Typography" },
		{ Key = "UnboundText", Type = "string", Default = "None", Group = "Behaviour" },
		{ Key = "ListeningText", Type = "string", Default = "...", Group = "Behaviour" },
		{ Key = "StrokeColor", Type = "color", Group = "Appearance" },
		{ Key = "StrokeThickness", Type = "number", Min = 0, Max = 8, Default = 1, Group = "Appearance" },
		{ Key = "Animation", Type = "animation", Default = "quick", Group = "Animation" },
	},
})

local function textboxRender(options)
	return function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local width = config.Width or 190
		local height = config.Height or 30
		local slot = Surface.slot(ctx, { Height = math.max(config.RowHeight or 30, height), ControlWidth = width })
		local parent = slot.ControlArea or slot.Root
		local panel = Surface.panel(ctx, parent, {
			Name = "Body",
			Background = config.BackgroundColor,
			Token = options.token,
			Transparency = Surface.transparency(ctx, config.Transparency, "SurfaceTransparency", options.transparency),
			CornerRadius = config.CornerRadius or ctx.Tokens.CornerRadius,
			Stroke = config.StrokeColor,
			StrokeThickness = config.StrokeThickness or 1,
		})
		panel.Size = host.udim2(0, width, 0, height)
		panel.Position = host.udim2(1, -width, 0.5, -height / 2)
		local padding = config.Padding or 8
		local input = host.new("TextBox", {
			Name = "Input",
			BackgroundTransparency = 1,
			Size = host.udim2(1, -padding * 2, options.multiline and 1 or 0, options.multiline and -padding * 2 or height),
			Position = host.udim2(0, padding, options.multiline and 0 or 0.5, options.multiline and padding or -height / 2),
			Text = "",
			PlaceholderText = options.placeholder or "",
			PlaceholderColor3 = Surface.color(ctx, config.PlaceholderColor, "TextMuted"),
			Font = ctx.Tokens.Font,
			TextSize = config.TextSize or 13,
			TextColor3 = Surface.color(ctx, config.TextColor, "Text"),
			TextXAlignment = host.enumItem("TextXAlignment", config.Alignment or "Left"),
			TextYAlignment = host.enumItem("TextYAlignment", options.multiline and "Top" or "Center"),
			MultiLine = options.multiline == true,
			ClearTextOnFocus = false,
			TextEditable = options.readOnly ~= true,
			TextWrap = options.multiline == true,
		}, panel)
		local view = {
			Root = slot.Root,
			Input = input,
			Body = panel,
			BaseStroke = Surface.color(ctx, config.StrokeColor, "Outline"),
		}
		view.Apply = function(self, state, renderCtx)
			if not state.Enabled then
				self.Body.BackgroundTransparency = math.min(1, (self.Body.BackgroundTransparency or 0) + 0.25)
				self.Input.TextColor3 = Surface.disabledText(renderCtx, Surface.color(renderCtx, renderCtx.Configuration.TextColor, "Text"))
			else
				self.Input.TextEditable = true
			end
			if state.Focused then
				self.Body.BackgroundColor3 = Surface.color(renderCtx, renderCtx.Configuration.BackgroundColor, "Surface")
			end
		end
		view.SetName = function(self, name)
			if self.Input and self.Input.PlaceholderText == "" then
				self.Input.PlaceholderText = name
			end
		end
		return view
	end
end

local styles = {}

styles[#styles + 1] = {
	Id = "textbox.outline",
	Name = "Outline textbox",
	Component = "Textbox",
	Category = "Inputs",
	Description = "Transparent input inside a hairline outline box.",
	Tags = { "default", "outline" },
	Render = textboxRender({ token = "Surface", transparency = 1, placeholder = "" }),
}

styles[#styles + 1] = {
	Id = "textbox.filled",
	Name = "Filled textbox",
	Component = "Textbox",
	Category = "Inputs",
	Description = "Filled surface input with a soft rounded background.",
	Tags = { "filled" },
	Render = textboxRender({ token = "SurfaceAlt", transparency = 0 }),
}

styles[#styles + 1] = {
	Id = "textbox.multiline",
	Name = "Multiline textbox",
	Component = "Textbox",
	Category = "Inputs",
	Description = "Tall wrapped input for notes and multiline text.",
	Render = textboxRender({ token = "SurfaceAlt", transparency = 0, multiline = true }),
}

styles[#styles + 1] = {
	Id = "copyableinput.inline",
	Name = "Inline copy field",
	Component = "CopyableInput",
	Category = "Inputs",
	Description = "Read-only value with an inline copy button that confirms on click.",
	Render = function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local width = config.Width or 200
		local height = config.Height or 30
		local buttonWidth = config.ButtonWidth or 44
		local slot = Surface.slot(ctx, { Height = math.max(config.RowHeight or 30, height), ControlWidth = width })
		local parent = slot.ControlArea or slot.Root
		local panel = Surface.panel(ctx, parent, {
			Name = "Body",
			Background = config.BackgroundColor,
			Token = "SurfaceAlt",
			Transparency = Surface.transparency(ctx, config.Transparency, "SurfaceTransparency", 0),
			CornerRadius = config.CornerRadius or ctx.Tokens.CornerRadius,
			Stroke = config.StrokeColor,
			StrokeThickness = config.StrokeThickness or 1,
		})
		panel.Size = host.udim2(0, width, 0, height)
		panel.Position = host.udim2(1, -width, 0.5, -height / 2)
		local value = Surface.text(ctx, panel, {
			Name = "Value",
			Size = host.udim2(1, -(buttonWidth + 16), 1, 0),
			Position = host.udim2(0, 8, 0, 0),
			Text = "",
			TextColor3 = Surface.color(ctx, config.TextColor, "Text"),
			TextSize = config.TextSize or 13,
			TextTruncate = host.enumItem("TextTruncate", "AtEnd"),
		})
		local button = Surface.panel(ctx, panel, {
			Name = "Copy",
			Button = true,
			Background = config.ButtonColor,
			Token = "Accent",
			Transparency = 0,
			CornerRadius = math.max(0, (config.CornerRadius or ctx.Tokens.CornerRadius or 8) - 2),
		})
		button.Size = host.udim2(0, buttonWidth - 6, 1, -6)
		button.Position = host.udim2(1, -buttonWidth + 3, 0, 3)
		local buttonLabel = Surface.text(ctx, button, {
			Name = "CopyLabel",
			Size = host.udim2(1, 0, 1, 0),
			Text = config.CopyLabel or "Copy",
			TextColor3 = Surface.color(ctx, config.ButtonTextColor, "AccentText"),
			Font = ctx.Tokens.FontBold,
			TextSize = math.max(9, (config.TextSize or 13) - 1),
			TextXAlignment = host.enumItem("TextXAlignment", "Center"),
		})
		local view = {
			Root = slot.Root,
			Input = button,
			Body = panel,
			Value = value,
			Copy = button,
			CopyLabel = buttonLabel,
			CopyText = config.CopyLabel or "Copy",
			CopiedText = config.CopiedLabel or "Copied",
		}
		view.Apply = function(self, state, renderCtx)
			self.Value.Text = tostring(state.Value or "")
			if not state.Enabled then
				self.CopyLabel.TextColor3 = Surface.disabledText(renderCtx, renderCtx.Tokens.AccentText)
			else
				self.CopyLabel.TextColor3 = renderCtx.Tokens.AccentText
			end
		end
		return view
	end,
}

styles[#styles + 1] = {
	Id = "numberinput.stepper",
	Name = "Stepper input",
	Component = "NumberInput",
	Category = "Inputs",
	Description = "Numeric field flanked by decrement and increment buttons.",
	Render = function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local width = config.Width or 130
		local height = config.Height or 30
		local slot = Surface.slot(ctx, { Height = math.max(config.RowHeight or 30, height), ControlWidth = width })
		local parent = slot.ControlArea or slot.Root
		local panel = Surface.panel(ctx, parent, {
			Name = "Body",
			Background = config.BackgroundColor,
			Token = "SurfaceAlt",
			Transparency = Surface.transparency(ctx, config.Transparency, "SurfaceTransparency", 0),
			CornerRadius = config.CornerRadius or ctx.Tokens.CornerRadius,
			Stroke = config.StrokeColor,
			StrokeThickness = config.StrokeThickness or 1,
		})
		panel.Size = host.udim2(0, width, 0, height)
		panel.Position = host.udim2(1, -width, 0.5, -height / 2)
		local buttonColour = Surface.color(ctx, config.ButtonColor, "Surface")
		local function stepper(name, label, xPosition)
			local button = Surface.panel(ctx, panel, {
				Name = name,
				Background = config.ButtonColor,
				Token = "Surface",
				Transparency = 0,
				CornerRadius = math.max(0, (config.CornerRadius or 6) - 2),
			})
			button.Size = host.udim2(0, height - 6, 0, height - 6)
			button.Position = host.udim2(xPosition, 3, 0.5, -(height - 6) / 2)
			local text = Surface.text(ctx, button, {
				Name = name .. "Label",
				Size = host.udim2(1, 0, 1, 0),
				Text = label,
				TextColor3 = Surface.color(ctx, config.TextColor, "Text"),
				Font = ctx.Tokens.FontBold,
				TextSize = config.TextSize or 13,
				TextXAlignment = host.enumItem("TextXAlignment", "Center"),
			})
			return button, text, buttonColour
		end
		local minus = stepper("Minus", "-", 0)
		local plus = stepper("Plus", "+", 1)
		plus.Position = host.udim2(1, -(height - 6) - 3, 0.5, -(height - 6) / 2)
		local input = host.new("TextBox", {
			Name = "Input",
			BackgroundTransparency = 1,
			Size = host.udim2(1, -(height + 4) * 2, 1, 0),
			Position = host.udim2(0.5, 0, 0.5, 0),
			AnchorPoint = host.vector2(0.5, 0.5),
			Text = "",
			Font = ctx.Tokens.Font,
			TextSize = config.TextSize or 13,
			TextColor3 = Surface.color(ctx, config.TextColor, "Text"),
			TextXAlignment = host.enumItem("TextXAlignment", "Center"),
			ClearTextOnFocus = false,
		}, panel)
		local view = {
			Root = slot.Root,
			Input = input,
			Body = panel,
			Controls = { Minus = minus, Plus = plus },
		}
		view.Apply = function(self, state, renderCtx)
			local value = state.Value
			self.Input.Text = tostring(value) .. ((renderCtx.Configuration.Suffix and renderCtx.Configuration.Suffix ~= "") and renderCtx.Configuration.Suffix or "")
		end
		return view
	end,
}

local function keybindRender(options)
	return function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local keyWidth = config.KeyWidth or 70
		local keyHeight = config.KeyHeight or 24
		local slot = Surface.slot(ctx, { Height = config.RowHeight or 28, ControlWidth = keyWidth })
		local parent = slot.ControlArea or slot.Root
		local box = Surface.panel(ctx, parent, {
			Name = "Key",
			Background = config.BackgroundColor,
			Token = options.token,
			Transparency = options.transparency,
			CornerRadius = options.pill and keyHeight / 2 or (config.CornerRadius or ctx.Tokens.CornerRadius or 6),
			Stroke = config.StrokeColor,
			StrokeThickness = config.StrokeThickness or 1,
		})
		box.Size = host.udim2(0, keyWidth, 0, keyHeight)
		box.Position = host.udim2(1, -keyWidth, 0.5, -keyHeight / 2)
		local label = Surface.text(ctx, box, {
			Name = "KeyLabel",
			Size = host.udim2(1, 0, 1, 0),
			Text = config.UnboundText or "None",
			TextColor3 = Surface.color(ctx, config.TextColor, "Text"),
			Font = ctx.Tokens.FontBold,
			TextSize = math.max(10, keyHeight - 11),
			TextXAlignment = host.enumItem("TextXAlignment", "Center"),
		})
		local input = Surface.hit(ctx, box)
		local view = {
			Root = slot.Root,
			Input = input,
			Body = box,
			KeyLabel = label,
			Base = Surface.color(ctx, config.BackgroundColor, options.token),
			Unbound = config.UnboundText or "None",
			Listening = config.ListeningText or "...",
		}
		view.Disabled = Surface.disabledColour(ctx, view.Base)
		view.Apply = function(self, state, renderCtx)
			if not state.Enabled then
				self.Body.BackgroundColor3 = self.Disabled
				self.KeyLabel.TextColor3 = Surface.disabledText(renderCtx, Surface.color(renderCtx, renderCtx.Configuration.TextColor, "Text"))
			elseif state.Listening then
				self.Body.BackgroundColor3 = renderCtx.Tokens.Accent
				self.KeyLabel.TextColor3 = renderCtx.Tokens.AccentText
				self.KeyLabel.Text = self.Listening
			else
				self.Body.BackgroundColor3 = self.Base
				self.KeyLabel.TextColor3 = Surface.color(renderCtx, renderCtx.Configuration.TextColor, "Text")
				self.KeyLabel.Text = state.Value == false and self.Unbound or tostring(state.Value)
			end
		end
		return view
	end
end

styles[#styles + 1] = {
	Id = "keybind.classic",
	Name = "Classic keybind",
	Component = "Keybind",
	Category = "Inputs",
	Description = "Rounded key box that highlights while listening for input.",
	Tags = { "default" },
	Render = keybindRender({ token = "SurfaceAlt", transparency = 0 }),
}

styles[#styles + 1] = {
	Id = "keybind.pill",
	Name = "Pill keybind",
	Component = "Keybind",
	Category = "Inputs",
	Description = "Borderless pill key label for compact lists.",
	Tags = { "pill", "minimal" },
	Render = keybindRender({ token = "Surface", transparency = 0.4, pill = true }),
}

local registered, failures = Registry.registerMany(styles, { BuiltIn = true })
for _, failure in ipairs(failures) do
	error(("NEVAHEXUI: text input style %s failed to register: %s"):format(tostring(failure.Id), table.concat(failure.Errors, "; ")))
end

return registered
end)()

local __NEVA_Styles_Defs_Toggles = (function()
--[[
	NEVAHEXUI - Styles/Defs/Toggles
	Toggle, Checkbox, Radio and RadioGroup descriptors and styles.
	The four switch styles share a two-part structure (track + knob) but differ in
	geometry, decoration, colour sourcing and animation; Checkbox and Radio are
	separate implementations with their own glyph logic.
]]

local Registry = __NEVA_Styles_Registry
local Surface = __NEVA_Styles_Surface
local Helpers = __NEVA_Styles_Helpers

local SWITCH_PROPERTIES = {
	{ Key = "RowHeight", Type = "number", Default = 28, Min = 16, Max = 120, Group = "Geometry" },
	{ Key = "Width", Type = "number", Default = 44, Min = 16, Max = 200, Group = "Geometry" },
	{ Key = "Height", Type = "number", Default = 24, Min = 12, Max = 120, Group = "Geometry" },
	{ Key = "CornerRadius", Type = "number", Min = 0, Max = 64, Group = "Geometry" },
	{ Key = "KnobSize", Type = "number", Min = 4, Max = 64, Group = "Geometry" },
	{ Key = "KnobPadding", Type = "number", Min = 0, Max = 12, Default = 2, Group = "Geometry" },
	{ Key = "AccentColor", Type = "color", Group = "Appearance" },
	{ Key = "TrackColor", Type = "color", Group = "Appearance" },
	{ Key = "KnobColor", Type = "color", Group = "Appearance" },
	{ Key = "StrokeColor", Type = "color", Group = "Appearance" },
	{ Key = "StrokeThickness", Type = "number", Min = 0, Max = 8, Default = 1, Group = "Appearance" },
	{ Key = "TrackTransparency", Type = "number", Min = 0, Max = 1, Step = 0.01, Group = "Appearance" },
	{ Key = "Glow", Type = "boolean", Default = false, Group = "Appearance" },
	{ Key = "GradientFrom", Type = "color", Group = "Appearance" },
	{ Key = "GradientTo", Type = "color", Group = "Appearance" },
	{ Key = "Animation", Type = "animation", Default = "pop", Group = "Animation" },
	{ Key = "AnimationDuration", Type = "number", Min = 0, Max = 2, Group = "Animation" },
}

local SWITCH_DEFAULTS = {
	RowHeight = 28,
	Width = 44,
	Height = 24,
	KnobPadding = 2,
	StrokeThickness = 1,
	Animation = "pop",
	TrackTransparency = 0,
}

Registry.registerComponent({
	Name = "Toggle",
	RegistryName = "Toggles",
	Category = "Controls",
	Description = "Boolean switch. Value is true or false.",
	Defaults = SWITCH_DEFAULTS,
	Properties = SWITCH_PROPERTIES,
})

Registry.registerComponent({
	Name = "Checkbox",
	RegistryName = "Checkboxes",
	Category = "Controls",
	Description = "Square checkbox with a tick glyph.",
	Defaults = {
		RowHeight = 26,
		Size = 20,
		CornerRadius = 4,
		StrokeThickness = 1,
		Animation = "pop",
	},
	Properties = {
		{ Key = "RowHeight", Type = "number", Default = 26, Min = 16, Max = 120, Group = "Geometry" },
		{ Key = "Size", Type = "number", Default = 20, Min = 10, Max = 64, Group = "Geometry" },
		{ Key = "CornerRadius", Type = "number", Min = 0, Max = 32, Group = "Geometry" },
		{ Key = "AccentColor", Type = "color", Group = "Appearance" },
		{ Key = "BoxColor", Type = "color", Group = "Appearance" },
		{ Key = "TickColor", Type = "color", Group = "Appearance" },
		{ Key = "StrokeColor", Type = "color", Group = "Appearance" },
		{ Key = "StrokeThickness", Type = "number", Min = 0, Max = 8, Default = 1, Group = "Appearance" },
		{ Key = "Tick", Type = "string", Default = "\u{2714}", Group = "Appearance" },
		{ Key = "Animation", Type = "animation", Default = "pop", Group = "Animation" },
	},
})

Registry.registerComponent({
	Name = "Radio",
	RegistryName = "Radios",
	Category = "Controls",
	Description = "Single radio button. Radios sharing a Group value behave as one selection.",
	Defaults = {
		RowHeight = 26,
		Size = 20,
		StrokeThickness = 1,
		Animation = "pop",
	},
	Properties = {
		{ Key = "RowHeight", Type = "number", Default = 26, Min = 16, Max = 120, Group = "Geometry" },
		{ Key = "Size", Type = "number", Default = 20, Min = 10, Max = 64, Group = "Geometry" },
		{ Key = "AccentColor", Type = "color", Group = "Appearance" },
		{ Key = "RingColor", Type = "color", Group = "Appearance" },
		{ Key = "DotColor", Type = "color", Group = "Appearance" },
		{ Key = "StrokeThickness", Type = "number", Min = 0, Max = 8, Default = 1, Group = "Appearance" },
		{ Key = "DotScale", Type = "number", Min = 0.2, Max = 1, Step = 0.05, Default = 0.5, Group = "Appearance" },
		{ Key = "Animation", Type = "animation", Default = "pop", Group = "Animation" },
	},
})

Registry.registerComponent({
	Name = "RadioGroup",
	RegistryName = "RadioGroups",
	Category = "Controls",
	Description = "Composite control that lays out Radio children and owns their selection.",
	Defaults = {
		RowHeight = 26,
		Gap = 6,
		Animation = "pop",
	},
	Properties = {
		{ Key = "RowHeight", Type = "number", Default = 26, Min = 16, Max = 120, Group = "Geometry" },
		{ Key = "Gap", Type = "number", Default = 6, Min = 0, Max = 40, Group = "Geometry" },
		{ Key = "CornerRadius", Type = "number", Min = 0, Max = 32, Group = "Geometry" },
		{ Key = "ContainerColor", Type = "color", Group = "Appearance" },
		{ Key = "ContainerTransparency", Type = "number", Min = 0, Max = 1, Step = 0.01, Default = 1, Group = "Appearance" },
		{ Key = "StrokeColor", Type = "color", Group = "Appearance" },
		{ Key = "Animation", Type = "animation", Default = "pop", Group = "Animation" },
	},
})

local function knobGeometry(ctx)
	local config = ctx.Configuration
	local width = config.Width or 44
	local height = config.Height or 24
	local padding = config.KnobPadding or 2
	local knob = config.KnobSize or (height - padding * 2)
	return width, height, padding, knob
end

local function switchRender(options)
	return function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local width, height, padding, knobSize = knobGeometry(ctx)
		if options.shape == "square" then
			width = config.Width or 36
			height = config.Height or 20
			knobSize = config.KnobSize or (height - padding * 2)
		end
		local slot = Surface.slot(ctx, { Height = config.RowHeight or 28, ControlWidth = width })
		local parent = slot.ControlArea or slot.Root
		local trackColourKey = options.trackToken or "Outline"
		local radius = config.CornerRadius
		if radius == nil then
			radius = options.radius == "pill" and height / 2 or 4
		end
		local track = Surface.panel(ctx, parent, {
			Name = "Track",
			Background = config.TrackColor,
			Token = trackColourKey,
			Transparency = Surface.transparency(ctx, config.TrackTransparency, "SurfaceTransparency", 0),
			CornerRadius = radius,
			Stroke = config.StrokeColor,
			StrokeThickness = config.StrokeThickness or 1,
		})
		track.Size = host.udim2(0, width, 0, height)
		track.Position = host.udim2(1, -width, 0.5, -height / 2)
		if config.GradientFrom or config.GradientTo then
			Helpers.gradient(
				host,
				track,
				Surface.color(ctx, config.GradientFrom, "Accent"),
				Surface.color(ctx, config.GradientTo, "SurfaceAlt"),
				90
			)
		end
		local glow
		if config.Glow then
			glow = host.new("Frame", {
				Name = "Glow",
				BackgroundColor3 = Surface.color(ctx, config.AccentColor, "Accent"),
				BackgroundTransparency = 0.72,
				BorderSizePixel = 0,
				Size = host.udim2(1, 8, 1, 8),
				Position = host.udim2(0.5, 0, 0.5, 0),
				AnchorPoint = host.vector2(0.5, 0.5),
				ZIndex = 0,
			}, track)
			Helpers.corner(host, glow, radius + 4)
		end
		local knob = host.new("Frame", {
			Name = "Knob",
			BackgroundColor3 = Surface.color(ctx, config.KnobColor, "Text"),
			BorderSizePixel = 0,
			Size = host.udim2(0, knobSize, 0, knobSize),
			Position = host.udim2(0, padding, 0.5, -knobSize / 2),
			ZIndex = 2,
		}, track)
		Helpers.corner(host, knob, options.shape == "square" and math.max(1, radius - 2) or knobSize / 2)
		local input = Surface.hit(ctx, track, { Size = host.udim2(1, 0, 1, 0), ZIndex = 3 })
		local view = {
			Root = slot.Root,
			Input = input,
			Track = track,
			Knob = knob,
			Glow = glow,
			Width = width,
			Padding = padding,
			KnobSize = knobSize,
			OffColour = Surface.color(ctx, config.TrackColor, trackColourKey),
			OnColour = Surface.color(ctx, config.AccentColor, "Accent"),
			OffKnob = Surface.color(ctx, config.KnobColor, "Text"),
			OffTransparency = Surface.transparency(ctx, config.TrackTransparency, "SurfaceTransparency", 0),
		}
		view.Apply = function(self, state, renderCtx)
			local configuration = renderCtx.Configuration
			local active = state.Value == true
			local travel = self.Width - self.KnobSize - self.Padding * 2
			if not state.Enabled then
				self.Track.BackgroundColor3 = Surface.disabledColour(renderCtx, self.OffColour)
				self.Knob.BackgroundColor3 = Surface.disabledText(renderCtx, self.OffKnob)
				active = false
			else
				self.Track.BackgroundColor3 = active and self.OnColour or self.OffColour
				self.Knob.BackgroundColor3 = active and renderCtx.Tokens.AccentText or self.OffKnob
			end
			Surface.animate(renderCtx, self.Knob, {
				Position = renderCtx.Host.udim2(0, active and (travel + self.Padding) or self.Padding, 0.5, -self.KnobSize / 2),
			})
			if self.Glow then
				self.Glow.BackgroundTransparency = active and 0.6 or 0.9
			end
		end
		return view
	end
end

local function checkboxRender(options)
	return function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local size = config.Size or 20
		local slot = Surface.slot(ctx, { Height = config.RowHeight or 26, ControlWidth = size })
		local parent = slot.ControlArea or slot.Root
		local radius = config.CornerRadius
		if radius == nil then
			radius = options.round and size / 2 or 4
		end
		local box = Surface.panel(ctx, parent, {
			Name = "Box",
			Background = config.BoxColor,
			Token = "SurfaceAlt",
			Transparency = 0,
			CornerRadius = radius,
			Stroke = config.StrokeColor or ctx.Tokens.Outline,
			StrokeThickness = config.StrokeThickness or 1,
		})
		box.Size = host.udim2(0, size, 0, size)
		box.Position = host.udim2(1, -size, 0.5, -size / 2)
		local tick = Surface.text(ctx, box, {
			Name = "Tick",
			Size = host.udim2(1, 0, 1, 0),
			Text = config.Tick or "\u{2714}",
			TextColor3 = Surface.color(ctx, config.TickColor, "AccentText"),
			Font = ctx.Tokens.FontBold,
			TextSize = size * 0.7,
			TextXAlignment = host.enumItem("TextXAlignment", "Center"),
			TextYAlignment = host.enumItem("TextYAlignment", "Center"),
			TextTransparency = 1,
		})
		local input = Surface.hit(ctx, box)
		local view = {
			Root = slot.Root,
			Input = input,
			Box = box,
			Tick = tick,
			OffColour = Surface.color(ctx, config.BoxColor, "SurfaceAlt"),
			OnColour = Surface.color(ctx, config.AccentColor, "Accent"),
			Size = size,
		}
		view.Apply = function(self, state, renderCtx)
			local active = state.Value == true
			if not state.Enabled then
				self.Box.BackgroundColor3 = Surface.disabledColour(renderCtx, self.OffColour)
				self.Tick.TextTransparency = 0.6
			else
				self.Box.BackgroundColor3 = active and self.OnColour or self.OffColour
				self.Tick.TextTransparency = active and 0 or 1
			end
		end
		return view
	end
end

local function radioRender(options)
	return function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local size = config.Size or 20
		local slot = Surface.slot(ctx, { Height = config.RowHeight or 26, ControlWidth = size })
		local parent = slot.ControlArea or slot.Root
		local ring = Surface.panel(ctx, parent, {
			Name = "Ring",
			Background = config.RingColor,
			Token = "SurfaceAlt",
			Transparency = 0,
			CornerRadius = size / 2,
			Stroke = config.StrokeColor or ctx.Tokens.Outline,
			StrokeThickness = config.StrokeThickness or 1,
		})
		ring.Size = host.udim2(0, size, 0, size)
		ring.Position = host.udim2(1, -size, 0.5, -size / 2)
		local dotScale = config.DotScale or 0.5
		local dotSize = math.max(4, size * dotScale)
		local dot = host.new("Frame", {
			Name = "Dot",
			BackgroundColor3 = Surface.color(ctx, config.DotColor, "Accent"),
			BorderSizePixel = 0,
			Size = options.dot == "fill" and host.udim2(1, -6, 1, -6) or host.udim2(0, dotSize, 0, dotSize),
			Position = host.udim2(0.5, 0, 0.5, 0),
			AnchorPoint = host.vector2(0.5, 0.5),
			BackgroundTransparency = 1,
		}, ring)
		Helpers.corner(host, dot, dotSize / 2)
		local input = Surface.hit(ctx, ring)
		local view = {
			Root = slot.Root,
			Input = input,
			Ring = ring,
			Dot = dot,
			OffColour = Surface.color(ctx, config.RingColor, "SurfaceAlt"),
			OnColour = Surface.color(ctx, config.AccentColor or config.RingColor, "Accent"),
			Fill = options.dot == "fill",
		}
		view.Apply = function(self, state, renderCtx)
			local active = state.Value == true
			if not state.Enabled then
				self.Ring.BackgroundColor3 = Surface.disabledColour(renderCtx, self.OffColour)
				self.Dot.BackgroundTransparency = 1
			else
				self.Ring.BackgroundColor3 = active and self.OnColour or self.OffColour
				self.Dot.BackgroundTransparency = active and 0 or 1
			end
		end
		return view
	end
end

local styles = {}

styles[#styles + 1] = {
	Id = "toggle.rounded",
	Name = "Rounded switch",
	Component = "Toggle",
	Category = "Controls",
	Description = "Classic pill switch with a circular knob and accent fill.",
	Tags = { "default", "pill" },
	Render = switchRender({ shape = "pill", radius = "pill", trackToken = "Outline" }),
}

styles[#styles + 1] = {
	Id = "toggle.compact",
	Name = "Compact switch",
	Component = "Toggle",
	Category = "Controls",
	Description = "Small square-cornered switch for dense layouts.",
	Tags = { "compact", "dense" },
	Render = switchRender({ shape = "square", radius = "square", trackToken = "Outline" }),
}

styles[#styles + 1] = {
	Id = "toggle.neon",
	Name = "Neon switch",
	Component = "Toggle",
	Category = "Controls",
	Description = "Glowing switch with an accent halo and gradient track.",
	Tags = { "neon", "glow" },
	Render = switchRender({ shape = "pill", radius = "pill", trackToken = "Background" }),
}

styles[#styles + 1] = {
	Id = "toggle.glass",
	Name = "Glass switch",
	Component = "Toggle",
	Category = "Controls",
	Description = "Translucent switch with a gradient track and soft rim.",
	Tags = { "glass", "translucent" },
	Render = switchRender({ shape = "pill", radius = "pill", trackToken = "Surface" }),
}

styles[#styles + 1] = {
	Id = "checkbox.standard",
	Name = "Standard checkbox",
	Component = "Checkbox",
	Category = "Controls",
	Description = "Square checkbox that fills with the accent colour when checked.",
	Tags = { "default", "tick" },
	Render = checkboxRender({}),
}

styles[#styles + 1] = {
	Id = "checkbox.circle",
	Name = "Round checkbox",
	Component = "Checkbox",
	Category = "Controls",
	Description = "Circular checkbox for compact toolbars.",
	Tags = { "round" },
	Render = checkboxRender({ round = true }),
}

styles[#styles + 1] = {
	Id = "radio.classic",
	Name = "Classic radio",
	Component = "Radio",
	Category = "Controls",
	Description = "Ring with a centred dot when selected.",
	Tags = { "default" },
	Render = radioRender({ dot = "dot" }),
}

styles[#styles + 1] = {
	Id = "radio.filled",
	Name = "Filled radio",
	Component = "Radio",
	Category = "Controls",
	Description = "Ring that fills with the accent colour when selected.",
	Tags = { "filled" },
	Render = radioRender({ dot = "fill" }),
}

styles[#styles + 1] = {
	Id = "radiogroup.list",
	Name = "Radio list",
	Component = "RadioGroup",
	Category = "Controls",
	Description = "Vertical list container that hosts Radio children.",
	Render = function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local slot = Surface.slot(ctx, {
			Height = config.RowHeight or 26,
			Label = true,
			ControlWidth = 0,
		})
		local holder = host.new("Frame", {
			Name = "Options",
			BackgroundColor3 = Surface.color(ctx, config.ContainerColor, "SurfaceAlt"),
			BackgroundTransparency = Surface.transparency(ctx, config.ContainerTransparency, "SurfaceTransparency", 1),
			BorderSizePixel = 0,
			Size = host.udim2(1, 0, 0, (config.RowHeight or 26) + (config.Gap or 6)),
			Position = host.udim2(0, 0, 1, 4),
		}, slot.LabelArea or slot.Root)
		Helpers.corner(host, holder, config.CornerRadius or ctx.Tokens.CornerRadius)
		if config.StrokeColor then
			Helpers.stroke(host, holder, Surface.color(ctx, config.StrokeColor, "Outline"), 1, 0)
		end
		host.new("UIListLayout", {
			FillDirection = host.enumItem("FillDirection", "Vertical"),
			Padding = host.udim(0, config.Gap or 6),
			SortOrder = host.enumItem("SortOrder", "LayoutOrder"),
		}, holder)
		local view = {
			Root = slot.Root,
			Holder = holder,
			Label = slot.Label,
			Gap = config.Gap or 6,
			RowHeight = config.RowHeight or 26,
		}
		view.Apply = function(self)
			-- RadioGroup owns no visual state of its own; children paint themselves.
		end
		view.SetName = function(self, name)
			if self.Label then
				self.Label.Text = name
			end
		end
		return view
	end,
}

local registered, failures = Registry.registerMany(styles, { BuiltIn = true })
for _, failure in ipairs(failures) do
	error(("NEVAHEXUI: toggles style %s failed to register: %s"):format(tostring(failure.Id), table.concat(failure.Errors, "; ")))
end

return registered
end)()

local __NEVA_Runtime = (function()
--[[
	NEVAHEXUI - Runtime
	The public entry point: `local NEVAHEXUI = require(...)` then
	`NEVAHEXUI:CreateWindow{...}`.

	The runtime owns the library-wide layer: host/back-end selection, the style and
	theme catalogues, global defaults, the synchronised component registries
	(`Toggles.Flag.Value`), and window creation. Style definitions are loaded here
	because registration order defines each component's default style.
]]

local Host = __NEVA_Compatibility_Host
local Capabilities = __NEVA_Compatibility_Capabilities
local Context = __NEVA_Core_Context
local Layouts = __NEVA_Core_Layouts
local Logger = __NEVA_Core_Logger
local Util = __NEVA_Core_Util
local Store = __NEVA_State_Store
local Keybinder = __NEVA_Input_Keybinder
local Styles = __NEVA_Styles_Registry
local Schema = __NEVA_Styles_Schema
local Resolver = __NEVA_Styles_Resolver
local Themes = __NEVA_Themes_Registry
local ThemesDefs = __NEVA_Themes_Defs
local Components = __NEVA_Components_Index
local Animation = __NEVA_Animation_Presets
local Json = __NEVA_Configuration_Json

-- Style definition modules. Requiring a module registers its component
-- descriptors and its style renderers.
local styleModules = {
	{ Name = "Buttons", Load = function() return __NEVA_Styles_Defs_Buttons end },
	{ Name = "Toggles", Load = function() return __NEVA_Styles_Defs_Toggles end },
	{ Name = "Sliders", Load = function() return __NEVA_Styles_Defs_Sliders end },
	{ Name = "TextInputs", Load = function() return __NEVA_Styles_Defs_TextInputs end },
	{ Name = "Display", Load = function() return __NEVA_Styles_Defs_Display end },
	{ Name = "DataViews", Load = function() return __NEVA_Styles_Defs_DataViews end },
	{ Name = "Pickers", Load = function() return __NEVA_Styles_Defs_Pickers end },
	{ Name = "Feedback", Load = function() return __NEVA_Styles_Defs_Feedback end },
}

local NEVAHEXUI = {}
NEVAHEXUI.Version = "1.0.0"
NEVAHEXUI.Name = "NEVAHEXUI"
NEVAHEXUI.Tagline = "Unified Roblox Luau UI framework with a configurable style engine"
NEVAHEXUI.Styles = Styles
NEVAHEXUI.Themes = Themes
NEVAHEXUI.Layouts = Layouts
NEVAHEXUI.Animation = Animation
NEVAHEXUI.Store = Store
NEVAHEXUI.Schema = Schema
NEVAHEXUI._Loaded = false
NEVAHEXUI.Windows = {}
NEVAHEXUI.Registries = {}

-- Loading --------------------------------------------------------------------

function NEVAHEXUI:Load(options)
	options = options or {}
	if self._Loaded and not options.Force then
		return self
	end
	self.Capabilities = Capabilities.detect()
	self.Logger = Logger.new({ Level = options.LogLevel or Logger.Levels.Warn, Name = "NEVAHEXUI" })
	self.Host = options.Host or Host.create({ Capabilities = self.Capabilities })
	Host.verify(self.Host)
	for _, entry in ipairs(styleModules) do
		local ok, err = pcall(entry.Load)
		if not ok then
			self.LoadingErrors = self.LoadingErrors or {}
			table.insert(self.LoadingErrors, { Module = entry.Name, Error = tostring(err) })
			self.Logger:Error(("style module %s failed to load: %s"):format(entry.Name, tostring(err)))
		end
	end
	self._Loaded = true
	self:BuildRegistries()
	self.GlobalDefaults = {
		Theme = options.Theme or "dark",
		Accent = options.Accent, -- themes define the default accent (red); only override when asked
		StyleConfiguration = Util.deepCopy(options.StyleConfiguration or {}),
		Styles = Util.deepCopy(options.Styles or {}),
		Layout = options.Layout or "Sidebar",
	}
	return self
end

function NEVAHEXUI:EnsureLoaded()
	if not self._Loaded then
		self:Load()
	end
	return self
end

-- Catalogues -----------------------------------------------------------------

function NEVAHEXUI:RegisterStyle(definition)
	self:EnsureLoaded()
	if type(definition) ~= "table" then
		return nil, { "RegisterStyle expects a table" }
	end
	-- A preset may inherit its renderer from the style it extends, so
	-- `RegisterStyle{ Id = "toggle.neva.red", Requires = "toggle.rounded",
	-- Configuration = {...} }` works without handing over a function reference.
	-- The registry itself stays strict: every stored style has a callable Render.
	local prepared = Util.deepCopy(definition)
	if prepared.Render == nil and prepared.Requires ~= nil then
		local parent = Styles.get(prepared.Requires)
		if parent == nil then
			return nil, { ("Requires references unknown style %q"):format(tostring(prepared.Requires)) }
		end
		prepared.Render = parent.Render
	end
	local record, errors = Styles.registerStyle(prepared)
	if not record then
		return nil, errors
	end
	self:_RecordUserStyle(record.Id)
	return record
end

function NEVAHEXUI:RegisterTheme(definition)
	self:EnsureLoaded()
	return Themes.register(definition)
end

function NEVAHEXUI:UnregisterStyle(id)
	self:EnsureLoaded()
	return Styles.unregister(id)
end

function NEVAHEXUI:GetStyle(id)
	self:EnsureLoaded()
	return Styles.get(id)
end

function NEVAHEXUI:HasStyle(id)
	self:EnsureLoaded()
	return Styles.has(id)
end

function NEVAHEXUI:ListStyles(component)
	self:EnsureLoaded()
	if component then
		return Styles.list(component)
	end
	return Styles.catalog()
end

function NEVAHEXUI:StyleIds(component)
	self:EnsureLoaded()
	-- Styles.catalog() is grouped per component, so the flat id list comes from
	-- the registry's own order -- which also includes styles registered at runtime.
	return Styles.styleIds(component)
end

function NEVAHEXUI:ListComponents()
	self:EnsureLoaded()
	return Styles.listComponents()
end

function NEVAHEXUI:ListThemes()
	self:EnsureLoaded()
	return Themes.list()
end

function NEVAHEXUI:ListLayouts()
	return Layouts.list()
end

function NEVAHEXUI:ListAnimations()
	return Animation.list()
end

function NEVAHEXUI:Explain(styleId, request)
	self:EnsureLoaded()
	local record = Styles.get(styleId)
	if not record then
		return nil, ("unknown style %q"):format(tostring(styleId))
	end
	local chain = Styles.chain(styleId)
	return {
		Style = record,
		Properties = Styles.effectiveProperties(chain),
		Chain = chain,
		Requires = record.Requires,
		Request = request,
	}
end

function NEVAHEXUI:ExportStyle(styleId, options)
	self:EnsureLoaded()
	local record = Styles.get(styleId)
	if not record then
		return nil, ("unknown style %q"):format(tostring(styleId))
	end
	return Schema.exportStyle(record, options)
end

function NEVAHEXUI:ExportConfiguration(componentType, configuration)
	self:EnsureLoaded()
	local record = Styles.get(componentType)
	return Schema.exportLua(configuration, record and Styles.effectiveProperties(Styles.chain(record.Id)) or {})
end

-- Registries -----------------------------------------------------------------

function NEVAHEXUI:_RecordUserStyle(id)
	self.UserStyles = self.UserStyles or {}
	self.UserStyles[id] = true
end

function NEVAHEXUI:BuildRegistries()
	self.Registries = {}
	for _, component in ipairs(Styles.listComponents()) do
		local name = component.RegistryName
		if name and name ~= "" and self.Registries[name] == nil then
			self.Registries[name] = setmetatable({}, {
				__index = function(_, key)
					local entry = Store.get(key)
					if entry then
						return entry
					end
					return Store.getById(key)
				end,
				__newindex = function() end,
			})
		end
	end
	return self.Registries
end

function NEVAHEXUI:GetRegistry(name)
	self:EnsureLoaded()
	return self.Registries[name]
end

function NEVAHEXUI:GetComponent(flagOrId)
	self:EnsureLoaded()
	return Store.get(flagOrId) or Store.getById(flagOrId)
end

function NEVAHEXUI:FindAll(flag)
	self:EnsureLoaded()
	return Store.getAll(flag)
end

-- Library configuration -----------------------------------------------------

function NEVAHEXUI:SetGlobalDefaults(configuration)
	self:EnsureLoaded()
	configuration = configuration or {}
	if configuration.Theme then
		self.GlobalDefaults.Theme = configuration.Theme
	end
	if configuration.Accent then
		self.GlobalDefaults.Accent = configuration.Accent
	end
	if configuration.Layout then
		self.GlobalDefaults.Layout = configuration.Layout
	end
	if configuration.Styles then
		self.GlobalDefaults.Styles = Util.deepMerge(self.GlobalDefaults.Styles or {}, configuration.Styles)
	end
	if configuration.StyleConfiguration then
		self.GlobalDefaults.StyleConfiguration = Util.deepMerge(
			self.GlobalDefaults.StyleConfiguration or {},
			configuration.StyleConfiguration
		)
	end
	for _, context in ipairs(self.Contexts or {}) do
		context.GlobalDefaults = self.GlobalDefaults
	end
	return self.GlobalDefaults
end

function NEVAHEXUI:GetGlobalDefaults()
	return self.GlobalDefaults
end

function NEVAHEXUI:SetCategoryStyle(component, styleId)
	for _, context in ipairs(self.Contexts or {}) do
		context:SetStyleDefault(component, styleId)
	end
	return true
end

function NEVAHEXUI:SetCategoryConfiguration(component, configuration, options)
	for _, context in ipairs(self.Contexts or {}) do
		context:SetCategoryConfiguration(component, configuration, options)
	end
	return true
end

function NEVAHEXUI:SetComponentStyle(flagOrId, styleId, configuration)
	self:EnsureLoaded()
	local component = self:GetComponent(flagOrId)
	if not component then
		return false, ("no component registered for %q"):format(tostring(flagOrId))
	end
	return component:SetStyle(styleId, configuration)
end

function NEVAHEXUI:SetTheme(themeId, overrides)
	for _, context in ipairs(self.Contexts or {}) do
		context:SetTheme(themeId, overrides)
	end
	return true
end

-- Window creation ------------------------------------------------------------

function NEVAHEXUI:CreateWindow(options)
	options = options or {}
	self:EnsureLoaded()
	self.Contexts = self.Contexts or {}

	local configuration = options.Configuration or {}
	local global = self.GlobalDefaults or {}
	local context = Context.new({
		Host = self.Host,
		Logger = self.Logger,
		Theme = options.Theme or configuration.Theme or global.Theme,
		ThemeConfiguration = options.ThemeConfiguration or configuration.ThemeConfiguration,
		Styles = options.Styles or global.Styles,
		StyleConfiguration = options.StyleConfiguration or global.StyleConfiguration,
		GlobalDefaults = {
			Styles = global.Styles,
			StyleConfiguration = global.StyleConfiguration,
		},
		LogLevel = options.LogLevel,
		Name = options.Name,
	})
	context.Keybinder = Keybinder.new(self.Host, { Name = options.Name or "NEVAHEXUI" })
	Components.install(context)

	local Window = __NEVA_Core_Window
	local merged = Util.deepMerge({
		Layout = options.Layout or global.Layout,
		Accent = configuration.Accent or global.Accent,
	}, options)
	local window = Window.new(context, merged)
	self.Windows[#self.Windows + 1] = window
	table.insert(self.Contexts, context)
	return window
end

function NEVAHEXUI:GetWindows()
	return self.Windows
end

function NEVAHEXUI:GetPrimaryWindow()
	return self.Windows[1]
end

function NEVAHEXUI:Notify(message, options)
	local window = self:GetPrimaryWindow()
	if not window then
		return nil, "no window has been created yet"
	end
	if type(options) == "table" then
		options.Message = options.Message or message
		return window:Notify(options)
	end
	return window:Notify({ Message = message, Level = options })
end

function NEVAHEXUI:Dialog(options)
	local window = self:GetPrimaryWindow()
	if not window then
		return nil, "no window has been created yet"
	end
	return window:Dialog(options)
end

function NEVAHEXUI:OpenStudio(options)
	local window = self:GetPrimaryWindow()
	if not window then
		return nil, "no window has been created yet"
	end
	return window:OpenStudio(options)
end

-- Diagnostics ----------------------------------------------------------------

function NEVAHEXUI:Summary()
	self:EnsureLoaded()
	return {
		Version = self.Version,
		Host = self.Host and self.Host.Kind or "unknown",
		Styles = Styles.count(),
		Themes = Themes.count(),
		Layouts = #Layouts.ids(),
		Components = #Styles.listComponents(),
		Windows = #self.Windows,
		LoadingErrors = self.LoadingErrors and #self.LoadingErrors or 0,
	}
end

function NEVAHEXUI:Diagnostics()
	self:EnsureLoaded()
	local report = {
		Summary = self:Summary(),
		LoadingErrors = self.LoadingErrors or {},
		Capabilities = self.Capabilities,
		DuplicateFlags = Store.duplicates(),
		Components = {},
	}
	for _, component in ipairs(Store.all()) do
		if component.LastError or component.LastValueError then
			table.insert(report.Components, {
				Flag = component.Flag,
				Type = component.Type,
				Style = component.StyleId,
				Error = component.LastError,
				ValueError = component.LastValueError,
			})
		end
	end
	return report
end

function NEVAHEXUI:PrintCatalog(filter)
	self:EnsureLoaded()
	local lines = {}
	for _, style in ipairs(Styles.list()) do
		if not filter or style.Component == filter or (style.Id or ""):find(filter, 1, true) then
			table.insert(lines, ("%s  (%s)  %s"):format(style.Id, tostring(style.Component), tostring(style.Name)))
		end
	end
	return lines
end

function NEVAHEXUI:Destroy()
	for _, window in ipairs(self.Windows) do
		if not window.Destroyed then
			pcall(function()
				window:Destroy()
			end)
		end
	end
	for _, context in ipairs(self.Contexts or {}) do
		pcall(function()
			context:Destroy()
		end)
	end
	self.Windows = {}
	self.Contexts = {}
	Store.reset()
	return true
end

NEVAHEXUI.Json = Json

return NEVAHEXUI
end)()

local __NEVA_Init = (function()
--[[
	NEVAHEXUI - Init
	The single-file build entry point. Loading NEVAHEXUI returns the runtime table
	already loaded, so callers can simply do:

	    local NEVAHEXUI = loadstring(game:HttpGet(url))()
	    local Window = NEVAHEXUI:CreateWindow({ Name = "My Interface" })

	Under a plain Luau interpreter (tests, CI) the same entry returns the runtime
	with the mock host back end.
]]

local Runtime = __NEVA_Runtime

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
end)()

return __NEVA_Init
end)()
do
-- test file: 01-smoke.test.luau
--[[
	NEVAHEXUI smoke tests.
	These run against the generated bundle under plain Luau with the mock host
	back end. They verify the library instantiates, styles resolve, registries stay
	synchronised and the Studio builds - the things static analysis cannot check.
]]

NevaTest:suite("smoke")

local function report(label, value)
	print(("      - %-26s %s"):format(label, tostring(value)))
end

local function newWindow(extra)
	local options = {
		Name = "Smoke",
		Layout = "Sidebar",
		Theme = "dark",
		SaveConfigs = false,
	}
	for key, value in pairs(extra or {}) do
		options[key] = value
	end
	return NEVAHEXUI:CreateWindow(options)
end

NevaTest:test("runtime loads every style module", function()
	NevaTest:assert(NEVAHEXUI, "runtime table is present")
	local summary = NEVAHEXUI:Summary()
	for key, value in pairs(summary) do
		report(key, value)
	end
	NevaTest:equals(summary.LoadingErrors, 0, "no style module failed to load")
	NevaTest:assert(summary.Styles >= 45, "the style catalogue is populated")
	NevaTest:assert(summary.Components >= 20, "component descriptors are registered")
	NevaTest:assert(summary.Layouts >= 4, "at least the four core layouts exist")
	NevaTest:assert(summary.Themes >= 6, "themes are registered")
	NevaTest:assert(NEVAHEXUI:HasStyle("toggle.rounded"), "toggle.rounded exists")
	NevaTest:assert(NEVAHEXUI:HasStyle("toggle.compact"), "toggle.compact exists")
	NevaTest:assert(NEVAHEXUI:HasStyle("slider.neon"), "slider.neon exists")
	NevaTest:assert(NEVAHEXUI:HasStyle("button.modern"), "button.modern exists")
end)

NevaTest:test("window, tab, section and components construct", function()
	local window = newWindow()
	local tab = window:CreateTab({ Name = "Main" })
	local section = tab:CreateSection({ Name = "Section" })
	NevaTest:equals(type(section.CreateToggle), "function", "containers expose CreateToggle")
	NevaTest:equals(type(section.CreateSlider), "function", "containers expose CreateSlider")
	NevaTest:equals(type(section.CreateColorPicker), "function", "containers expose CreateColorPicker")

	local label = section:CreateLabel({ Name = "Greeting", Default = "hello" })
	local toggle = section:CreateToggle({ Name = "Enabled", Flag = "SmokeToggle", Default = false })
	local slider = section:CreateSlider({ Name = "Volume", Flag = "SmokeSlider", Min = 0, Max = 100, Default = 40 })
	local picker = section:CreateColorPicker({ Name = "Tint", Flag = "SmokeColor", Default = { 1, 0, 0 } })

	NevaTest:equals(label:GetValue(), "hello", "label value")
	NevaTest:equals(toggle:GetValue(), false, "toggle default")
	NevaTest:equals(slider:GetValue(), 40, "slider default")
	NevaTest:assert(picker:GetValue() ~= nil, "colour picker coerced a value")
	NevaTest:equals(window:GetComponentCount(), 4, "window counts its components")
	report("components", window:GetComponentCount())
	window:Destroy()
end)

NevaTest:test("registry stays synchronised with components", function()
	local window = newWindow()
	local tab = window:CreateTab({ Name = "Main" })
	local section = tab:CreateSection({ Name = "Registry" })
	local toggle = section:CreateToggle({ Name = "Reg", Flag = "RegToggle", Default = false })

	local registry = NEVAHEXUI:GetRegistry("Toggles")
	NevaTest:assert(registry, "the Toggles registry exists")
	NevaTest:equals(registry.RegToggle, toggle, "Toggles.RegToggle is the same component")
	local callbackCount = 0
	toggle:OnChanged(function()
		callbackCount += 1
	end)
	toggle:SetValue(true)
	NevaTest:equals(toggle:GetValue(), true, "programmatic SetValue applied")
	NevaTest:equals(registry.RegToggle.Value, true, "registry reads the new value")
	NevaTest:equals(callbackCount, 1, "the change callback fired once")
	report("callback fires", callbackCount)
	window:Destroy()
end)

NevaTest:test("style switching preserves value, flag and callback", function()
	local window = newWindow()
	local tab = window:CreateTab({ Name = "Main" })
	local section = tab:CreateSection({ Name = "Styles" })
	local toggle = section:CreateToggle({ Name = "Styled", Flag = "StyledToggle", Default = true })
	local fires = 0
	toggle:OnChanged(function()
		fires += 1
	end)

	NevaTest:equals(toggle:GetStyle(), "toggle.rounded", "first registered toggle renderer is the default")
	local ok = toggle:SetStyle("toggle.compact")
	NevaTest:assert(ok ~= false, "SetStyle to a real style succeeds")
	NevaTest:equals(toggle:GetStyle(), "toggle.compact", "style id updated")
	NevaTest:equals(toggle:GetValue(), true, "value survived the style change")
	NevaTest:equals(toggle.Flag, "StyledToggle", "flag survived the style change")
	toggle:SetValue(false)
	NevaTest:equals(fires, 1, "the callback survived the style change")

	local failed, err = toggle:SetStyle("nonexistent.style")
	NevaTest:equals(failed, false, "an unknown style is rejected")
	NevaTest:assert(err ~= nil, "an unknown style reports why")
	NevaTest:equals(toggle:GetStyle(), "toggle.compact", "the rejected change left the old style in place")
	report("unknown style error", err)
	window:Destroy()
end)

NevaTest:test("Style 1 and Style 2 coexist in one window", function()
	local window = newWindow()
	local tab = window:CreateTab({ Name = "Main" })
	local section = tab:CreateSection({ Name = "Two styles" })
	local first = section:CreateToggle({
		Name = "Style 1 - Modern",
		Flag = "StyleOne",
		Default = true,
		Style = { Id = "toggle.rounded", Configuration = { CornerRadius = 12, Width = 44, Height = 24 } },
	})
	local second = section:CreateToggle({
		Name = "Style 2 - Compact",
		Flag = "StyleTwo",
		Default = false,
		Style = { Id = "toggle.compact", Configuration = { CornerRadius = 3, Width = 36, Height = 20 } },
	})
	NevaTest:equals(first:GetStyle(), "toggle.rounded", "first toggle uses style 1")
	NevaTest:equals(second:GetStyle(), "toggle.compact", "second toggle uses style 2")
	NevaTest:equals(first:GetEffectiveConfiguration().Width, 44, "style 1 keeps its own width")
	NevaTest:equals(second:GetEffectiveConfiguration().Width, 36, "style 2 keeps its own width")
	NevaTest:equals(first:GetValue(), true, "style 1 keeps its own value")
	NevaTest:equals(second:GetValue(), false, "style 2 keeps its own value")

	second:SetStyleConfiguration({ CornerRadius = 14 })
	NevaTest:equals(second:GetStyleConfiguration().CornerRadius, 14, "per-component override recorded")
	NevaTest:equals(first:GetStyleConfiguration().CornerRadius, 12, "the other component keeps its own overrides")
	report("style1 width / style2 width", tostring(first:GetEffectiveConfiguration().Width) .. " / " .. tostring(second:GetEffectiveConfiguration().Width))
	window:Destroy()
end)

NevaTest:test("category defaults and per-component overrides resolve", function()
	local window = newWindow({
		StyleConfiguration = { Toggle = { CornerRadius = 10, Height = 24 } },
	})
	local tab = window:CreateTab({ Name = "Main" })
	local section = tab:CreateSection({ Name = "Cascade" })
	local plain = section:CreateToggle({ Name = "Category", Flag = "CascadeA", Style = { Id = "toggle.rounded" } })
	local overridden = section:CreateToggle({
		Name = "Override",
		Flag = "CascadeB",
		Style = { Id = "toggle.rounded", Configuration = { CornerRadius = 20 } },
	})
	NevaTest:equals(plain:GetEffectiveConfiguration().CornerRadius, 10, "category default applied")
	NevaTest:equals(overridden:GetEffectiveConfiguration().CornerRadius, 20, "per-component override wins")
	NevaTest:equals(overridden:GetEffectiveConfiguration().Height, 24, "category default still fills other keys")

	NEVAHEXUI:SetCategoryStyle("Toggle", "toggle.neon")
	local third = section:CreateToggle({ Name = "Default", Flag = "CascadeC" })
	NevaTest:equals(third:GetStyle(), "toggle.neon", "category default style is honoured for new components")
	report("explain", tostring(overridden:ExplainConfiguration() and "provided" or "missing"))
	window:Destroy()
end)

NevaTest:test("themes, layouts and window state survive changes", function()
	local window = newWindow()
	local tab = window:CreateTab({ Name = "Main" })
	local section = tab:CreateSection({ Name = "State" })
	local toggle = section:CreateToggle({ Name = "Kept", Flag = "KeptToggle", Default = true })
	local slider = section:CreateSlider({ Name = "Kept2", Flag = "KeptSlider", Min = 0, Max = 10, Default = 3 })

	NevaTest:equals(window:SetTheme("light"), true, "theme switched to light")
	NevaTest:equals(window:GetTheme(), "light", "theme id updated")
	NevaTest:equals(toggle:GetValue(), true, "value survived the theme change")
	NevaTest:equals(window:SetLayout("TopTabs"), true, "layout switched to TopTabs")
	NevaTest:equals(window:GetLayout(), "TopTabs", "layout id updated")
	NevaTest:equals(toggle:GetValue(), true, "value survived the layout change")
	NevaTest:equals(slider:GetEffectiveConfiguration() ~= nil, true, "slider still resolves configuration")
	NevaTest:equals(#window:GetTabs(), 1, "the tab survived the layout change")
	NevaTest:equals(window:GetTab("Main") ~= nil, true, "the tab is still addressable by name")
	window:Destroy()
end)

NevaTest:test("user styles register, validate and reject duplicates", function()
	local record, errors = NEVAHEXUI:RegisterStyle({
		Id = "toggle.neva.red",
		Name = "NEVA Red",
		Component = "Toggle",
		Configuration = { CornerRadius = 10, Width = 44, Height = 24 },
		Requires = "toggle.rounded",
	})
	NevaTest:assert(record ~= nil, "a style preset registers")
	if record then
		NevaTest:equals(record.Id, "toggle.neva.red", "the preset keeps its id")
	end
	local again, duplicateErrors = NEVAHEXUI:RegisterStyle({
		Id = "toggle.neva.red",
		Name = "Duplicate",
		Component = "Toggle",
		Requires = "toggle.rounded",
	})
	NevaTest:assert(again == nil, "a duplicate id is rejected rather than overwriting")
	report("duplicate rejection", tostring(duplicateErrors and duplicateErrors[1] or duplicateErrors))

	local bad, badErrors = NEVAHEXUI:RegisterStyle({ Id = "", Name = "Bad", Component = "Toggle" })
	NevaTest:assert(bad == nil, "an invalid definition is rejected")

	local window = newWindow()
	local tab = window:CreateTab({ Name = "Main" })
	local section = tab:CreateSection({ Name = "Preset" })
	local toggle = section:CreateToggle({ Name = "Preset", Flag = "PresetToggle", Style = { Id = "toggle.neva.red" } })
	NevaTest:equals(toggle:GetStyle(), "toggle.neva.red", "a registered preset can be selected")
	NevaTest:equals(toggle:GetEffectiveConfiguration().Width, 44, "the preset configuration applies")
	window:Destroy()
end)

NevaTest:test("dependencies hide and reveal components", function()
	local window = newWindow()
	local tab = window:CreateTab({ Name = "Main" })
	local section = tab:CreateSection({ Name = "Deps" })
	local master = section:CreateToggle({ Name = "Master", Flag = "DepMaster", Default = false })
	local dependent = section:CreateSlider({
		Name = "Dependent",
		Flag = "DepSlider",
		Min = 0,
		Max = 10,
		Default = 5,
		DependsOn = { Flag = "DepMaster", Value = true },
	})
	NevaTest:equals(dependent.DependenciesMet, false, "the dependent starts hidden")
	master:SetValue(true)
	NevaTest:equals(dependent.DependenciesMet, true, "turning the master on reveals the dependent")
	master:SetValue(false)
	NevaTest:equals(dependent.DependenciesMet, false, "turning the master off hides it again")
	window:Destroy()
end)

NevaTest:test("Style Studio builds previews and exports a style", function()
	local window = newWindow()
	local tab = window:CreateTab({ Name = "Main" })
	local section = tab:CreateSection({ Name = "Studio" })
	local live = section:CreateSlider({ Name = "Live", Flag = "StudioTarget", Min = 0, Max = 100, Default = 25 })

	local studio = window:OpenStudio({ Component = "Slider" })
	NevaTest:assert(studio, "the Studio opened")
	NevaTest:equals(studio.ComponentType, "Slider", "the Studio selected the requested type")
	NevaTest:assert(studio.Previews[1] ~= nil, "slot 1 has a live preview")
	NevaTest:assert(studio.Previews[2] ~= nil, "slot 2 has a live preview")
	NevaTest:assert(studio.Previews[1] ~= studio.Previews[2], "the two slots are separate components")
	report("preview style 1", studio.Previews[1]:GetStyle())
	report("preview style 2", studio.Previews[2]:GetStyle())
	NevaTest:equals(studio.Previews[1]:GetValue(), 45, "the preview has a working value")

	studio:SetTarget(live)
	local applied, error = studio:ApplyToTarget()
	NevaTest:assert(applied, "the Studio applied its style to a live component: " .. tostring(error))
	NevaTest:equals(live:GetValue(), 25, "applying a style preserved the live value")

	local exported = studio:ExportStyle(1)
	NevaTest:assert(type(exported) == "string" and #exported > 0, "the Studio exported Luau text")
	NevaTest:contains(exported, "Component", "the export mentions the component type")
	report("export bytes", #exported)

	local presetId = studio:SavePreset("Smoke Preset")
	NevaTest:assert(presetId ~= nil, "the Studio saved a preset: " .. tostring(presetId))
	report("preset id", presetId)

	studio:Destroy()
	NevaTest:equals(studio.Destroyed, true, "the Studio closed cleanly")
	window:Destroy()
end)

NevaTest:test("configuration saves, lists and loads", function()
	local window = newWindow({ SaveConfigs = true, ConfigFolder = "NEVAHEXUITest" })
	local tab = window:CreateTab({ Name = "Main" })
	local section = tab:CreateSection({ Name = "Config" })
	local toggle = section:CreateToggle({ Name = "Persisted", Flag = "PersistToggle", Default = false })
	toggle:SetValue(true)

	local saved, saveError = window:SaveConfig("smoke")
	report("save result", tostring(saved) .. " " .. tostring(saveError))
	local listed = window:ListConfigs()
	report("configs listed", type(listed) == "table" and #listed or 0)

	toggle:SetValue(false)
	if saved then
		local loaded, loadError = window:LoadConfig("smoke")
		report("load result", tostring(loaded) .. " " .. tostring(loadError))
		if loaded then
			NevaTest:equals(toggle:GetValue(), true, "the saved value was restored")
		end
	end
	local exported = window:ExportConfig()
	NevaTest:assert(type(exported) == "string" and #exported > 0, "the configuration exports as text")
	window:Destroy()
end)

NevaTest:test("destroying a window cleans up its components", function()
	local window = newWindow()
	local tab = window:CreateTab({ Name = "Main" })
	local section = tab:CreateSection({ Name = "Cleanup" })
	local first
	for index = 1, 5 do
		local component = section:CreateToggle({ Name = "T" .. tostring(index), Flag = "Cleanup" .. tostring(index) })
		first = first or component
	end
	NevaTest:equals(window:GetComponentCount(), 5, "five components exist")
	NevaTest:equals(NEVAHEXUI:GetComponent("Cleanup1"), first, "components are reachable through the store")
	NevaTest:equals(window:Destroy(), true, "the window destroyed")
	NevaTest:equals(window.Destroyed, true, "the window reports itself destroyed")
	NevaTest:equals(first.Destroyed, true, "its components were destroyed with it")
	NevaTest:equals(first:GetStyle(), "toggle.rounded", "the destroyed component kept its last style id")
end)
end
NevaTest:runAll()
