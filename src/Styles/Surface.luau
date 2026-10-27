--[[
	NEVAHEXUI - Styles/Surface
	Shared composition helpers used by every style renderer: rows, panels,
	labelled slots, hit areas and animation. Styles read colours through
	this module so a component's resolved configuration always beats the theme
	token fallback, which is the documented theme/style precedence.
]]

local Helpers = require("NEVA:Styles/Helpers")
local Color = require("NEVA:Utilities/Color")
local Presets = require("NEVA:Animation/Presets")

local Surface = {}

function Surface.color(ctx, value, tokenKey)
	if value ~= nil then
		local resolved = Helpers.colour(ctx.Host, value)
		if resolved ~= nil then
			return resolved
		end
	end
	if tokenKey ~= nil then
		local tokenValue = ctx.Tokens[tokenKey]
		if tokenValue ~= nil then
			return tokenValue
		end
	end
	return ctx.Tokens.SurfaceAlt or ctx.Tokens.Surface
end

function Surface.number(ctx, value, tokenKey, fallback)
	if type(value) == "number" then
		return value
	end
	if tokenKey ~= nil and type(ctx.Tokens[tokenKey]) == "number" then
		return ctx.Tokens[tokenKey]
	end
	return fallback or 0
end

function Surface.transparency(ctx, value, tokenKey, fallback)
	if type(value) == "number" then
		return value
	end
	if tokenKey ~= nil and type(ctx.Tokens[tokenKey]) == "number" then
		return ctx.Tokens[tokenKey]
	end
	return fallback or 0
end

function Surface.font(ctx, value)
	if type(value) == "string" then
		return ctx.Host.font(value)
	end
	return ctx.Tokens.Font
end

function Surface.animationSpec(ctx)
	local config = ctx.Configuration
	local preset = config.Animation
	if type(preset) == "string" then
		return preset
	end
	local duration = config.AnimationDuration
	if type(duration) == "number" then
		return {
			Name = "Inline",
			Duration = duration,
			Easing = config.Easing or ctx.Tokens.Easing or "Quad",
			Direction = config.AnimationDirection or "Out",
		}
	end
	return "smooth"
end

function Surface.animate(ctx, instance, goal)
	local resolved, name = Presets.get(Surface.animationSpec(ctx))
	if name == "none" or (type(resolved) == "table" and resolved.Duration <= 0) then
		return ctx.Host.set(instance, goal)
	end
	return ctx.Host.tween(instance, goal, ctx.Host.tweenInfo(resolved.Duration, resolved.Easing, resolved.Direction))
end

-- Labelled slot: the standard "name on the left, control on the right" row.
function Surface.slot(ctx, options)
	options = options or {}
	local host = ctx.Host
	local config = ctx.Configuration
	local height = options.Height or config.RowHeight or 28
	local root = host.new("Frame", {
		Name = options.Name or (ctx.Type .. "Row"),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = options.Size or host.udim2(1, 0, 0, height),
		LayoutOrder = options.Order or 0,
		ClipsDescendants = options.ClipsDescendants == true,
	}, options.Parent)
	local slot = { Root = root, Host = host }

	local hasLabel = options.Label ~= false and (options.LabelText or ctx.Props.Name)
	if hasLabel then
		local controlWidth = options.ControlWidth or 0
		local labelArea = host.new("Frame", {
			Name = "LabelArea",
			BackgroundTransparency = 1,
			Size = host.udim2(1, -controlWidth - (controlWidth > 0 and 12 or 0), 1, 0),
			Position = host.udim2(0, 0, 0, 0),
		}, root)
		slot.LabelArea = labelArea
		local description = options.Description
		if description == nil then
			description = ctx.Props.Description
		end
		local hasDescription = type(description) == "string" and description ~= ""
		slot.Label = host.new("TextLabel", {
			Name = "Label",
			BackgroundTransparency = 1,
			Size = hasDescription and host.udim2(1, 0, 0, math.max(12, height * 0.55)) or host.udim2(1, 0, 1, 0),
			Text = options.LabelText or ctx.Props.Name or "",
			TextColor3 = ctx.Tokens.Text,
			Font = ctx.Tokens.Font,
			TextSize = config.TextSize or ctx.Tokens.FontSize or 13,
			TextXAlignment = host.enumItem("TextXAlignment", "Left"),
			TextYAlignment = host.enumItem("TextYAlignment", hasDescription and "Top" or "Center"),
			TextTruncate = host.enumItem("TextTruncate", "AtEnd"),
		}, labelArea)
		if hasDescription then
			slot.Description = host.new("TextLabel", {
				Name = "Description",
				BackgroundTransparency = 1,
				Size = host.udim2(1, 0, 0, math.max(10, height * 0.4)),
				Position = host.udim2(0, 0, 1, -math.max(10, height * 0.4)),
				Text = description,
				TextColor3 = ctx.Tokens.TextMuted,
				Font = ctx.Tokens.Font,
				TextSize = config.DescriptionTextSize or math.max(10, (config.TextSize or ctx.Tokens.FontSize or 13) - 2),
				TextXAlignment = host.enumItem("TextXAlignment", "Left"),
				TextYAlignment = host.enumItem("TextYAlignment", "Bottom"),
				TextTruncate = host.enumItem("TextTruncate", "AtEnd"),
			}, labelArea)
		end
	end

	if options.ControlWidth and options.ControlWidth > 0 then
		slot.ControlArea = host.new("Frame", {
			Name = "ControlArea",
			BackgroundTransparency = 1,
			Size = host.udim2(0, options.ControlWidth, 1, 0),
			Position = host.udim2(1, -options.ControlWidth, 0, 0),
		}, root)
	end

	return slot
end

-- Panel with themed background, optional corner radius and stroke.
function Surface.panel(ctx, parent, options)
	options = options or {}
	local host = ctx.Host
	local config = ctx.Configuration
	local frame = host.new("Frame", {
		Name = options.Name or "Panel",
		BackgroundColor3 = Surface.color(ctx, options.Background, options.Token or "SurfaceAlt"),
		BackgroundTransparency = options.Transparency or 0,
		BorderSizePixel = 0,
		Size = options.Size or host.udim2(1, 0, 0, options.Height or 32),
		Position = options.Position,
		Visible = options.Visible ~= false,
		ClipsDescendants = options.ClipsDescendants == true,
		LayoutOrder = options.Order or 0,
	}, parent)
	local radius = options.CornerRadius
	if radius == nil then
		radius = config.CornerRadius
	end
	if radius == nil then
		radius = ctx.Tokens.CornerRadius
	end
	Helpers.corner(host, frame, radius)
	if options.Stroke then
		frame.__nevaStroke = Helpers.stroke(host, frame, options.Stroke, options.StrokeThickness or 1, options.StrokeTransparency or 0)
	end
	return frame
end

function Surface.text(ctx, parent, props)
	local merged = {
		BackgroundTransparency = 1,
		Font = ctx.Tokens.Font,
		TextColor3 = ctx.Tokens.Text,
		TextSize = ctx.Configuration.TextSize or ctx.Tokens.FontSize or 13,
		TextXAlignment = ctx.Host.enumItem("TextXAlignment", "Left"),
		TextYAlignment = ctx.Host.enumItem("TextYAlignment", "Center"),
	}
	for key, value in pairs(props or {}) do
		merged[key] = value
	end
	return ctx.Host.new("TextLabel", merged, parent)
end

-- Invisible clickable area used as the component's Input surface.
function Surface.hit(ctx, parent, props)
	local merged = {
		Name = "Input",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = ctx.Host.udim2(1, 0, 1, 0),
		AutoButtonColor = false,
		Text = "",
	}
	for key, value in pairs(props or {}) do
		merged[key] = value
	end
	return ctx.Host.new("TextButton", merged, parent)
end

-- Pressed state tracking. Styles call this once per Input surface; the flag is
-- read back by the style's Apply through renderCtx.Component.Pressed.
function Surface.wirePress(ctx, input)
	local component = ctx.Component
	if not component or not input then
		return
	end
	component:Connect(input, "MouseButton1Down", function()
		component.Pressed = true
		component:_applyState()
	end)
	component:Connect(input, "MouseButton1Up", function()
		component.Pressed = false
		component:_applyState()
	end)
end

function Surface.disabledColour(ctx, colour)
	local background = ctx.Tokens.Background
	if type(colour) ~= "table" or type(background) ~= "table" then
		return colour
	end
	return Color.lerp(colour, background, 0.55)
end

function Surface.disabledText(ctx, colour)
	local muted = ctx.Tokens.TextMuted
	if colour == nil then
		return muted
	end
	return Color.lerp(colour, muted, 0.6)
end

function Surface.rowColour(ctx, colour)
	return colour
end

return Surface
