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
