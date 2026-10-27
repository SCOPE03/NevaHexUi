--[[
	NEVAHEXUI - Configuration/Config
	Versioned configuration persistence. Files are written as JSON, so importing a
	configuration never executes Luau. When the runtime has no filesystem the
	system silently falls back to an in-memory store and reports that persistence
	is session-only.
]]

local Util = require("NEVA:Core/Util")
local Json = require("NEVA:Configuration/Json")
local Themes = require("NEVA:Themes/Registry")
local Styles = require("NEVA:Styles/Registry")

local Config = {}
Config.__index = Config

Config.Version = 2

local function now()
	local ok, value = pcall(function()
		return os.time()
	end)
	if ok and type(value) == "number" then
		return value
	end
	return nil
end

function Config.new(context, options)
	options = options or {}
	local self = setmetatable({}, Config)
	self.Context = context
	self.Host = context.Host
	self.Folder = options.Folder or "NEVAHEXUI"
	self.Persistent = context.Host.Capabilities.filesystem == true
	self.SaveEnabled = options.SaveConfigs ~= false
	self.Memory = {}
	self.AutoSaveKey = options.AutoSaveKey
	self.LastError = nil
	if self.Persistent then
		pcall(function()
			self.Host.fs.makefolder(self.Folder)
		end)
	end
	return self
end

function Config:_path(name)
	return ("%s/%s.json"):format(self.Folder, name)
end

function Config:IsPersistent()
	return self.Persistent
end

function Config:Describe()
	return {
		Folder = self.Folder,
		Persistent = self.Persistent,
		SaveEnabled = self.SaveEnabled,
		Version = Config.Version,
		Names = self:List(),
	}
end

function Config:Snapshot()
	local components = {}
	for _, component in ipairs(self.Context:AllComponents()) do
		if not component.Destroyed then
			components[component.Flag or component.Id] = component:Serialize()
		end
	end
	return {
		Version = Config.Version,
		CreatedAt = now(),
		Theme = self.Context.ThemeId,
		ThemeConfiguration = Util.deepCopy(self.Context.ThemeOverrides),
		Layout = self.Context.Options.Layout,
		Styles = Util.deepCopy(self.Context.StyleDefaults),
		StyleConfiguration = Util.deepCopy(self.Context.CategoryConfigurations),
		Components = components,
	}
end

function Config:Encode(name, payload)
	local document = Util.deepCopy(payload or {})
	document.Version = document.Version or Config.Version
	document.Name = name or document.Name
	document.CreatedAt = document.CreatedAt or now()
	document.UpdatedAt = now()
	return Json.encode(document)
end

function Config:Decode(text)
	local data, err = Json.decode(text)
	if not data then
		return nil, err
	end
	if type(data) ~= "table" then
		return nil, "configuration root must be an object"
	end
	return self:Migrate(data)
end

-- Upgrades payloads written by older versions and repairs missing sections.
function Config:Migrate(data)
	local version = tonumber(data.Version) or 1
	local migrated = data
	if version < Config.Version then
		migrated.Components = migrated.Components or {}
		migrated.Styles = migrated.Styles or {}
		migrated.StyleConfiguration = migrated.StyleConfiguration or {}
		migrated.SchemaVersion = Config.Version
		migrated.MigratedFrom = version
	end
	migrated.Version = Config.Version
	return migrated
end

function Config:Validate(data)
	local errors = {}
	local warnings = {}
	if type(data) ~= "table" then
		return false, { "configuration must be an object" }, warnings
	end
	if data.Theme ~= nil and not Themes.has(data.Theme) then
		table.insert(warnings, ("unknown theme %q; keeping the current theme"):format(tostring(data.Theme)))
	end
	if data.Styles ~= nil then
		if type(data.Styles) ~= "table" then
			table.insert(errors, "Styles must be a table of category -> style id")
		else
			for category, styleId in pairs(data.Styles) do
				local style = Styles.get(styleId)
				if not style then
					table.insert(warnings, ("unknown style %q for %s"):format(tostring(styleId), tostring(category)))
				elseif style.Component ~= category then
					table.insert(warnings, ("style %q does not render %s"):format(styleId, tostring(category)))
				end
			end
		end
	end
	if data.Components ~= nil and type(data.Components) ~= "table" then
		table.insert(errors, "Components must be a table of flag -> value")
	end
	return #errors == 0, errors, warnings
end

function Config:Save(name, payload)
	if not self.SaveEnabled then
		return false, "configuration saving is disabled"
	end
	assert(type(name) == "string" and name ~= "", "Config:Save expects a name")
	local document = payload or self:Snapshot()
	local text = self:Encode(name, document)
	if self.Persistent then
		local ok, err = pcall(function()
			self.Host.fs.writefile(self:_path(name), text)
		end)
		if not ok then
			self.LastError = err
			return false, err
		end
		return true, nil, text
	end
	self.Memory[name] = text
	return true, "session-only (no filesystem available)", text
end

function Config:Load(name)
	local text
	if self.Persistent then
		local path = self:_path(name)
		local exists = false
		pcall(function()
			exists = self.Host.fs.isfile(path)
		end)
		if not exists then
			return nil, ("configuration %q does not exist"):format(name)
		end
		local ok, contents = pcall(function()
			return self.Host.fs.readfile(path)
		end)
		if not ok then
			self.LastError = contents
			return nil, contents
		end
		text = contents
	else
		text = self.Memory[name]
		if not text then
			return nil, ("configuration %q does not exist in memory"):format(name)
		end
	end
	local data, err = self:Decode(text)
	if not data then
		return nil, err
	end
	local ok, errors = self:Validate(data)
	if not ok then
		return nil, table.concat(errors, "; ")
	end
	return data, nil
end

function Config:Exists(name)
	if self.Persistent then
		local exists = false
		pcall(function()
			exists = self.Host.fs.isfile(self:_path(name))
		end)
		return exists
	end
	return self.Memory[name] ~= nil
end

function Config:List()
	if self.Persistent then
		local files = {}
		local ok, listed = pcall(function()
			return self.Host.fs.listfiles(self.Folder)
		end)
		if ok and listed then
			files = listed
		end
		local names = {}
		local prefix = self.Folder .. "/"
		for _, path in ipairs(files) do
			if path:sub(1, #prefix) == prefix and path:sub(-5) == ".json" then
				table.insert(names, path:sub(#prefix + 1, -6))
			end
		end
		table.sort(names)
		return names
	end
	local names = {}
	for name in pairs(self.Memory) do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

function Config:Delete(name)
	if self.Persistent then
		local ok = pcall(function()
			self.Host.fs.delfile(self:_path(name))
		end)
		return ok
	end
	if self.Memory[name] == nil then
		return false
	end
	self.Memory[name] = nil
	return true
end

function Config:Export(payload)
	return self:Encode(payload and payload.Name, payload or self:Snapshot())
end

function Config:Import(text, name, options)
	options = options or {}
	local data, err = self:Decode(text)
	if not data then
		return false, err
	end
	local ok, errors = self:Validate(data)
	if not ok then
		return false, table.concat(errors, "; ")
	end
	if name then
		local saved, saveErr = self:Save(name, data)
		if not saved then
			return false, saveErr
		end
	end
	if options.Apply ~= false then
		return self:Apply(data, options), nil, data
	end
	return true, nil, data
end

-- Applies a configuration payload to the live interface. Component values are
-- restored without firing callbacks unless the payload requests it.
function Config:Apply(data, options)
	options = options or {}
	local applied = { Components = 0, Styles = 0, Theme = false }
	if type(data) ~= "table" then
		return false, "configuration must be a table"
	end
	if data.Theme and Themes.has(data.Theme) then
		local ok = self.Context:SetTheme(data.Theme, data.ThemeConfiguration)
		applied.Theme = ok == true
	end
	if type(data.Styles) == "table" then
		for category, styleId in pairs(data.Styles) do
			if Styles.get(styleId) then
				self.Context:SetStyleDefault(category, styleId)
				applied.Styles += 1
			end
		end
	end
	if type(data.StyleConfiguration) == "table" then
		for category, configuration in pairs(data.StyleConfiguration) do
			self.Context:SetCategoryConfiguration(category, configuration, { Replace = true })
		end
	end
	if type(data.Components) == "table" then
		for flag, entry in pairs(data.Components) do
			local component = self.Context.Store.get(flag)
			if component then
				local ok = component:Restore(entry, options)
				if ok then
					applied.Components += 1
				end
			end
		end
	end
	return true, nil, applied
end

function Config:Destroy()
	self.Memory = {}
	self.Context = nil
end

return Config
