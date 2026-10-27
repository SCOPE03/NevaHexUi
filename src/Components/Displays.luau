--[[
	NEVAHEXUI - Components/Displays
	Component classes for the non-interactive surface: Label, Divider, Badge,
	ProgressBar, Loader, Image, Table, TreeView, LogView and Graph.

	A class only declares behaviour (defaults, coercion, extra state, methods).
	All visuals come from the style renderers in Styles/Defs, so the same class
	renders through every registered style for its type.
]]

local Component = require("NEVA:Core/Component")
local Util = require("NEVA:Core/Util")

local Displays = {}

local function text(value)
	if value == nil then
		return ""
	end
	return tostring(value)
end

Displays.Label = Component.define({
	Type = "Label",
	Default = "",
	Description = "Static or programmatic text.",
	Coerce = text,
})

Displays.Divider = Component.define({
	Type = "Divider",
	Default = "",
	Description = "Visual separator between sections.",
	Coerce = text,
})

Displays.Badge = Component.define({
	Type = "Badge",
	Default = "New",
	Description = "Short status label.",
	Coerce = text,
})

Displays.ProgressBar = Component.define({
	Type = "ProgressBar",
	Default = 0,
	Description = "Determinate progress from 0 to 1.",
	Coerce = function(value)
		local number = tonumber(value) or 0
		return math.max(0, math.min(1, number))
	end,
})

function Displays.ProgressBar:SetProgress(value, silent)
	local number = math.max(0, math.min(1, tonumber(value) or 0))
	return self:SetValue(number, { Silent = silent })
end

function Displays.ProgressBar:GetProgress()
	return self:GetValue()
end

Displays.Loader = Component.define({
	Type = "Loader",
	Default = true,
	Description = "Indeterminate activity indicator.",
	Coerce = function(value)
		return value ~= false
	end,
})

function Displays.Loader:Start()
	return self:SetValue(true)
end

function Displays.Loader:Stop()
	return self:SetValue(false)
end

Displays.Image = Component.define({
	Type = "Image",
	Default = "",
	Description = "Icon or texture display.",
	Coerce = text,
})

function Displays.Image:SetImage(imageId)
	return self:SetValue(imageId)
end

Displays.Table = Component.define({
	Type = "Table",
	Default = {},
	Description = "Columnar data list.",
	Coerce = function(value)
		if type(value) ~= "table" then
			return {}
		end
		return Util.deepCopy(value)
	end,
	State = function(self)
		local columns = self.Spec.Columns or self.Metadata.Columns or {}
		return { Columns = columns, Rows = self.Value }
	end,
})

function Displays.Table:SetRows(rows)
	return self:SetValue(rows)
end

function Displays.Table:SetRow(index, row)
	local rows = Util.deepCopy(self:GetValue()) or {}
	rows[index] = row
	return self:SetValue(rows)
end

Displays.TreeView = Component.define({
	Type = "TreeView",
	Default = nil,
	Description = "Expandable node hierarchy.",
	Coerce = function(value)
		if value == nil then
			return nil
		end
		return tostring(value)
	end,
	State = function(self)
		return { Nodes = self:FlattenNodes() }
	end,
})

function Displays.TreeView:Init()
	self.ExpandedNodes = {}
	self.SelectedNode = nil
end

function Displays.TreeView:SetNodes(nodes)
	self.TreeNodes = nodes or {}
	for index, node in ipairs(self.TreeNodes) do
		node.Id = node.Id or ("node" .. tostring(index))
		if node.Expanded == nil then
			node.Expanded = node.DefaultExpanded == true
		end
	end
	return self:Refresh("nodes")
end

function Displays.TreeView:FlattenNodes()
	local out = {}
	local function walk(nodes, depth)
		for _, node in ipairs(nodes or {}) do
			local id = node.Id
			local children = node.Children
			local expanded = self.ExpandedNodes and self.ExpandedNodes[id] == true
			table.insert(out, {
				Id = id,
				Label = node.Label or id,
				Depth = depth,
				HasChildren = children ~= nil and #children > 0,
				Expanded = expanded,
			})
			if expanded and children then
				walk(children, depth + 1)
			end
		end
	end
	walk(self.TreeNodes, 0)
	return out
end

function Displays.TreeView:SetExpanded(id, expanded)
	self.ExpandedNodes = self.ExpandedNodes or {}
	self.ExpandedNodes[id] = expanded == true
	return self:Refresh("expansion")
end

function Displays.TreeView:ToggleNode(id)
	self.ExpandedNodes = self.ExpandedNodes or {}
	return self:SetExpanded(id, not self.ExpandedNodes[id])
end

function Displays.TreeView:SelectNode(id)
	self.SelectedNode = id
	return self:SetValue(id)
end

Displays.LogView = Component.define({
	Type = "LogView",
	Default = {},
	Description = "Append-only console output.",
	Coerce = function(value)
		if type(value) ~= "table" then
			return {}
		end
		local out = {}
		for index, entry in ipairs(value) do
			out[index] = entry
		end
		return out
	end,
	State = function(self)
		return { Lines = self.Value }
	end,
})

function Displays.LogView:Push(message, level)
	local lines = {}
	for index, entry in ipairs(self:GetValue()) do
		lines[index] = entry
	end
	table.insert(lines, { Text = tostring(message), Level = level or "Info" })
	local max = (self.Configuration and self.Configuration.MaxLines) or 200
	while #lines > max do
		table.remove(lines, 1)
	end
	return self:SetValue(lines)
end

function Displays.LogView:Clear()
	return self:SetValue({})
end

Displays.Graph = Component.define({
	Type = "Graph",
	Default = {},
	Description = "Stepped line graph for a numeric series.",
	Coerce = function(value)
		if type(value) ~= "table" then
			return {}
		end
		local out = {}
		for index, entry in ipairs(value) do
			out[index] = math.max(0, math.min(1, tonumber(entry) or 0))
		end
		return out
	end,
	State = function(self)
		return { Series = self.Value }
	end,
})

function Displays.Graph:Push(value)
	local series = {}
	for index, entry in ipairs(self:GetValue()) do
		series[index] = entry
	end
	table.insert(series, math.max(0, math.min(1, tonumber(value) or 0)))
	local limit = (self.Configuration and self.Configuration.Points) or 24
	while #series > limit do
		table.remove(series, 1)
	end
	return self:SetValue(series)
end

function Displays.Graph:SetSeries(series)
	return self:SetValue(series)
end

return Displays
