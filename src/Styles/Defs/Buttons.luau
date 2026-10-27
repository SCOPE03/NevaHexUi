--[[
	NEVAHEXUI - Styles/Defs/Buttons
	Button and IconButton component descriptors plus their style
	implementations. Each style builds its own instance tree; they are not
	parameter variations of one renderer.
]]

local Registry = require("NEVA:Styles/Registry")
local Surface = require("NEVA:Styles/Surface")
local Helpers = require("NEVA:Styles/Helpers")

local BUTTON_PROPERTIES = {
	{ Key = "RowHeight", Type = "number", Default = 30, Min = 16, Max = 120, Group = "Geometry", Description = "Total row height." },
	{ Key = "TextSize", Type = "number", Default = 13, Min = 8, Max = 32, Group = "Typography" },
	{ Key = "Font", Type = "font", Group = "Typography" },
	{ Key = "TextColor", Type = "color", Group = "Typography" },
	{ Key = "TextAlignment", Type = "enum", Options = { "Left", "Center", "Right" }, Default = "Center", Group = "Typography" },
	{ Key = "BackgroundColor", Type = "color", Group = "Appearance" },
	{ Key = "HoverColor", Type = "color", Group = "States" },
	{ Key = "PressedColor", Type = "color", Group = "States" },
	{ Key = "CornerRadius", Type = "number", Min = 0, Max = 32, Group = "Geometry" },
	{ Key = "Transparency", Type = "number", Min = 0, Max = 1, Step = 0.01, Group = "Appearance" },
	{ Key = "StrokeColor", Type = "color", Group = "Appearance" },
	{ Key = "StrokeThickness", Type = "number", Min = 0, Max = 8, Default = 1, Group = "Appearance" },
	{ Key = "Animation", Type = "animation", Default = "quick", Group = "Animation" },
	{ Key = "AnimationDuration", Type = "number", Min = 0, Max = 2, Group = "Animation" },
	{ Key = "Icon", Type = "string", Group = "Appearance" },
	{ Key = "IconSide", Type = "enum", Options = { "Left", "Right" }, Default = "Left", Group = "Appearance" },
}

local BUTTON_DEFAULTS = {
	RowHeight = 30,
	TextSize = 13,
	TextAlignment = "Center",
	StrokeThickness = 1,
	Transparency = 0,
	Animation = "quick",
	IconSide = "Left",
}

Registry.registerComponent({
	Name = "Button",
	RegistryName = "Buttons",
	Category = "Controls",
	Description = "Momentary action control. Its value is the number of activations.",
	Defaults = BUTTON_DEFAULTS,
	Properties = BUTTON_PROPERTIES,
})

Registry.registerComponent({
	Name = "IconButton",
	RegistryName = "IconButtons",
	Category = "Controls",
	Description = "Compact icon-only action control.",
	Defaults = {
		RowHeight = 28,
		ButtonSize = 28,
		StrokeThickness = 1,
		IconSize = 16,
		Transparency = 0,
		Animation = "quick",
	},
	Properties = {
		{ Key = "RowHeight", Type = "number", Default = 28, Min = 16, Max = 120, Group = "Geometry" },
		{ Key = "ButtonSize", Type = "number", Default = 28, Min = 16, Max = 96, Group = "Geometry" },
		{ Key = "IconSize", Type = "number", Default = 16, Min = 8, Max = 64, Group = "Appearance" },
		{ Key = "Icon", Type = "string", Group = "Appearance" },
		{ Key = "BackgroundColor", Type = "color", Group = "Appearance" },
		{ Key = "IconColor", Type = "color", Group = "Appearance" },
		{ Key = "HoverColor", Type = "color", Group = "States" },
		{ Key = "PressedColor", Type = "color", Group = "States" },
		{ Key = "CornerRadius", Type = "number", Min = 0, Max = 32, Group = "Geometry" },
		{ Key = "Transparency", Type = "number", Min = 0, Max = 1, Step = 0.01, Group = "Appearance" },
		{ Key = "StrokeColor", Type = "color", Group = "Appearance" },
		{ Key = "StrokeThickness", Type = "number", Min = 0, Max = 8, Default = 1, Group = "Appearance" },
		{ Key = "Animation", Type = "animation", Default = "quick", Group = "Animation" },
	},
})

local function cornerOf(ctx, config)
	local radius = config.CornerRadius
	if radius == nil then
		radius = ctx.Tokens.CornerRadius
	end
	if radius == nil then
		radius = 8
	end
	return radius
end

local styles = {}

styles[#styles + 1] = {
	Id = "button.modern",
	Name = "Modern",
	Component = "Button",
	Category = "Controls",
	Description = "Rounded surface button with hover tint and optional stroke.",
	Tags = { "filled", "default" },
	Render = function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local slot = Surface.slot(ctx, { Height = config.RowHeight or 30, Label = false })
		local base = Surface.color(ctx, config.BackgroundColor, "SurfaceAlt")
		local textColour = Surface.color(ctx, config.TextColor, "Text")
		local panel = Surface.panel(ctx, slot.Root, {
			Name = "Body",
			Background = config.BackgroundColor,
			Token = "SurfaceAlt",
			Transparency = Surface.transparency(ctx, config.Transparency, "SurfaceTransparency", 0),
			CornerRadius = cornerOf(ctx, config),
			Stroke = config.StrokeColor,
			StrokeThickness = config.StrokeThickness or 1,
		})
		panel.Size = host.udim2(1, 0, 1, 0)
		local label = Surface.text(ctx, panel, {
			Size = host.udim2(1, -20, 1, 0),
			Position = host.udim2(0, 10, 0, 0),
			Text = ctx.Props.Name or "",
			TextColor3 = textColour,
			Font = ctx.Tokens.FontBold,
			TextSize = config.TextSize or 13,
			TextXAlignment = host.enumItem("TextXAlignment", config.TextAlignment or "Center"),
		})
		local input = Surface.hit(ctx, panel)
		Surface.wirePress(ctx, input)
		local view = {
			Root = slot.Root,
			Input = input,
			Body = panel,
			Label = label,
			Base = base,
			BaseText = textColour,
			Hover = Surface.color(ctx, config.HoverColor, "Surface"),
		}
		view.Disabled = Surface.disabledColour(ctx, base)
		view.Apply = function(self, state, renderCtx)
			local configuration = renderCtx.Configuration
			if not state.Enabled then
				self.Body.BackgroundColor3 = self.Disabled
				self.Label.TextColor3 = Surface.disabledText(renderCtx, self.BaseText)
			elseif renderCtx.Component and renderCtx.Component.Pressed then
				self.Body.BackgroundColor3 = Surface.color(renderCtx, configuration.PressedColor, "Accent")
			elseif state.Hovered then
				self.Body.BackgroundColor3 = self.Hover
				self.Label.TextColor3 = self.BaseText
			else
				self.Body.BackgroundColor3 = self.Base
				self.Label.TextColor3 = self.BaseText
			end
		end
		return view
	end,
}

styles[#styles + 1] = {
	Id = "button.flat",
	Name = "Flat",
	Component = "Button",
	Category = "Controls",
	Description = "Borderless flat button with an accent underline on hover.",
	Tags = { "flat" },
	Render = function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local slot = Surface.slot(ctx, { Height = config.RowHeight or 30, Label = false })
		local panel = host.new("Frame", {
			Name = "Body",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = host.udim2(1, 0, 1, 0),
		}, slot.Root)
		local label = Surface.text(ctx, panel, {
			Size = host.udim2(1, 0, 1, 0),
			Text = ctx.Props.Name or "",
			TextColor3 = Surface.color(ctx, config.TextColor, "Text"),
			Font = ctx.Tokens.Font,
			TextSize = config.TextSize or 13,
			TextXAlignment = host.enumItem("TextXAlignment", config.TextAlignment or "Center"),
		})
		local underline = host.new("Frame", {
			Name = "Underline",
			BackgroundColor3 = ctx.Tokens.Accent,
			BorderSizePixel = 0,
			Size = host.udim2(0, 0, 0, 2),
			Position = host.udim2(0.5, 0, 1, -2),
			AnchorPoint = host.vector2(0.5, 0),
			BackgroundTransparency = 1,
		}, panel)
		local input = Surface.hit(ctx, panel)
		Surface.wirePress(ctx, input)
		local view = {
			Root = slot.Root,
			Input = input,
			Body = panel,
			Label = label,
			Underline = underline,
			BaseText = Surface.color(ctx, config.TextColor, "Text"),
			AccentText = Surface.color(ctx, config.HoverColor, "Accent"),
		}
		view.Apply = function(self, state, renderCtx)
			local width = 0
			if not state.Enabled then
				self.Label.TextColor3 = Surface.disabledText(renderCtx, self.BaseText)
			elseif renderCtx.Component and renderCtx.Component.Pressed then
				width = 1
				self.Label.TextColor3 = self.AccentText
			elseif state.Hovered then
				width = 1
				self.Label.TextColor3 = self.AccentText
			else
				self.Label.TextColor3 = self.BaseText
			end
			Surface.animate(renderCtx, self.Underline, {
				Size = self.Underline.Size and renderCtx.Host.udim2(width, 0, 0, 2) or renderCtx.Host.udim2(width, 0, 0, 2),
				BackgroundTransparency = width > 0 and 0 or 1,
			})
		end
		return view
	end,
}

styles[#styles + 1] = {
	Id = "button.glass",
	Name = "Glass",
	Component = "Button",
	Category = "Controls",
	Description = "Translucent gradient button with a bright rim, designed for overlays.",
	Tags = { "glass", "gradient" },
	Render = function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local slot = Surface.slot(ctx, { Height = config.RowHeight or 30, Label = false })
		local panel = Surface.panel(ctx, slot.Root, {
			Name = "Body",
			Background = config.BackgroundColor,
			Token = "Surface",
			Transparency = Surface.transparency(ctx, config.Transparency, "SurfaceTransparency", 0.35),
			CornerRadius = cornerOf(ctx, config),
			Stroke = config.StrokeColor or ctx.Tokens.Accent,
			StrokeThickness = config.StrokeThickness or 1,
			StrokeTransparency = 0.35,
		})
		panel.Size = host.udim2(1, 0, 1, 0)
		Helpers.gradient(host, panel, ctx.Tokens.Surface, ctx.Tokens.Accent, 90, { 0.15, 0.75 })
		local label = Surface.text(ctx, panel, {
			Size = host.udim2(1, -20, 1, 0),
			Position = host.udim2(0, 10, 0, 0),
			Text = ctx.Props.Name or "",
			TextColor3 = Surface.color(ctx, config.TextColor, "Text"),
			Font = ctx.Tokens.FontBold,
			TextSize = config.TextSize or 13,
			TextXAlignment = host.enumItem("TextXAlignment", config.TextAlignment or "Center"),
		})
		local input = Surface.hit(ctx, panel)
		Surface.wirePress(ctx, input)
		local view = {
			Root = slot.Root,
			Input = input,
			Body = panel,
			Label = label,
			BaseText = Surface.color(ctx, config.TextColor, "Text"),
			Base = Surface.transparency(ctx, config.Transparency, "SurfaceTransparency", 0.35),
		}
		view.Apply = function(self, state, renderCtx)
			if not state.Enabled then
				self.Label.TextColor3 = Surface.disabledText(renderCtx, self.BaseText)
				self.Body.BackgroundTransparency = math.min(1, self.Base + 0.3)
			elseif renderCtx.Component and renderCtx.Component.Pressed then
				self.Body.BackgroundTransparency = math.max(0, self.Base - 0.2)
			elseif state.Hovered then
				self.Body.BackgroundTransparency = math.max(0, self.Base - 0.1)
			else
				self.Body.BackgroundTransparency = self.Base
				self.Label.TextColor3 = self.BaseText
			end
		end
		return view
	end,
}

local function iconButtonRender(options)
	return function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local slot = Surface.slot(ctx, { Height = config.RowHeight or 28, ControlWidth = config.ButtonSize or 28 })
		local size = config.ButtonSize or 28
		local parent = slot.ControlArea or slot.Root
		local button = Surface.panel(ctx, parent, {
			Name = "Body",
			Background = config.BackgroundColor,
			Token = options.token,
			Transparency = Surface.transparency(ctx, config.Transparency, "SurfaceTransparency", options.transparency),
			CornerRadius = options.radius == "round" and size / 2 or (config.CornerRadius or ctx.Tokens.CornerRadius or 8),
			Stroke = config.StrokeColor,
			StrokeThickness = config.StrokeThickness or 1,
		})
		button.Size = host.udim2(0, size, 0, size)
		button.Position = host.udim2(1, -size, 0.5, -size / 2)
		local icon = Surface.text(ctx, button, {
			Name = "Icon",
			Size = host.udim2(1, 0, 1, 0),
			Text = config.Icon or ctx.Props.Icon or "\u{25CF}",
			TextColor3 = Surface.color(ctx, config.IconColor, "Text"),
			Font = ctx.Tokens.FontBold,
			TextSize = config.IconSize or 16,
			TextXAlignment = host.enumItem("TextXAlignment", "Center"),
			TextYAlignment = host.enumItem("TextYAlignment", "Center"),
		})
		local input = Surface.hit(ctx, button)
		Surface.wirePress(ctx, input)
		local view = {
			Root = slot.Root,
			Input = input,
			Body = button,
			Icon = icon,
			Base = Surface.color(ctx, config.BackgroundColor, options.token),
			BaseText = Surface.color(ctx, config.IconColor, "Text"),
			Hover = Surface.color(ctx, config.HoverColor, "SurfaceAlt"),
		}
		view.Disabled = Surface.disabledColour(ctx, view.Base)
		view.Apply = function(self, state, renderCtx)
			local configuration = renderCtx.Configuration
			if not state.Enabled then
				self.Body.BackgroundColor3 = self.Disabled
				self.Icon.TextColor3 = Surface.disabledText(renderCtx, self.BaseText)
			elseif renderCtx.Component and renderCtx.Component.Pressed then
				self.Body.BackgroundColor3 = Surface.color(renderCtx, configuration.PressedColor, "Accent")
			elseif state.Hovered then
				self.Body.BackgroundColor3 = self.Hover
			else
				self.Body.BackgroundColor3 = self.Base
				self.Icon.TextColor3 = self.BaseText
			end
		end
		return view
	end
end



styles[#styles + 1] = {
	Id = "iconbutton.rounded",
	Name = "Rounded icon",
	Component = "IconButton",
	Category = "Controls",
	Description = "Circular icon button with a filled surface.",
	Render = iconButtonRender({ token = "SurfaceAlt", radius = "round", transparency = 0 }),
}

styles[#styles + 1] = {
	Id = "iconbutton.ghost",
	Name = "Ghost icon",
	Component = "IconButton",
	Category = "Controls",
	Description = "Transparent icon button that only gains a surface on hover.",
	Render = iconButtonRender({ token = "Surface", radius = "square", transparency = 1 }),
}

local registered, failures = Registry.registerMany(styles, { BuiltIn = true })
for _, failure in ipairs(failures) do
	error(("NEVAHEXUI: buttons style %s failed to register: %s"):format(tostring(failure.Id), table.concat(failure.Errors, "; ")))
end

return registered
