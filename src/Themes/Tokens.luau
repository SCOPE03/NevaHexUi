--[[
	NEVAHEXUI - Themes/Tokens
	Design token schema. Theme tokens are the shared vocabulary every style reads
	from; styles never hardcode colours. Documented precedence (see
	docs/themes.md): style defaults < theme tokens < category configuration <
	component configuration.
]]

local Tokens = {}

Tokens.Colors = {
	"Background",
	"Surface",
	"SurfaceAlt",
	"Outline",
	"Text",
	"TextMuted",
	"Accent",
	"AccentText",
	"Positive",
	"Warning",
	"Negative",
}

Tokens.Numbers = {
	"CornerRadius",
	"Padding",
	"Spacing",
	"FontSize",
	"StrokeThickness",
	"BackgroundTransparency",
	"SurfaceTransparency",
	"AccentTransparency",
	"AnimationDuration",
}

Tokens.Strings = {
	"Name",
	"Id",
	"Description",
	"Icon",
}

Tokens.Fonts = {
	"Font",
	"FontBold",
}

Tokens.Enums = {
	Easing = { "Linear", "Sine", "Quad", "Cubic", "Quart", "Quint", "Bounce", "Elastic", "Exponential", "Circular", "Back" },
}

Tokens.Required = {
	"Background",
	"Surface",
	"Text",
	"TextMuted",
	"Accent",
	"AccentText",
	"Outline",
}

Tokens.Defaults = {
	Background = "#101014",
	Surface = "#17171E",
	SurfaceAlt = "#1F1F2A",
	Outline = "#2E2E3C",
	Text = "#F4F4F7",
	TextMuted = "#9C9CAC",
	Accent = "#EF4444",
	AccentText = "#FFFFFF",
	Positive = "#3DDC97",
	Warning = "#F5A524",
	Negative = "#FF5470",
	CornerRadius = 8,
	Padding = 10,
	Spacing = 8,
	FontSize = 13,
	StrokeThickness = 1,
	BackgroundTransparency = 0.06,
	SurfaceTransparency = 0.12,
	AccentTransparency = 0,
	AnimationDuration = 0.2,
	Font = "GothamMedium",
	FontBold = "GothamBold",
	Easing = "Quad",
}

function Tokens.schema()
	local schema = {}
	for _, key in ipairs(Tokens.Colors) do
		table.insert(schema, { Key = key, Type = "color", Required = Tokens.Required[#Tokens.Required] ~= nil and table.find(Tokens.Required, key) ~= nil })
	end
	for _, key in ipairs(Tokens.Numbers) do
		table.insert(schema, { Key = key, Type = "number", Min = 0 })
	end
	for _, key in ipairs(Tokens.Fonts) do
		table.insert(schema, { Key = key, Type = "font" })
	end
	for key, options in pairs(Tokens.Enums) do
		table.insert(schema, { Key = key, Type = "enum", Options = options })
	end
	table.sort(schema, function(a, b)
		return a.Key < b.Key
	end)
	return schema
end

function Tokens.isRequired(key)
	for _, candidate in ipairs(Tokens.Required) do
		if candidate == key then
			return true
		end
	end
	return false
end

return Tokens
