--[[
	NEVAHEXUI - Styles/Defs/DataViews
	Descriptors and renderers for the data-oriented display components: Table,
	TreeView, LogView and Graph. Each exposes a single renderer because these
	categories have one genuinely distinct presentation each (documented in the
	style catalog rather than padded with near-identical variants).
]]

local Registry = require("NEVA:Styles/Registry")
local Surface = require("NEVA:Styles/Surface")
local Helpers = require("NEVA:Styles/Helpers")

Registry.registerComponent({
	Name = "Table", RegistryName = "Tables", Category = "Display",
	Description = "Columnar data list with a header row.",
	Defaults = { RowHeight = 26, HeaderHeight = 28, MaxRows = 8, Stripe = true, TextSize = 12 },
	Properties = {
		{ Key = "RowHeight", Type = "number", Default = 26, Min = 16, Max = 80, Group = "Geometry" },
		{ Key = "HeaderHeight", Type = "number", Default = 28, Min = 16, Max = 80, Group = "Geometry" },
		{ Key = "MaxRows", Type = "number", Default = 8, Min = 1, Max = 100, Group = "Behaviour" },
		{ Key = "RowColor", Type = "color", Group = "Appearance" },
		{ Key = "AltRowColor", Type = "color", Group = "Appearance" },
		{ Key = "HeaderColor", Type = "color", Group = "Appearance" },
		{ Key = "TextColor", Type = "color", Group = "Typography" },
		{ Key = "TextSize", Type = "number", Default = 12, Min = 8, Max = 24, Group = "Typography" },
		{ Key = "Stripe", Type = "boolean", Default = true, Group = "Appearance" },
	},
})

Registry.registerComponent({
	Name = "TreeView", RegistryName = "TreeViews", Category = "Display",
	Description = "Expandable node hierarchy.",
	Defaults = { RowHeight = 24, Indent = 14, ExpandGlyph = "+", CollapseGlyph = "-", TextSize = 13 },
	Properties = {
		{ Key = "RowHeight", Type = "number", Default = 24, Min = 14, Max = 64, Group = "Geometry" },
		{ Key = "Indent", Type = "number", Default = 14, Min = 0, Max = 48, Group = "Geometry" },
		{ Key = "TextSize", Type = "number", Default = 13, Min = 8, Max = 24, Group = "Typography" },
		{ Key = "TextColor", Type = "color", Group = "Typography" },
		{ Key = "SelectedColor", Type = "color", Group = "States" },
		{ Key = "ExpandGlyph", Type = "string", Default = "+", Group = "Appearance" },
		{ Key = "CollapseGlyph", Type = "string", Default = "-", Group = "Appearance" },
	},
})

Registry.registerComponent({
	Name = "LogView", RegistryName = "LogViews", Category = "Display",
	Description = "Append-only console output.",
	Defaults = { RowHeight = 120, MaxLines = 6, Monospace = true, Transparency = 0.1, TextSize = 12 },
	Properties = {
		{ Key = "RowHeight", Type = "number", Default = 120, Min = 40, Max = 600, Group = "Geometry" },
		{ Key = "MaxLines", Type = "number", Default = 6, Min = 1, Max = 200, Group = "Behaviour" },
		{ Key = "BackgroundColor", Type = "color", Group = "Appearance" },
		{ Key = "Transparency", Type = "number", Min = 0, Max = 1, Step = 0.01, Default = 0.1, Group = "Appearance" },
		{ Key = "TextColor", Type = "color", Group = "Typography" },
		{ Key = "MutedColor", Type = "color", Group = "Typography" },
		{ Key = "TextSize", Type = "number", Default = 12, Min = 8, Max = 24, Group = "Typography" },
		{ Key = "Monospace", Type = "boolean", Default = true, Group = "Typography" },
	},
})

Registry.registerComponent({
	Name = "Graph", RegistryName = "Graphs", Category = "Display",
	Description = "Stepped line graph for a numeric series.",
	Defaults = { RowHeight = 120, Points = 24, LineHeight = 2, ShowGrid = true },
	Properties = {
		{ Key = "RowHeight", Type = "number", Default = 120, Min = 40, Max = 600, Group = "Geometry" },
		{ Key = "Points", Type = "number", Default = 24, Min = 4, Max = 200, Group = "Geometry" },
		{ Key = "LineColor", Type = "color", Group = "Appearance" },
		{ Key = "GridColor", Type = "color", Group = "Appearance" },
		{ Key = "LineHeight", Type = "number", Default = 2, Min = 1, Max = 8, Group = "Appearance" },
		{ Key = "ShowGrid", Type = "boolean", Default = true, Group = "Appearance" },
	},
})

local styles = {}

styles[#styles + 1] = {
	Id = "table.data", Name = "Data table", Component = "Table", Category = "Display",
	Description = "Header row plus striped data rows fed from the value array.",
	Tags = { "default" },
	Render = function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local columns = ctx.State.Columns or {}
		local rows = ctx.State.Value or {}
		local rowHeight = config.RowHeight or 26
		local headerHeight = config.HeaderHeight or 28
		local visible = math.max(1, math.min(#rows, config.MaxRows or 8))
		local slot = Surface.slot(ctx, { Height = headerHeight + visible * rowHeight + 8, Label = false })
		local holder = host.new("Frame", {
			Name = "Table",
			BackgroundColor3 = config.RowColor and Surface.color(ctx, config.RowColor, "SurfaceAlt") or ctx.Tokens.SurfaceAlt,
			BackgroundTransparency = 0.15,
			BorderSizePixel = 0,
			Size = host.udim2(1, 0, 1, 0),
			ClipsDescendants = true,
		}, slot.Root)
		Helpers.corner(host, holder, ctx.Tokens.CornerRadius)
		Helpers.stroke(host, holder, ctx.Tokens.Outline, 1, 0.4)
		local header = host.new("Frame", {
			Name = "Header",
			BackgroundColor3 = config.HeaderColor and Surface.color(ctx, config.HeaderColor, "Surface") or ctx.Tokens.Surface,
			BackgroundTransparency = 0.2,
			BorderSizePixel = 0,
			Size = host.udim2(1, 0, 0, headerHeight),
		}, holder)
		local columnWidth = 1 / math.max(1, #columns)
		for index, column in ipairs(columns) do
			Surface.text(ctx, header, {
				Name = "Header" .. tostring(index),
				Size = host.udim2(columnWidth, -8, 1, 0),
				Position = host.udim2(columnWidth * (index - 1), 4, 0, 0),
				Text = tostring(column),
				TextColor3 = ctx.Tokens.TextMuted,
				Font = ctx.Tokens.FontBold,
				TextSize = config.TextSize or 12,
				TextTruncate = host.enumItem("TextTruncate", "AtEnd"),
			})
		end
		local rowViews = {}
		for rowIndex = 1, visible do
			local row = host.new("Frame", {
				Name = "Row" .. tostring(rowIndex),
				BackgroundColor3 = (config.Stripe ~= false and rowIndex % 2 == 0)
					and (config.AltRowColor and Surface.color(ctx, config.AltRowColor, "Surface") or ctx.Tokens.Surface)
					or ctx.Tokens.SurfaceAlt,
				BackgroundTransparency = 0.35,
				BorderSizePixel = 0,
				Size = host.udim2(1, 0, 0, rowHeight),
				Position = host.udim2(0, 0, 0, headerHeight + (rowIndex - 1) * rowHeight),
			}, holder)
			local cells = {}
			for columnIndex = 1, math.max(1, #columns) do
				cells[columnIndex] = Surface.text(ctx, row, {
					Name = "Cell" .. tostring(columnIndex),
					Size = host.udim2(columnWidth, -8, 1, 0),
					Position = host.udim2(columnWidth * (columnIndex - 1), 4, 0, 0),
					Text = "",
					TextColor3 = Surface.color(ctx, config.TextColor, "Text"),
					TextSize = config.TextSize or 12,
					TextTruncate = host.enumItem("TextTruncate", "AtEnd"),
				})
			end
			rowViews[rowIndex] = { Row = row, Cells = cells }
		end
		local view = { Root = slot.Root, Holder = holder, Rows = rowViews }
		view.Apply = function(self, state)
			local data = type(state.Value) == "table" and state.Value or {}
			for rowIndex, entry in ipairs(self.Rows) do
				local row = data[rowIndex]
				entry.Row.Visible = row ~= nil
				for columnIndex, cell in ipairs(entry.Cells) do
					local value = row and row[columnIndex]
					cell.Text = value == nil and "" or tostring(value)
				end
			end
		end
		return view
	end,
}

styles[#styles + 1] = {
	Id = "treeview.plain", Name = "Plain tree", Component = "TreeView", Category = "Display",
	Description = "Flattened node list with expand and collapse glyphs.",
	Tags = { "default" },
	Render = function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local nodes = ctx.State.Nodes or {}
		local rowHeight = config.RowHeight or 24
		local indent = config.Indent or 14
		local slot = Surface.slot(ctx, { Height = math.max(rowHeight, math.max(1, #nodes) * rowHeight), Label = false })
		local holder = host.new("Frame", {
			Name = "Nodes",
			BackgroundTransparency = 1,
			Size = host.udim2(1, 0, 1, 0),
		}, slot.Root)
		local rows = {}
		for index, node in ipairs(nodes) do
			local depth = node.Depth or 0
			local row = Surface.hit(ctx, holder, {
				Name = "Node" .. tostring(index),
				Size = host.udim2(1, -(depth * indent), 0, rowHeight),
				Position = host.udim2(0, depth * indent, 0, (index - 1) * rowHeight),
				BackgroundTransparency = 1,
			})
			local glyph = Surface.text(ctx, row, {
				Name = "Glyph",
				Size = host.udim2(0, indent, 1, 0),
				Text = node.HasChildren
					and (node.Expanded and (config.CollapseGlyph or "-") or (config.ExpandGlyph or "+"))
					or "",
				TextColor3 = ctx.Tokens.TextMuted,
				TextSize = math.max(10, rowHeight - 12),
				TextXAlignment = host.enumItem("TextXAlignment", "Center"),
			})
			local label = Surface.text(ctx, row, {
				Name = "Label",
				Size = host.udim2(1, -(indent + 6), 1, 0),
				Position = host.udim2(0, indent + 4, 0, 0),
				Text = tostring(node.Label or ""),
				TextColor3 = Surface.color(ctx, config.TextColor, "Text"),
				TextSize = config.TextSize or 13,
				TextTruncate = host.enumItem("TextTruncate", "AtEnd"),
			})
			rows[index] = { Row = row, Glyph = glyph, Label = label, Node = node }
		end
		local view = {
			Root = slot.Root,
			Rows = rows,
			SelectedColour = Surface.color(ctx, config.SelectedColor, "Accent"),
			IdleColour = Surface.color(ctx, config.TextColor, "Text"),
		}
		view.Apply = function(self, state)
			local selected = state.Value
			for _, entry in ipairs(self.Rows) do
				entry.Label.TextColor3 = (selected ~= nil and entry.Node.Id == selected)
					and self.SelectedColour
					or self.IdleColour
			end
		end
		return view
	end,
}

styles[#styles + 1] = {
	Id = "logview.console", Name = "Console log", Component = "LogView", Category = "Display",
	Description = "Scrollable monospace console with level colouring.",
	Tags = { "default" },
	Render = function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local height = config.RowHeight or 120
		local slot = Surface.slot(ctx, { Height = height, Label = false })
		local panel = Surface.panel(ctx, slot.Root, {
			Name = "Console",
			Background = config.BackgroundColor,
			Token = "Background",
			Transparency = Surface.transparency(ctx, config.Transparency, "BackgroundTransparency", 0.1),
			CornerRadius = ctx.Tokens.CornerRadius,
			Stroke = ctx.Tokens.Outline,
			StrokeThickness = 1,
		})
		panel.Size = host.udim2(1, 0, 1, 0)
		local lines = host.new("ScrollingFrame", {
			Name = "Lines",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = host.udim2(1, -10, 1, -10),
			Position = host.udim2(0, 5, 0, 5),
			ScrollBarThickness = 2,
			CanvasSize = host.udim2(0, 0, 0, 0),
		}, panel)
		host.new("UIListLayout", {
			FillDirection = host.enumItem("FillDirection", "Vertical"),
			SortOrder = host.enumItem("SortOrder", "LayoutOrder"),
		}, lines)
		local rows = {}
		for index = 1, math.max(1, config.MaxLines or 6) do
			rows[index] = Surface.text(ctx, lines, {
				Name = "Line" .. tostring(index),
				Size = host.udim2(1, 0, 0, 15),
				Text = "",
				TextColor3 = Surface.color(ctx, config.TextColor, "Text"),
				Font = config.Monospace ~= false and host.font("Code") or ctx.Tokens.Font,
				TextSize = config.TextSize or 12,
				TextTruncate = host.enumItem("TextTruncate", "AtEnd"),
				LayoutOrder = index,
			})
		end
		local view = {
			Root = slot.Root,
			Lines = rows,
			InfoColour = Surface.color(ctx, config.TextColor, "Text"),
			MutedColour = Surface.color(ctx, config.MutedColor, "TextMuted"),
			WarnColour = ctx.Tokens.Warning,
			ErrorColour = ctx.Tokens.Negative,
		}
		view.Apply = function(self, state)
			local entries = type(state.Value) == "table" and state.Value or {}
			local offset = math.max(0, #entries - #self.Lines)
			for index, label in ipairs(self.Lines) do
				local entry = entries[offset + index]
				if entry then
					label.Text = tostring(entry.Text ~= nil and entry.Text or entry)
					local level = entry.Level or "Info"
					label.TextColor3 = level == "Error" and self.ErrorColour
						or level == "Warn" and self.WarnColour
						or level == "Muted" and self.MutedColour
						or self.InfoColour
					label.Visible = true
				else
					label.Text = ""
					label.Visible = false
				end
			end
		end
		return view
	end,
}

styles[#styles + 1] = {
	Id = "graph.line", Name = "Stepped graph", Component = "Graph", Category = "Display",
	Description = "Grid-backed stepped line graph drawn from bar segments.",
	Tags = { "default" },
	Render = function(ctx)
		local config = ctx.Configuration
		local host = ctx.Host
		local height = config.RowHeight or 120
		local lineHeight = config.LineHeight or 2
		local points = math.max(2, config.Points or 24)
		local steps = points - 1
		local slot = Surface.slot(ctx, { Height = height, Label = false })
		local panel = Surface.panel(ctx, slot.Root, {
			Name = "Graph",
			Background = config.GridColor,
			Token = "Background",
			Transparency = 0.2,
			CornerRadius = ctx.Tokens.CornerRadius,
			Stroke = ctx.Tokens.Outline,
			StrokeThickness = 1,
		})
		panel.Size = host.udim2(1, 0, 1, 0)
		panel.ClipsDescendants = true
		if config.ShowGrid ~= false then
			for index = 1, 3 do
				host.new("Frame", {
					Name = "GridLine" .. tostring(index),
					BackgroundColor3 = ctx.Tokens.Outline,
					BackgroundTransparency = 0.6,
					BorderSizePixel = 0,
					Size = host.udim2(1, 0, 0, 1),
					Position = host.udim2(0, 0, index / 4, 0),
				}, panel)
			end
		end
		local segments = {}
		for index = 1, steps do
			segments[index] = {
				Horizontal = host.new("Frame", {
					Name = "H" .. tostring(index),
					BackgroundColor3 = Surface.color(ctx, config.LineColor, "Accent"),
					BorderSizePixel = 0,
					Size = host.udim2(1 / steps, 0, 0, lineHeight),
					Position = host.udim2((index - 1) / steps, 0, 0, 0),
					AnchorPoint = host.vector2(0, 0.5),
				}, panel),
				Vertical = host.new("Frame", {
					Name = "V" .. tostring(index),
					BackgroundColor3 = Surface.color(ctx, config.LineColor, "Accent"),
					BackgroundTransparency = 0.3,
					BorderSizePixel = 0,
					Size = host.udim2(0, lineHeight, 0, 0),
					Position = host.udim2(index / steps, 0, 0, 0),
					AnchorPoint = host.vector2(0.5, 0.5),
				}, panel),
			}
		end
		local view = {
			Root = slot.Root,
			Panel = panel,
			Segments = segments,
			Steps = steps,
			LineHeight = lineHeight,
			Height = height,
		}
		view.Apply = function(self, state)
			local series = type(state.Value) == "table" and state.Value or {}
			local function sample(index)
				if #series == 0 then
					return 0
				end
				local position = ((index - 1) / self.Steps) * (#series - 1) + 1
				local low = math.floor(position)
				local high = math.min(#series, low + 1)
				local alpha = position - low
				local a = tonumber(series[low]) or 0
				local b = tonumber(series[high]) or a
				return math.max(0, math.min(1, a + (b - a) * alpha))
			end
			for index, segment in ipairs(self.Segments) do
				local value = sample(index)
				local delta = sample(index + 1) - value
				segment.Horizontal.Position = ctx.Host.udim2((index - 1) / self.Steps, 0, 1 - value, 0)
				segment.Vertical.Position = ctx.Host.udim2(index / self.Steps, 0, 1 - value - delta / 2, 0)
				segment.Vertical.Size = ctx.Host.udim2(0, self.LineHeight, 0, math.abs(delta) * self.Height)
			end
		end
		return view
	end,
}

local registered, failures = Registry.registerMany(styles, { BuiltIn = true })
for _, failure in ipairs(failures) do
	error(("NEVAHEXUI: data view style %s failed to register: %s"):format(tostring(failure.Id), table.concat(failure.Errors, "; ")))
end

return registered
