--[[
	NEVAHEXUI - Configuration/Json
	Small, dependency-free JSON encoder/decoder used by the configuration system.
	Configuration is exchanged as JSON precisely so that imports never execute
	untrusted Luau: parsing is structural and cannot call functions.
]]

local Util = require("NEVA:Core/Util")

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
