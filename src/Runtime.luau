--[[
	NEVAHEXUI - Runtime
	The public entry point: `local NEVAHEXUI = require(...)` then
	`NEVAHEXUI:CreateWindow{...}`.

	The runtime owns the library-wide layer: host/back-end selection, the style and
	theme catalogues, global defaults, the synchronised component registries
	(`Toggles.Flag.Value`), and window creation. Style definitions are loaded here
	because registration order defines each component's default style.
]]

local Host = require("NEVA:Compatibility/Host")
local Capabilities = require("NEVA:Compatibility/Capabilities")
local Context = require("NEVA:Core/Context")
local Layouts = require("NEVA:Core/Layouts")
local Logger = require("NEVA:Core/Logger")
local Util = require("NEVA:Core/Util")
local Store = require("NEVA:State/Store")
local Keybinder = require("NEVA:Input/Keybinder")
local Styles = require("NEVA:Styles/Registry")
local Schema = require("NEVA:Styles/Schema")
local Resolver = require("NEVA:Styles/Resolver")
local Themes = require("NEVA:Themes/Registry")
local ThemesDefs = require("NEVA:Themes/Defs")
local Components = require("NEVA:Components/Index")
local Animation = require("NEVA:Animation/Presets")
local Json = require("NEVA:Configuration/Json")

-- Style definition modules. Requiring a module registers its component
-- descriptors and its style renderers.
local styleModules = {
	{ Name = "Buttons", Load = function() return require("NEVA:Styles/Defs/Buttons") end },
	{ Name = "Toggles", Load = function() return require("NEVA:Styles/Defs/Toggles") end },
	{ Name = "Sliders", Load = function() return require("NEVA:Styles/Defs/Sliders") end },
	{ Name = "TextInputs", Load = function() return require("NEVA:Styles/Defs/TextInputs") end },
	{ Name = "Display", Load = function() return require("NEVA:Styles/Defs/Display") end },
	{ Name = "DataViews", Load = function() return require("NEVA:Styles/Defs/DataViews") end },
	{ Name = "Pickers", Load = function() return require("NEVA:Styles/Defs/Pickers") end },
	{ Name = "Feedback", Load = function() return require("NEVA:Styles/Defs/Feedback") end },
}

local NEVAHEXUI = {}
NEVAHEXUI.Version = "1.0.0"
NEVAHEXUI.Name = "NEVAHEXUI"
NEVAHEXUI.Tagline = "Unified Roblox Luau UI framework with a configurable style engine"
NEVAHEXUI.Styles = Styles
NEVAHEXUI.Themes = Themes
NEVAHEXUI.Layouts = Layouts
NEVAHEXUI.Animation = Animation
NEVAHEXUI.Store = Store
NEVAHEXUI.Schema = Schema
NEVAHEXUI._Loaded = false
NEVAHEXUI.Windows = {}
NEVAHEXUI.Registries = {}

-- Loading --------------------------------------------------------------------

function NEVAHEXUI:Load(options)
	options = options or {}
	if self._Loaded and not options.Force then
		return self
	end
	self.Capabilities = Capabilities.detect()
	self.Logger = Logger.new({ Level = options.LogLevel or Logger.Levels.Warn, Name = "NEVAHEXUI" })
	self.Host = options.Host or Host.create({ Capabilities = self.Capabilities })
	Host.verify(self.Host)
	for _, entry in ipairs(styleModules) do
		local ok, err = pcall(entry.Load)
		if not ok then
			self.LoadingErrors = self.LoadingErrors or {}
			table.insert(self.LoadingErrors, { Module = entry.Name, Error = tostring(err) })
			self.Logger:Error(("style module %s failed to load: %s"):format(entry.Name, tostring(err)))
		end
	end
	self._Loaded = true
	self:BuildRegistries()
	self.GlobalDefaults = {
		Theme = options.Theme or "dark",
		Accent = options.Accent, -- themes define the default accent (red); only override when asked
		StyleConfiguration = Util.deepCopy(options.StyleConfiguration or {}),
		Styles = Util.deepCopy(options.Styles or {}),
		Layout = options.Layout or "Sidebar",
	}
	return self
end

function NEVAHEXUI:EnsureLoaded()
	if not self._Loaded then
		self:Load()
	end
	return self
end

-- Catalogues -----------------------------------------------------------------

function NEVAHEXUI:RegisterStyle(definition)
	self:EnsureLoaded()
	if type(definition) ~= "table" then
		return nil, { "RegisterStyle expects a table" }
	end
	-- A preset may inherit its renderer from the style it extends, so
	-- `RegisterStyle{ Id = "toggle.neva.red", Requires = "toggle.rounded",
	-- Configuration = {...} }` works without handing over a function reference.
	-- The registry itself stays strict: every stored style has a callable Render.
	local prepared = Util.deepCopy(definition)
	if prepared.Render == nil and prepared.Requires ~= nil then
		local parent = Styles.get(prepared.Requires)
		if parent == nil then
			return nil, { ("Requires references unknown style %q"):format(tostring(prepared.Requires)) }
		end
		prepared.Render = parent.Render
	end
	local record, errors = Styles.registerStyle(prepared)
	if not record then
		return nil, errors
	end
	self:_RecordUserStyle(record.Id)
	return record
end

function NEVAHEXUI:RegisterTheme(definition)
	self:EnsureLoaded()
	return Themes.register(definition)
end

function NEVAHEXUI:UnregisterStyle(id)
	self:EnsureLoaded()
	return Styles.unregister(id)
end

function NEVAHEXUI:GetStyle(id)
	self:EnsureLoaded()
	return Styles.get(id)
end

function NEVAHEXUI:HasStyle(id)
	self:EnsureLoaded()
	return Styles.has(id)
end

function NEVAHEXUI:ListStyles(component)
	self:EnsureLoaded()
	if component then
		return Styles.list(component)
	end
	return Styles.catalog()
end

function NEVAHEXUI:StyleIds(component)
	self:EnsureLoaded()
	if component then
		return Styles.styleIds(component)
	end
	local out = {}
	for _, entry in ipairs(Styles.catalog()) do
		table.insert(out, entry.Id)
	end
	return out
end

function NEVAHEXUI:ListComponents()
	self:EnsureLoaded()
	return Styles.listComponents()
end

function NEVAHEXUI:ListThemes()
	self:EnsureLoaded()
	return Themes.list()
end

function NEVAHEXUI:ListLayouts()
	return Layouts.list()
end

function NEVAHEXUI:ListAnimations()
	return Animation.list()
end

function NEVAHEXUI:Explain(styleId, request)
	self:EnsureLoaded()
	local record = Styles.get(styleId)
	if not record then
		return nil, ("unknown style %q"):format(tostring(styleId))
	end
	local chain = Styles.chain(styleId)
	return {
		Style = record,
		Properties = Styles.effectiveProperties(chain),
		Chain = chain,
		Requires = record.Requires,
		Request = request,
	}
end

function NEVAHEXUI:ExportStyle(styleId, options)
	self:EnsureLoaded()
	local record = Styles.get(styleId)
	if not record then
		return nil, ("unknown style %q"):format(tostring(styleId))
	end
	return Schema.exportStyle(record, options)
end

function NEVAHEXUI:ExportConfiguration(componentType, configuration)
	self:EnsureLoaded()
	local record = Styles.get(componentType)
	return Schema.exportLua(configuration, record and Styles.effectiveProperties(Styles.chain(record.Id)) or {})
end

-- Registries -----------------------------------------------------------------

function NEVAHEXUI:_RecordUserStyle(id)
	self.UserStyles = self.UserStyles or {}
	self.UserStyles[id] = true
end

function NEVAHEXUI:BuildRegistries()
	self.Registries = {}
	for _, component in ipairs(Styles.listComponents()) do
		local name = component.RegistryName
		if name and name ~= "" and self.Registries[name] == nil then
			self.Registries[name] = setmetatable({}, {
				__index = function(_, key)
					local entry = Store.get(key)
					if entry then
						return entry
					end
					return Store.getById(key)
				end,
				__newindex = function() end,
			})
		end
	end
	return self.Registries
end

function NEVAHEXUI:GetRegistry(name)
	self:EnsureLoaded()
	return self.Registries[name]
end

function NEVAHEXUI:GetComponent(flagOrId)
	self:EnsureLoaded()
	return Store.get(flagOrId) or Store.getById(flagOrId)
end

function NEVAHEXUI:FindAll(flag)
	self:EnsureLoaded()
	return Store.getAll(flag)
end

-- Library configuration -----------------------------------------------------

function NEVAHEXUI:SetGlobalDefaults(configuration)
	self:EnsureLoaded()
	configuration = configuration or {}
	if configuration.Theme then
		self.GlobalDefaults.Theme = configuration.Theme
	end
	if configuration.Accent then
		self.GlobalDefaults.Accent = configuration.Accent
	end
	if configuration.Layout then
		self.GlobalDefaults.Layout = configuration.Layout
	end
	if configuration.Styles then
		self.GlobalDefaults.Styles = Util.deepMerge(self.GlobalDefaults.Styles or {}, configuration.Styles)
	end
	if configuration.StyleConfiguration then
		self.GlobalDefaults.StyleConfiguration = Util.deepMerge(
			self.GlobalDefaults.StyleConfiguration or {},
			configuration.StyleConfiguration
		)
	end
	for _, context in ipairs(self.Contexts or {}) do
		context.GlobalDefaults = self.GlobalDefaults
	end
	return self.GlobalDefaults
end

function NEVAHEXUI:GetGlobalDefaults()
	return self.GlobalDefaults
end

function NEVAHEXUI:SetCategoryStyle(component, styleId)
	for _, context in ipairs(self.Contexts or {}) do
		context:SetStyleDefault(component, styleId)
	end
	return true
end

function NEVAHEXUI:SetCategoryConfiguration(component, configuration, options)
	for _, context in ipairs(self.Contexts or {}) do
		context:SetCategoryConfiguration(component, configuration, options)
	end
	return true
end

function NEVAHEXUI:SetComponentStyle(flagOrId, styleId, configuration)
	self:EnsureLoaded()
	local component = self:GetComponent(flagOrId)
	if not component then
		return false, ("no component registered for %q"):format(tostring(flagOrId))
	end
	return component:SetStyle(styleId, configuration)
end

function NEVAHEXUI:SetTheme(themeId, overrides)
	for _, context in ipairs(self.Contexts or {}) do
		context:SetTheme(themeId, overrides)
	end
	return true
end

-- Window creation ------------------------------------------------------------

function NEVAHEXUI:CreateWindow(options)
	options = options or {}
	self:EnsureLoaded()
	self.Contexts = self.Contexts or {}

	local configuration = options.Configuration or {}
	local global = self.GlobalDefaults or {}
	local context = Context.new({
		Host = self.Host,
		Logger = self.Logger,
		Theme = options.Theme or configuration.Theme or global.Theme,
		ThemeConfiguration = options.ThemeConfiguration or configuration.ThemeConfiguration,
		Styles = options.Styles or global.Styles,
		StyleConfiguration = options.StyleConfiguration or global.StyleConfiguration,
		GlobalDefaults = {
			Styles = global.Styles,
			StyleConfiguration = global.StyleConfiguration,
		},
		LogLevel = options.LogLevel,
		Name = options.Name,
	})
	context.Keybinder = Keybinder.new(self.Host, { Name = options.Name or "NEVAHEXUI" })
	Components.install(context)

	local Window = require("NEVA:Core/Window")
	local merged = Util.deepMerge({
		Layout = options.Layout or global.Layout,
		Accent = configuration.Accent or global.Accent,
	}, options)
	local window = Window.new(context, merged)
	self.Windows[#self.Windows + 1] = window
	table.insert(self.Contexts, context)
	return window
end

function NEVAHEXUI:GetWindows()
	return self.Windows
end

function NEVAHEXUI:GetPrimaryWindow()
	return self.Windows[1]
end

function NEVAHEXUI:Notify(message, options)
	local window = self:GetPrimaryWindow()
	if not window then
		return nil, "no window has been created yet"
	end
	if type(options) == "table" then
		options.Message = options.Message or message
		return window:Notify(options)
	end
	return window:Notify({ Message = message, Level = options })
end

function NEVAHEXUI:Dialog(options)
	local window = self:GetPrimaryWindow()
	if not window then
		return nil, "no window has been created yet"
	end
	return window:Dialog(options)
end

function NEVAHEXUI:OpenStudio(options)
	local window = self:GetPrimaryWindow()
	if not window then
		return nil, "no window has been created yet"
	end
	return window:OpenStudio(options)
end

-- Diagnostics ----------------------------------------------------------------

function NEVAHEXUI:Summary()
	self:EnsureLoaded()
	return {
		Version = self.Version,
		Host = self.Host and self.Host.Kind or "unknown",
		Styles = Styles.count(),
		Themes = Themes.count(),
		Layouts = #Layouts.ids(),
		Components = #Styles.listComponents(),
		Windows = #self.Windows,
		LoadingErrors = self.LoadingErrors and #self.LoadingErrors or 0,
	}
end

function NEVAHEXUI:Diagnostics()
	self:EnsureLoaded()
	local report = {
		Summary = self:Summary(),
		LoadingErrors = self.LoadingErrors or {},
		Capabilities = self.Capabilities,
		DuplicateFlags = Store.duplicates(),
		Components = {},
	}
	for _, component in ipairs(Store.all()) do
		if component.LastError or component.LastValueError then
			table.insert(report.Components, {
				Flag = component.Flag,
				Type = component.Type,
				Style = component.StyleId,
				Error = component.LastError,
				ValueError = component.LastValueError,
			})
		end
	end
	return report
end

function NEVAHEXUI:PrintCatalog(filter)
	self:EnsureLoaded()
	local lines = {}
	for _, entry in ipairs(Styles.catalog()) do
		if not filter or entry.Component == filter or (entry.Id or ""):find(filter, 1, true) then
			table.insert(lines, ("%s  (%s)  %s"):format(entry.Id, tostring(entry.Component), tostring(entry.Name)))
		end
	end
	return lines
end

function NEVAHEXUI:Destroy()
	for _, window in ipairs(self.Windows) do
		if not window.Destroyed then
			pcall(function()
				window:Destroy()
			end)
		end
	end
	for _, context in ipairs(self.Contexts or {}) do
		pcall(function()
			context:Destroy()
		end)
	end
	self.Windows = {}
	self.Contexts = {}
	Store.reset()
	return true
end

NEVAHEXUI.Json = Json

return NEVAHEXUI
