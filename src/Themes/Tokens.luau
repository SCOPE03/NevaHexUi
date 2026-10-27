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

-- !! These tokens were derived from the visual specifications of the
-- referenced Roblox UI libraries (Fluent, WindUI, Obsidian, LinoriaLib,
-- Kavo UI, Rayfield, and others). Colours, radii, spacing and fonts
-- aim to match the aesthetic of modern executor/loadstring UI libraries.
Tokens.Defaults = {
	Background = "#0d0d0f",
	Surface = "#18181b",
	SurfaceAlt = "#202025",
	Outline = "#3d3d4f",
	Text = "#f4f6f8",
	TextMuted = "#a3a5b1",
	Accent = "#00d4aa",   -- NEVA Cyan accent (distinct from libraries' red)
	AccentText = "#000000",
	Positive = "#39d353",
	Warning = "#fbbf24",
	Negative = "#f87171",
	CornerRadius = 6,      -- pill-shaped corners per Fluent/WindUI spec
	Padding = 8,
	Spacing = 6,
	FontSize = 12,
	StrokeThickness = 1,
	BackgroundTransparency = 0.1,
	SurfaceTransparency = 0.15,
	AccentTransparency = 0,
	AnimationDuration = 0.15,
	Font = "Gotham",       -- system font, matches library conventions
	FontBold = "Gotham Bold",
	Easing = "Cubic",
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
