--[[
	NEVAHEXUI - Styles/Defs/Pickers
	Colour and keybind components.

	Design note: every interaction in this file is click based (discrete grid
	cells, cycling key lists). Slider-style free dragging needs pointer position
	reporting, which is provided by the host back ends and used by the Slider
	styles instead. Keeping pickers click based means they behave identically on
	a touch device, in Studio and under the headless test host.
]]

local Registry = require("NEVA:Styles/Registry")
local Surface = require("NEVA:Styles/Surface")
local Helpers = require("NEVA:Styles/Helpers")
local Color = require("NEVA:Utilities/Color")

Registry.registerComponent({
	Name = "ColorPicker", RegistryName = "ColorPickers", Category = "Pickers",
	Description = "Colour selection with a swatch grid, hex field and alpha.",
	Defaults = { RowHeight = 30, SwatchSize = 18, Columns = 12, ShowHex = true, ShowAlpha = true, Animation = "smooth" },
	Properties = {
		{ Key = "RowHeight", Type = "number", Default = 30, Min = 18, Max = 120, Group = "Geometry" },
		{ Key = "SwatchSize", Type = "number", Default = 18, Min = 8, Max = 48, Group = "Geometry" },
		{ Key = "Spacing", Type = "number", Default = 3, Min = 0, Max = 16, Group = "Geometry" },
		{ Key = "Columns", Type = "number", Default = 12, Min = 2, Max = 24, Group = "Geometry" },
		{ Key = "CornerRadius", Type = "number", Min = 0, Max = 24, Group = "Geometry" },
		{ Key = "TextColor", Type = "color", Group = "Typography" },
		{ Key = "StrokeColor", Type = "color", Group = "Appearance" },
		{ Key = "ShowHex", Type = "boolean", Default = true, Group = "Behaviour" },
		{ Key = "ShowAlpha", Type = "boolean", Default = true, Group = "Behaviour" },
		{ Key = "Animation", Type = "animation", Default = "smooth", Group = "Animation" },
	},
})

Registry.registerComponent({
	Name = "ColorPalette", RegistryName = "ColorPalettes", Category = "Pickers",
	Description = "Named colour chips for quick theme and accent selection.",
	Defaults = { RowHeight = 26, ChipSize = 18, Spacing = 4, ShowLabels = false },
	Properties = {
		{ Key = "RowHeight", Type = "number", Default = 26, Min = 14, Max = 80, Group = "Geometry" },
		{ Key = "ChipSize", Type = "number", Default = 18, Min = 8, Max = 48, Group = "Geometry" },
		{ Key = "Spacing", Type = "number", Default = 4, Min = 0, Max = 16, Group = "Geometry" },
		{ Key = "CornerRadius", Type = "number", Min = 0, Max = 24, Group = "Geometry" },
		{ Key = "ShowLabels", Type = "boolean", Default = false, Group = "Behaviour" },
	},
})

-- The Keybind *component* is declared by Styles/Defs/TextInputs (keybind.classic
-- and keybind.pill live there). This file only contributes two more renderers for
-- the same component type, so the descriptor is registered once, guarded by an
-- existence check that keeps module load order irrelevant.
local function componentKnown(name)
	for _, entry in ipairs(Registry.listComponents() or {}) do
		local entryName = type(entry) == "table" and (entry.Name or entry.Component) or entry
		if entryName == name then
			return true
		end
	end
	return false
end

local keybindDescriptor = {
	Name = "Keybind", RegistryName = "Keybinds", Category = "Pickers",
	Description = "Key assignment control with conflict reporting.",
	Defaults = { RowHeight = 28, ChipWidth = 92, ShowToggle = true, Cyclable = true, Animation = "smooth" },
	Properties = {
		{ Key = "RowHeight", Type = "number", Default = 28, Min = 18, Max = 80, Group = "Geometry" },
		{ Key = "ChipWidth", Type = "number", Default = 92, Min = 40, Max = 240, Group = "Geometry" },
		{ Key = "CornerRadius", Type = "number", Min = 0, Max = 24, Group = "Geometry" },
		{ Key = "TextColor", Type = "color", Group = "Typography" },
		{ Key = "ChipColor", Type = "color", Group = "Appearance" },
		{ Key = "ConflictColor", Type = "color", Group = "States" },
		{ Key = "ShowToggle", Type = "boolean", Default = true, Group = "Behaviour" },
		{ Key = "Cyclable", Type = "boolean", Default = true, Group = "Behaviour" },
		{ Key = "Animation", Type = "animation", Default = "smooth", Group = "Animation" },
	},
}

if not componentKnown("Keybind") then
	Registry.registerComponent(keybindDescriptor)
end

-- Shared helpers ------------------------------------------------------------

local function hexText(colour)
	if type(colour) ~= "table" then
		return "--------"
	end
	local ok, value = pcall(function()
		return Color.normalize(colour):ToHex()
	end)
	if not ok then
		return "--------"
	end
	return value
end

local function paletteColours(state)
	local colours = {}
	if type(state.Palette) == "table" and #state.Palette > 0 then
		for index, entry in ipairs(state.Palette) do
			colours[index] = entry
		end
		return colours
	end
	local steps = { 0, 0.12, 0.25, 0.4, 0.55, 0.7, 0.85, 1 }
	local hues = { 0, 0.06, 0.11, 0.17, 0.25, 0.33, 0.42, 0.5, 0.58, 0.66, 0.75, 0.83, 0.92 }
	for _, hue in ipairs(hues) do
		for _, value in ipairs(steps) do
			local saturation = value > 0.85 and 1 or 0.85
			table.insert(colours, Color.fromHSV(hue, saturation, math.max(0.12, value)))
		end
	end
	for value = 0, 1, 0.125 do
		table.insert(colours, Color.fromRGB(value * 255, value * 255, value * 255))
	end
	return colours
end

-- ColorPicker styles --------------------------------------------------------

local function pickerGridRender(options)
	return function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local swatch = config.SwatchSize or 18
		local spacing = config.Spacing or 3
		local columns = math.max(2, config.Columns or 12)
		local colours = paletteColours(ctx.State)
		local rows = math.ceil(#colours / columns)
		local panelWidth = columns * (swatch + spacing) + 48
		local slot = Surface.slot(ctx, {
			Height = config.RowHeight or 30,
			ControlWidth = panelWidth,
		})
		local parent = slot.ControlArea or slot.Root
		local preview = Surface.panel(ctx, parent, {
			Name = "Preview",
			Button = true,
			Background = ctx.State.Value,
			Token = "Accent",
			Transparency = 0,
			CornerRadius = config.CornerRadius or (ctx.Tokens.CornerRadius or 6),
		})
		preview.Size = host.udim2(0, 30, 0, 30)
		preview.Position = host.udim2(1, -panelWidth + 18, 0.5, -15)
		if options.Inline then
			preview.Size = host.udim2(0, 26, 0, 26)
		end
		local popup = Surface.panel(ctx, parent, {
			Name = "Popup",
			Background = "Surface",
			Token = "Surface",
			Transparency = 0,
			CornerRadius = config.CornerRadius or 8,
			Stroke = config.StrokeColor or ctx.Tokens.Outline,
			StrokeThickness = 1,
			Visible = false,
		})
		popup.Size = host.udim2(0, columns * (swatch + spacing) + spacing, 0, rows * (swatch + spacing) + spacing)
		popup.Position = host.udim2(1, 0, 0, 34)
		popup.ZIndex = 40
		local cells = {}
		for index, colour in ipairs(colours) do
			local column = (index - 1) % columns
			local row = math.floor((index - 1) / columns)
			local cell = Surface.hit(ctx, popup, {
				Name = "Cell" .. tostring(index),
				BackgroundColor3 = colour,
				BackgroundTransparency = 0,
				BorderSizePixel = 0,
				Size = host.udim2(0, swatch, 0, swatch),
				Position = host.udim2(0, spacing + column * (swatch + spacing), 0, spacing + row * (swatch + spacing)),
			})
			Helpers.corner(host, cell, math.max(2, (config.CornerRadius or 6) / 3))
			cells[index] = { Instance = cell, Colour = colour }
		end
		local hexLabel
		if config.ShowHex ~= false then
			hexLabel = Surface.text(ctx, parent, {
				Name = "Hex",
				Size = host.udim2(0, 74, 0, 24),
				Position = host.udim2(1, -panelWidth + 54, 0.5, -12),
				Text = hexText(ctx.State.Value),
				TextColor3 = Surface.color(ctx, config.TextColor, "Text"),
				TextSize = 12,
				TextXAlignment = host.enumItem("TextXAlignment", "Left"),
			})
		end
		local alpha
		if config.ShowAlpha ~= false then
			alpha = Surface.text(ctx, parent, {
				Name = "Alpha",
				Size = host.udim2(0, 34, 0, 24),
				Position = host.udim2(1, -26, 0.5, -12),
				Text = "A1.00",
				TextColor3 = ctx.Tokens.TextMuted,
				TextSize = 11,
				TextXAlignment = host.enumItem("TextXAlignment", "Right"),
			})
		end
		local view = {
			Root = slot.Root,
			Input = preview,
			Preview = preview,
			Popup = popup,
			Cells = cells,
			Hex = hexLabel,
			Alpha = alpha,
			Open = false,
		}
		view.Apply = function(self, state)
			self.Preview.BackgroundColor3 = type(state.Value) == "table" and state.Value or ctx.Tokens.Accent
			self.Preview.BackgroundTransparency = 0
			if self.Hex then
				self.Hex.Text = hexText(state.Value)
			end
			if self.Alpha then
				local colour = state.Value
				local value = type(colour) == "table" and (colour.A or colour[4]) or nil
				self.Alpha.Text = ("A%.2f"):format(tonumber(value) or 1)
			end
			self.Popup.Visible = self.Open == true and state.Visible ~= false
			for _, cell in ipairs(self.Cells) do
				cell.Instance.BackgroundTransparency = 0
			end
		end
		return view
	end
end

local styles = {}

styles[#styles + 1] = {
	Id = "colorpicker.popup", Name = "Popup swatches", Component = "ColorPicker", Category = "Pickers",
	Description = "Swatch button that opens a grid of hues, tints and greys.",
	Tags = { "default" },
	Render = pickerGridRender({ Inline = false }),
}

styles[#styles + 1] = {
	Id = "colorpicker.inline", Name = "Inline swatches", Component = "ColorPicker", Category = "Pickers",
	Description = "Always-visible swatch grid for embedding directly in a row.",
	Tags = { "inline" },
	Render = pickerGridRender({ Inline = true }),
}

styles[#styles + 1] = {
	Id = "colorpalette.chips", Name = "Chips", Component = "ColorPalette", Category = "Pickers",
	Description = "Row of named or unlabelled colour chips with a selected outline.",
	Tags = { "default" },
	Render = function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local chip = config.ChipSize or 18
		local spacing = config.Spacing or 4
		local colours = paletteColours(ctx.State)
		local slot = Surface.slot(ctx, { Height = config.RowHeight or 26, ControlWidth = #colours * (chip + spacing) })
		local parent = slot.ControlArea or slot.Root
		local chips = {}
		for index, colour in ipairs(colours) do
			local instance = Surface.hit(ctx, parent, {
				Name = "Chip" .. tostring(index),
				BackgroundColor3 = colour,
				BackgroundTransparency = 0,
				BorderSizePixel = 0,
				Size = host.udim2(0, chip, 0, chip),
				Position = host.udim2(0, (index - 1) * (chip + spacing), 0.5, -chip / 2),
			})
			Helpers.corner(host, instance, config.CornerRadius or 4)
			chips[index] = { Instance = instance, Colour = colour }
		end
		local view = { Root = slot.Root, Chips = chips, Selected = {} }
		view.Apply = function(self, state)
			for _, entry in ipairs(self.Chips) do
				local selected = type(state.Value) == "table" and Color.equals(entry.Colour, state.Value)
				local stroke = entry.Instance.__nevaStroke
					or Helpers.stroke(host, entry.Instance, ctx.Tokens.Outline, 2, 0)
				entry.Instance.__nevaStroke = stroke
				stroke.Color = selected and ctx.Tokens.Text or ctx.Tokens.Outline
				stroke.Transparency = selected and 0 or 0.5
			end
		end
		return view
	end,
}

styles[#styles + 1] = {
	Id = "keybind.chip", Name = "Key chip", Component = "Keybind", Category = "Pickers",
	Description = "Single key chip that cycles through the assignable key list on click.",
	Tags = { "default" },
	Render = function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local width = config.ChipWidth or 92
		local slot = Surface.slot(ctx, { Height = config.RowHeight or 28, ControlWidth = width })
		local parent = slot.ControlArea or slot.Root
		local chip = Surface.hit(ctx, parent, {
			Name = "Chip",
			BackgroundColor3 = Surface.color(ctx, config.ChipColor, "SurfaceAlt"),
			BorderSizePixel = 0,
			Size = host.udim2(0, width, 0, 22),
			Position = host.udim2(1, -width, 0.5, -11),
		})
		Helpers.corner(host, chip, config.CornerRadius or 6)
		local stroke = Helpers.stroke(host, chip, ctx.Tokens.Outline, 1, 0.3)
		local label = Surface.text(ctx, chip, {
			Name = "Key",
			Size = host.udim2(1, 0, 1, 0),
			Text = tostring(ctx.State.Value or "None"),
			TextColor3 = Surface.color(ctx, config.TextColor, "Text"),
			Font = ctx.Tokens.FontBold,
			TextSize = 12,
			TextXAlignment = host.enumItem("TextXAlignment", "Center"),
		})
		local view = {
			Root = slot.Root,
			Input = chip,
			Chip = chip,
			Label = label,
			Stroke = stroke,
			ConflictColour = Surface.color(ctx, config.ConflictColor, "Negative"),
			IdleStroke = ctx.Tokens.Outline,
		}
		view.Apply = function(self, state)
			self.Label.Text = tostring(state.Value or "None")
			local conflict = state.Conflict == true
			self.Stroke.Color = conflict and self.ConflictColour or self.IdleStroke
			self.Stroke.Transparency = conflict and 0 or 0.3
			self.Chip.BackgroundTransparency = state.Enabled == false and 0.45 or 0
			self.Chip.Active = state.Enabled ~= false
		end
		return view
	end,
}

styles[#styles + 1] = {
	Id = "keybind.row", Name = "Key row", Component = "Keybind", Category = "Pickers",
	Description = "Mode toggle plus key chip, listing the bound key and its state.",
	Tags = { "row", "modes" },
	Render = function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local width = config.ChipWidth or 92
		local showToggle = config.ShowToggle ~= false
		local slot = Surface.slot(ctx, {
			Height = config.RowHeight or 28,
			ControlWidth = width + (showToggle and 108 or 4),
		})
		local parent = slot.ControlArea or slot.Root
		local mode
		if showToggle then
			mode = Surface.hit(ctx, parent, {
				Name = "Mode",
				BackgroundColor3 = Surface.color(ctx, config.ChipColor, "SurfaceAlt"),
				Size = host.udim2(0, 100, 0, 22),
				Position = host.udim2(1, -width - 108, 0.5, -11),
			})
			Helpers.corner(host, mode, config.CornerRadius or 6)
			Surface.text(ctx, mode, {
				Name = "ModeLabel",
				Size = host.udim2(1, 0, 1, 0),
				Text = "Toggle",
				TextColor3 = Surface.color(ctx, config.TextColor, "Text"),
				TextSize = 12,
				TextXAlignment = host.enumItem("TextXAlignment", "Center"),
			})
		end
		local chip = Surface.hit(ctx, parent, {
			Name = "Chip",
			BackgroundColor3 = Surface.color(ctx, config.ChipColor, "SurfaceAlt"),
			BorderSizePixel = 0,
			Size = host.udim2(0, width, 0, 22),
			Position = host.udim2(1, -width, 0.5, -11),
		})
		Helpers.corner(host, chip, config.CornerRadius or 6)
		local stroke = Helpers.stroke(host, chip, ctx.Tokens.Outline, 1, 0.3)
		local label = Surface.text(ctx, chip, {
			Name = "Key",
			Size = host.udim2(1, 0, 1, 0),
			Text = tostring(ctx.State.Value or "None"),
			TextColor3 = Surface.color(ctx, config.TextColor, "Text"),
			Font = ctx.Tokens.FontBold,
			TextSize = 12,
			TextXAlignment = host.enumItem("TextXAlignment", "Center"),
		})
		local view = {
			Root = slot.Root,
			Input = chip,
			Chip = chip,
			Label = label,
			Stroke = stroke,
			ModeButton = mode,
			ConflictColour = Surface.color(ctx, config.ConflictColor, "Negative"),
			IdleStroke = ctx.Tokens.Outline,
		}
		view.Apply = function(self, state)
			self.Label.Text = tostring(state.Value or "None")
			local conflict = state.Conflict == true
			self.Stroke.Color = conflict and self.ConflictColour or self.IdleStroke
			self.Stroke.Transparency = conflict and 0 or 0.3
			if self.ModeButton then
				local child = self.ModeButton:FindFirstChild("ModeLabel")
				if child then
					child.Text = tostring(state.Mode or "Toggle")
				end
			end
		end
		return view
	end,
}

local registered, failures = Registry.registerMany(styles, { BuiltIn = true })
for _, failure in ipairs(failures) do
	error(("NEVAHEXUI: picker style %s failed to register: %s"):format(tostring(failure.Id), table.concat(failure.Errors, "; ")))
end

return registered
