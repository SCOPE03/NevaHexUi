--[[
	NEVAHEXUI - Styles/Defs/Sliders
	Slider and RangeSlider descriptors and styles. The filled, neon and minimal
	styles share the track + handle composition but differ in geometry, glow,
	value display and decoration; the stepped style is a separate implementation
	with tick marks and named stops.
]]

local Registry = require("NEVA:Styles/Registry")
local Surface = require("NEVA:Styles/Surface")
local Helpers = require("NEVA:Styles/Helpers")

local SLIDER_PROPERTIES = {
	{ Key = "RowHeight", Type = "number", Default = 34, Min = 20, Max = 120, Group = "Geometry" },
	{ Key = "Width", Type = "number", Default = 180, Min = 60, Max = 600, Group = "Geometry", Description = "Track width in pixels." },
	{ Key = "TrackHeight", Type = "number", Default = 6, Min = 1, Max = 32, Group = "Geometry" },
	{ Key = "HandleSize", Type = "number", Default = 14, Min = 4, Max = 48, Group = "Geometry" },
	{ Key = "TrackColor", Type = "color", Group = "Appearance" },
	{ Key = "FillColor", Type = "color", Group = "Appearance" },
	{ Key = "HandleColor", Type = "color", Group = "Appearance" },
	{ Key = "TextColor", Type = "color", Group = "Typography" },
	{ Key = "ShowValue", Type = "boolean", Default = true, Group = "Behaviour" },
	{ Key = "Suffix", Type = "string", Default = "", Group = "Behaviour" },
	{ Key = "ValueFormat", Type = "string", Default = "%s", Group = "Behaviour" },
	{ Key = "Glow", Type = "boolean", Default = false, Group = "Appearance" },
	{ Key = "StrokeColor", Type = "color", Group = "Appearance" },
	{ Key = "Step", Type = "number", Default = 0, Min = 0, Group = "Behaviour" },
	{ Key = "Precision", Type = "number", Default = 0, Min = 0, Max = 4, Group = "Behaviour" },
	{ Key = "Animation", Type = "animation", Default = "quick", Group = "Animation" },
	{ Key = "AnimationDuration", Type = "number", Min = 0, Max = 2, Group = "Animation" },
	{ Key = "Stops", Type = "colorArray", Group = "Advanced", Max = 8, Description = "Named colour stops rendered by the stepped style." },
}

Registry.registerComponent({
	Name = "Slider",
	RegistryName = "Sliders",
	Category = "Controls",
	Description = "Continuous numeric input. Value is a number between Min and Max.",
	Defaults = {
		RowHeight = 34,
		Width = 180,
		TrackHeight = 6,
		HandleSize = 14,
		ShowValue = true,
		Animation = "quick",
		Step = 0,
		Precision = 0,
	},
	Properties = SLIDER_PROPERTIES,
})

Registry.registerComponent({
	Name = "RangeSlider",
	RegistryName = "RangeSliders",
	Category = "Controls",
	Description = "Two-handed numeric range. Value is { Low = number, High = number }.",
	Defaults = {
		RowHeight = 34,
		Width = 180,
		TrackHeight = 6,
		HandleSize = 14,
		ShowValue = true,
		Animation = "quick",
	},
	Properties = SLIDER_PROPERTIES,
})

local function fraction(state, value)
	local minimum = state.Min or 0
	local maximum = state.Max or 100
	if maximum == minimum then
		return 0
	end
	return math.max(0, math.min(1, (value - minimum) / (maximum - minimum)))
end

local function buildTrack(ctx, options)
	local config = ctx.Configuration
	local host = ctx.Host
	local width = config.Width or 180
	local trackHeight = config.TrackHeight or 6
	local handleSize = config.HandleSize or 14
	local slot = Surface.slot(ctx, {
		Height = config.RowHeight or 34,
		ControlWidth = width + (config.ShowValue ~= false and 52 or 0),
	})
	local parent = slot.ControlArea or slot.Root
	local track = Surface.panel(ctx, parent, {
		Name = "Track",
		Background = config.TrackColor,
		Token = "Outline",
		Transparency = 0.25,
		CornerRadius = math.max(1, trackHeight / 2),
	})
	track.Size = host.udim2(0, width, 0, trackHeight)
	track.Position = host.udim2(0, 0, 0.5, -trackHeight / 2)
	local fill = host.new("Frame", {
		Name = "Fill",
		BackgroundColor3 = Surface.color(ctx, config.FillColor, "Accent"),
		BorderSizePixel = 0,
		Size = host.udim2(0, 0, 1, 0),
		ClipsDescendants = true,
	}, track)
	Helpers.corner(host, fill, math.max(1, trackHeight / 2))
	local handle = host.new("Frame", {
		Name = "Handle",
		BackgroundColor3 = Surface.color(ctx, config.HandleColor, "Text"),
		BorderSizePixel = 0,
		Size = host.udim2(0, handleSize, 0, handleSize),
		Position = host.udim2(0, -handleSize / 2, 0.5, -handleSize / 2),
		ZIndex = 3,
	}, track)
	Helpers.corner(host, handle, config.SquareHandle == true and math.max(1, handleSize / 4) or handleSize / 2)
	if config.StrokeColor then
		Helpers.stroke(host, handle, Surface.color(ctx, config.StrokeColor, "Outline"), 1, 0)
	end
	local glow
	if config.Glow then
		glow = host.new("Frame", {
			Name = "Glow",
			BackgroundColor3 = Surface.color(ctx, config.FillColor, "Accent"),
			BackgroundTransparency = 0.7,
			BorderSizePixel = 0,
			Size = host.udim2(0, handleSize + 8, 0, handleSize + 8),
			Position = host.udim2(0, -(handleSize + 8) / 2, 0.5, -(handleSize + 8) / 2),
			ZIndex = 2,
		}, track)
		Helpers.corner(host, glow, (handleSize + 8) / 2)
	end
	local valueLabel
	if config.ShowValue ~= false then
		valueLabel = Surface.text(ctx, parent, {
			Name = "Value",
			Size = host.udim2(0, 48, 1, 0),
			Position = host.udim2(1, -48, 0, 0),
			Text = "",
			TextColor3 = Surface.color(ctx, config.TextColor, "Text"),
			TextSize = math.max(10, (config.RowHeight or 34) - 22),
			TextXAlignment = host.enumItem("TextXAlignment", "Right"),
		})
	end
	local input = Surface.hit(ctx, track, {
		Name = "Input",
		Size = host.udim2(1, 0, 0, handleSize + 10),
		Position = host.udim2(0, 0, 0.5, -(handleSize + 10) / 2),
		ZIndex = 4,
	})
	local view = {
		Root = slot.Root,
		Input = input,
		Track = track,
		Fill = fill,
		Handle = handle,
		Glow = glow,
		Value = valueLabel,
		TrackWidth = width,
		HandleSize = handleSize,
	}
	return view, slot
end

local function paintSlider(view, state, ctx, suffix)
	local config = ctx.Configuration
	local position = fraction(state, state.Value)
	Surface.animate(ctx, view.Fill, { Size = ctx.Host.udim2(position, 0, 1, 0) })
	Surface.animate(ctx, view.Handle, {
		Position = ctx.Host.udim2(position, -view.HandleSize / 2, 0.5, -view.HandleSize / 2),
	})
	local colour = Surface.color(ctx, config.FillColor, "Accent")
	if not state.Enabled then
		colour = Surface.disabledColour(ctx, colour)
	end
	view.Fill.BackgroundColor3 = colour
	view.Handle.BackgroundColor3 = state.Enabled
		and Surface.color(ctx, config.HandleColor, "Text")
		or Surface.disabledText(ctx, Surface.color(ctx, config.HandleColor, "Text"))
	if view.Glow then
		view.Glow.BackgroundTransparency = state.Enabled and 0.55 or 0.85
	end
	if view.Value then
		local text = tostring(state.Value)
		if config.ValueFormat and config.ValueFormat ~= "%s" then
			local ok, formatted = pcall(string.format, config.ValueFormat, state.Value)
			text = ok and formatted or text
		end
		view.Value.Text = text .. (suffix or config.Suffix or "")
	end
end

local styles = {}

styles[#styles + 1] = {
	Id = "slider.filled",
	Name = "Filled slider",
	Component = "Slider",
	Category = "Controls",
	Description = "Rounded track filled with the accent colour and a circular handle.",
	Tags = { "default", "filled" },
	Render = function(ctx)
		local view = buildTrack(ctx)
		view.Apply = function(self, state, renderCtx)
			paintSlider(self, state, renderCtx)
		end
		return view
	end,
}

styles[#styles + 1] = {
	Id = "slider.neon",
	Name = "Neon slider",
	Component = "Slider",
	Category = "Controls",
	Description = "Glowing accent fill with a halo around the handle.",
	Tags = { "neon", "glow" },
	Render = function(ctx)
		local view = buildTrack(ctx)
		if not view.Glow then
			local host = ctx.Host
			view.Glow = host.new("Frame", {
				Name = "Glow",
				BackgroundColor3 = Surface.color(ctx, ctx.Configuration.FillColor, "Accent"),
				BackgroundTransparency = 0.7,
				BorderSizePixel = 0,
				Size = host.udim2(0, view.HandleSize + 10, 0, view.HandleSize + 10),
				Position = host.udim2(0, -(view.HandleSize + 10) / 2, 0.5, -(view.HandleSize + 10) / 2),
				ZIndex = 2,
			}, view.Track)
			Helpers.corner(host, view.Glow, (view.HandleSize + 10) / 2)
		end
		view.Apply = function(self, state, renderCtx)
			paintSlider(self, state, renderCtx)
			local position = fraction(state, state.Value)
			if self.Glow then
				Surface.animate(renderCtx, self.Glow, {
					Position = renderCtx.Host.udim2(position, -(self.HandleSize + 10) / 2, 0.5, -(self.HandleSize + 10) / 2),
				})
			end
		end
		return view
	end,
}

styles[#styles + 1] = {
	Id = "slider.minimal",
	Name = "Minimal slider",
	Component = "Slider",
	Category = "Controls",
	Description = "Hairline track with a small square handle and no fill gradient.",
	Tags = { "minimal" },
	Render = function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local width = config.Width or 180
		local slot = Surface.slot(ctx, {
			Height = config.RowHeight or 34,
			ControlWidth = width + (config.ShowValue ~= false and 44 or 0),
		})
		local parent = slot.ControlArea or slot.Root
		local line = host.new("Frame", {
			Name = "Track",
			BackgroundColor3 = Surface.color(ctx, config.TrackColor, "Outline"),
			BorderSizePixel = 0,
			Size = host.udim2(0, width, 0, 1),
			Position = host.udim2(0, 0, 0.5, 0),
		}, parent)
		local fill = host.new("Frame", {
			Name = "Fill",
			BackgroundColor3 = Surface.color(ctx, config.FillColor, "Accent"),
			BorderSizePixel = 0,
			Size = host.udim2(0, 0, 1, 0),
		}, line)
		local handle = host.new("Frame", {
			Name = "Handle",
			BackgroundColor3 = Surface.color(ctx, config.HandleColor, "Accent"),
			BorderSizePixel = 0,
			Size = host.udim2(0, 6, 0, 16),
			Position = host.udim2(0, -3, 0.5, -8),
			ZIndex = 2,
		}, line)
		Helpers.corner(host, handle, 1)
		local valueLabel
		if config.ShowValue ~= false then
			valueLabel = Surface.text(ctx, parent, {
				Name = "Value",
				Size = host.udim2(0, 40, 1, 0),
				Position = host.udim2(1, -40, 0, 0),
				TextColor3 = Surface.color(ctx, config.TextColor, "TextMuted"),
				TextXAlignment = host.enumItem("TextXAlignment", "Right"),
			})
		end
		local input = Surface.hit(ctx, line, {
			Name = "Input",
			Size = host.udim2(1, 0, 0, 24),
			Position = host.udim2(0, 0, 0.5, -12),
			ZIndex = 3,
		})
		local view = {
			Root = slot.Root,
			Input = input,
			Track = line,
			Fill = fill,
			Handle = handle,
			Value = valueLabel,
			TrackWidth = width,
			HandleSize = 6,
		}
		view.Apply = function(self, state, renderCtx)
			local position = fraction(state, state.Value)
			self.Fill.Size = renderCtx.Host.udim2(position, 0, 1, 0)
			Surface.animate(renderCtx, self.Handle, {
				Position = renderCtx.Host.udim2(position, -3, 0.5, -8),
			})
			if self.Value then
				self.Value.Text = tostring(state.Value)
			end
		end
		return view
	end,
}

styles[#styles + 1] = {
	Id = "slider.stepped",
	Name = "Stepped slider",
	Component = "Slider",
	Category = "Controls",
	Description = "Track with labelled tick stops and a discrete handle.",
	Tags = { "stops", "ticks" },
	Render = function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local width = config.Width or 180
		local trackHeight = config.TrackHeight or 8
		local handleSize = config.HandleSize or 16
		local stops = ctx.State.Stops or {}
		local slot = Surface.slot(ctx, {
			Height = config.RowHeight or 40,
			ControlWidth = width + (config.ShowValue ~= false and 56 or 0),
			Description = (config.Suffix ~= nil and config.Suffix ~= "") and ("Step: " .. tostring(config.Suffix)) or nil,
		})
		local parent = slot.ControlArea or slot.Root
		local track = Surface.panel(ctx, parent, {
			Name = "Track",
			Background = config.TrackColor,
			Token = "Outline",
			Transparency = 0.35,
			CornerRadius = trackHeight / 2,
		})
		track.Size = host.udim2(0, width, 0, trackHeight)
		track.Position = host.udim2(0, 0, 0.5, -trackHeight / 2)
		local fill = host.new("Frame", {
			Name = "Fill",
			BackgroundColor3 = Surface.color(ctx, config.FillColor, "Accent"),
			BorderSizePixel = 0,
			Size = host.udim2(0, 0, 1, 0),
		}, track)
		Helpers.corner(host, fill, trackHeight / 2)
		local tickCount = math.max(2, #stops > 0 and #stops or 5)
		local ticks = {}
		for index = 0, tickCount - 1 do
			local ratio = tickCount == 1 and 0 or index / (tickCount - 1)
			local tick = host.new("Frame", {
				Name = "Tick" .. tostring(index),
				BackgroundColor3 = Surface.color(ctx, config.HandleColor, "TextMuted"),
				BackgroundTransparency = 0.4,
				BorderSizePixel = 0,
				Size = host.udim2(0, 2, 0, 6),
				Position = host.udim2(ratio, -1, 0.5, trackHeight / 2 + 4),
			}, track)
			ticks[index + 1] = tick
			if #stops > 0 and stops[index + 1] then
				local label = Surface.text(ctx, track, {
					Name = "StopLabel" .. tostring(index),
					Size = host.udim2(0, 40, 0, 10),
					Position = host.udim2(ratio, -20, 1, 8),
					Text = stops[index + 1]:ToHex(),
					TextColor3 = stops[index + 1] and ctx.Host.color(stops[index + 1].R * 255, stops[index + 1].G * 255, stops[index + 1].B * 255) or ctx.Tokens.TextMuted,
					TextSize = 9,
					TextXAlignment = host.enumItem("TextXAlignment", "Center"),
				})
				label.Text = ""
			end
		end
		local handle = host.new("Frame", {
			Name = "Handle",
			BackgroundColor3 = Surface.color(ctx, config.HandleColor, "Accent"),
			BorderSizePixel = 0,
			Size = host.udim2(0, handleSize, 0, handleSize),
			Position = host.udim2(0, -handleSize / 2, 0.5, -handleSize / 2),
			ZIndex = 3,
		}, track)
		Helpers.corner(host, handle, 3)
		local valueLabel
		if config.ShowValue ~= false then
			valueLabel = Surface.text(ctx, parent, {
				Name = "Value",
				Size = host.udim2(0, 52, 1, 0),
				Position = host.udim2(1, -52, 0, 0),
				TextColor3 = Surface.color(ctx, config.TextColor, "Text"),
				TextXAlignment = host.enumItem("TextXAlignment", "Right"),
			})
		end
		local input = Surface.hit(ctx, track, {
			Name = "Input",
			Size = host.udim2(1, 0, 0, 24),
			Position = host.udim2(0, 0, 0.5, -12),
			ZIndex = 4,
		})
		local view = {
			Root = slot.Root,
			Input = input,
			Track = track,
			Fill = fill,
			Handle = handle,
			Value = valueLabel,
			TrackWidth = width,
			HandleSize = handleSize,
			Ticks = ticks,
		}
		view.Apply = function(self, state, renderCtx)
			local position = fraction(state, state.Value)
			self.Fill.Size = renderCtx.Host.udim2(position, 0, 1, 0)
			self.Handle.Position = renderCtx.Host.udim2(position, -self.HandleSize / 2, 0.5, -self.HandleSize / 2)
			if self.Value then
				self.Value.Text = tostring(state.Value) .. (renderCtx.Configuration.Suffix or "")
			end
		end
		return view
	end,
}

local function rangeRender(options)
	return function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local width = config.Width or 180
		local trackHeight = config.TrackHeight or 6
		local handleSize = config.HandleSize or 14
		local slot = Surface.slot(ctx, {
			Height = config.RowHeight or 34,
			ControlWidth = width + (config.ShowValue ~= false and 76 or 0),
		})
		local parent = slot.ControlArea or slot.Root
		local track = Surface.panel(ctx, parent, {
			Name = "Track",
			Background = config.TrackColor,
			Token = "Outline",
			Transparency = 0.25,
			CornerRadius = trackHeight / 2,
		})
		track.Size = host.udim2(0, width, 0, trackHeight)
		track.Position = host.udim2(0, 0, 0.5, -trackHeight / 2)
		local selection = host.new("Frame", {
			Name = "Selection",
			BackgroundColor3 = Surface.color(ctx, config.FillColor, "Accent"),
			BorderSizePixel = 0,
			Size = host.udim2(0, 0, 1, 0),
		}, track)
		Helpers.corner(host, selection, trackHeight / 2)
		local handles = {}
		for index = 1, 2 do
			local handle = host.new("Frame", {
				Name = index == 1 and "HandleLow" or "HandleHigh",
				BackgroundColor3 = Surface.color(ctx, config.HandleColor, "Text"),
				BorderSizePixel = 0,
				Size = host.udim2(0, handleSize, 0, handleSize),
				Position = host.udim2(0, -handleSize / 2, 0.5, -handleSize / 2),
				ZIndex = 3,
			}, track)
			Helpers.corner(host, handle, options.square and 2 or handleSize / 2)
			handles[index] = handle
		end
		local valueLabel
		if config.ShowValue ~= false then
			valueLabel = Surface.text(ctx, parent, {
				Name = "Value",
				Size = host.udim2(0, 72, 1, 0),
				Position = host.udim2(1, -72, 0, 0),
				TextColor3 = Surface.color(ctx, config.TextColor, "Text"),
				TextXAlignment = host.enumItem("TextXAlignment", "Right"),
			})
		end
		local input = Surface.hit(ctx, track, {
			Name = "Input",
			Size = host.udim2(1, 0, 0, handleSize + 10),
			Position = host.udim2(0, 0, 0.5, -(handleSize + 10) / 2),
			ZIndex = 4,
		})
		local view = {
			Root = slot.Root,
			Input = input,
			Track = track,
			Selection = selection,
			HandleLow = handles[1],
			HandleHigh = handles[2],
			Value = valueLabel,
			TrackWidth = width,
			HandleSize = handleSize,
		}
		view.Apply = function(self, state, renderCtx)
			local value = state.Value or {}
			local low = value.Low or state.Min or 0
			local high = value.High or state.Max or 100
			local lowFraction = fraction(state, low)
			local highFraction = fraction(state, math.max(high, low))
			self.Selection.Position = renderCtx.Host.udim2(lowFraction, 0, 0, 0)
			self.Selection.Size = renderCtx.Host.udim2(highFraction - lowFraction, 0, 1, 0)
			self.HandleLow.Position = renderCtx.Host.udim2(lowFraction, -self.HandleSize / 2, 0.5, -self.HandleSize / 2)
			self.HandleHigh.Position = renderCtx.Host.udim2(highFraction, -self.HandleSize / 2, 0.5, -self.HandleSize / 2)
			if self.Value then
				self.Value.Text = ("%s - %s"):format(tostring(low), tostring(high))
			end
		end
		return view
	end
end

styles[#styles + 1] = {
	Id = "rangeslider.dual",
	Name = "Dual range",
	Component = "RangeSlider",
	Category = "Controls",
	Description = "Two circular handles with an accent selection between them.",
	Render = rangeRender({}),
}

styles[#styles + 1] = {
	Id = "rangeslider.compact",
	Name = "Compact range",
	Component = "RangeSlider",
	Category = "Controls",
	Description = "Square handles for dense toolbars.",
	Render = rangeRender({ square = true }),
}

local registered, failures = Registry.registerMany(styles, { BuiltIn = true })
for _, failure in ipairs(failures) do
	error(("NEVAHEXUI: sliders style %s failed to register: %s"):format(tostring(failure.Id), table.concat(failure.Errors, "; ")))
end

return registered
