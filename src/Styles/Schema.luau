--[[
	NEVAHEXUI - Styles/Schema
	Property schemas describe what a style can be configured with. The schema is
	the single source of truth for: defaults, validation, the Style Studio
	inspector, generated documentation and Luau export.
]]

local Util = require("NEVA:Core/Util")
local Color = require("NEVA:Utilities/Color")

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
