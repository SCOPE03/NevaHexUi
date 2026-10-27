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
