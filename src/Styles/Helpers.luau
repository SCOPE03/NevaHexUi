--[[
	NEVAHEXUI - Styles/Helpers
	Shared tree-building helpers used by every style renderer. Keeping instance
	creation here means styles never touch Roblox APIs directly, and it keeps the
	frameworks' style files small and readable.
]]

local Color = require("NEVA:Utilities/Color")

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
