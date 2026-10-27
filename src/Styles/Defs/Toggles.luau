--[[
	NEVAHEXUI - Styles/Defs/Toggles
	Toggle, Checkbox, Radio and RadioGroup descriptors and styles.
	The four switch styles share a two-part structure (track + knob) but differ in
	geometry, decoration, colour sourcing and animation; Checkbox and Radio are
	separate implementations with their own glyph logic.
]]

local Registry = require("NEVA:Styles/Registry")
local Surface = require("NEVA:Styles/Surface")
local Helpers = require("NEVA:Styles/Helpers")

local SWITCH_PROPERTIES = {
	{ Key = "RowHeight", Type = "number", Default = 28, Min = 16, Max = 120, Group = "Geometry" },
	{ Key = "Width", Type = "number", Default = 44, Min = 16, Max = 200, Group = "Geometry" },
	{ Key = "Height", Type = "number", Default = 24, Min = 12, Max = 120, Group = "Geometry" },
	{ Key = "CornerRadius", Type = "number", Min = 0, Max = 64, Group = "Geometry" },
	{ Key = "KnobSize", Type = "number", Min = 4, Max = 64, Group = "Geometry" },
	{ Key = "KnobPadding", Type = "number", Min = 0, Max = 12, Default = 2, Group = "Geometry" },
	{ Key = "AccentColor", Type = "color", Group = "Appearance" },
	{ Key = "TrackColor", Type = "color", Group = "Appearance" },
	{ Key = "KnobColor", Type = "color", Group = "Appearance" },
	{ Key = "StrokeColor", Type = "color", Group = "Appearance" },
	{ Key = "StrokeThickness", Type = "number", Min = 0, Max = 8, Default = 1, Group = "Appearance" },
	{ Key = "TrackTransparency", Type = "number", Min = 0, Max = 1, Step = 0.01, Group = "Appearance" },
	{ Key = "Glow", Type = "boolean", Default = false, Group = "Appearance" },
	{ Key = "GradientFrom", Type = "color", Group = "Appearance" },
	{ Key = "GradientTo", Type = "color", Group = "Appearance" },
	{ Key = "Animation", Type = "animation", Default = "pop", Group = "Animation" },
	{ Key = "AnimationDuration", Type = "number", Min = 0, Max = 2, Group = "Animation" },
}

local SWITCH_DEFAULTS = {
	RowHeight = 28,
	Width = 44,
	Height = 24,
	KnobPadding = 2,
	StrokeThickness = 1,
	Animation = "pop",
	TrackTransparency = 0,
}

Registry.registerComponent({
	Name = "Toggle",
	RegistryName = "Toggles",
	Category = "Controls",
	Description = "Boolean switch. Value is true or false.",
	Defaults = SWITCH_DEFAULTS,
	Properties = SWITCH_PROPERTIES,
})

Registry.registerComponent({
	Name = "Checkbox",
	RegistryName = "Checkboxes",
	Category = "Controls",
	Description = "Square checkbox with a tick glyph.",
	Defaults = {
		RowHeight = 26,
		Size = 20,
		CornerRadius = 4,
		StrokeThickness = 1,
		Animation = "pop",
	},
	Properties = {
		{ Key = "RowHeight", Type = "number", Default = 26, Min = 16, Max = 120, Group = "Geometry" },
		{ Key = "Size", Type = "number", Default = 20, Min = 10, Max = 64, Group = "Geometry" },
		{ Key = "CornerRadius", Type = "number", Min = 0, Max = 32, Group = "Geometry" },
		{ Key = "AccentColor", Type = "color", Group = "Appearance" },
		{ Key = "BoxColor", Type = "color", Group = "Appearance" },
		{ Key = "TickColor", Type = "color", Group = "Appearance" },
		{ Key = "StrokeColor", Type = "color", Group = "Appearance" },
		{ Key = "StrokeThickness", Type = "number", Min = 0, Max = 8, Default = 1, Group = "Appearance" },
		{ Key = "Tick", Type = "string", Default = "\u{2714}", Group = "Appearance" },
		{ Key = "Animation", Type = "animation", Default = "pop", Group = "Animation" },
	},
})

Registry.registerComponent({
	Name = "Radio",
	RegistryName = "Radios",
	Category = "Controls",
	Description = "Single radio button. Radios sharing a Group value behave as one selection.",
	Defaults = {
		RowHeight = 26,
		Size = 20,
		StrokeThickness = 1,
		Animation = "pop",
		Group = "default",
	},
	Properties = {
		{ Key = "RowHeight", Type = "number", Default = 26, Min = 16, Max = 120, Group = "Geometry" },
		{ Key = "Size", Type = "number", Default = 20, Min = 10, Max = 64, Group = "Geometry" },
		{ Key = "AccentColor", Type = "color", Group = "Appearance" },
		{ Key = "RingColor", Type = "color", Group = "Appearance" },
		{ Key = "DotColor", Type = "color", Group = "Appearance" },
		{ Key = "StrokeThickness", Type = "number", Min = 0, Max = 8, Default = 1, Group = "Appearance" },
		{ Key = "DotScale", Type = "number", Min = 0.2, Max = 1, Step = 0.05, Default = 0.5, Group = "Appearance" },
		{ Key = "Animation", Type = "animation", Default = "pop", Group = "Animation" },
	},
})

Registry.registerComponent({
	Name = "RadioGroup",
	RegistryName = "RadioGroups",
	Category = "Controls",
	Description = "Composite control that lays out Radio children and owns their selection.",
	Defaults = {
		RowHeight = 26,
		Gap = 6,
		Options = {},
		Animation = "pop",
	},
	Properties = {
		{ Key = "RowHeight", Type = "number", Default = 26, Min = 16, Max = 120, Group = "Geometry" },
		{ Key = "Gap", Type = "number", Default = 6, Min = 0, Max = 40, Group = "Geometry" },
		{ Key = "CornerRadius", Type = "number", Min = 0, Max = 32, Group = "Geometry" },
		{ Key = "ContainerColor", Type = "color", Group = "Appearance" },
		{ Key = "ContainerTransparency", Type = "number", Min = 0, Max = 1, Step = 0.01, Default = 1, Group = "Appearance" },
		{ Key = "StrokeColor", Type = "color", Group = "Appearance" },
		{ Key = "Animation", Type = "animation", Default = "pop", Group = "Animation" },
	},
})

local function knobGeometry(ctx)
	local config = ctx.Configuration
	local width = config.Width or 44
	local height = config.Height or 24
	local padding = config.KnobPadding or 2
	local knob = config.KnobSize or (height - padding * 2)
	return width, height, padding, knob
end

local function switchRender(options)
	return function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local width, height, padding, knobSize = knobGeometry(ctx)
		if options.shape == "square" then
			width = config.Width or 36
			height = config.Height or 20
			knobSize = config.KnobSize or (height - padding * 2)
		end
		local slot = Surface.slot(ctx, { Height = config.RowHeight or 28, ControlWidth = width })
		local parent = slot.ControlArea or slot.Root
		local trackColourKey = options.trackToken or "Outline"
		local radius = config.CornerRadius
		if radius == nil then
			radius = options.radius == "pill" and height / 2 or 4
		end
		local track = Surface.panel(ctx, parent, {
			Name = "Track",
			Background = config.TrackColor,
			Token = trackColourKey,
			Transparency = Surface.transparency(ctx, config.TrackTransparency, "SurfaceTransparency", 0),
			CornerRadius = radius,
			Stroke = config.StrokeColor,
			StrokeThickness = config.StrokeThickness or 1,
		})
		track.Size = host.udim2(0, width, 0, height)
		track.Position = host.udim2(1, -width, 0.5, -height / 2)
		if config.GradientFrom or config.GradientTo then
			Helpers.gradient(
				host,
				track,
				Surface.color(ctx, config.GradientFrom, "Accent"),
				Surface.color(ctx, config.GradientTo, "SurfaceAlt"),
				90
			)
		end
		local glow
		if config.Glow then
			glow = host.new("Frame", {
				Name = "Glow",
				BackgroundColor3 = Surface.color(ctx, config.AccentColor, "Accent"),
				BackgroundTransparency = 0.72,
				BorderSizePixel = 0,
				Size = host.udim2(1, 8, 1, 8),
				Position = host.udim2(0.5, 0, 0.5, 0),
				AnchorPoint = host.vector2(0.5, 0.5),
				ZIndex = 0,
			}, track)
			Helpers.corner(host, glow, radius + 4)
		end
		local knob = host.new("Frame", {
			Name = "Knob",
			BackgroundColor3 = Surface.color(ctx, config.KnobColor, "Text"),
			BorderSizePixel = 0,
			Size = host.udim2(0, knobSize, 0, knobSize),
			Position = host.udim2(0, padding, 0.5, -knobSize / 2),
			ZIndex = 2,
		}, track)
		Helpers.corner(host, knob, options.shape == "square" and math.max(1, radius - 2) or knobSize / 2)
		local input = Surface.hit(ctx, track, { Size = host.udim2(1, 0, 1, 0), ZIndex = 3 })
		local view = {
			Root = slot.Root,
			Input = input,
			Track = track,
			Knob = knob,
			Glow = glow,
			Width = width,
			Padding = padding,
			KnobSize = knobSize,
			OffColour = Surface.color(ctx, config.TrackColor, trackColourKey),
			OnColour = Surface.color(ctx, config.AccentColor, "Accent"),
			OffKnob = Surface.color(ctx, config.KnobColor, "Text"),
			OffTransparency = Surface.transparency(ctx, config.TrackTransparency, "SurfaceTransparency", 0),
		}
		view.Apply = function(self, state, renderCtx)
			local configuration = renderCtx.Configuration
			local active = state.Value == true
			local travel = self.Width - self.KnobSize - self.Padding * 2
			if not state.Enabled then
				self.Track.BackgroundColor3 = Surface.disabledColour(renderCtx, self.OffColour)
				self.Knob.BackgroundColor3 = Surface.disabledText(renderCtx, self.OffKnob)
				active = false
			else
				self.Track.BackgroundColor3 = active and self.OnColour or self.OffColour
				self.Knob.BackgroundColor3 = active and renderCtx.Tokens.AccentText or self.OffKnob
			end
			Surface.animate(renderCtx, self.Knob, {
				Position = renderCtx.Host.udim2(0, active and (travel + self.Padding) or self.Padding, 0.5, -self.KnobSize / 2),
			})
			if self.Glow then
				self.Glow.BackgroundTransparency = active and 0.6 or 0.9
			end
		end
		return view
	end
end

local function checkboxRender(options)
	return function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local size = config.Size or 20
		local slot = Surface.slot(ctx, { Height = config.RowHeight or 26, ControlWidth = size })
		local parent = slot.ControlArea or slot.Root
		local radius = config.CornerRadius
		if radius == nil then
			radius = options.round and size / 2 or 4
		end
		local box = Surface.panel(ctx, parent, {
			Name = "Box",
			Background = config.BoxColor,
			Token = "SurfaceAlt",
			Transparency = 0,
			CornerRadius = radius,
			Stroke = config.StrokeColor or ctx.Tokens.Outline,
			StrokeThickness = config.StrokeThickness or 1,
		})
		box.Size = host.udim2(0, size, 0, size)
		box.Position = host.udim2(1, -size, 0.5, -size / 2)
		local tick = Surface.text(ctx, box, {
			Name = "Tick",
			Size = host.udim2(1, 0, 1, 0),
			Text = config.Tick or "\u{2714}",
			TextColor3 = Surface.color(ctx, config.TickColor, "AccentText"),
			Font = ctx.Tokens.FontBold,
			TextSize = size * 0.7,
			TextXAlignment = host.enumItem("TextXAlignment", "Center"),
			TextYAlignment = host.enumItem("TextYAlignment", "Center"),
			TextTransparency = 1,
		})
		local input = Surface.hit(ctx, box)
		local view = {
			Root = slot.Root,
			Input = input,
			Box = box,
			Tick = tick,
			OffColour = Surface.color(ctx, config.BoxColor, "SurfaceAlt"),
			OnColour = Surface.color(ctx, config.AccentColor, "Accent"),
			Size = size,
		}
		view.Apply = function(self, state, renderCtx)
			local active = state.Value == true
			if not state.Enabled then
				self.Box.BackgroundColor3 = Surface.disabledColour(renderCtx, self.OffColour)
				self.Tick.TextTransparency = 0.6
			else
				self.Box.BackgroundColor3 = active and self.OnColour or self.OffColour
				self.Tick.TextTransparency = active and 0 or 1
			end
		end
		return view
	end
end

local function radioRender(options)
	return function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local size = config.Size or 20
		local slot = Surface.slot(ctx, { Height = config.RowHeight or 26, ControlWidth = size })
		local parent = slot.ControlArea or slot.Root
		local ring = Surface.panel(ctx, parent, {
			Name = "Ring",
			Background = config.RingColor,
			Token = "SurfaceAlt",
			Transparency = 0,
			CornerRadius = size / 2,
			Stroke = config.StrokeColor or ctx.Tokens.Outline,
			StrokeThickness = config.StrokeThickness or 1,
		})
		ring.Size = host.udim2(0, size, 0, size)
		ring.Position = host.udim2(1, -size, 0.5, -size / 2)
		local dotScale = config.DotScale or 0.5
		local dotSize = math.max(4, size * dotScale)
		local dot = host.new("Frame", {
			Name = "Dot",
			BackgroundColor3 = Surface.color(ctx, config.DotColor, "Accent"),
			BorderSizePixel = 0,
			Size = options.dot == "fill" and host.udim2(1, -6, 1, -6) or host.udim2(0, dotSize, 0, dotSize),
			Position = host.udim2(0.5, 0, 0.5, 0),
			AnchorPoint = host.vector2(0.5, 0.5),
			BackgroundTransparency = 1,
		}, ring)
		Helpers.corner(host, dot, dotSize / 2)
		local input = Surface.hit(ctx, ring)
		local view = {
			Root = slot.Root,
			Input = input,
			Ring = ring,
			Dot = dot,
			OffColour = Surface.color(ctx, config.RingColor, "SurfaceAlt"),
			OnColour = Surface.color(ctx, config.AccentColor or config.RingColor, "Accent"),
			Fill = options.dot == "fill",
		}
		view.Apply = function(self, state, renderCtx)
			local active = state.Value == true
			if not state.Enabled then
				self.Ring.BackgroundColor3 = Surface.disabledColour(renderCtx, self.OffColour)
				self.Dot.BackgroundTransparency = 1
			else
				self.Ring.BackgroundColor3 = active and self.OnColour or self.OffColour
				self.Dot.BackgroundTransparency = active and 0 or 1
			end
		end
		return view
	end
end

local styles = {}

styles[#styles + 1] = {
	Id = "toggle.rounded",
	Name = "Rounded switch",
	Component = "Toggle",
	Category = "Controls",
	Description = "Classic pill switch with a circular knob and accent fill.",
	Tags = { "default", "pill" },
	Render = switchRender({ shape = "pill", radius = "pill", trackToken = "Outline" }),
}

styles[#styles + 1] = {
	Id = "toggle.compact",
	Name = "Compact switch",
	Component = "Toggle",
	Category = "Controls",
	Description = "Small square-cornered switch for dense layouts.",
	Tags = { "compact", "dense" },
	Render = switchRender({ shape = "square", radius = "square", trackToken = "Outline" }),
}

styles[#styles + 1] = {
	Id = "toggle.neon",
	Name = "Neon switch",
	Component = "Toggle",
	Category = "Controls",
	Description = "Glowing switch with an accent halo and gradient track.",
	Tags = { "neon", "glow" },
	Render = switchRender({ shape = "pill", radius = "pill", trackToken = "Background" }),
}

styles[#styles + 1] = {
	Id = "toggle.glass",
	Name = "Glass switch",
	Component = "Toggle",
	Category = "Controls",
	Description = "Translucent switch with a gradient track and soft rim.",
	Tags = { "glass", "translucent" },
	Render = switchRender({ shape = "pill", radius = "pill", trackToken = "Surface" }),
}

styles[#styles + 1] = {
	Id = "checkbox.standard",
	Name = "Standard checkbox",
	Component = "Checkbox",
	Category = "Controls",
	Description = "Square checkbox that fills with the accent colour when checked.",
	Tags = { "default", "tick" },
	Render = checkboxRender({}),
}

styles[#styles + 1] = {
	Id = "checkbox.circle",
	Name = "Round checkbox",
	Component = "Checkbox",
	Category = "Controls",
	Description = "Circular checkbox for compact toolbars.",
	Tags = { "round" },
	Render = checkboxRender({ round = true }),
}

styles[#styles + 1] = {
	Id = "radio.classic",
	Name = "Classic radio",
	Component = "Radio",
	Category = "Controls",
	Description = "Ring with a centred dot when selected.",
	Tags = { "default" },
	Render = radioRender({ dot = "dot" }),
}

styles[#styles + 1] = {
	Id = "radio.filled",
	Name = "Filled radio",
	Component = "Radio",
	Category = "Controls",
	Description = "Ring that fills with the accent colour when selected.",
	Tags = { "filled" },
	Render = radioRender({ dot = "fill" }),
}

styles[#styles + 1] = {
	Id = "radiogroup.list",
	Name = "Radio list",
	Component = "RadioGroup",
	Category = "Controls",
	Description = "Vertical list container that hosts Radio children.",
	Render = function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local slot = Surface.slot(ctx, {
			Height = config.RowHeight or 26,
			Label = true,
			ControlWidth = 0,
		})
		local holder = host.new("Frame", {
			Name = "Options",
			BackgroundColor3 = Surface.color(ctx, config.ContainerColor, "SurfaceAlt"),
			BackgroundTransparency = Surface.transparency(ctx, config.ContainerTransparency, "SurfaceTransparency", 1),
			BorderSizePixel = 0,
			Size = host.udim2(1, 0, 0, (config.RowHeight or 26) + (config.Gap or 6)),
			Position = host.udim2(0, 0, 1, 4),
		}, slot.LabelArea or slot.Root)
		Helpers.corner(host, holder, config.CornerRadius or ctx.Tokens.CornerRadius)
		if config.StrokeColor then
			Helpers.stroke(host, holder, Surface.color(ctx, config.StrokeColor, "Outline"), 1, 0)
		end
		host.new("UIListLayout", {
			FillDirection = host.enumItem("FillDirection", "Vertical"),
			Padding = host.udim(0, config.Gap or 6),
			SortOrder = host.enumItem("SortOrder", "LayoutOrder"),
		}, holder)
		local view = {
			Root = slot.Root,
			Holder = holder,
			Label = slot.Label,
			Gap = config.Gap or 6,
			RowHeight = config.RowHeight or 26,
		}
		view.Apply = function(self)
			-- RadioGroup owns no visual state of its own; children paint themselves.
		end
		view.SetName = function(self, name)
			if self.Label then
				self.Label.Text = name
			end
		end
		return view
	end,
}

local registered, failures = Registry.registerMany(styles, { BuiltIn = true })
for _, failure in ipairs(failures) do
	error(("NEVAHEXUI: toggles style %s failed to register: %s"):format(tostring(failure.Id), table.concat(failure.Errors, "; ")))
end

return registered
