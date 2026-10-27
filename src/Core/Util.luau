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
