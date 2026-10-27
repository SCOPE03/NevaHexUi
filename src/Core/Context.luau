--[[
	NEVAHEXUI - Core/Context
	The render/lifecycle context handed to every window, container and component.
	It carries the host back end, resolved theme tokens, style/category defaults,
	registries, diagnostics and the factory table used by containers to create
	components.
]]

local Util = require("NEVA:Core/Util")
local Logger = require("NEVA:Core/Logger")
local Store = require("NEVA:State/Store")
local Dependency = require("NEVA:Core/Dependency")
local Themes = require("NEVA:Themes/Registry")
local Styles = require("NEVA:Styles/Registry")

local Context = {}
Context.__index = Context

function Context.new(options)
	options = options or {}
	local self = setmetatable({}, Context)
	self.Options = options
	self.Host = options.Host
	self.Logger = options.Logger or Logger.new({ Level = options.LogLevel or Logger.Levels.Warn })
	self.Store = options.Store or Store
	self.DependencyHub = Dependency.newHub(self.Store)
	self.ThemeRegistry = Themes
	self.StyleRegistry = Styles
	self.ThemeId = options.Theme or "dark"
	self.ThemeOverrides = Util.deepCopy(options.ThemeConfiguration or {})
	self.StyleDefaults = Util.deepCopy(options.Styles or {})
	self.CategoryConfigurations = Util.deepCopy(options.StyleConfiguration or {})
	self.GlobalDefaults = Util.deepCopy(options.GlobalDefaults or {})
	self.Factories = {}
	self.Singletons = {}
	self.Diagnostics = { Errors = {}, Warnings = {}, Log = {} }
	self.Components = {}
	self.Scopes = {}
	self.Destroyed = false
	-- A context is also a valid render context for window chrome and other
	-- library-owned surfaces, so the fields Surface helpers read always exist.
	self.Configuration = {}
	self.Props = { Name = options.Name or "NEVAHEXUI" }
	self.State = {}
	self.Type = "Context"
	self:RefreshTheme()
	return self
end

function Context:RefreshTheme()
	local tokens, record, errors, warnings = self.ThemeRegistry.resolve(self.ThemeId, self.ThemeOverrides)
	self.Tokens = self.ThemeRegistry.forHost(self.Host, tokens)
	self.RawTokens = tokens
	self.ThemeRecord = record
	for _, message in ipairs(errors or {}) do
		self:Diagnostic("Error", ("theme %s: %s"):format(tostring(self.ThemeId), message))
	end
	for _, message in ipairs(warnings or {}) do
		self:Diagnostic("Warn", ("theme %s: %s"):format(tostring(self.ThemeId), message))
	end
	return self.Tokens
end

function Context:SetTheme(themeId, overrides)
	if not self.ThemeRegistry.has(themeId) then
		return false, ("unknown theme %q"):format(tostring(themeId))
	end
	self.ThemeId = themeId
	if overrides ~= nil then
		self.ThemeOverrides = Util.deepCopy(overrides)
	end
	self:RefreshTheme()
	for _, component in ipairs(self:AllComponents()) do
		if not component.Destroyed then
			component:_applyState()
		end
	end
	return true
end

function Context:GetTheme()
	return self.ThemeId
end

function Context:Diagnostic(level, message)
	local entry = { Level = level, Message = message, At = os and os.clock and os.clock() or nil }
	table.insert(self.Diagnostics.Log, entry)
	if level == "Error" then
		table.insert(self.Diagnostics.Errors, message)
		self.Logger:Error(message)
	elseif level == "Warn" then
		table.insert(self.Diagnostics.Warnings, message)
		self.Logger:Warn(message)
	else
		self.Logger:Info(message)
	end
	if #self.Diagnostics.Log > 500 then
		table.remove(self.Diagnostics.Log, 1)
	end
	return entry
end

function Context:SetStyleDefault(category, styleId)
	self.StyleDefaults[category] = styleId
	return true
end

function Context:StyleDefaultFor(componentType)
	local configured = self.StyleDefaults[componentType]
	if configured then
		return configured
	end
	local global = self.GlobalDefaults.Styles and self.GlobalDefaults.Styles[componentType]
	if global then
		return global
	end
	local defaultId = self.StyleRegistry.defaultStyleId(componentType)
	return defaultId
end

function Context:CategoryConfigurationFor(componentType)
	local configured = self.CategoryConfigurations[componentType]
	local global = self.GlobalDefaults.StyleConfiguration and self.GlobalDefaults.StyleConfiguration[componentType]
	if configured and global then
		return Util.deepMerge(global, configured)
	end
	return Util.deepCopy(configured or global or {})
end

function Context:SetCategoryConfiguration(componentType, configuration, options)
	options = options or {}
	if options.Replace then
		self.CategoryConfigurations[componentType] = Util.deepCopy(configuration)
	else
		self.CategoryConfigurations[componentType] = Util.deepMerge(
			self.CategoryConfigurations[componentType] or {},
			configuration
		)
	end
	for _, component in ipairs(self:ComponentsOfType(componentType)) do
		if not component.Destroyed then
			component:Refresh("category-configuration")
		end
	end
	return self.CategoryConfigurations[componentType]
end

function Context:RegisterComponent(component)
	table.insert(self.Components, component)
	local ok, err = self.Store.register(component)
	if not ok then
		self:Diagnostic("Warn", err or "component registration failed")
	end
	component:EvaluateDependencies()
	return component
end

function Context:AllComponents()
	return self.Components
end

function Context:ComponentsOfType(componentType)
	local out = {}
	for _, component in ipairs(self.Components) do
		if component.Type == componentType then
			table.insert(out, component)
		end
	end
	return out
end

function Context:ComponentCount()
	return #self.Components
end

function Context:RegisterScope(scope)
	table.insert(self.Scopes, scope)
	return scope
end

function Context:FindComponent(flagOrId)
	return self.Store.get(flagOrId)
end

function Context:Factory(componentType)
	return self.Factories[componentType]
end

function Context:Create(componentType, container, spec)
	local class = self.Factories[componentType]
	assert(class, ("NEVAHEXUI: no component factory registered for %q"):format(tostring(componentType)))
	local Component = require("NEVA:Core/Component")
	local component = Component.create(class, self, container, spec)
	-- Registration is centralised here: every component is counted by its
	-- container and reachable through the synchronised store/registries.
	if container and container.AddChild then
		container:AddChild(component)
	end
	self:RegisterComponent(component)
	if spec and spec.DependsOn or (spec and spec.Dependencies) then
		component:EvaluateDependencies()
	end
	return component
end

function Context:Summary()
	return {
		Theme = self.ThemeId,
		Host = self.Host.Kind,
		Components = #self.Components,
		Scopes = #self.Scopes,
		Styles = self.StyleRegistry.count(),
		Themes = self.ThemeRegistry.count(),
		Errors = #self.Diagnostics.Errors,
		Warnings = #self.Diagnostics.Warnings,
	}
end

function Context:Destroy()
	if self.Destroyed then
		return
	end
	self.Destroyed = true
	for _, scope in ipairs(self.Scopes) do
		if scope.Destroy then
			pcall(function()
				scope:Destroy()
			end)
		end
	end
	for _, component in ipairs(self.Components) do
		if not component.Destroyed and component.Destroy then
			pcall(function()
				component:Destroy()
			end)
		end
	end
	self.Components = {}
	self.Store.reset()
end

return Context
