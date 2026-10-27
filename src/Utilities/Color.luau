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
