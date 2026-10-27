--[[
	NEVAHEXUI - Core/Component
	The base component class. Every NEVAHEXUI component is created by
	Component.define{ Type = ..., ... } and shares this lifecycle:

	  resolve configuration -> render the style's view -> apply state

	The base class owns: value + default, callbacks, flag identity, dependencies,
	visibility/enabled state, style and style-configuration replacement, event
	connection tracking, instance cleanup, serialization and destruction.

	Style changes never recreate the window and never touch the component's value,
	callback, flag, dependencies or connections: only the view is rebuilt.
]]

local Util = require("NEVA:Core/Util")
local Signal = require("NEVA:Core/Signal")
local Dependency = require("NEVA:Core/Dependency")
local Schema = require("NEVA:Styles/Schema")
local Registry = require("NEVA:Styles/Registry")
local Resolver = require("NEVA:Styles/Resolver")

local Component = {}
Component.__index = Component

-- Called by Component.define to create a component class.
function Component.define(definition)
	assert(type(definition) == "table", "Component.define expects a table")
	assert(type(definition.Type) == "string" and definition.Type ~= "", "Component.define needs a Type string")
	local class = setmetatable({}, { __index = Component })
	class.__index = class
	class.Type = definition.Type
	class.Definition = definition
	return class
end

function Component.create(class, context, container, spec, options)
	assert(context, "Component.create needs a context")
	spec = spec or {}
	options = options or {}
	local self = setmetatable({}, class)

	self.Id = Util.uniqueId(class.Type)
	self.Type = class.Type
	self.Definition = class.Definition
	self.Context = context
	self.Container = container
	self.Scope = container and container.Window or nil
	self.Flag = spec.Flag or spec.Name or self.Id
	self.Name = spec.Name or self.Flag
	self.Description = spec.Description or ""
	self.Callback = spec.Callback
	self.Internal = options.Internal == true
	self.FireOnLoad = spec.FireOnLoad == true
	self.Enabled = spec.Enabled ~= false
	self.Visible = spec.Visible ~= false
	self.Destroyed = false
	self.DestroyedAt = nil
	self.PlainInstances = {}
	self.Instances = {}
	self.Connections = {}
	self.Dependencies = {}
	self.Metadata = spec.Metadata and Util.deepCopy(spec.Metadata) or {}
	self.Spec = Util.deepCopy(spec)
	self.Spec.Callback = nil
	self.Spec.Style = nil

	local definition = class.Definition
	self.Default = spec.Default
	if self.Default == nil and definition.Default ~= nil then
		self.Default = definition.Default
	end
	self.Value = self:_coerce(self.Default)

	local styleSpec = spec.Style
	if type(styleSpec) == "string" then
		self.StyleId = styleSpec
		self.StyleConfiguration = {}
	elseif type(styleSpec) == "table" then
		self.StyleId = styleSpec.Id
		self.StyleConfiguration = Util.deepCopy(styleSpec.Configuration or {})
	else
		self.StyleId = nil
		self.StyleConfiguration = {}
	end
	self.RequestedStyle = self.StyleId
	self.RuntimeOverrides = {}
	self.Resolution = nil
	self.Configuration = {}
	self.Schema = {}
	self.Style = nil

	self.Changed = Signal.new(class.Type)
	self.DestroyedSignal = Signal.new(class.Type .. "Destroyed")
	self.LastError = nil
	self.LastValueError = nil
	self.DependenciesMet = true

	self:_build(define and nil)
	self:_wireHover()

	if definition.Wire then
		definition.Wire(self, self.View, self:_renderContext())
	end
	if definition.AfterBuild then
		definition.AfterBuild(self, self.View)
	end
	if spec.DependsOn or spec.Dependencies then
		local list = spec.DependsOn or spec.Dependencies
		if type(list) == "table" and list[1] ~= nil then
			for _, entry in ipairs(list) do
				self:AddDependency(entry)
			end
		else
			self:AddDependency(list)
		end
	end

	return self
end

-- Value coercion hook. Component modules override Definition.Coerce.
function Component:_coerce(value)
	local coerce = self.Definition.Coerce
	if Util.isCallable(coerce) then
		return coerce(value, self)
	end
	return value
end

function Component:GetDefault()
	return Util.deepCopy(self.Default)
end

function Component:GetValue()
	return self.Value
end

function Component:IsValueEqual(a, b)
	return Util.deepEquals(a, b)
end

-- options.Silent      -> do not fire the callback or the Changed signal
-- options.FromConfig  -> configuration load; callbacks only fire when FireOnLoad
-- options.FromInput   -> user interaction
function Component:SetValue(value, options)
	options = options or {}
	if self.Destroyed then
		return false, "component has been destroyed"
	end
	local coerced, err = self:_coerce(value)
	if err ~= nil then
		self.LastValueError = err
		if self.Context then
			self.Context:Diagnostic("Warn", ("%s (%s) rejected value: %s"):format(self.Name, self.Type, tostring(err)))
		end
		return false, err
	end
	local previous = self.Value
	local changed = not self:IsValueEqual(previous, coerced)
	self.Value = coerced
	self:_applyState()

	if changed and not options.Silent then
		self.Changed:Fire(coerced, self, previous)
		if self.Context and self.Context.DependencyHub then
			self.Context.DependencyHub:publish(self.Flag)
		end
	end

	local fire = false
	if options.Silent then
		fire = false
	elseif options.FromConfig then
		fire = self.FireOnLoad == true
	else
		fire = true
	end
	if fire and Util.isCallable(self.Callback) then
		self:_invoke(self.Callback, coerced, options)
	end
	return true, nil, changed
end

function Component:_invoke(callback, value, options)
	local ok, err = pcall(callback, value, self)
	if not ok then
		self.LastError = err
		if self.Context then
			self.Context:Diagnostic("Error", ("callback for %s (%s) failed: %s"):format(self.Name, self.Type, tostring(err)))
		end
		return false
	end
	return true
end

function Component:OnChanged(callback)
	return self.Changed:Connect(callback)
end

function Component:Reset(options)
	return self:SetValue(self.Default, options)
end

-- Connections and instances created by a component are tracked so that
-- Destroy can release every one of them.
function Component:Connect(instance, event, callback)
	local connection = self.Context.Host.connect(instance, event, callback)
	table.insert(self.Connections, connection)
	return connection
end

function Component:Track(instance)
	table.insert(self.Instances, instance)
	return instance
end

function Component:Create(className, props, parent)
	local instance = self.Context.Host.new(className, props, parent)
	return self:Track(instance)
end

function Component:_renderContext()
	return {
		Host = self.Context.Host,
		Tokens = self.Context.Tokens,
		Theme = self.Context.ThemeId,
		Configuration = self.Configuration,
		Defaults = Schema.defaults(self.Schema),
		Schema = self.Schema,
		Component = self,
		Type = self.Type,
		Props = {
			Name = self.Name,
			Description = self.Description,
			Flag = self.Flag,
			Enabled = self.Enabled,
			Visible = self.Visible,
			Icon = self.Spec.Icon,
		},
		State = self:_state(),
		Context = self.Context,
	}
end

function Component:_state()
	local state = {
		Value = self.Value,
		Enabled = self.Enabled,
		Visible = self:IsActuallyVisible(),
		Hovered = self.Hovered == true,
		Dragging = self.Dragging == true,
		Focused = self.Focused == true,
		Component = self,
	}
	local extra = self.Definition.State
	if Util.isCallable(extra) then
		local additional = extra(self)
		if type(additional) == "table" then
			for key, value in pairs(additional) do
				state[key] = value
			end
		end
	end
	return state
end

-- Generic hover tracking: every style gets hover state without implementing it.
function Component:_wireHover()
	local view = self.View
	if not view then
		return
	end
	local surface = view.Input or view.HoverTarget or view.Root
	if not surface then
		return
	end
	self:Connect(surface, "MouseEnter", function()
		self.Hovered = true
		self:_applyState()
	end)
	self:Connect(surface, "MouseLeave", function()
		self.Hovered = false
		self:_applyState()
	end)
end

function Component:_applyState()
	if not self.View then
		return
	end
	local state = self:_state()
	local apply = self.View.Apply
	if Util.isCallable(apply) then
		local ok, err = pcall(apply, self.View, state, self:_renderContext())
		if not ok then
			self.LastError = err
			self.Context:Diagnostic("Error", ("style %s Apply failed for %s: %s"):format(
				tostring(self.Style and self.Style.Id), self.Type, tostring(err)))
		end
	end
	if self.View.Root then
		self.View.Root.Visible = state.Visible
	end
end

function Component:_clearView()
	for _, connection in ipairs(self.Connections) do
		if connection and connection.Disconnect then
			pcall(function()
				connection:Disconnect()
			end)
		end
	end
	self.Connections = {}
	for _, instance in ipairs(self.Instances) do
		self.Context.Host.destroy(instance)
	end
	self.Instances = {}
	self.View = nil
end

function Component:_resolveStyle()
	local request = {
		Component = self.Type,
		StyleId = self.StyleId or self.Context:StyleDefaultFor(self.Type),
		CategoryConfiguration = self.Context:CategoryConfigurationFor(self.Type),
		ComponentConfiguration = self.StyleConfiguration,
		RuntimeOverrides = self.RuntimeOverrides,
	}
	local result = Resolver.resolve(request)
	self.Resolution = result
	self.EffectiveConfigurationSource = result.Effective
	if result.StyleId and result.StyleId ~= self.StyleId then
		self.StyleId = result.StyleId
	end
	for _, message in ipairs(result.Warnings) do
		self.Context:Diagnostic("Warn", ("%s (%s): %s"):format(self.Name, self.Type, message))
	end
	for _, message in ipairs(result.Errors) do
		self.Context:Diagnostic("Error", ("%s (%s): %s"):format(self.Name, self.Type, message))
	end
	self.Style = result.Style
	self.Configuration = result.Configuration
	self.Schema = result.Schema
	return result
end

function Component:_build()
	if self.Destroyed then
		return
	end
	local result = self:_resolveStyle()
	if not result.Ok or not result.Style then
		self.Context:Diagnostic("Error", ("%s (%s): no usable style; component not rendered"):format(self.Name, self.Type))
		return
	end
	local render = self.Style.Render
	local ok, view = pcall(render, self:_renderContext())
	if not ok then
		self.LastError = view
		self.Context:Diagnostic("Error", ("style %s failed to render %s: %s"):format(self.Style.Id, self.Type, tostring(view)))
		return
	end
	if type(view) ~= "table" or view.Root == nil then
		self.Context:Diagnostic("Error", ("style %s did not return a view with a Root for %s"):format(self.Style.Id, self.Type))
		return
	end
	self.View = view
	if view.Instances then
		for _, instance in ipairs(view.Instances) do
			table.insert(self.Instances, instance)
		end
	end
	table.insert(self.Instances, view.Root)
	local parent = self.Container and self.Container.Instance or nil
	if parent then
		view.Root.Parent = parent
	end
	self.StyleId = self.Style.Id
	self:_applyState()
end

-- Full rebuild: only used when the resolved style actually changes.
function Component:Refresh(reason)
	if self.Destroyed then
		return false, "component has been destroyed"
	end
	local previousValue = self.Value
	self:_clearView()
	self:_build()
	self.Value = previousValue
	self:_applyState()
	return true, nil
end

function Component:GetStyle()
	return self.StyleId
end

function Component:SetStyle(styleId, configuration)
	if self.Destroyed then
		return false, "component has been destroyed"
	end
	if type(styleId) == "table" then
		configuration = styleId.Configuration
		styleId = styleId.Id
	end
	assert(type(styleId) == "string" and styleId ~= "", "SetStyle expects a style id string")
	local style = Registry.get(styleId)
	if not style then
		return false, ("unknown style %q"):format(styleId)
	end
	if style.Component ~= self.Type then
		return false, ("style %q renders %s, not %s"):format(styleId, style.Component, self.Type)
	end
	local changed = self.StyleId ~= styleId
	self.StyleId = styleId
	self.RequestedStyle = styleId
	if type(configuration) == "table" then
		self.StyleConfiguration = Util.deepCopy(configuration)
		changed = true
	end
	if changed then
		return self:Refresh("SetStyle")
	end
	return true, nil
end

function Component:GetStyleInfo()
	return Registry.get(self.StyleId)
end

function Component:SetStyleConfiguration(configuration, options)
	if self.Destroyed then
		return false, "component has been destroyed"
	end
	assert(type(configuration) == "table", "SetStyleConfiguration expects a table")
	options = options or {}
	if options.Replace then
		self.StyleConfiguration = Util.deepCopy(configuration)
	else
		self.StyleConfiguration = Util.deepMerge(self.StyleConfiguration, configuration)
	end
	self.RuntimeOverrides = Util.deepCopy(configuration)
	if options.Replace then
		self.RuntimeOverrides = Util.deepCopy(configuration)
	end
	return self:Refresh("SetStyleConfiguration")
end

function Component:SetStyleProperty(key, value)
	if self.Destroyed then
		return false, "component has been destroyed"
	end
	assert(type(key) == "string", "SetStyleProperty expects a property name")
	return self:SetStyleConfiguration({ [key] = value })
end

function Component:GetStyleConfiguration()
	return Util.deepCopy(self.StyleConfiguration)
end

function Component:ResetStyleConfiguration()
	self.StyleConfiguration = {}
	self.RuntimeOverrides = {}
	return self:Refresh("ResetStyleConfiguration")
end

function Component:GetEffectiveConfiguration()
	return Util.deepCopy(self.Configuration)
end

function Component:GetSchema()
	return Schema.describe(self.Schema)
end

function Component:ExplainConfiguration()
	if not self.Resolution then
		return "no resolution recorded"
	end
	return Resolver.explain(self.Resolution)
end

function Component:SetEnabled(enabled)
	self.Enabled = enabled ~= false
	self:_applyState()
	return self.Enabled
end

function Component:IsEnabled()
	return self.Enabled ~= false
end

function Component:SetVisible(visible)
	self.Visible = visible ~= false
	self:_applyState()
	return self.Visible
end

function Component:IsVisible()
	return self.Visible ~= false
end

function Component:IsActuallyVisible()
	return self:IsVisible() and self.DependenciesMet ~= false
end

function Component:SetName(name)
	self.Name = tostring(name)
	if self.View and self.View.SetName then
		self.View.SetName(self.View, self.Name)
	end
	return self.Name
end

function Component:GetName()
	return self.Name
end

function Component:SetDescription(description)
	self.Description = tostring(description)
	return self.Description
end

function Component:SetCallback(callback)
	self.Callback = callback
	return true
end

function Component:AddDependency(spec, mode)
	assert(spec ~= nil, "AddDependency expects a dependency specification")
	local entry = {
		Spec = spec,
		Mode = mode or "Visible",
		Callback = nil,
	}
	if type(spec) == "table" and spec.Callback then
		entry.Callback = spec.Callback
		entry.Mode = spec.Mode or entry.Mode
		spec = Util.shallowCopy(spec)
		spec.Callback = nil
		spec.Mode = nil
		entry.Spec = spec
	end
	table.insert(self.Dependencies, entry)
	local flags = Dependency.flagsIn(entry.Spec, {})
	if self.Context and self.Context.DependencyHub then
		self._dependencyConnection = self.Context.DependencyHub:subscribe(flags, function(flag)
			if flag ~= self.Flag then
				self:EvaluateDependencies()
			end
		end)
		self:TrackConnection(self._dependencyConnection)
	end
	self:EvaluateDependencies()
	return entry
end

function Component:TrackConnection(connection)
	if connection then
		table.insert(self.Connections, connection)
	end
	return connection
end

function Component:EvaluateDependencies()
	if self.Destroyed then
		return true
	end
	local hub = self.Context and self.Context.DependencyHub
	local function getValue(flag)
		if hub then
			return hub:getValue(flag)
		end
		return nil
	end
	local met = true
	for _, entry in ipairs(self.Dependencies) do
		local satisfied = Dependency.matches(entry.Spec, getValue)
		entry.Satisfied = satisfied
		if not satisfied then
			met = false
		end
		if entry.Callback and entry.Triggered ~= satisfied then
			entry.Triggered = satisfied
			entry.Callback(satisfied, self)
		end
		if not satisfied and entry.Mode == "Enabled" then
			self.Enabled = false
		end
	end
	if self.DependenciesMet ~= met then
		self.DependenciesMet = met
	end
	local hideWhenUnmet = false
	for _, entry in ipairs(self.Dependencies) do
		if entry.Mode == "Visible" and not entry.Satisfied then
			hideWhenUnmet = true
			break
		end
	end
	self.DependenciesMet = not hideWhenUnmet
	self:_applyState()
	return met
end

function Component:GetDependencyState()
	local out = {}
	for _, entry in ipairs(self.Dependencies) do
		table.insert(out, {
			Description = Dependency.describe(entry.Spec),
			Mode = entry.Mode,
			Satisfied = entry.Satisfied == true,
		})
	end
	return out
end

function Component:SetOrder(order)
	self.Order = order
	if self.View and self.View.Root then
		self.View.Root.LayoutOrder = order
	end
	return order
end

function Component:GetOrder()
	return self.Order
end

function Component:Serialize()
	local value = self.Value
	if type(value) == "table" and getmetatable(value) ~= nil then
		local mode = getmetatable(value)
		local ok, text = pcall(function()
			return value:ToHex()
		end)
		if ok and text then
			value = text
		end
	end
	local style = self.StyleId
	local configuration = Util.deepCopy(self.StyleConfiguration)
	local hasStyleConfiguration = next(configuration) ~= nil
	return {
		Type = self.Type,
		Flag = self.Flag,
		Value = Util.deepCopy(value),
		Style = style,
		StyleConfiguration = hasStyleConfiguration and configuration or nil,
		Enabled = self.Enabled,
		Visible = self.Visible,
	}
end

function Component:Restore(data, options)
	options = options or {}
	if type(data) ~= "table" then
		return false, "Restore expects a serialized table"
	end
	if data.Style and Registry.get(data.Style) and data.Style ~= self.StyleId then
		self:SetStyle(data.Style, data.StyleConfiguration)
	elseif type(data.StyleConfiguration) == "table" then
		self:SetStyleConfiguration(data.StyleConfiguration, { Replace = true })
	end
	if data.Enabled ~= nil then
		self:SetEnabled(data.Enabled)
	end
	if data.Visible ~= nil then
		self:SetVisible(data.Visible)
	end
	if data.Value ~= nil then
		local value = data.Value
		local coerced, err = self:_coerce(value)
		if self.LastValueError ~= nil and coerced == self.Value and err ~= nil then
			return false, err
		end
		self:SetValue(value, {
			FromConfig = true,
			Silent = options.FireCallbacks == false,
		})
	end
	return true, nil
end

function Component:GetState()
	return {
		Id = self.Id,
		Type = self.Type,
		Flag = self.Flag,
		Name = self.Name,
		Value = self.Value,
		Default = self.Default,
		Style = self.StyleId,
		StyleConfiguration = Util.deepCopy(self.StyleConfiguration),
		EffectiveConfiguration = Util.deepCopy(self.Configuration),
		Enabled = self.Enabled,
		Visible = self.Visible,
		DependenciesMet = self.DependenciesMet,
		Dependencies = self:GetDependencyState(),
		Schema = self:GetSchema(),
		Diagnostics = {
			LastError = self.LastError,
			LastValueError = self.LastValueError,
			Warnings = self.Resolution and self.Resolution.Warnings or {},
			Errors = self.Resolution and self.Resolution.Errors or {},
		},
	}
end

function Component:Destroy()
	if self.Destroyed then
		return false
	end
	self.Destroyed = true
	self.DestroyedAt = os and os.clock and os.clock() or nil
	if self.Definition.BeforeDestroy then
		pcall(self.Definition.BeforeDestroy, self)
	end
	self.DestroyedSignal:Fire(self)
	self:_clearView()
	self.Changed:Destroy()
	self.DestroyedSignal:Destroy()
	if self.Context and self.Context.Store then
		self.Context.Store.unregister(self)
	end
	return true
end

function Component:OnDestroyed(callback)
	return self.DestroyedSignal:Connect(callback)
end

function Component:GetConnectionCount()
	return #self.Connections
end

function Component:GetInstanceCount()
	return #self.Instances
end

return Component
