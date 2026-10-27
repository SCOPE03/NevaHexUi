--[[
	NEVAHEXUI - Styles/Defs/Feedback
	Notification and Dialog styles. These components are transient: the window
	creates them through Notify/Dialog, they render through the same style engine
	as every other component, and they destroy themselves when dismissed.
]]

local Registry = require("NEVA:Styles/Registry")
local Surface = require("NEVA:Styles/Surface")
local Helpers = require("NEVA:Styles/Helpers")

Registry.registerComponent({
	Name = "Notification",
	RegistryName = "Notifications",
	Category = "Feedback",
	Description = "Transient message card with an optional dismiss control.",
	Defaults = {
		Height = 48,
		Width = 260,
		TextSize = 13,
		Duration = 4,
		Dismissible = true,
		Animation = "smooth",
	},
	Properties = {
		{ Key = "Height", Type = "number", Default = 48, Min = 28, Max = 200, Group = "Geometry" },
		{ Key = "Width", Type = "number", Default = 260, Min = 120, Max = 520, Group = "Geometry" },
		{ Key = "TextSize", Type = "number", Default = 13, Min = 8, Max = 28, Group = "Typography" },
		{ Key = "CornerRadius", Type = "number", Min = 0, Max = 32, Group = "Geometry" },
		{ Key = "BackgroundColor", Type = "color", Group = "Appearance" },
		{ Key = "TextColor", Type = "color", Group = "Typography" },
		{ Key = "MutedColor", Type = "color", Group = "Typography" },
		{ Key = "AccentColor", Type = "color", Group = "Appearance" },
		{ Key = "StrokeColor", Type = "color", Group = "Appearance" },
		{ Key = "Transparency", Type = "number", Min = 0, Max = 1, Step = 0.01, Group = "Appearance" },
		{ Key = "Duration", Type = "number", Default = 4, Min = 0, Max = 60, Group = "Behaviour" },
		{ Key = "Dismissible", Type = "boolean", Default = true, Group = "Behaviour" },
		{ Key = "Animation", Type = "animation", Default = "smooth", Group = "Animation" },
	},
})

Registry.registerComponent({
	Name = "Dialog",
	RegistryName = "Dialogs",
	Category = "Feedback",
	Description = "Modal dialog with title, body text and action buttons.",
	Defaults = {
		Width = 320,
		ButtonHeight = 28,
		TextSize = 13,
		Dismissible = true,
		Animation = "smooth",
	},
	Properties = {
		{ Key = "Width", Type = "number", Default = 320, Min = 180, Max = 720, Group = "Geometry" },
		{ Key = "ButtonHeight", Type = "number", Default = 28, Min = 18, Max = 80, Group = "Geometry" },
		{ Key = "TextSize", Type = "number", Default = 13, Min = 8, Max = 28, Group = "Typography" },
		{ Key = "CornerRadius", Type = "number", Min = 0, Max = 32, Group = "Geometry" },
		{ Key = "BackgroundColor", Type = "color", Group = "Appearance" },
		{ Key = "TextColor", Type = "color", Group = "Typography" },
		{ Key = "MutedColor", Type = "color", Group = "Typography" },
		{ Key = "AccentColor", Type = "color", Group = "States" },
		{ Key = "ConfirmColor", Type = "color", Group = "States" },
		{ Key = "CancelColor", Type = "color", Group = "States" },
		{ Key = "StrokeColor", Type = "color", Group = "Appearance" },
		{ Key = "DimBackground", Type = "boolean", Default = true, Group = "Appearance" },
		{ Key = "Animation", Type = "animation", Default = "smooth", Group = "Animation" },
	},
})

local function notificationRender(options)
	return function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local body = ctx.State.Body or {}
		local width = config.Width or 260
		local height = config.Height or 48
		local radius = config.CornerRadius
		if radius == nil then
			radius = ctx.Tokens.CornerRadius
		end
		local root = host.new("Frame", {
			Name = "Notification",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = host.udim2(0, width, 0, height),
		}, nil)
		local card = Surface.panel(ctx, root, {
			Name = "Card",
			Background = config.BackgroundColor,
			Token = options.token,
			Transparency = Surface.transparency(ctx, config.Transparency, "SurfaceTransparency", options.transparency),
			CornerRadius = radius,
			Stroke = config.StrokeColor,
			StrokeThickness = 1,
		})
		card.Size = host.udim2(1, 0, 1, 0)
		local stripe = host.new("Frame", {
			Name = "Stripe",
			BackgroundColor3 = Surface.color(ctx, config.AccentColor, "Accent"),
			BorderSizePixel = 0,
			Size = host.udim2(0, 3, 1, -8),
			Position = host.udim2(0, 4, 0, 4),
		}, card)
		Helpers.corner(host, stripe, 2)
		local title = Surface.text(ctx, card, {
			Name = "Title",
			Size = host.udim2(1, -26, 0, 18),
			Position = host.udim2(0, 12, 0, 6),
			Text = tostring(ctx.Props.Name or ""),
			TextColor3 = Surface.color(ctx, config.TextColor, "Text"),
			Font = ctx.Tokens.FontBold,
			TextSize = config.TextSize or 13,
			TextTruncate = host.enumItem("TextTruncate", "AtEnd"),
		})
		local message = Surface.text(ctx, card, {
			Name = "Message",
			Size = host.udim2(1, -26, 0, math.max(14, height - 32)),
			Position = host.udim2(0, 12, 0, 22),
			Text = tostring(body.Message or ctx.Props.Description or ""),
			TextColor3 = Surface.color(ctx, config.MutedColor, "TextMuted"),
			TextSize = math.max(10, (config.TextSize or 13) - 1),
			TextWrapped = true,
			TextTruncate = host.enumItem("TextTruncate", "AtEnd"),
		})
		local dismiss
		if config.Dismissible ~= false then
			dismiss = Surface.hit(ctx, card, {
				Name = "Dismiss",
				Size = host.udim2(0, 18, 0, 18),
				Position = host.udim2(1, -22, 0, 6),
			})
			Surface.text(ctx, dismiss, {
				Name = "Glyph",
				Size = host.udim2(1, 0, 1, 0),
				Text = "x",
				TextColor3 = Surface.color(ctx, config.MutedColor, "TextMuted"),
				TextSize = math.max(10, (config.TextSize or 13) - 2),
				TextXAlignment = host.enumItem("TextXAlignment", "Center"),
			})
		end
		local view = {
			Root = root,
			Card = card,
			Title = title,
			Message = message,
			Dismiss = dismiss,
			Stripe = stripe,
		}
		view.SetName = function(self, name)
			self.Title.Text = name
		end
		view.Apply = function(self, state)
			local level = state.Level or "Info"
			local colour = level == "Error" and ctx.Tokens.Negative
				or level == "Warn" and ctx.Tokens.Warning
				or level == "Success" and ctx.Tokens.Positive
				or Surface.color(ctx, config.AccentColor, "Accent")
			self.Stripe.BackgroundColor3 = colour
			if state.Message then
				self.Message.Text = tostring(state.Message)
			end
		end
		return view
	end
end

local styles = {}

styles[#styles + 1] = {
	Id = "notification.toast",
	Name = "Toast",
	Component = "Notification",
	Category = "Feedback",
	Description = "Filled toast card with a level-coloured stripe.",
	Tags = { "default" },
	Render = notificationRender({ token = "Surface", transparency = 0 }),
}

styles[#styles + 1] = {
	Id = "notification.glass",
	Name = "Glass toast",
	Component = "Notification",
	Category = "Feedback",
	Description = "Translucent toast with a gradient wash for overlay interfaces.",
	Tags = { "glass" },
	Render = function(ctx)
		local view = notificationRender({ token = "Surface", transparency = 0.3 })(ctx)
		Helpers.gradient(ctx.Host, view.Card, ctx.Tokens.SurfaceAlt, ctx.Tokens.Accent, 90, { 0.25, 0.9 })
		return view
	end,
}

local function dialogRender(options)
	return function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local body = ctx.State.Body or {}
		local width = config.Width or 320
		local buttonHeight = config.ButtonHeight or 28
		local actions = body.Actions or {}
		local buttonCount = math.max(1, #actions)
		local height = options.compact and 128 or 160
		local root = host.new("Frame", {
			Name = "DialogRoot",
			BackgroundTransparency = 1,
			Size = host.udim2(0, width, 0, height),
		}, nil)
		local card = Surface.panel(ctx, root, {
			Name = "Card",
			Background = config.BackgroundColor,
			Token = "Surface",
			Transparency = options.transparency,
			CornerRadius = config.CornerRadius or ctx.Tokens.CornerRadius,
			Stroke = config.StrokeColor or ctx.Tokens.Outline,
			StrokeThickness = 1,
		})
		card.Size = host.udim2(1, 0, 1, 0)
		local accent = host.new("Frame", {
			Name = "Accent",
			BackgroundColor3 = Surface.color(ctx, config.AccentColor, "Accent"),
			BorderSizePixel = 0,
			Size = host.udim2(1, 0, 0, options.compact and 3 or 4),
		}, card)
		local title = Surface.text(ctx, card, {
			Name = "Title",
			Size = host.udim2(1, -32, 0, 22),
			Position = host.udim2(0, 16, 0, options.compact and 12 or 18),
			Text = tostring(ctx.Props.Name or ""),
			TextColor3 = Surface.color(ctx, config.TextColor, "Text"),
			Font = ctx.Tokens.FontBold,
			TextSize = (config.TextSize or 13) + 2,
			TextTruncate = host.enumItem("TextTruncate", "AtEnd"),
		})
		local message = Surface.text(ctx, card, {
			Name = "Message",
			Size = host.udim2(1, -32, 0, options.compact and 34 or 46),
			Position = host.udim2(0, 16, 0, options.compact and 36 or 44),
			Text = tostring(body.Message or ctx.Props.Description or ""),
			TextColor3 = Surface.color(ctx, config.MutedColor, "TextMuted"),
			TextWrapped = true,
			TextSize = math.max(10, (config.TextSize or 13) - 1),
		})
		local buttonArea = host.new("Frame", {
			Name = "Actions",
			BackgroundTransparency = 1,
			Size = host.udim2(1, -32, 0, buttonHeight),
			Position = host.udim2(0, 16, 1, -buttonHeight - 16),
		}, card)
		host.new("UIListLayout", {
			FillDirection = host.enumItem("FillDirection", "Horizontal"),
			Padding = host.udim(0, 8),
			HorizontalAlignment = host.enumItem("HorizontalAlignment", options.alignRight and "Right" or "Left"),
			VerticalAlignment = host.enumItem("VerticalAlignment", "Center"),
			SortOrder = host.enumItem("SortOrder", "LayoutOrder"),
		}, buttonArea)
		local buttons = {}
		local confirmColour = Surface.color(ctx, config.ConfirmColor, "Accent")
		local cancelColour = Surface.color(ctx, config.CancelColor, "SurfaceAlt")
		for index, action in ipairs(actions) do
			local isPrimary = action.Style == "Primary" or index == 1
			local button = Surface.panel(ctx, buttonArea, {
				Name = "Action" .. tostring(index),
				Background = isPrimary and (action.Style == "Cancel" and cancelColour or confirmColour) or cancelColour,
				Token = isPrimary and "Accent" or "SurfaceAlt",
				Transparency = 0,
				CornerRadius = math.max(0, (config.CornerRadius or 8) - 2),
			})
			button.Size = host.udim2(0, math.min(120, math.floor((width - 48) / buttonCount)), 0, buttonHeight)
			button.LayoutOrder = index
			Surface.text(ctx, button, {
				Name = "Label",
				Size = host.udim2(1, 0, 1, 0),
				Text = tostring(action.Label or ("Option " .. tostring(index))),
				TextColor3 = isPrimary and ctx.Tokens.AccentText or ctx.Tokens.Text,
				Font = ctx.Tokens.FontBold,
				TextSize = math.max(10, (config.TextSize or 13) - 1),
				TextXAlignment = host.enumItem("TextXAlignment", "Center"),
			})
			buttons[index] = { Value = action.Value or index, Button = button, Label = tostring(action.Label or "") }
		end
		local view = {
			Root = root,
			Card = card,
			Title = title,
			Message = message,
			ActionButtons = buttons,
			Accent = accent,
			ConfirmColour = confirmColour,
			CancelColour = cancelColour,
		}
		view.SetName = function(self, name)
			self.Title.Text = name
		end
		view.Apply = function(self, state)
			self.Title.Text = tostring(state.Title or ctx.Props.Name or "")
			self.Message.Text = tostring(state.Message or "")
		end
		return view
	end
end

styles[#styles + 1] = {
	Id = "dialog.modal",
	Name = "Modal dialog",
	Component = "Dialog",
	Category = "Feedback",
	Description = "Centred modal card with a title, body text and horizontal actions.",
	Tags = { "default" },
	Render = dialogRender({ transparency = 0, alignRight = false }),
}

styles[#styles + 1] = {
	Id = "dialog.compact",
	Name = "Compact dialog",
	Component = "Dialog",
	Category = "Feedback",
	Description = "Shorter dialog with right-aligned actions for confirmations.",
	Tags = { "compact" },
	Render = dialogRender({ transparency = 0.05, alignRight = true, compact = true }),
}

local registered, failures = Registry.registerMany(styles, { BuiltIn = true })
for _, failure in ipairs(failures) do
	error(("NEVAHEXUI: feedback style %s failed to register: %s"):format(tostring(failure.Id), table.concat(failure.Errors, "; ")))
end

return registered
