--[[
	NEVAHEXUI - Components/Controls
	Interactive component classes: Button, IconButton, Toggle, Checkbox, Radio,
	RadioGroup, Slider, RangeSlider, Textbox, NumberInput, CopyableInput,
	Keybind, ColorPicker and ColorPalette.

	Every class declares behaviour only. Visuals come from the style renderers, so
	each class works with every renderer registered for its type. Wiring uses the
	host contract: instance events through Component:Connect, pointer position
	through host.pointerPosition/host.bounds/host.trackPointer, and keyboard
	capture through host.captureKeys.
]]

local Component = require("NEVA:Core/Component")
local Util = require("NEVA:Core/Util")
local Color = require("NEVA:Utilities/Color")

local Controls = {}

local function inputSurface(view)
	return view.Input or view.HoverTarget or view.Root
end

local function clamp(value, min, max)
	if value < min then
		return min
	end
	if value > max then
		return max
	end
	return value
end

local function number(value, fallback)
	local parsed = tonumber(value)
	if parsed == nil then
		return fallback
	end
	return parsed
end

-- Button ---------------------------------------------------------------------

local function clickOnly(definition)
	definition.Default = definition.Default
	definition.Wire = function(self, view)
		local surface = inputSurface(view)
		if not surface then
			return
		end
		self:Connect(surface, "MouseButton1Click", function()
			self:Fire()
		end)
	end
	function definition.FireMethod(self)
		self.Clicks = (self.Clicks or 0) + 1
		return self:_invoke(self.Callback, self.Clicks, { Source = "Click" })
	end
	return definition
end

Controls.Button = Component.define(clickOnly({
	Type = "Button",
	Default = nil,
	Description = "Pressable action button; the callback receives the click count.",
}))

function Controls.Button:Fire()
	self.Clicks = (self.Clicks or 0) + 1
	return self:_invoke(self.Callback, self.Clicks, { Source = "Click" })
end

function Controls.Button:GetClicks()
	return self.Clicks or 0
end

Controls.IconButton = Component.define({
	Type = "IconButton",
	Default = nil,
	Description = "Square icon-only action button.",
})

function Controls.IconButton:Fire()
	self.Clicks = (self.Clicks or 0) + 1
	return self:_invoke(self.Callback, self.Clicks, { Source = "Click" })
end

function Controls.IconButton:SetIcon(imageId)
	self.Spec.Icon = imageId
	return self:Refresh("icon")
end

function Controls.IconButton:GetClicks()
	return self.Clicks or 0
end

-- Boolean controls -----------------------------------------------------------

local function wireToggleish(self, view)
	local surface = inputSurface(view)
	if not surface then
		return
	end
	self:Connect(surface, "MouseButton1Click", function()
		if not self.Enabled then
			return
		end
		self:SetValue(not self.Value, { Source = "User" })
	end)
end

Controls.Toggle = Component.define({
	Type = "Toggle",
	Default = false,
	Description = "On/off switch.",
	Coerce = function(value)
		return value == true
	end,
	Wire = wireToggleish,
})

Controls.Checkbox = Component.define({
	Type = "Checkbox",
	Default = false,
	Description = "Checkbox with tick mark.",
	Coerce = function(value)
		return value == true
	end,
	Wire = wireToggleish,
})

-- Radio and radio groups -----------------------------------------------------

local function radioGroupMembers(self)
	local members = {}
	for _, component in ipairs(self.Context:ComponentsOfType("Radio")) do
		if component ~= self and component.Group == self.Group and not component.Destroyed then
			table.insert(members, component)
		end
	end
	return members
end

Controls.Radio = Component.define({
	Type = "Radio",
	Default = false,
	Description = "Single-choice option; group members are mutually exclusive.",
	Coerce = function(value)
		return value == true
	end,
	State = function(self)
		return { Group = self.Group, Option = self.Option or self.Spec.Option }
	end,
	Wire = function(self, view)
		self.Group = self.Spec.Group or self.Container and self.Container.Id or "default"
		self.Option = self.Spec.Option or self.Spec.Name
		local surface = inputSurface(view)
		if not surface then
			return
		end
		self:Connect(surface, "MouseButton1Click", function()
			if not self.Enabled or self.Selecting then
				return
			end
			self:Select()
		end)
	end,
})

function Controls.Radio:Select()
	if self.Value then
		return self
	end
	self.Selecting = true
	self:SetValue(true, { Source = "User" })
	for _, member in ipairs(radioGroupMembers(self)) do
		member:SetValue(false, { Silent = true })
	end
	self.Selecting = false
	if self.Callback then
		self:_invoke(self.Callback, self.Option, { Source = "Group" })
	end
	return self
end

function Controls.Radio:GetOption()
	return self.Option
end

Controls.RadioGroup = Component.define({
	Type = "RadioGroup",
	Default = nil,
	Description = "List of mutually exclusive options with a shared selected value.",
	Coerce = function(value)
		if value == nil then
			return nil
		end
		return value
	end,
	State = function(self)
		return { Options = self.Spec.Options or {}, Value = self.Value }
	end,
	Wire = function(self, view)
		local entries = view.Options or view.Rows or view.Buttons or {}
		for _, entry in ipairs(entries) do
			local instance = entry.Instance or entry.Button or entry
			local optionValue = entry.Value
			if instance and optionValue ~= nil then
				self:Connect(instance, "MouseButton1Click", function()
					self:SetValue(optionValue, { Source = "User" })
				end)
			end
		end
	end,
})

function Controls.RadioGroup:SetOptions(options)
	self.Spec.Options = options
	return self:Refresh("options")
end

-- Sliders --------------------------------------------------------------------

local function sliderRange(self)
	local spec = self.Spec
	return number(spec.Min, 0), number(spec.Max, 100), number(spec.Step, 0)
end

local function quantize(value, step)
	if step == nil or step <= 0 then
		return value
	end
	local steps = math.floor(value / step + 0.5)
	return steps * step
end

Controls.Slider = Component.define({
	Type = "Slider",
	Default = nil,
	Description = "Continuous numeric input with optional step, suffix and named stops.",
	Coerce = function(value, self)
		local min, max, step = sliderRange(self)
		local parsed = number(value, min)
		if self.Spec.Step ~= nil and step > 0 then
			parsed = quantize(parsed, step)
		end
		return Util.round(clamp(parsed, min, max), 6)
	end,
	State = function(self)
		local min, max = sliderRange(self)
		return {
			Min = min,
			Max = max,
			Step = self.Spec.Step,
			Suffix = self.Spec.Suffix,
			Stops = self.Spec.Stops,
			Ratio = max > min and ((self.Value - min) / (max - min)) or 0,
			Format = self.Spec.Format,
		}
	end,
	Wire = function(self, view)
		local surface = inputSurface(view)
		if not surface then
			return
		end
		local function apply(position)
			local bounds = self.Context.Host.bounds(surface)
			if not bounds or bounds.Width <= 0 then
				return
			end
			local point = position or self.Context.Host.pointerPosition() or { X = bounds.X, Y = bounds.Y }
			local x = number(point.X, bounds.X)
			local ratio = clamp((x - bounds.X) / bounds.Width, 0, 1)
			local min, max, step = sliderRange(self)
			local value = min + ratio * (max - min)
			if self.Spec.Step ~= nil then
				value = quantize(value, step)
			end
			self:SetValue(Util.round(clamp(value, min, max), 6), { Source = "User" })
		end
		self:Connect(surface, "MouseButton1Down", function()
			self.Dragging = true
			apply()
			self:_applyState()
		end)
		self:Connect(surface, "MouseButton1Up", function()
			self.Dragging = false
			self:_applyState()
		end)
		if self.Context.Host.trackPointer then
			self:TrackConnection(self.Context.Host.trackPointer(function(position)
				if self.Dragging then
					apply(position)
				end
			end))
		end
	end,
})

function Controls.Slider:GetRatio()
	local min, max = sliderRange(self)
	if max <= min then
		return 0
	end
	return (self.Value - min) / (max - min)
end

function Controls.Slider:SetRatio(ratio, silent)
	local min, max = sliderRange(self)
	return self:SetValue(min + clamp(ratio, 0, 1) * (max - min), { Silent = silent })
end

function Controls.Slider:Step(direction)
	local min, max, step = sliderRange(self)
	local increment = step > 0 and step or (max - min) / 100
	return self:SetValue(self.Value + increment * (direction or 1), { Source = "Programmatic" })
end

Controls.RangeSlider = Component.define({
	Type = "RangeSlider",
	Default = { Lower = 25, Upper = 75 },
	Description = "Dual-handle range input. Value is { Lower = n, Upper = m }.",
	Coerce = function(value, self)
		local min, max, step = sliderRange(self)
		local lower, upper
		if type(value) == "table" then
			lower = number(value.Lower or value[1], min)
			upper = number(value.Upper or value[2], max)
		else
			lower, upper = min, max
		end
		if self.Spec.Step ~= nil and step > 0 then
			lower = quantize(lower, step)
			upper = quantize(upper, step)
		end
		lower = clamp(lower, min, max)
		upper = clamp(upper, min, max)
		if lower > upper then
			lower, upper = upper, lower
		end
		return { Lower = Util.round(lower, 6), Upper = Util.round(upper, 6) }
	end,
	State = function(self)
		local min, max = sliderRange(self)
		local span = max > min and (max - min) or 1
		return {
			Min = min,
			Max = max,
			Step = self.Spec.Step,
			Suffix = self.Spec.Suffix,
			LowerRatio = (self.Value.Lower - min) / span,
			UpperRatio = (self.Value.Upper - min) / span,
		}
	end,
	Wire = function(self, view)
		local surface = inputSurface(view)
		if not surface then
			return
		end
		local function apply(position, handle)
			local bounds = self.Context.Host.bounds(surface)
			if not bounds or bounds.Width <= 0 then
				return
			end
			local point = position or self.Context.Host.pointerPosition() or { X = bounds.X, Y = bounds.Y }
			local ratio = clamp((number(point.X, bounds.X) - bounds.X) / bounds.Width, 0, 1)
			local min, max, step = sliderRange(self)
			local raw = min + ratio * (max - min)
			if self.Spec.Step ~= nil then
				raw = quantize(raw, step)
			end
			raw = clamp(raw, min, max)
			local lower, upper = self.Value.Lower, self.Value.Upper
			local target = handle
			if target == nil then
				target = math.abs(raw - lower) <= math.abs(raw - upper) and "Lower" or "Upper"
			end
			if target == "Lower" then
				lower = math.min(raw, upper)
			else
				upper = math.max(raw, lower)
			end
			self:SetValue({ Lower = Util.round(lower, 6), Upper = Util.round(upper, 6) }, { Source = "User" })
		end
		self:Connect(surface, "MouseButton1Down", function()
			self.Dragging = true
			self.DraggingHandle = nil
			apply()
			self:_applyState()
		end)
		self:Connect(surface, "MouseButton1Up", function()
			self.Dragging = false
			self:_applyState()
		end)
		if self.Context.Host.trackPointer then
			self:TrackConnection(self.Context.Host.trackPointer(function(position)
				if self.Dragging then
					apply(position, self.DraggingHandle)
				end
			end))
		end
	end,
})

function Controls.RangeSlider:SetRange(lower, upper, silent)
	return self:SetValue({ Lower = lower, Upper = upper }, { Silent = silent })
end

-- Text inputs ----------------------------------------------------------------

Controls.Textbox = Component.define({
	Type = "Textbox",
	Default = "",
	Description = "Single or multi-line text entry.",
	Coerce = function(value)
		if value == nil then
			return ""
		end
		return tostring(value)
	end,
	State = function(self)
		return { Placeholder = self.Spec.Placeholder or "", Multiline = self.Spec.Multiline == true }
	end,
	Wire = function(self, view)
		local box = view.Box or view.TextBox or view.Input
		if not box then
			return
		end
		local function commit()
			local text = box.Text
			if text == nil then
				return
			end
			self:SetValue(text, { Source = "User" })
		end
		self:Connect(box, "FocusLost", function(enterPressed)
			commit()
			if enterPressed and self.Spec.ClearOnFocus == true then
				box.Text = self.Value
			end
		end)
		self:Connect(box, "ReturnPressedFromOnScreenKeyboard", commit)
	end,
})

function Controls.Textbox:GetText()
	return self.Value
end

function Controls.Textbox:SetText(text, silent)
	return self:SetValue(text, { Silent = silent })
end

Controls.NumberInput = Component.define({
	Type = "NumberInput",
	Default = 0,
	Description = "Numeric field with optional stepper buttons.",
	Coerce = function(value, self)
		local parsed = number(value, 0)
		if self.Spec.Min then
			parsed = math.max(self.Spec.Min, parsed)
		end
		if self.Spec.Max then
			parsed = math.min(self.Spec.Max, parsed)
		end
		if self.Spec.Precision then
			parsed = Util.round(parsed, self.Spec.Precision)
		end
		return parsed
	end,
	State = function(self)
		return { Min = self.Spec.Min, Max = self.Spec.Max, Step = self.Spec.Step or 1, Suffix = self.Spec.Suffix }
	end,
	Wire = function(self, view)
		local box = view.Box or view.Input
		if box and box.Text ~= nil then
			self:Connect(box, "FocusLost", function()
				self:SetValue(box.Text, { Source = "User" })
			end)
		end
		for _, entry in ipairs({ { view.StepUp, 1 }, { view.StepDown, -1 } }) do
			local button, direction = entry[1], entry[2]
			if button then
				self:Connect(button, "MouseButton1Click", function()
					self:Increment(direction)
				end)
			end
		end
	end,
})

function Controls.NumberInput:Increment(direction)
	local step = self.Spec.Step or 1
	return self:SetValue(self.Value + step * (direction or 1), { Source = "Programmatic" })
end

Controls.CopyableInput = Component.define({
	Type = "CopyableInput",
	Default = "",
	Description = "Read-only value with a copy-to-clipboard action.",
	Coerce = function(value)
		if value == nil then
			return ""
		end
		return tostring(value)
	end,
	State = function(self)
		return { CopyLabel = self.Spec.CopyLabel or "Copy" }
	end,
	Wire = function(self, view)
		local button = view.Copy
		if not button then
			return
		end
		self:Connect(button, "MouseButton1Click", function()
			self:Copy()
		end)
	end,
})

function Controls.CopyableInput:Copy()
	local host = self.Context.Host
	local ok = false
	if host.clipboardSet then
		ok = host.clipboardSet(self.Value) and true or false
	end
	self.LastCopySucceeded = ok
	return ok
end

Controls.Keybind = Component.define({
	Type = "Keybind",
	Default = "None",
	Description = "Key assignment with optional mode toggle and conflict reporting.",
	Coerce = function(value)
		if value == nil then
			return "None"
		end
		if type(value) == "table" then
			if value.Key then
				return tostring(value.Key)
			end
			return "None"
		end
		return tostring(value)
	end,
	State = function(self)
		return {
			Mode = self.Mode or self.Spec.Mode or "Toggle",
			Conflict = self.Conflict == true,
			Keys = self.Spec.Keys or {},
		}
	end,
	Wire = function(self, view)
		self.Mode = self.Spec.Mode or "Toggle"
		self.Conflict = self.Spec.Conflict == true
		local surface = inputSurface(view)
		if surface then
			self:Connect(surface, "MouseButton1Click", function()
				self:Capture()
			end)
		end
		local mode = view.ModeButton or view.Mode
		if mode then
			self:Connect(mode, "MouseButton1Click", function()
				self:SetMode(self.Mode == "Toggle" and "Hold" or "Toggle")
			end)
		end
	end,
})

function Controls.Keybind:Capture()
	local host = self.Context.Host
	if not host.captureKeys then
		self.Context:Diagnostic("Warn", "key capture is not supported by this host")
		return false
	end
	self.Listening = true
	self:_applyState()
	local capture
	capture = host.captureKeys(function(key)
		self.Listening = false
		self:SetValue(key, { Source = "User" })
		if capture and capture.Disconnect then
			capture:Disconnect()
		end
	end)
	if capture then
		self:TrackConnection(capture)
	end
	return true
end

function Controls.Keybind:SetMode(mode)
	self.Mode = mode
	return self:Refresh("mode")
end

function Controls.Keybind:SetConflict(conflict)
	self.Conflict = conflict == true
	return self:Refresh("conflict")
end

function Controls.Keybind:IsConflict()
	return self.Conflict == true
end

-- Colour controls ------------------------------------------------------------

Controls.ColorPicker = Component.define({
	Type = "ColorPicker",
	Default = nil,
	Description = "Colour selection with a swatch grid, hex readout and alpha.",
	Coerce = function(value, self)
		local fallback = self.Default
		if value == nil then
			return fallback
		end
		local ok, colour = pcall(Color.normalize, value)
		if not ok or colour == nil then
			return fallback
		end
		return colour
	end,
	State = function(self)
		return { Palette = self.Spec.Palette or {}, Value = self.Value }
	end,
	Wire = function(self, view)
		if self.Value == nil then
			self.Value = self:_coerce(self.Default or { 1, 0, 0 })
		end
		local surface = inputSurface(view)
		if surface then
			self:Connect(surface, "MouseButton1Click", function()
				view.Open = not view.Open
				self:_applyState()
			end)
		end
		for _, cell in ipairs(view.Cells or {}) do
			self:Connect(cell.Instance, "MouseButton1Click", function()
				view.Open = false
				self:SetValue(cell.Colour, { Source = "User" })
			end)
		end
	end,
})

function Controls.ColorPicker:SetColour(colour, silent)
	return self:SetValue(colour, { Silent = silent })
end

function Controls.ColorPicker:GetColour()
	return self.Value
end

function Controls.ColorPicker:ToHex()
	local ok, value = pcall(Color.normalize, self.Value)
	if not ok or value == nil then
		return nil
	end
	return value:ToHex()
end

Controls.ColorPalette = Component.define({
	Type = "ColorPalette",
	Default = nil,
	Description = "Row of colour chips for quick accent selection.",
	Coerce = function(value, self)
		if value == nil then
			return self.Spec.Palette and self.Spec.Palette[1] or nil
		end
		local ok, colour = pcall(Color.normalize, value)
		if not ok or colour == nil then
			return nil
		end
		return colour
	end,
	State = function(self)
		return { Palette = self.Spec.Palette or {}, Value = self.Value }
	end,
	Wire = function(self, view)
		for _, chip in ipairs(view.Chips or {}) do
			self:Connect(chip.Instance, "MouseButton1Click", function()
				self:SetValue(chip.Colour, { Source = "User" })
			end)
		end
	end,
})

function Controls.ColorPalette:SetOptions(colours)
	self.Spec.Palette = colours
	return self:Refresh("palette")
end

return Controls
