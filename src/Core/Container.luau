--[[
	NEVAHEXUI - Core/Container
	Shared implementation for tabs, sections, group boxes, cards and other
	content holders. Containers get one Create<Type> method per registered
	component factory, so the public API surface always matches the component
	catalogue instead of a hand-maintained list.
]]

local Util = require("NEVA:Core/Util")
local Component = require("NEVA:Core/Component")
local Keybinder = require("NEVA:Input/Keybinder")

local Container = {}
Container.__index = Container

Container.Kinds = {
	Tab = "Tab",
	SubTab = "SubTab",
	Section = "Section",
	Groupbox = "Groupbox",
	Card = "Card",
	Column = "Column",
	Collapsible = "Collapsible",
	DependencyBox = "DependencyBox",
	Panel = "Panel",
}

-- options = {
--   Kind, Name, Icon, Parent (instance), Window, Layout = {Order, Padding},
--   Collapsible = bool, Collapsed = bool, Dependency = spec
-- }
function Container.new(context, options)
	options = options or {}
	assert(context, "Container.new expects a context")
	local self = setmetatable({}, Container)
	self.Context = context
	self.Kind = options.Kind or "Section"
	self.Name = options.Name or self.Kind
	self.Icon = options.Icon
	self.Id = Util.uniqueId(self.Kind)
	self.Window = options.Window or options.Scope
	self.Parent = options.Parent
	self.Order = options.Order or #(options.Siblings or {}) + 1
	self.Children = {}
	self.Subtabs = {}
	self.Subcontainers = {}
	self.Collapsed = options.Collapsed == true
	self.Collapsible = options.Collapsible == true
	self.Dependency = options.Dependency
	self.Destroyed = false
	self.Visible = options.Visible ~= false

	local host = context.Host
	self.Container = host.new("Frame", {
		Name = self.Kind .. "_" .. self.Name,
		BackgroundTransparency = 1,
		Size = host.udim2(1, 0, 1, 0),
		Visible = self.Visible,
		LayoutOrder = self.Order,
	}, self.Parent)

	self.Instance = host.new("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = host.udim2(1, 0, 1, 0),
		LayoutOrder = 2,
	}, self.Container)

	local padding = options.Padding
	if padding == nil then
		padding = context.Tokens.Padding or 10
	end
	if self.Kind == "Section" or self.Kind == "Groupbox" or self.Kind == "Card" or self.Kind == "Collapsible" then
		host.new("UIPadding", {
			PaddingLeft = host.udim(0, padding),
			PaddingRight = host.udim(0, padding),
			PaddingTop = host.udim(0, padding),
			PaddingBottom = host.udim(0, padding),
		}, self.Instance)
	end
	self.LayoutObject = host.new("UIListLayout", {
		FillDirection = host.enumItem("FillDirection", "Vertical"),
		Padding = host.udim(0, context.Tokens.Spacing or 8),
		SortOrder = host.enumItem("SortOrder", "LayoutOrder"),
	}, self.Instance)
	self.AutomaticCanvasSize = nil

	if options.Dependency then
		self:SetDependency(options.Dependency)
	end

	self:_installFactories()
	self:_installContainerFactories()
	return self
end

function Container:_installFactories()
	local factories = self.Context.Factories
	local names = Util.keys(factories)
	for _, typeName in ipairs(names) do
		local class = factories[typeName]
		if type(class) == "table" and class.Type == typeName then
			local methodName = "Create" .. typeName
			if self[methodName] == nil then
				self[methodName] = function(container, spec)
					return container.Context:Create(typeName, container, spec)
				end
			end
		end
	end
end

-- Container kinds, installable on any container. This is what makes
-- `Tab:CreateSection{...}`, `Section:CreateGroupbox{...}` and
-- `Tab:CreateDependencyBox{...}` work: nested containers are created with the
-- same lifecycle, parenting and dependency support as window-level ones.
local SubKinds = { "Section", "Groupbox", "Card", "Collapsible", "DependencyBox", "Column" }

function Container:_installContainerFactories()
	for _, kind in ipairs(SubKinds) do
		local methodName = "Create" .. kind
		if self[methodName] == nil then
			self[methodName] = function(container, options)
				options = options or {}
				local child = Container.new(container.Context, {
					Kind = kind,
					Name = options.Name or kind,
					Icon = options.Icon,
					Order = options.Order,
					Collapsible = options.Collapsible,
					Collapsed = options.Collapsed,
					Padding = options.Padding,
					Dependency = options.Dependency or options.DependsOn,
					Parent = options.Parent or container.Instance or container.Container,
					Window = container.Window,
				})
				table.insert(container.Subcontainers, child)
				return child
			end
		end
	end
end

function Container:Create(componentType, spec)
	return self.Context:Create(componentType, self, spec)
end

-- Optional containers may be collapsed; the window keeps the layout in sync.
function Container:SetCollapsed(collapsed)
	self.Collapsed = collapsed == true
	if self.Instance then
		self.Instance.Visible = not self.Collapsed
	end
	if self.Window and self.Window.RefreshLayout then
		self.Window:RefreshLayout()
	end
	return self.Collapsed
end

function Container:ToggleCollapsed()
	return self:SetCollapsed(not self.Collapsed)
end

function Container:SetDependency(spec)
	self.Dependency = spec
	local hub = self.Context.DependencyHub
	local Dependency = require("NEVA:Core/Dependency")
	local flags = Dependency.flagsIn(spec, {})
	self.DependencyConnection = hub:subscribe(flags, function()
		self:EvaluateDependency()
	end)
	self:EvaluateDependency()
	return self
end

function Container:EvaluateDependency()
	if not self.Dependency then
		self.DependenciesMet = true
		return true
	end
	local Dependency = require("NEVA:Core/Dependency")
	local hub = self.Context.DependencyHub
	local met = Dependency.matches(self.Dependency, function(flag)
		return hub:getValue(flag)
	end)
	self.DependenciesMet = met
	if self.Container then
		self.Container.Visible = met and self.Visible
	end
	if self.Window and self.Window.RefreshLayout then
		self.Window:RefreshLayout()
	end
	return met
end

function Container:SetVisible(visible)
	self.Visible = visible ~= false
	if self.Container then
		self.Container.Visible = self.Visible and self.DependenciesMet ~= false
	end
	if self.Window and self.Window.RefreshLayout then
		self.Window:RefreshLayout()
	end
	return self.Visible
end

function Container:IsVisible()
	return self.Visible and self.DependenciesMet ~= false
end

function Container:SetName(name)
	self.Name = tostring(name)
	if self.Label then
		self.Label.Text = self.Name
	end
	if self.Container then
		self.Container.Name = self.Kind .. "_" .. self.Name
	end
	return self.Name
end

function Container:GetComponentCount()
	local total = 0
	for _, child in ipairs(self.Children) do
		if not child.Destroyed then
			total += 1
		end
	end
	for _, child in ipairs(self.Subcontainers) do
		if not child.Destroyed then
			total += child:GetComponentCount()
		end
	end
	return total
end

function Container:GetComponents()
	return self.Children
end

function Container:AddChild(component)
	table.insert(self.Children, component)
end

function Container:GetSize()
	if not self.Instance then
		return 0
	end
	local layout = self.LayoutObject
	if layout and layout.AbsoluteContentSize then
		return layout.AbsoluteContentSize.Y
	end
	return 0
end

function Container:Destroy()
	if self.Destroyed then
		return false
	end
	self.Destroyed = true
	for _, component in ipairs(self.Children) do
		if not component.Destroyed then
			component:Destroy()
		end
	end
	for _, subtab in ipairs(self.Subtabs) do
		subtab:Destroy()
	end
	for _, child in ipairs(self.Subcontainers) do
		if not child.Destroyed then
			child:Destroy()
		end
	end
	if self.DependencyConnection then
		self.DependencyConnection:Disconnect()
	end
	local host = self.Context.Host
	if self.Container then
		host.destroy(self.Container)
	end
	self.Children = {}
	self.Subtabs = {}
	self.Subcontainers = {}
	return true
end

return Container
