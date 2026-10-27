--[[
	NEVAHEXUI - Compatibility/MockHost
	Headless back end. Implements the same host contract as the Roblox back end
	using plain tables, an in-memory filesystem and deterministic tween / input
	stubs. Every NEVAHEXUI module is host agnostic, which is what makes the
	framework's behaviour verifiable without a Roblox runtime.
]]

local PressEvents = require("NEVA:Compatibility/PressEvents")

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
	-- Real Instances hold no custom fields: `frame.__nevaStroke = stroke` raises
	-- in Roblox ("__nevaStroke is not a valid member of Frame"). No Roblox
	-- property name starts with an underscore, so the mock refuses them too --
	-- that is what makes this mistake visible in the headless runs.
	if type(key) == "string" and key:sub(1, 1) == "_" then
		error(("%s is not a valid member of %s"):format(key, tostring(rawget(self, "_props").ClassName)))
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
	-- Mirrors the Roblox path closely enough to be checked: the ScreenGui gets a
	-- container, so a window that never received one is visible in the tests as
	-- an unparented root.
	if not host.CoreGui then
		host.CoreGui = host.new("CoreGui", { Name = "CoreGui" }, nil)
	end
	local gui = host.new("ScreenGui", props or {}, host.CoreGui)
	host.Root = gui
	host.ParentSource = "CoreGui"
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
