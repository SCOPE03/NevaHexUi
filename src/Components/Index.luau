--[[
	NEVAHEXUI - Components/Index
	The single place that knows every component class. Registering here wires the
	classes into a context's factory table, which is what gives every container
	its Create<Type> methods and the Style Studio its catalogue of live components.
]]

local Controls = require("NEVA:Components/Controls")
local Displays = require("NEVA:Components/Displays")
local Transient = require("NEVA:Components/Transient")

local Index = {}

-- Registration order defines the default style for a component type (the first
-- style registered for that type), so the order below is meaningful.
Index.Classes = {
	Buttons = {
		Controls.Button,
		Controls.IconButton,
	},
	Toggles = {
		Controls.Toggle,
		Controls.Checkbox,
		Controls.Radio,
		Controls.RadioGroup,
	},
	Sliders = {
		Controls.Slider,
		Controls.RangeSlider,
	},
	TextInputs = {
		Controls.Textbox,
		Controls.NumberInput,
		Controls.CopyableInput,
		Controls.Keybind,
	},
	Pickers = {
		Controls.ColorPicker,
		Controls.ColorPalette,
	},
	Displays = {
		Displays.Label,
		Displays.Divider,
		Displays.Badge,
		Displays.ProgressBar,
		Displays.Loader,
		Displays.Image,
		Displays.Table,
		Displays.TreeView,
		Displays.LogView,
		Displays.Graph,
	},
}

-- Components that are not created inside a tab: they are transient surfaces the
-- window owns (Notify, Dialog). They live in the same factory table so the
-- window creates them through the identical component pipeline.
Index.TransientClasses = Transient.classes

function Index.flatten()
	local out = {}
	for _, group in ipairs({ "Buttons", "Toggles", "Sliders", "TextInputs", "Pickers", "Displays" }) do
		for _, class in ipairs(Index.Classes[group] or {}) do
			table.insert(out, class)
		end
	end
	for _, class in ipairs(Index.TransientClasses) do
		table.insert(out, class)
	end
	return out
end

-- Installs the classes into context.Factories. Containers read this table to
-- create their Create<Type> methods, so a component added here appears in the
-- public API without touching any other file.
function Index.install(context)
	local installed = {}
	for _, class in ipairs(Index.flatten()) do
		context.Factories[class.Type] = class
		table.insert(installed, class.Type)
	end
	return installed
end

function Index.has(componentType)
	for _, class in ipairs(Index.flatten()) do
		if class.Type == componentType then
			return true
		end
	end
	return false
end

return Index
