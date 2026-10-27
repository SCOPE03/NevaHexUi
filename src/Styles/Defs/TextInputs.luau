--[[
	NEVAHEXUI - Styles/Defs/TextInputs
	Textbox, NumberInput and CopyableInput descriptors plus the Keybind styles.
	Keybinds live here because they share the same inline input geometry.
]]

local Registry = require("NEVA:Styles/Registry")
local Surface = require("NEVA:Styles/Surface")
local Helpers = require("NEVA:Styles/Helpers")

local TEXTBOX_PROPERTIES = {
	{ Key = "RowHeight", Type = "number", Default = 30, Min = 18, Max = 200, Group = "Geometry" },
	{ Key = "Height", Type = "number", Default = 30, Min = 18, Max = 400, Group = "Geometry", Description = "Input height; raise it for multiline inputs." },
	{ Key = "Width", Type = "number", Default = 190, Min = 60, Max = 700, Group = "Geometry" },
	{ Key = "CornerRadius", Type = "number", Min = 0, Max = 32, Group = "Geometry" },
	{ Key = "BackgroundColor", Type = "color", Group = "Appearance" },
	{ Key = "TextColor", Type = "color", Group = "Typography" },
	{ Key = "PlaceholderColor", Type = "color", Group = "Typography" },
	{ Key = "StrokeColor", Type = "color", Group = "Appearance" },
	{ Key = "StrokeThickness", Type = "number", Min = 0, Max = 8, Default = 1, Group = "Appearance" },
	{ Key = "Transparency", Type = "number", Min = 0, Max = 1, Step = 0.01, Group = "Appearance" },
	{ Key = "TextSize", Type = "number", Default = 13, Min = 8, Max = 32, Group = "Typography" },
	{ Key = "Padding", Type = "number", Default = 8, Min = 0, Max = 32, Group = "Geometry" },
	{ Key = "MultiLine", Type = "boolean", Default = false, Group = "Behaviour" },
	{ Key = "Alignment", Type = "enum", Options = { "Left", "Center", "Right" }, Default = "Left", Group = "Typography" },
	{ Key = "Animation", Type = "animation", Default = "quick", Group = "Animation" },
}

Registry.registerComponent({
	Name = "Textbox",
	RegistryName = "Textboxes",
	Category = "Inputs",
	Description = "Text entry. Value is a string; supports validation and multiline input.",
	Defaults = {
		RowHeight = 30,
		Height = 30,
		Width = 190,
		TextSize = 13,
		Padding = 8,
		StrokeThickness = 1,
		Animation = "quick",
	},
	Properties = TEXTBOX_PROPERTIES,
})

Registry.registerComponent({
	Name = "NumberInput",
	RegistryName = "NumberInputs",
	Category = "Inputs",
	Description = "Numeric entry with stepper buttons. Value is a number.",
	Defaults = {
		RowHeight = 30,
		Height = 30,
		Width = 130,
		TextSize = 13,
		Step = 1,
		Precision = 0,
		StrokeThickness = 1,
		Animation = "quick",
	},
	Properties = {
		{ Key = "RowHeight", Type = "number", Default = 30, Min = 18, Max = 200, Group = "Geometry" },
		{ Key = "Height", Type = "number", Default = 30, Min = 18, Max = 200, Group = "Geometry" },
		{ Key = "Width", Type = "number", Default = 130, Min = 60, Max = 400, Group = "Geometry" },
		{ Key = "CornerRadius", Type = "number", Min = 0, Max = 32, Group = "Geometry" },
		{ Key = "BackgroundColor", Type = "color", Group = "Appearance" },
		{ Key = "TextColor", Type = "color", Group = "Typography" },
		{ Key = "ButtonColor", Type = "color", Group = "Appearance" },
		{ Key = "StrokeColor", Type = "color", Group = "Appearance" },
		{ Key = "StrokeThickness", Type = "number", Min = 0, Max = 8, Default = 1, Group = "Appearance" },
		{ Key = "Transparency", Type = "number", Min = 0, Max = 1, Step = 0.01, Group = "Appearance" },
		{ Key = "TextSize", Type = "number", Default = 13, Min = 8, Max = 32, Group = "Typography" },
		{ Key = "Suffix", Type = "string", Default = "", Group = "Behaviour" },
		{ Key = "Step", Type = "number", Default = 1, Min = 0, Group = "Behaviour" },
		{ Key = "Precision", Type = "number", Default = 0, Min = 0, Max = 4, Group = "Behaviour" },
		{ Key = "Animation", Type = "animation", Default = "quick", Group = "Animation" },
	},
})

Registry.registerComponent({
	Name = "CopyableInput",
	RegistryName = "CopyableInputs",
	Category = "Inputs",
	Description = "Read-only text with a copy button. Value is a string.",
	Defaults = {
		RowHeight = 30,
		Height = 30,
		Width = 200,
		ButtonWidth = 44,
		TextSize = 13,
		CopyLabel = "Copy",
		CopiedLabel = "Copied",
		StrokeThickness = 1,
		Animation = "quick",
	},
	Properties = {
		{ Key = "RowHeight", Type = "number", Default = 30, Min = 18, Max = 200, Group = "Geometry" },
		{ Key = "Height", Type = "number", Default = 30, Min = 18, Max = 200, Group = "Geometry" },
		{ Key = "Width", Type = "number", Default = 200, Min = 80, Max = 700, Group = "Geometry" },
		{ Key = "ButtonWidth", Type = "number", Default = 44, Min = 24, Max = 200, Group = "Geometry" },
		{ Key = "CornerRadius", Type = "number", Min = 0, Max = 32, Group = "Geometry" },
		{ Key = "BackgroundColor", Type = "color", Group = "Appearance" },
		{ Key = "TextColor", Type = "color", Group = "Typography" },
		{ Key = "ButtonColor", Type = "color", Group = "Appearance" },
		{ Key = "ButtonTextColor", Type = "color", Group = "Typography" },
		{ Key = "StrokeColor", Type = "color", Group = "Appearance" },
		{ Key = "StrokeThickness", Type = "number", Min = 0, Max = 8, Default = 1, Group = "Appearance" },
		{ Key = "Transparency", Type = "number", Min = 0, Max = 1, Step = 0.01, Group = "Appearance" },
		{ Key = "TextSize", Type = "number", Default = 13, Min = 8, Max = 32, Group = "Typography" },
		{ Key = "CopyLabel", Type = "string", Default = "Copy", Group = "Behaviour" },
		{ Key = "CopiedLabel", Type = "string", Default = "Copied", Group = "Behaviour" },
		{ Key = "Animation", Type = "animation", Default = "quick", Group = "Animation" },
	},
})

Registry.registerComponent({
	Name = "Keybind",
	RegistryName = "Keybinds",
	Category = "Inputs",
	Description = "Keyboard binding picker with conflict detection. Value is a key name or false.",
	Defaults = {
		RowHeight = 28,
		KeyWidth = 70,
		KeyHeight = 24,
		Mode = "Hold",
		Animation = "quick",
	},
	Properties = {
		{ Key = "RowHeight", Type = "number", Default = 28, Min = 18, Max = 120, Group = "Geometry" },
		{ Key = "KeyWidth", Type = "number", Default = 70, Min = 32, Max = 240, Group = "Geometry" },
		{ Key = "KeyHeight", Type = "number", Default = 24, Min = 16, Max = 80, Group = "Geometry" },
		{ Key = "CornerRadius", Type = "number", Min = 0, Max = 32, Group = "Geometry" },
		{ Key = "BackgroundColor", Type = "color", Group = "Appearance" },
		{ Key = "TextColor", Type = "color", Group = "Typography" },
		{ Key = "UnboundText", Type = "string", Default = "None", Group = "Behaviour" },
		{ Key = "ListeningText", Type = "string", Default = "...", Group = "Behaviour" },
		{ Key = "StrokeColor", Type = "color", Group = "Appearance" },
		{ Key = "StrokeThickness", Type = "number", Min = 0, Max = 8, Default = 1, Group = "Appearance" },
		{ Key = "Animation", Type = "animation", Default = "quick", Group = "Animation" },
	},
})

local function textboxRender(options)
	return function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local width = config.Width or 190
		local height = config.Height or 30
		local slot = Surface.slot(ctx, { Height = math.max(config.RowHeight or 30, height), ControlWidth = width })
		local parent = slot.ControlArea or slot.Root
		local panel = Surface.panel(ctx, parent, {
			Name = "Body",
			Background = config.BackgroundColor,
			Token = options.token,
			Transparency = Surface.transparency(ctx, config.Transparency, "SurfaceTransparency", options.transparency),
			CornerRadius = config.CornerRadius or ctx.Tokens.CornerRadius,
			Stroke = config.StrokeColor,
			StrokeThickness = config.StrokeThickness or 1,
		})
		panel.Size = host.udim2(0, width, 0, height)
		panel.Position = host.udim2(1, -width, 0.5, -height / 2)
		local padding = config.Padding or 8
		local input = host.new("TextBox", {
			Name = "Input",
			BackgroundTransparency = 1,
			Size = host.udim2(1, -padding * 2, options.multiline and 1 or 0, options.multiline and -padding * 2 or height),
			Position = host.udim2(0, padding, options.multiline and 0 or 0.5, options.multiline and padding or -height / 2),
			Text = "",
			PlaceholderText = options.placeholder or "",
			PlaceholderColor3 = Surface.color(ctx, config.PlaceholderColor, "TextMuted"),
			Font = ctx.Tokens.Font,
			TextSize = config.TextSize or 13,
			TextColor3 = Surface.color(ctx, config.TextColor, "Text"),
			TextXAlignment = host.enumItem("TextXAlignment", config.Alignment or "Left"),
			TextYAlignment = host.enumItem("TextYAlignment", options.multiline and "Top" or "Center"),
			MultiLine = options.multiline == true,
			ClearTextOnFocus = false,
			TextEditable = options.readOnly ~= true,
			TextWrap = options.multiline == true,
		}, panel)
		local view = {
			Root = slot.Root,
			Input = input,
			Body = panel,
			BaseStroke = Surface.color(ctx, config.StrokeColor, "Outline"),
		}
		view.Apply = function(self, state, renderCtx)
			if not state.Enabled then
				self.Body.BackgroundTransparency = math.min(1, (self.Body.BackgroundTransparency or 0) + 0.25)
				self.Input.TextColor3 = Surface.disabledText(renderCtx, Surface.color(renderCtx, renderCtx.Configuration.TextColor, "Text"))
			else
				self.Input.TextEditable = true
			end
			if state.Focused then
				self.Body.BackgroundColor3 = Surface.color(renderCtx, renderCtx.Configuration.BackgroundColor, "Surface")
			end
		end
		view.SetName = function(self, name)
			if self.Input and self.Input.PlaceholderText == "" then
				self.Input.PlaceholderText = name
			end
		end
		return view
	end
end

local styles = {}

styles[#styles + 1] = {
	Id = "textbox.outline",
	Name = "Outline textbox",
	Component = "Textbox",
	Category = "Inputs",
	Description = "Transparent input inside a hairline outline box.",
	Tags = { "default", "outline" },
	Render = textboxRender({ token = "Surface", transparency = 1, placeholder = "" }),
}

styles[#styles + 1] = {
	Id = "textbox.filled",
	Name = "Filled textbox",
	Component = "Textbox",
	Category = "Inputs",
	Description = "Filled surface input with a soft rounded background.",
	Tags = { "filled" },
	Render = textboxRender({ token = "SurfaceAlt", transparency = 0 }),
}

styles[#styles + 1] = {
	Id = "textbox.multiline",
	Name = "Multiline textbox",
	Component = "Textbox",
	Category = "Inputs",
	Description = "Tall wrapped input for notes and multiline text.",
	Render = textboxRender({ token = "SurfaceAlt", transparency = 0, multiline = true }),
}

styles[#styles + 1] = {
	Id = "copyableinput.inline",
	Name = "Inline copy field",
	Component = "CopyableInput",
	Category = "Inputs",
	Description = "Read-only value with an inline copy button that confirms on click.",
	Render = function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local width = config.Width or 200
		local height = config.Height or 30
		local buttonWidth = config.ButtonWidth or 44
		local slot = Surface.slot(ctx, { Height = math.max(config.RowHeight or 30, height), ControlWidth = width })
		local parent = slot.ControlArea or slot.Root
		local panel = Surface.panel(ctx, parent, {
			Name = "Body",
			Background = config.BackgroundColor,
			Token = "SurfaceAlt",
			Transparency = Surface.transparency(ctx, config.Transparency, "SurfaceTransparency", 0),
			CornerRadius = config.CornerRadius or ctx.Tokens.CornerRadius,
			Stroke = config.StrokeColor,
			StrokeThickness = config.StrokeThickness or 1,
		})
		panel.Size = host.udim2(0, width, 0, height)
		panel.Position = host.udim2(1, -width, 0.5, -height / 2)
		local value = Surface.text(ctx, panel, {
			Name = "Value",
			Size = host.udim2(1, -(buttonWidth + 16), 1, 0),
			Position = host.udim2(0, 8, 0, 0),
			Text = "",
			TextColor3 = Surface.color(ctx, config.TextColor, "Text"),
			TextSize = config.TextSize or 13,
			TextTruncate = host.enumItem("TextTruncate", "AtEnd"),
		})
		local button = Surface.panel(ctx, panel, {
			Name = "Copy",
			Button = true,
			Background = config.ButtonColor,
			Token = "Accent",
			Transparency = 0,
			CornerRadius = math.max(0, (config.CornerRadius or ctx.Tokens.CornerRadius or 8) - 2),
		})
		button.Size = host.udim2(0, buttonWidth - 6, 1, -6)
		button.Position = host.udim2(1, -buttonWidth + 3, 0, 3)
		local buttonLabel = Surface.text(ctx, button, {
			Name = "CopyLabel",
			Size = host.udim2(1, 0, 1, 0),
			Text = config.CopyLabel or "Copy",
			TextColor3 = Surface.color(ctx, config.ButtonTextColor, "AccentText"),
			Font = ctx.Tokens.FontBold,
			TextSize = math.max(9, (config.TextSize or 13) - 1),
			TextXAlignment = host.enumItem("TextXAlignment", "Center"),
		})
		local view = {
			Root = slot.Root,
			Input = button,
			Body = panel,
			Value = value,
			Copy = button,
			CopyLabel = buttonLabel,
			CopyText = config.CopyLabel or "Copy",
			CopiedText = config.CopiedLabel or "Copied",
		}
		view.Apply = function(self, state, renderCtx)
			self.Value.Text = tostring(state.Value or "")
			if not state.Enabled then
				self.CopyLabel.TextColor3 = Surface.disabledText(renderCtx, renderCtx.Tokens.AccentText)
			else
				self.CopyLabel.TextColor3 = renderCtx.Tokens.AccentText
			end
		end
		return view
	end,
}

styles[#styles + 1] = {
	Id = "numberinput.stepper",
	Name = "Stepper input",
	Component = "NumberInput",
	Category = "Inputs",
	Description = "Numeric field flanked by decrement and increment buttons.",
	Render = function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local width = config.Width or 130
		local height = config.Height or 30
		local slot = Surface.slot(ctx, { Height = math.max(config.RowHeight or 30, height), ControlWidth = width })
		local parent = slot.ControlArea or slot.Root
		local panel = Surface.panel(ctx, parent, {
			Name = "Body",
			Background = config.BackgroundColor,
			Token = "SurfaceAlt",
			Transparency = Surface.transparency(ctx, config.Transparency, "SurfaceTransparency", 0),
			CornerRadius = config.CornerRadius or ctx.Tokens.CornerRadius,
			Stroke = config.StrokeColor,
			StrokeThickness = config.StrokeThickness or 1,
		})
		panel.Size = host.udim2(0, width, 0, height)
		panel.Position = host.udim2(1, -width, 0.5, -height / 2)
		local buttonColour = Surface.color(ctx, config.ButtonColor, "Surface")
		local function stepper(name, label, xPosition)
			local button = Surface.panel(ctx, panel, {
				Name = name,
				Background = config.ButtonColor,
				Token = "Surface",
				Transparency = 0,
				CornerRadius = math.max(0, (config.CornerRadius or 6) - 2),
			})
			button.Size = host.udim2(0, height - 6, 0, height - 6)
			button.Position = host.udim2(xPosition, 3, 0.5, -(height - 6) / 2)
			local text = Surface.text(ctx, button, {
				Name = name .. "Label",
				Size = host.udim2(1, 0, 1, 0),
				Text = label,
				TextColor3 = Surface.color(ctx, config.TextColor, "Text"),
				Font = ctx.Tokens.FontBold,
				TextSize = config.TextSize or 13,
				TextXAlignment = host.enumItem("TextXAlignment", "Center"),
			})
			return button, text, buttonColour
		end
		local minus = stepper("Minus", "-", 0)
		local plus = stepper("Plus", "+", 1)
		plus.Position = host.udim2(1, -(height - 6) - 3, 0.5, -(height - 6) / 2)
		local input = host.new("TextBox", {
			Name = "Input",
			BackgroundTransparency = 1,
			Size = host.udim2(1, -(height + 4) * 2, 1, 0),
			Position = host.udim2(0.5, 0, 0.5, 0),
			AnchorPoint = host.vector2(0.5, 0.5),
			Text = "",
			Font = ctx.Tokens.Font,
			TextSize = config.TextSize or 13,
			TextColor3 = Surface.color(ctx, config.TextColor, "Text"),
			TextXAlignment = host.enumItem("TextXAlignment", "Center"),
			ClearTextOnFocus = false,
		}, panel)
		local view = {
			Root = slot.Root,
			Input = input,
			Body = panel,
			Controls = { Minus = minus, Plus = plus },
		}
		view.Apply = function(self, state, renderCtx)
			local value = state.Value
			self.Input.Text = tostring(value) .. ((renderCtx.Configuration.Suffix and renderCtx.Configuration.Suffix ~= "") and renderCtx.Configuration.Suffix or "")
		end
		return view
	end,
}

local function keybindRender(options)
	return function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local keyWidth = config.KeyWidth or 70
		local keyHeight = config.KeyHeight or 24
		local slot = Surface.slot(ctx, { Height = config.RowHeight or 28, ControlWidth = keyWidth })
		local parent = slot.ControlArea or slot.Root
		local box = Surface.panel(ctx, parent, {
			Name = "Key",
			Background = config.BackgroundColor,
			Token = options.token,
			Transparency = options.transparency,
			CornerRadius = options.pill and keyHeight / 2 or (config.CornerRadius or ctx.Tokens.CornerRadius or 6),
			Stroke = config.StrokeColor,
			StrokeThickness = config.StrokeThickness or 1,
		})
		box.Size = host.udim2(0, keyWidth, 0, keyHeight)
		box.Position = host.udim2(1, -keyWidth, 0.5, -keyHeight / 2)
		local label = Surface.text(ctx, box, {
			Name = "KeyLabel",
			Size = host.udim2(1, 0, 1, 0),
			Text = config.UnboundText or "None",
			TextColor3 = Surface.color(ctx, config.TextColor, "Text"),
			Font = ctx.Tokens.FontBold,
			TextSize = math.max(10, keyHeight - 11),
			TextXAlignment = host.enumItem("TextXAlignment", "Center"),
		})
		local input = Surface.hit(ctx, box)
		local view = {
			Root = slot.Root,
			Input = input,
			Body = box,
			KeyLabel = label,
			Base = Surface.color(ctx, config.BackgroundColor, options.token),
			Unbound = config.UnboundText or "None",
			Listening = config.ListeningText or "...",
		}
		view.Disabled = Surface.disabledColour(ctx, view.Base)
		view.Apply = function(self, state, renderCtx)
			if not state.Enabled then
				self.Body.BackgroundColor3 = self.Disabled
				self.KeyLabel.TextColor3 = Surface.disabledText(renderCtx, Surface.color(renderCtx, renderCtx.Configuration.TextColor, "Text"))
			elseif state.Listening then
				self.Body.BackgroundColor3 = renderCtx.Tokens.Accent
				self.KeyLabel.TextColor3 = renderCtx.Tokens.AccentText
				self.KeyLabel.Text = self.Listening
			else
				self.Body.BackgroundColor3 = self.Base
				self.KeyLabel.TextColor3 = Surface.color(renderCtx, renderCtx.Configuration.TextColor, "Text")
				self.KeyLabel.Text = state.Value == false and self.Unbound or tostring(state.Value)
			end
		end
		return view
	end
end

styles[#styles + 1] = {
	Id = "keybind.classic",
	Name = "Classic keybind",
	Component = "Keybind",
	Category = "Inputs",
	Description = "Rounded key box that highlights while listening for input.",
	Tags = { "default" },
	Render = keybindRender({ token = "SurfaceAlt", transparency = 0 }),
}

styles[#styles + 1] = {
	Id = "keybind.pill",
	Name = "Pill keybind",
	Component = "Keybind",
	Category = "Inputs",
	Description = "Borderless pill key label for compact lists.",
	Tags = { "pill", "minimal" },
	Render = keybindRender({ token = "Surface", transparency = 0.4, pill = true }),
}

local registered, failures = Registry.registerMany(styles, { BuiltIn = true })
for _, failure in ipairs(failures) do
	error(("NEVAHEXUI: text input style %s failed to register: %s"):format(tostring(failure.Id), table.concat(failure.Errors, "; ")))
end

return registered
