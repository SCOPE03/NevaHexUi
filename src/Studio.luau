--[[
	NEVAHEXUI - Studio
	The interactive Style Studio: a developer tool that browses the real style
	catalogue, renders two live previews of the same component type side by side,
	generates a configuration editor from the selected style's own schema, applies
	styles to a live component, saves presets and exports Luau.

	Every preview is a real component created through the normal pipeline with a
	sandboxed callback, so what the Studio shows is what the library renders.
]]

local Container = require("NEVA:Core/Container")
local Styles = require("NEVA:Styles/Registry")
local Schema = require("NEVA:Styles/Schema")
local Helpers = require("NEVA:Styles/Helpers")
local Surface = require("NEVA:Styles/Surface")

local Studio = {}
Studio.__index = Studio

-- Component types the Studio offers. Every entry is verified to have at least
-- one registered renderer at open time; anything without a renderer is skipped.
local CANDIDATE_TYPES = {
	"Button", "IconButton", "Toggle", "Checkbox", "Radio", "RadioGroup",
	"Slider", "RangeSlider", "Textbox", "NumberInput", "CopyableInput", "Keybind",
	"ColorPicker", "ColorPalette", "Label", "Badge", "ProgressBar", "Loader",
	"Image", "Divider", "Table", "TreeView", "LogView", "Graph",
	"Notification", "Dialog",
}

local CATEGORY_OF_TYPE = {
	Button = "Buttons",
	IconButton = "Buttons",
	Toggle = "Toggles",
	Checkbox = "Toggles",
	Radio = "Toggles",
	RadioGroup = "Toggles",
	Slider = "Sliders",
	RangeSlider = "Sliders",
	Textbox = "Text input",
	NumberInput = "Text input",
	CopyableInput = "Text input",
	Keybind = "Keybinds",
	ColorPicker = "Colour",
	ColorPalette = "Colour",
	Notification = "Feedback",
	Dialog = "Feedback",
}

local function categoryOf(componentType)
	return CATEGORY_OF_TYPE[componentType] or "Display"
end

-- Preview specifications give every type a sane, interactive demo value.
local function previewSpec(componentType, flag, styleId)
	local base = {
		Name = "Studio preview",
		Flag = flag,
		Style = { Id = styleId },
		Callback = function() end,
	}
	if componentType == "Slider" or componentType == "RangeSlider" then
		base.Min = 0
		base.Max = 100
		base.Default = componentType == "RangeSlider" and { Lower = 25, Upper = 70 } or 45
		base.Suffix = "%"
	elseif componentType == "Toggle" or componentType == "Checkbox" or componentType == "Radio" then
		base.Default = true
	elseif componentType == "RadioGroup" then
		base.Options = { "Small", "Medium", "Large" }
		base.Default = "Medium"
	elseif componentType == "Textbox" then
		base.Default = "Editable text"
	elseif componentType == "NumberInput" then
		base.Default = 12
		base.Min = 0
		base.Max = 100
	elseif componentType == "CopyableInput" then
		base.Default = "NEVAHEXUI"
	elseif componentType == "Keybind" then
		base.Default = "F"
		base.Keys = { "F", "G", "H", "LeftShift", "E" }
	elseif componentType == "ColorPicker" or componentType == "ColorPalette" then
		base.Default = { 0.94, 0.27, 0.27 }
	elseif componentType == "Label" then
		base.Default = "Preview label"
	elseif componentType == "Badge" then
		base.Default = "New"
	elseif componentType == "ProgressBar" then
		base.Default = 0.62
	elseif componentType == "Image" then
		base.Default = "rbxassetid://6031075931"
		base.Icon = "rbxassetid://6031075931"
	elseif componentType == "Table" then
		base.Columns = { "Name", "Value", "Unit" }
		base.Default = { { "Speed", 24, "studs" }, { "Jump", 50, "studs" }, { "Health", 100, "hp" } }
	elseif componentType == "TreeView" then
		base.Default = "Root"
	elseif componentType == "LogView" then
		base.Default = {
			{ Text = "[12:00:01] Studio preview", Level = "Info" },
			{ Text = "[12:00:02] Style applied", Level = "Warn" },
		}
	elseif componentType == "Graph" then
		base.Default = { 0.1, 0.35, 0.2, 0.6, 0.45, 0.8, 0.55, 0.9, 0.7, 0.95 }
	elseif componentType == "Notification" then
		base.Default = nil
		base.Body = { Message = "Preview notification", Level = "Info" }
		base.Duration = 0
	elseif componentType == "Dialog" then
		base.Default = nil
		base.Duration = 0
		base.Body = {
			Title = "Preview dialog",
			Message = "Actions are sandboxed inside the Studio.",
			Actions = {
				{ Label = "Confirm", Value = true, Style = "Primary" },
				{ Label = "Cancel", Value = false, Style = "Cancel" },
			},
		}
	end
	return base
end

local function typeIsAvailable(context, componentType)
	if not context:Factory(componentType) then
		return false
	end
	local ids = Styles.styleIds(componentType)
	return #ids > 0
end

function Studio.new(window, options)
	options = options or {}
	assert(window, "Studio.new expects a window")
	local self = setmetatable({}, Studio)
	self.Window = window
	self.Context = window.Context
	self.Host = window.Context.Host
	self.Options = options
	self.Destroyed = false
	self.SlotStyles = { "label.plain", "label.heading" }
	self.Editing = {}
	self.Search = ""
	self:BuildPanel()
	return self
end

-- Panel ----------------------------------------------------------------------

function Studio:BuildPanel()
	local host = self.Host
	local tokens = self.Context.Tokens
	self.Root = host.new("Frame", {
		Name = "NEVAHEXUI_StyleStudio",
		BackgroundColor3 = tokens.Background,
		BorderSizePixel = 0,
		Size = host.udim2(0.86, 0, 0.82, 0),
		Position = host.udim2(0.5, 0, 0.5, 0),
		AnchorPoint = host.vector2(0.5, 0.5),
		ZIndex = 80,
	}, self.Window.Root)
	Helpers.corner(host, self.Root, tokens.CornerRadius or 8)
	Helpers.stroke(host, self.Root, tokens.Outline, 1, 0.1)

	self.Header = host.new("Frame", {
		Name = "Header",
		BackgroundColor3 = tokens.Surface,
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		Size = host.udim2(1, 0, 0, 34),
		ZIndex = 81,
	}, self.Root)
	Helpers.corner(host, self.Header, tokens.CornerRadius or 8)
	Surface.text(self.Context, self.Header, {
		Name = "Title",
		Size = host.udim2(1, -120, 1, 0),
		Position = host.udim2(0, 12, 0, 0),
		Text = "NEVAHEXUI Style Studio",
		TextColor3 = tokens.Text,
		Font = tokens.FontBold,
		TextSize = 14,
	})
	local close = host.new("TextButton", {
		Name = "Close",
		BackgroundColor3 = tokens.SurfaceAlt,
		BorderSizePixel = 0,
		Size = host.udim2(0, 24, 0, 24),
		Position = host.udim2(1, -34, 0, 5),
		Text = "x",
		TextColor3 = tokens.Text,
		Font = tokens.FontBold,
		AutoButtonColor = false,
		ZIndex = 82,
	}, self.Header)
	Helpers.corner(host, close, 6)
	self:Connect(close, "MouseButton1Click", function()
		self:Destroy()
	end)

	local body = host.new("Frame", {
		Name = "Body",
		BackgroundTransparency = 1,
		Position = host.udim2(0, 0, 0, 34),
		Size = host.udim2(1, 0, 1, -34),
	}, self.Root)

	self.CatalogColumn = host.new("ScrollingFrame", {
		Name = "Catalog",
		BackgroundColor3 = tokens.SurfaceAlt,
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		Size = host.udim2(0, 260, 1, 0),
		CanvasSize = host.udim2(0, 0, 0, 0),
		ScrollBarThickness = 3,
	}, body)
	Helpers.corner(host, self.CatalogColumn, tokens.CornerRadius or 8)
	host.new("UIListLayout", {
		FillDirection = host.enumItem("FillDirection", "Vertical"),
		Padding = host.udim(0, 3),
		SortOrder = host.enumItem("SortOrder", "LayoutOrder"),
	}, self.CatalogColumn)
	host.new("UIPadding", {
		PaddingLeft = host.udim(0, 6),
		PaddingRight = host.udim(0, 6),
		PaddingTop = host.udim(0, 6),
		PaddingBottom = host.udim(0, 6),
	}, self.CatalogColumn)

	self.PreviewColumn = host.new("ScrollingFrame", {
		Name = "Previews",
		BackgroundColor3 = tokens.Surface,
		BackgroundTransparency = 0.6,
		BorderSizePixel = 0,
		Position = host.udim2(0, 266, 0, 0),
		Size = host.udim2(0, 340, 1, 0),
		CanvasSize = host.udim2(0, 0, 0, 0),
		ScrollBarThickness = 3,
	}, body)
	Helpers.corner(host, self.PreviewColumn, tokens.CornerRadius or 8)
	host.new("UIListLayout", {
		FillDirection = host.enumItem("FillDirection", "Vertical"),
		Padding = host.udim(0, 6),
		SortOrder = host.enumItem("SortOrder", "LayoutOrder"),
	}, self.PreviewColumn)
	host.new("UIPadding", {
		PaddingLeft = host.udim(0, 8),
		PaddingRight = host.udim(0, 8),
		PaddingTop = host.udim(0, 8),
		PaddingBottom = host.udim(0, 8),
	}, self.PreviewColumn)

	self.InspectorColumn = host.new("ScrollingFrame", {
		Name = "Inspector",
		BackgroundColor3 = tokens.SurfaceAlt,
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		Position = host.udim2(0, 612, 0, 0),
		Size = host.udim2(1, -618, 1, 0),
		CanvasSize = host.udim2(0, 0, 0, 0),
		ScrollBarThickness = 3,
	}, body)
	Helpers.corner(host, self.InspectorColumn, tokens.CornerRadius or 8)
	host.new("UIListLayout", {
		FillDirection = host.enumItem("FillDirection", "Vertical"),
		Padding = host.udim(0, 4),
		SortOrder = host.enumItem("SortOrder", "LayoutOrder"),
	}, self.InspectorColumn)
	host.new("UIPadding", {
		PaddingLeft = host.udim(0, 8),
		PaddingRight = host.udim(0, 8),
		PaddingTop = host.udim(0, 8),
		PaddingBottom = host.udim(0, 8),
	}, self.InspectorColumn)

	self.CatalogContainer = Container.new(self.Context, {
		Kind = "Panel",
		Name = "CatalogList",
		Parent = self.CatalogColumn,
		Window = self.Window,
	})
	self.PreviewContainer = Container.new(self.Context, {
		Kind = "Panel",
		Name = "PreviewList",
		Parent = self.PreviewColumn,
		Window = self.Window,
	})
	self.InspectorContainer = Container.new(self.Context, {
		Kind = "Panel",
		Name = "InspectorFields",
		Parent = self.InspectorColumn,
		Window = self.Window,
	})

	self:BuildTypeList()
	self:SelectType(self.Options.Component or "Toggle")
	return self.Root
end

function Studio:Connect(instance, event, callback)
	local host = self.Host
	local connection
	if host.connect then
		connection = host.connect(instance, event, callback)
	elseif instance[event] and instance[event].Connect then
		connection = instance[event]:Connect(callback)
	end
	self.Connections = self.Connections or {}
	if connection then
		table.insert(self.Connections, connection)
	end
	return connection
end

function Studio:BuildTypeList()
	local host = self.Host
	local tokens = self.Context.Tokens
	self.TypeButtons = {}
	local index = 0
	for _, componentType in ipairs(CANDIDATE_TYPES) do
		if typeIsAvailable(self.Context, componentType) then
			index += 1
			local count = #Styles.styleIds(componentType)
			local button = host.new("TextButton", {
				Name = "Type_" .. componentType,
				BackgroundColor3 = tokens.Surface,
				BackgroundTransparency = 0.4,
				BorderSizePixel = 0,
				Size = host.udim2(1, 0, 0, 26),
				Text = ("%s  [%s] (%d)"):format(componentType, categoryOf(componentType), count),
				TextColor3 = tokens.Text,
				TextSize = 12,
				TextXAlignment = host.enumItem("TextXAlignment", "Left"),
				AutoButtonColor = false,
				LayoutOrder = index,
			}, self.CatalogColumn)
			Helpers.corner(host, button, 6)
			host.new("UIPadding", {
				PaddingLeft = host.udim(0, 6),
			}, button)
			self:Connect(button, "MouseButton1Click", function()
				self:SelectType(componentType)
			end)
			self.TypeButtons[componentType] = button
		end
	end
	return self.TypeButtons
end

-- Selection ------------------------------------------------------------------

function Studio:SelectType(componentType)
	if not typeIsAvailable(self.Context, componentType) then
		return false, ("%s has no registered renderer"):format(tostring(componentType))
	end
	self.ComponentType = componentType
	self.StyleIds = Styles.styleIds(componentType)
	self.SlotStyles[1] = self.StyleIds[1]
	self.SlotStyles[2] = self.StyleIds[math.min(2, #self.StyleIds)] or self.StyleIds[1]
	self:HideAllPreviews()
	self:BuildPreviews()
	self:BuildStyleList()
	self:BuildInspector(1)
	return true
end

function Studio:HideAllPreviews()
	self.Previews = self.Previews or {}
	for _, preview in ipairs(self.Previews) do
		if preview.Root then
			preview.Root.Visible = false
		end
	end
end

function Studio:BuildStyleList()
	local host = self.Host
	local tokens = self.Context.Tokens
	for _, child in ipairs(self.PreviewColumn:GetChildren()) do
		if child:IsA("TextButton") and child.Name:sub(1, 10) == "StyleRow_" then
			host.destroy(child)
		end
	end
	self.StyleRows = {}
	local baseOrder = 1000
	for index, styleId in ipairs(self.StyleIds) do
		local record = Styles.get(styleId)
		local row = host.new("TextButton", {
			Name = "StyleRow_" .. tostring(index),
			BackgroundColor3 = tokens.SurfaceAlt,
			BackgroundTransparency = 0.35,
			BorderSizePixel = 0,
			Size = host.udim2(1, 0, 0, 22),
			Text = ("%s  -  %s"):format(styleId, record and record.Name or "?"),
			TextColor3 = tokens.Text,
			TextSize = 11,
			TextXAlignment = host.enumItem("TextXAlignment", "Left"),
			AutoButtonColor = false,
			LayoutOrder = baseOrder + index,
		}, self.PreviewColumn)
		Helpers.corner(host, row, 5)
		self.StyleRows[styleId] = row
		self:Connect(row, "MouseButton1Click", function()
			self:AssignStyle(styleId)
		end)
	end
	return self.StyleRows
end

function Studio:AssignStyle(styleId)
	local slot = self.Options.AlternateSlot and 2 or 1
	self.SlotStyles[slot] = styleId
	self:BuildPreviews()
	self:BuildInspector(slot)
	return styleId
end

function Studio:SelectedStyle(slot)
	return self.SlotStyles[slot or 1]
end


-- Live previews --------------------------------------------------------------

local SLOT_LABELS = { "Style 1", "Style 2" }

function Studio:BuildPreviews()
	local host = self.Host
	local tokens = self.Context.Tokens
	self.Previews = self.Previews or {}
	for slot, preview in ipairs(self.Previews) do
		if not preview.Destroyed then
			pcall(function()
				preview:Destroy()
			end)
		end
		self.Previews[slot] = nil
	end
	for slot = 1, 2 do
		local styleId = self.SlotStyles[slot]
		if styleId then
			local frame = host.new("Frame", {
				Name = ("Preview%s"):format(tostring(slot)),
				BackgroundColor3 = tokens.Surface,
				BackgroundTransparency = 0.55,
				BorderSizePixel = 0,
				Size = host.udim2(1, 0, 0, 0),
				AutomaticSize = host.enumItem("AutomaticSize", "Y"),
				LayoutOrder = slot,
			}, self.PreviewColumn)
			Helpers.corner(host, frame, tokens.CornerRadius or 8)
			local _layout = host.new("UIListLayout", {
				Name = "PreviewLayout",
				FillDirection = host.enumItem("FillDirection", "Vertical"),
				Padding = host.udim(0, 4),
				SortOrder = host.enumItem("SortOrder", "LayoutOrder"),
			}, frame)
			host.new("UIPadding", {
				PaddingLeft = host.udim(0, 6),
				PaddingRight = host.udim(0, 6),
				PaddingTop = host.udim(0, 6),
				PaddingBottom = host.udim(0, 6),
			}, frame)
			local _header = Surface.text(self.Context, frame, {
				Name = "SlotLabel",
				Size = host.udim2(1, 0, 0, 16),
				Text = ("%s: %s"):format(SLOT_LABELS[slot], styleId),
				TextColor3 = tokens.TextMuted,
				Font = tokens.FontBold,
				TextSize = 11,
				LayoutOrder = 0,
			})
			local _record = Styles.get(styleId)
			local container = Container.new(self.Context, {
				Kind = "Panel",
				Name = ("PreviewSlot%s"):format(tostring(slot)),
				Parent = frame,
				Window = self.Window,
				Padding = 0,
			})
			if container.LayoutObject then
				container.LayoutObject.Padding = host.udim(0, 4)
			end
			local spec = previewSpec(self.ComponentType, ("StudioPreview%s"):format(tostring(slot)), styleId)
			local ok, component = pcall(function()
				return container:Create(self.ComponentType, spec)
			end)
			if not ok then
				Surface.text(self.Context, frame, {
					Name = "PreviewError",
					Size = host.udim2(1, 0, 0, 20),
					Text = ("Preview failed: %s"):format(tostring(component)),
					TextColor3 = tokens.Negative,
					TextSize = 11,
					LayoutOrder = 2,
				})
			else
				component.Internal = true
				component.Metadata.Studio = true
				table.insert(self.Previews, component)
				self.Previews[slot] = component
				if component.View and component.View.Root then
					component.View.Root.Size = host.udim2(1, 0, 0, component.View.Root.Size.Y.Offset)
				end
			end
			frame.Name = ("Preview%s_%s"):format(tostring(slot), styleId)
		end
	end
	return self.Previews
end

-- Inspector ------------------------------------------------------------------

-- One inspector row: a labelled frame whose control is parented into it.
local function container_row(host, parent, order, label)
	local row = host.new("Frame", {
		Name = "Row_" .. tostring(label),
		BackgroundTransparency = 1,
		Size = host.udim2(1, 0, 0, 26),
		LayoutOrder = order,
	}, parent)
	return row
end

local FONT_CYCLE = { "Gotham", "GothamBold", "Code", "SourceSans", "Arial" }

local function propertyBounds(descriptor, configuration)
	local min = descriptor.Min or 0
	local max = descriptor.Max or 1
	if max <= min then
		max = min + 1
	end
	return min, max
end

function Studio:ClearInspector()
	local host = self.Host
	for index = #self.InspectorRows, 1, -1 do
		local entry = self.InspectorRows[index]
		if entry and not entry.Destroyed then
			pcall(function()
				entry:Destroy()
			end)
		end
		self.InspectorRows[index] = nil
	end
	for _, child in ipairs(self.InspectorColumn:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextButton") then
			host.destroy(child)
		end
	end
	self.InspectorRows = {}
	return true
end

function Studio:BuildInspector(slot)
	slot = slot or 1
	self.InspectorRows = self.InspectorRows or {}
	local host = self.Host
	local tokens = self.Context.Tokens
	local styleId = self.SlotStyles[slot]
	local preview = self.Previews and self.Previews[slot]
	if not styleId or not preview then
		return false
	end
	self.Editing = { Slot = slot, StyleId = styleId, Preview = preview }
	local record = Styles.get(styleId)
	local chain = Styles.chain(styleId)
	local properties = Styles.effectiveProperties(chain)
	local order = 0

	local function header(text, colour)
		order += 1
		return Surface.text(self.Context, self.InspectorColumn, {
			Name = "Label_" .. tostring(order),
			Size = host.udim2(1, 0, 0, 18),
			Text = text,
			TextColor3 = colour or tokens.Text,
			Font = tokens.FontBold,
			TextSize = 11,
			LayoutOrder = order,
		})
	end

	header(("Style %s  (%s)"):format(styleId, record and record.Name or "?"), tokens.Accent)
	header(record and record.Description or "", tokens.TextMuted)
	header(("Slot %d  -  %d propert%s"):format(slot, #properties, #properties == 1 and "y" or "ies"))

	for _, descriptor in ipairs(properties) do
		order += 1
		local value = preview:GetStyleConfiguration()[descriptor.Key]
		if value == nil then
			value = preview.Configuration[descriptor.Key]
		end
		local label = ("%s%s"):format(descriptor.Key, descriptor.Type == "number" and "  (number)" or "")
		local row = container_row(host, self.InspectorColumn, order, label)
		local property = descriptor.Key
		local kind = descriptor.Type

		local function apply(newValue)
			local configuration = preview:GetStyleConfiguration()
			configuration[property] = newValue
			preview:SetStyleConfiguration(configuration)
			return newValue
		end

		if kind == "number" then
			local min, max = propertyBounds(descriptor)
			local control = self.InspectorContainer:Create("Slider", {
				Name = label,
				Flag = ("Studio_%s_%d"):format(property, slot),
				RowHeight = 24,
				Min = min,
				Max = max,
				Step = descriptor.Step,
				Default = tonumber(value) or descriptor.Default or min,
				Style = { Id = "slider.minimal" },
				Callback = function(newValue)
					apply(newValue)
				end,
			})
			table.insert(self.InspectorRows, control)
			control.View.Root.Parent = row
		elseif kind == "boolean" then
			local control = self.InspectorContainer:Create("Toggle", {
				Name = label,
				Flag = ("Studio_%s_%d"):format(property, slot),
				Default = value == true,
				Style = { Id = "toggle.compact" },
				Callback = function(newValue)
					apply(newValue)
				end,
			})
			table.insert(self.InspectorRows, control)
			control.View.Root.Parent = row
		elseif kind == "color" then
			local control = self.InspectorContainer:Create("ColorPicker", {
				Name = label,
				Flag = ("Studio_%s_%d"):format(property, slot),
				SwatchSize = 14,
				Columns = 10,
				Default = value or "Accent",
				Palette = self.Context.Tokens.Palette,
				Style = { Id = "colorpicker.popup" },
				Callback = function(newValue)
					apply(newValue)
				end,
			})
			table.insert(self.InspectorRows, control)
			control.View.Root.Parent = row
		elseif kind == "string" then
			local control = self.InspectorContainer:Create("Textbox", {
				Name = label,
				Flag = ("Studio_%s_%d"):format(property, slot),
				Default = tostring(value or descriptor.Default or ""),
				Style = { Id = "textbox.outline" },
				Callback = function(newValue)
					apply(newValue)
				end,
			})
			table.insert(self.InspectorRows, control)
			control.View.Root.Parent = row
		else
			local choices = descriptor.Type == "enum" and descriptor.Options or (descriptor.Type == "font" and FONT_CYCLE or nil)
			if not choices and descriptor.Type == "animation" then
				choices = {}
				for _, entry in ipairs(require("NEVA:Animation/Presets").list()) do
					table.insert(choices, entry.Name or entry.Id or entry)
				end
			end
			choices = choices or { "Default" }
			local control = self.InspectorContainer:Create("Button", {
				Name = label,
				Flag = ("Studio_%s_%d"):format(property, slot),
				Style = { Id = "button.flat" },
				Callback = function()
					-- The callback cycles, so it does not need the returned count.
				end,
			})
			table.insert(self.InspectorRows, control)
			control.View.Root.Parent = row
			local current = value
			control:OnChanged(function()
				local nextIndex = 1
				for index, choice in ipairs(choices) do
					if tostring(choice) == tostring(current) then
						nextIndex = index % #choices + 1
						break
					end
				end
				current = choices[nextIndex]
				apply(current)
			end)
		end
	end

	order += 1
	local actions = host.new("Frame", {
		Name = "Actions",
		BackgroundTransparency = 1,
		Size = host.udim2(1, 0, 0, 26),
		LayoutOrder = order,
	}, self.InspectorColumn)
	host.new("UIListLayout", {
		FillDirection = host.enumItem("FillDirection", "Horizontal"),
		Padding = host.udim(0, 4),
		SortOrder = host.enumItem("SortOrder", "LayoutOrder"),
	}, actions)
	local function actionButton(text, order2, callback)
		local button = host.new("TextButton", {
			Name = "Action_" .. text,
			BackgroundColor3 = tokens.SurfaceAlt,
			BorderSizePixel = 0,
			Size = host.udim2(0, 92, 1, 0),
			Text = text,
			TextColor3 = tokens.Text,
			Font = tokens.FontBold,
			TextSize = 11,
			AutoButtonColor = false,
			LayoutOrder = order2,
		}, actions)
		Helpers.corner(host, button, 6)
		self:Connect(button, "MouseButton1Click", callback)
		return button
	end
	actionButton("Apply", 1, function()
		self:ApplyToTarget()
	end)
	actionButton("Preset", 2, function()
		self:SavePreset()
	end)
	actionButton("Export", 3, function()
		self:ExportStyle()
	end)
	actionButton("Reset", 4, function()
		if self.Editing and self.Editing.Preview then
			self.Editing.Preview:ResetStyleConfiguration()
		end
	end)
	return true
end

-- Apply, preset, export ------------------------------------------------------

function Studio:SetTarget(component)
	self.Target = component
	return component
end

function Studio:GetTargets()
	local out = {}
	for _, component in ipairs(self.Context:ComponentsOfType(self.ComponentType)) do
		if component.Metadata and component.Metadata.Studio then
			continue
		end
		table.insert(out, component)
	end
	return out
end

function Studio:ApplyToTarget()
	if not self.Editing or not self.Editing.Preview then
		return false, "nothing selected"
	end
	local target = self.Target
	if not target then
		local candidates = self:GetTargets()
		target = candidates[1]
	end
	if not target then
		return false, ("no live %s component to apply to"):format(tostring(self.ComponentType))
	end
	local preview = self.Editing.Preview
	local configuration = preview:GetStyleConfiguration()
	local ok, err = target:SetStyle(self.Editing.StyleId, configuration)
	self.LastApply = { Component = target, Style = self.Editing.StyleId, Ok = ok ~= false, Error = err }
	return ok ~= false, err
end

function Studio:SavePreset(name)
	if not self.Editing or not self.Editing.Preview then
		return false, "nothing selected"
	end
	local preview = self.Editing.Preview
	local componentType = self.ComponentType
	local id = ("studio.%s.%d"):format(componentType:lower(), os.time and os.time() or 0)
	local definition = {
		Id = id,
		Name = name or ("Studio " .. componentType),
		Component = componentType,
		Category = "Studio",
		Description = ("Created in the Style Studio from %s"):format(self.Editing.StyleId),
		Requires = self.Editing.StyleId,
		Configuration = preview:GetStyleConfiguration(),
		Render = preview.Style and preview.Style.Render or nil,
	}
	if not definition.Render then
		return false, "the selected style has no renderer to copy"
	end
	local Styles2 = require("NEVA:Styles/Registry")
	local record, errors = Styles2.registerStyle(definition)
	if not record then
		return false, errors
	end
	table.insert(self.SavedPresets or {}, record.Id)
	self.SavedPresets = self.SavedPresets or {}
	return record.Id
end

function Studio:ExportStyle(slot)
	local styleId = self.SlotStyles[slot or (self.Editing and self.Editing.Slot) or 1]
	local record = Styles.get(styleId)
	if not record then
		return nil, "no style selected"
	end
	local preview = self.Previews and self.Previews[slot or (self.Editing and self.Editing.Slot) or 1]
	local configuration = preview and preview:GetStyleConfiguration() or {}
	local text = Schema.exportStyle({
		Id = record.Id .. ".exported",
		Name = record.Name .. " (exported)",
		Component = record.Component,
		Category = record.Category,
		Description = record.Description,
		Configuration = configuration,
	}, { Properties = Styles.effectiveProperties(Styles.chain(styleId)) })
	self.LastExport = text
	if self.Host.clipboardSet then
		pcall(function()
			self.Host.clipboardSet(text)
		end)
	end
	return text
end

function Studio:ExplainConfiguration()
	if not self.Editing or not self.Editing.Preview then
		return nil
	end
	local component = self.Editing.Preview
	return {
		StyleId = component:GetStyle(),
		Effective = component:GetEffectiveConfiguration(),
		Overrides = component:GetStyleConfiguration(),
		Explanation = component:ExplainConfiguration(),
	}
end

function Studio:Destroy()
	if self.Destroyed then
		return false
	end
	self.Destroyed = true
	for _, preview in ipairs(self.Previews or {}) do
		if not preview.Destroyed then
			pcall(function()
				preview:Destroy()
			end)
		end
	end
	self.Previews = {}
	for _, entry in ipairs(self.InspectorRows or {}) do
		if entry and not entry.Destroyed then
			pcall(function()
				entry:Destroy()
			end)
		end
	end
	self.InspectorRows = {}
	for _, container in ipairs({ self.CatalogContainer, self.PreviewContainer, self.InspectorContainer }) do
		if container and container.Destroy then
			pcall(function()
				container:Destroy()
			end)
		end
	end
	if self.Window and self.Window.Studio == self then
		self.Window.Studio = nil
	end
	for _, connection in ipairs(self.Connections or {}) do
		if connection and connection.Disconnect then
			pcall(function()
				connection:Disconnect()
			end)
		end
	end
	self.Connections = {}
	if self.Root then
		self.Host.destroy(self.Root)
		self.Root = nil
	end
	return true
end

return Studio
