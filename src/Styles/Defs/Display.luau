--[[
	NEVAHEXUI - Styles/Defs/Display
	Component descriptors plus the first group of display renderers. Display
	components have no value the user sets directly, so they expose fewer styles
	than interactive categories; every one of them is a real renderer.
]]

local Registry = require("NEVA:Styles/Registry")
local Surface = require("NEVA:Styles/Surface")
local Helpers = require("NEVA:Styles/Helpers")

local function component(spec)
	Registry.registerComponent(spec)
end

component({
	Name = "Label", RegistryName = "Labels", Category = "Display",
	Description = "Static text with an optional description.",
	Defaults = { RowHeight = 22, TextSize = 13, Wrapped = false, Alignment = "Left" },
	Properties = {
		{ Key = "RowHeight", Type = "number", Default = 22, Min = 12, Max = 200, Group = "Geometry" },
		{ Key = "TextSize", Type = "number", Default = 13, Min = 8, Max = 40, Group = "Typography" },
		{ Key = "TextColor", Type = "color", Group = "Typography" },
		{ Key = "Font", Type = "font", Group = "Typography" },
		{ Key = "Alignment", Type = "enum", Options = { "Left", "Center", "Right" }, Default = "Left", Group = "Typography" },
		{ Key = "Wrapped", Type = "boolean", Default = false, Group = "Typography" },
	},
})

component({
	Name = "Divider", RegistryName = "Dividers", Category = "Display",
	Description = "Horizontal rule with an optional caption.",
	Defaults = { RowHeight = 14, Thickness = 1, Transparency = 0.4 },
	Properties = {
		{ Key = "RowHeight", Type = "number", Default = 14, Min = 4, Max = 80, Group = "Geometry" },
		{ Key = "Thickness", Type = "number", Default = 1, Min = 1, Max = 8, Group = "Geometry" },
		{ Key = "Color", Type = "color", Group = "Appearance" },
		{ Key = "Transparency", Type = "number", Min = 0, Max = 1, Step = 0.01, Default = 0.4, Group = "Appearance" },
		{ Key = "Caption", Type = "string", Default = "", Group = "Typography" },
	},
})

component({
	Name = "Badge", RegistryName = "Badges", Category = "Display",
	Description = "Small status pill.",
	Defaults = { RowHeight = 20, Height = 18, Padding = 8, TextSize = 12 },
	Properties = {
		{ Key = "RowHeight", Type = "number", Default = 20, Min = 12, Max = 80, Group = "Geometry" },
		{ Key = "Height", Type = "number", Default = 18, Min = 10, Max = 60, Group = "Geometry" },
		{ Key = "Padding", Type = "number", Default = 8, Min = 0, Max = 32, Group = "Geometry" },
		{ Key = "TextSize", Type = "number", Default = 12, Min = 8, Max = 28, Group = "Typography" },
		{ Key = "TextColor", Type = "color", Group = "Typography" },
		{ Key = "BackgroundColor", Type = "color", Group = "Appearance" },
		{ Key = "StrokeColor", Type = "color", Group = "Appearance" },
		{ Key = "StrokeThickness", Type = "number", Min = 0, Max = 4, Default = 1, Group = "Appearance" },
	},
})

component({
	Name = "ProgressBar", RegistryName = "ProgressBars", Category = "Display",
	Description = "Determinate progress bar from 0 to 1.",
	Defaults = { RowHeight = 26, Width = 180, Height = 8, ShowValue = false, Animation = "smooth" },
	Properties = {
		{ Key = "RowHeight", Type = "number", Default = 26, Min = 12, Max = 120, Group = "Geometry" },
		{ Key = "Width", Type = "number", Default = 180, Min = 40, Max = 700, Group = "Geometry" },
		{ Key = "Height", Type = "number", Default = 8, Min = 2, Max = 60, Group = "Geometry" },
		{ Key = "CornerRadius", Type = "number", Min = 0, Max = 32, Group = "Geometry" },
		{ Key = "TrackColor", Type = "color", Group = "Appearance" },
		{ Key = "FillColor", Type = "color", Group = "Appearance" },
		{ Key = "TextColor", Type = "color", Group = "Typography" },
		{ Key = "ShowValue", Type = "boolean", Default = false, Group = "Behaviour" },
		{ Key = "Segments", Type = "number", Default = 10, Min = 2, Max = 40, Group = "Appearance" },
		{ Key = "Animation", Type = "animation", Default = "smooth", Group = "Animation" },
	},
})

component({
	Name = "Loader", RegistryName = "Loaders", Category = "Display",
	Description = "Indeterminate activity indicator.",
	Defaults = { RowHeight = 24, Size = 16, Dots = 3, Speed = 1 },
	Properties = {
		{ Key = "RowHeight", Type = "number", Default = 24, Min = 10, Max = 120, Group = "Geometry" },
		{ Key = "Size", Type = "number", Default = 16, Min = 6, Max = 64, Group = "Geometry" },
		{ Key = "Dots", Type = "number", Default = 3, Min = 1, Max = 8, Group = "Geometry" },
		{ Key = "Color", Type = "color", Group = "Appearance" },
		{ Key = "Speed", Type = "number", Default = 1, Min = 0.1, Max = 5, Step = 0.1, Group = "Animation" },
	},
})

component({
	Name = "Image", RegistryName = "Images", Category = "Display",
	Description = "Icon or texture display.",
	Defaults = { RowHeight = 32, Size = 32, Transparency = 0 },
	Properties = {
		{ Key = "RowHeight", Type = "number", Default = 32, Min = 8, Max = 200, Group = "Geometry" },
		{ Key = "Size", Type = "number", Default = 32, Min = 8, Max = 200, Group = "Geometry" },
		{ Key = "CornerRadius", Type = "number", Min = 0, Max = 64, Group = "Geometry" },
		{ Key = "ImageColor", Type = "color", Group = "Appearance" },
		{ Key = "Transparency", Type = "number", Min = 0, Max = 1, Step = 0.01, Default = 0, Group = "Appearance" },
	},
})

local styles = {}

styles[#styles + 1] = {
	Id = "label.plain", Name = "Plain label", Component = "Label", Category = "Display",
	Description = "Single-line text bound to the component value.",
	Tags = { "default" },
	Render = function(ctx)
		local config = ctx.Configuration
		local slot = Surface.slot(ctx, { Height = config.RowHeight or 22, Label = false })
		local label = Surface.text(ctx, slot.Root, {
			Name = "Value",
			Size = ctx.Host.udim2(1, 0, 1, 0),
			Text = tostring(ctx.State.Value or ""),
			TextColor3 = Surface.color(ctx, config.TextColor, "Text"),
			Font = Surface.font(ctx, config.Font) or ctx.Tokens.Font,
			TextSize = config.TextSize or 13,
			TextXAlignment = ctx.Host.enumItem("TextXAlignment", config.Alignment or "Left"),
			TextWrapped = config.Wrapped == true,
		})
		local view = { Root = slot.Root, Value = label }
		view.Apply = function(self, state)
			self.Value.Text = tostring(state.Value or "")
			if not state.Enabled then
				self.Value.TextColor3 = ctx.Tokens.TextMuted
			end
		end
		view.SetName = function(self, name)
			self.Value.Text = name
		end
		return view
	end,
}

styles[#styles + 1] = {
	Id = "label.heading", Name = "Heading label", Component = "Label", Category = "Display",
	Description = "Emphasised heading with a muted caption underneath.",
	Tags = { "heading" },
	Render = function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local height = math.max(config.RowHeight or 22, 34)
		local slot = Surface.slot(ctx, { Height = height, Label = false })
		local title = Surface.text(ctx, slot.Root, {
			Name = "Value",
			Size = host.udim2(1, 0, 0, height * 0.6),
			Text = tostring(ctx.State.Value or ctx.Props.Name or ""),
			TextColor3 = Surface.color(ctx, config.TextColor, "Text"),
			Font = ctx.Tokens.FontBold,
			TextSize = (config.TextSize or 13) + 2,
			TextXAlignment = host.enumItem("TextXAlignment", config.Alignment or "Left"),
		})
		local caption = Surface.text(ctx, slot.Root, {
			Name = "Caption",
			Size = host.udim2(1, 0, 0, height * 0.4),
			Position = host.udim2(0, 0, 1, -height * 0.4),
			Text = tostring(ctx.Props.Description or ""),
			TextColor3 = ctx.Tokens.TextMuted,
			TextSize = math.max(10, (config.TextSize or 13) - 2),
		})
		local view = { Root = slot.Root, Value = title, Caption = caption }
		view.Apply = function(self, state)
			self.Value.Text = tostring(state.Value or "")
		end
		view.SetName = function(self, name)
			self.Value.Text = name
		end
		return view
	end,
}

styles[#styles + 1] = {
	Id = "divider.line", Name = "Line divider", Component = "Divider", Category = "Display",
	Description = "Rule split around an optional centred caption.",
	Tags = { "default" },
	Render = function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local thickness = config.Thickness or 1
		local transparency = config.Transparency == nil and 0.4 or config.Transparency
		local slot = Surface.slot(ctx, { Height = config.RowHeight or 14, Label = false })
		local colour = Surface.color(ctx, config.Color, "Outline")
		local captionText = (config.Caption ~= nil and config.Caption ~= "") and config.Caption or ctx.Props.Name
		local hasCaption = captionText ~= nil and captionText ~= ""
		local rule
		local caption
		if hasCaption then
			local measured = #tostring(captionText) * 6 + 16
			rule = host.new("Frame", {
				Name = "RuleLeft",
				BackgroundColor3 = colour,
				BackgroundTransparency = transparency,
				BorderSizePixel = 0,
				Size = host.udim2(1, -measured, 0, thickness),
				Position = host.udim2(0, 0, 0.5, -thickness / 2),
			}, slot.Root)
			host.new("Frame", {
				Name = "RuleRight",
				BackgroundColor3 = colour,
				BackgroundTransparency = transparency,
				BorderSizePixel = 0,
				Size = host.udim2(1, -measured, 0, thickness),
				Position = host.udim2(0, measured, 0.5, -thickness / 2),
			}, slot.Root)
			caption = Surface.text(ctx, slot.Root, {
				Name = "Caption",
				Size = host.udim2(1, 0, 1, 0),
				Text = tostring(captionText),
				TextColor3 = ctx.Tokens.TextMuted,
				TextSize = math.max(10, (config.RowHeight or 14) - 4),
				TextXAlignment = host.enumItem("TextXAlignment", "Center"),
			})
		else
			rule = host.new("Frame", {
				Name = "Rule",
				BackgroundColor3 = colour,
				BackgroundTransparency = transparency,
				BorderSizePixel = 0,
				Size = host.udim2(1, 0, 0, thickness),
				Position = host.udim2(0, 0, 0.5, -thickness / 2),
			}, slot.Root)
		end
		local view = { Root = slot.Root, Rule = rule, Caption = caption }
		view.Apply = function()
			-- Divider carries no interaction state.
		end
		view.SetName = function(self, name)
			if self.Caption then
				self.Caption.Text = name
			end
		end
		return view
	end,
}

styles[#styles + 1] = {
	Id = "badge.pill", Name = "Pill badge", Component = "Badge", Category = "Display",
	Description = "Filled pill sized to its label.",
	Tags = { "default" },
	Render = function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local height = config.Height or 18
		local padding = config.Padding or 8
		local slot = Surface.slot(ctx, { Height = config.RowHeight or 20, Label = false })
		local pill = host.new("Frame", {
			Name = "Pill",
			BackgroundColor3 = Surface.color(ctx, config.BackgroundColor, "Accent"),
			BorderSizePixel = 0,
			Size = host.udim2(0, 60, 0, height),
			Position = host.udim2(0, 0, 0.5, -height / 2),
		}, slot.Root)
		Helpers.corner(host, pill, height / 2)
		local label = Surface.text(ctx, pill, {
			Name = "Label",
			Size = host.udim2(1, -padding * 2, 1, 0),
			Position = host.udim2(0, padding, 0, 0),
			Text = tostring(ctx.State.Value or ctx.Props.Name or ""),
			TextColor3 = Surface.color(ctx, config.TextColor, "AccentText"),
			Font = ctx.Tokens.FontBold,
			TextSize = config.TextSize or 12,
			TextXAlignment = host.enumItem("TextXAlignment", "Center"),
			TextTruncate = host.enumItem("TextTruncate", "AtEnd"),
		})
		local view = { Root = slot.Root, Pill = pill, Label = label, Padding = padding, Height = height }
		view.Apply = function(self, state)
			self.Label.Text = tostring(state.Value or "")
			local estimate = #self.Label.Text * (self.Label.TextSize * 0.62) + self.Padding * 2
			self.Pill.Size = ctx.Host.udim2(0, math.max(self.Height, estimate), 0, self.Height)
		end
		view.SetName = function(self, name)
			self.Label.Text = name
		end
		return view
	end,
}

styles[#styles + 1] = {
	Id = "badge.outline", Name = "Outline badge", Component = "Badge", Category = "Display",
	Description = "Transparent badge with a coloured rim.",
	Tags = { "outline" },
	Render = function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local height = config.Height or 18
		local slot = Surface.slot(ctx, { Height = config.RowHeight or 20, Label = false })
		local pill = host.new("Frame", {
			Name = "Pill",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = host.udim2(0, 64, 0, height),
			Position = host.udim2(0, 0, 0.5, -height / 2),
		}, slot.Root)
		Helpers.corner(host, pill, height / 2)
		Helpers.stroke(host, pill, Surface.color(ctx, config.StrokeColor, "Accent"), config.StrokeThickness or 1, 0)
		local label = Surface.text(ctx, pill, {
			Name = "Label",
			Size = host.udim2(1, -18, 1, 0),
			Position = host.udim2(0, 9, 0, 0),
			Text = tostring(ctx.State.Value or ctx.Props.Name or ""),
			TextColor3 = Surface.color(ctx, config.TextColor, "Accent"),
			TextSize = config.TextSize or 12,
			TextXAlignment = host.enumItem("TextXAlignment", "Center"),
		})
		local view = { Root = slot.Root, Pill = pill, Label = label }
		view.Apply = function(self, state)
			self.Label.Text = tostring(state.Value or "")
		end
		view.SetName = function(self, name)
			self.Label.Text = name
		end
		return view
	end,
}

styles[#styles + 1] = {
	Id = "progressbar.bar", Name = "Progress bar", Component = "ProgressBar", Category = "Display",
	Description = "Rounded track with an animated fill and optional percentage.",
	Tags = { "default" },
	Render = function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local width = config.Width or 180
		local height = config.Height or 8
		local slot = Surface.slot(ctx, {
			Height = config.RowHeight or 26,
			ControlWidth = width + (config.ShowValue and 44 or 0),
		})
		local parent = slot.ControlArea or slot.Root
		local track = host.new("Frame", {
			Name = "Track",
			BackgroundColor3 = Surface.color(ctx, config.TrackColor, "Outline"),
			BackgroundTransparency = 0.55,
			BorderSizePixel = 0,
			Size = host.udim2(0, width, 0, height),
			Position = host.udim2(1, -width, 0.5, -height / 2),
		}, parent)
		Helpers.corner(host, track, config.CornerRadius or height / 2)
		local fill = host.new("Frame", {
			Name = "Fill",
			BackgroundColor3 = Surface.color(ctx, config.FillColor, "Accent"),
			BorderSizePixel = 0,
			Size = host.udim2(0, 0, 1, 0),
		}, track)
		Helpers.corner(host, fill, config.CornerRadius or height / 2)
		local valueLabel
		if config.ShowValue then
			valueLabel = Surface.text(ctx, parent, {
				Name = "Value",
				Size = host.udim2(0, 40, 1, 0),
				Position = host.udim2(1, -40, 0, 0),
				TextColor3 = Surface.color(ctx, config.TextColor, "Text"),
				TextXAlignment = host.enumItem("TextXAlignment", "Right"),
			})
		end
		local view = { Root = slot.Root, Track = track, Fill = fill, Value = valueLabel }
		view.Apply = function(self, state, renderCtx)
			local ratio = math.max(0, math.min(1, tonumber(state.Value) or 0))
			Surface.animate(renderCtx, self.Fill, { Size = renderCtx.Host.udim2(ratio, 0, 1, 0) })
			if self.Value then
				self.Value.Text = ("%d%%"):format(math.floor(ratio * 100 + 0.5))
			end
		end
		return view
	end,
}

styles[#styles + 1] = {
	Id = "progressbar.segmented", Name = "Segmented bar", Component = "ProgressBar", Category = "Display",
	Description = "Discrete segments that light up left to right.",
	Tags = { "segments" },
	Render = function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local width = config.Width or 180
		local height = config.Height or 10
		local count = math.max(2, config.Segments or 10)
		local slot = Surface.slot(ctx, { Height = config.RowHeight or 26, ControlWidth = width })
		local parent = slot.ControlArea or slot.Root
		local holder = host.new("Frame", {
			Name = "Track",
			BackgroundTransparency = 1,
			Size = host.udim2(0, width, 0, height),
			Position = host.udim2(1, -width, 0.5, -height / 2),
		}, parent)
		local segments = {}
		local cell = math.floor((width - (count - 1) * 2) / count)
		for index = 1, count do
			local segment = host.new("Frame", {
				Name = "Segment" .. tostring(index),
				BackgroundColor3 = Surface.color(ctx, config.FillColor, "Accent"),
				BackgroundTransparency = 0.75,
				BorderSizePixel = 0,
				Size = host.udim2(0, cell, 1, 0),
				Position = host.udim2(0, (index - 1) * (cell + 2), 0, 0),
			}, holder)
			Helpers.corner(host, segment, 2)
			segments[index] = segment
		end
		local view = { Root = slot.Root, Segments = segments, Count = count }
		view.Apply = function(self, state)
			local ratio = math.max(0, math.min(1, tonumber(state.Value) or 0))
			local active = math.floor(ratio * self.Count + 0.5)
			for index, segment in ipairs(self.Segments) do
				segment.BackgroundTransparency = index <= active and 0 or 0.75
			end
		end
		return view
	end,
}

styles[#styles + 1] = {
	Id = "loader.spinner", Name = "Spinner", Component = "Loader", Category = "Display",
	Description = "Rotating ring driven by one Heartbeat connection.",
	Tags = { "default" },
	Render = function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local size = config.Size or 16
		local slot = Surface.slot(ctx, { Height = config.RowHeight or 24, ControlWidth = size })
		local parent = slot.ControlArea or slot.Root
		local spinner = host.new("Frame", {
			Name = "Spinner",
			BackgroundTransparency = 1,
			Size = host.udim2(0, size, 0, size),
			Position = host.udim2(1, -size, 0.5, -size / 2),
		}, parent)
		local ring = host.new("Frame", {
			Name = "Ring",
			BackgroundTransparency = 1,
			Size = host.udim2(1, 0, 1, 0),
		}, spinner)
		Helpers.corner(host, ring, size / 2)
		Helpers.stroke(host, ring, Surface.color(ctx, config.Color, "Accent"), math.max(1, size / 8), 0.25)
		local dotSize = math.max(3, size / 4)
		local dot = host.new("Frame", {
			Name = "Dot",
			BackgroundColor3 = Surface.color(ctx, config.Color, "Accent"),
			BorderSizePixel = 0,
			Size = host.udim2(0, dotSize, 0, dotSize),
			Position = host.udim2(0.5, -dotSize / 2, 0, 0),
		}, spinner)
		Helpers.corner(host, dot, dotSize / 2)
		local rotation = 0
		local speed = config.Speed or 1
		local connection = host.heartbeat(function(delta)
			rotation = (rotation + delta * 180 * speed) % 360
			spinner.Rotation = rotation
		end)
		local view = { Root = slot.Root, Spinner = spinner, Connection = connection }
		view.Apply = function(self, state)
			self.Spinner.Visible = state.Enabled ~= false
		end
		view.Dispose = function(self)
			if self.Connection then
				self.Connection:Disconnect()
			end
		end
		return view
	end,
}

styles[#styles + 1] = {
	Id = "loader.dots", Name = "Dots", Component = "Loader", Category = "Display",
	Description = "Pulsing dots animated from one Heartbeat connection.",
	Tags = { "dots" },
	Render = function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local size = math.max(6, (config.Size or 16) * 0.6)
		local count = math.max(1, config.Dots or 3)
		local total = count * (size + 6)
		local slot = Surface.slot(ctx, { Height = config.RowHeight or 24, ControlWidth = total })
		local parent = slot.ControlArea or slot.Root
		local holder = host.new("Frame", {
			Name = "Dots",
			BackgroundTransparency = 1,
			Size = host.udim2(0, total, 0, size),
			Position = host.udim2(1, -total, 0.5, -size / 2),
		}, parent)
		local dots = {}
		for index = 1, count do
			local dot = host.new("Frame", {
				Name = "Dot" .. tostring(index),
				BackgroundColor3 = Surface.color(ctx, config.Color, "Accent"),
				BorderSizePixel = 0,
				Size = host.udim2(0, size, 0, size),
				Position = host.udim2(0, (index - 1) * (size + 6), 0, 0),
			}, holder)
			Helpers.corner(host, dot, size / 2)
			dots[index] = dot
		end
		local phase = 0
		local speed = config.Speed or 1
		local connection = host.heartbeat(function(delta)
			phase = (phase + delta * speed) % 1
			for index, dot in ipairs(dots) do
				local offset = (index - 1) / #dots
				local wave = math.abs(((phase + offset) % 1) - 0.5) * 2
				dot.BackgroundTransparency = 0.2 + wave * 0.6
			end
		end)
		local view = { Root = slot.Root, Dots = dots, Connection = connection }
		view.Apply = function()
			-- Animated entirely by the Heartbeat connection.
		end
		view.Dispose = function(self)
			if self.Connection then
				self.Connection:Disconnect()
			end
		end
		return view
	end,
}

styles[#styles + 1] = {
	Id = "image.plain", Name = "Plain image", Component = "Image", Category = "Display",
	Description = "Image asset with optional rounding and tint.",
	Tags = { "default" },
	Render = function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local size = config.Size or 32
		local slot = Surface.slot(ctx, { Height = config.RowHeight or 32, ControlWidth = size })
		local parent = slot.ControlArea or slot.Root
		local image = host.new("ImageLabel", {
			Name = "Image",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = host.udim2(0, size, 0, size),
			Position = host.udim2(1, -size, 0.5, -size / 2),
			Image = ctx.Props.Icon or "",
			ImageColor3 = Surface.color(ctx, config.ImageColor, "Text"),
			ImageTransparency = config.Transparency or 0,
			ScaleType = host.enumItem("ScaleType", "Fit"),
		}, parent)
		Helpers.corner(host, image, config.CornerRadius)
		local view = { Root = slot.Root, Image = image }
		view.Apply = function(self, state)
			self.Image.ImageTransparency = state.Enabled
				and (ctx.Configuration.Transparency or 0)
				or math.max(0, (ctx.Configuration.Transparency or 0) + 0.5)
		end
		view.SetName = function(self, name)
			self.Image.Image = name
		end
		return view
	end,
}

local registered, failures = Registry.registerMany(styles, { BuiltIn = true })
for _, failure in ipairs(failures) do
	error(("NEVAHEXUI: display style %s failed to register: %s"):format(tostring(failure.Id), table.concat(failure.Errors, "; ")))
end

return registered
