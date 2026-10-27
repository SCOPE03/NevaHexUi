--[[
	NEVAHEXUI - Themes/Registry
	Theme registration, validation and token resolution. Themes are additive: a
	theme supplies only the tokens it decides to change and the registry merges
	them over the documented defaults.
]]

local Util = require("NEVA:Core/Util")
local Color = require("NEVA:Utilities/Color")
local Tokens = require("NEVA:Themes/Tokens")
local Defs = require("NEVA:Themes/Defs")

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
