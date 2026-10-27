--!nonstrict
--[[
	NEVAHEXUI - Compatibility/RobloxHost
	Roblox back end. Wraps Instances, TweenService, UserInputService and the
	optional executor APIs behind the same contract the mock back end implements.
	This module is only constructed when a Roblox runtime is detected.
]]

local PressEvents = require("NEVA:Compatibility/PressEvents")

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
