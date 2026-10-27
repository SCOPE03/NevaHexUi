--[[
	NEVAHEXUI - Input/Keybinder
	Central keyboard manager. Owns every key binding in the library so conflicts
	can be detected, saved and restored, and so bindings are released when a
	component or window is destroyed.
]]

local Util = require("NEVA:Core/Util")

local Keybinder = {}
Keybinder.__index = Keybinder

Keybinder.Modes = { "Hold", "Toggle" }

function Keybinder.new(host, options)
	options = options or {}
	local self = setmetatable({}, Keybinder)
	self.Host = host
	self.Bindings = {}
	self.Order = {}
	self.Enabled = options.Enabled ~= false
	self.WarnOnConflict = options.WarnOnConflict ~= false
	self.OnConflict = options.OnConflict
	self.Conflicts = {}
	return self
end

function Keybinder:_connects(binding)
	local function handler(state)
		if not self.Enabled or not binding.Enabled or not binding.Bound then
			return
		end
		local mode = binding.Mode
		if mode == "Toggle" then
			if state == "Begin" then
				binding.Active = not binding.Active
				if binding.Callback then
					binding.Callback(binding.Active, "Toggle", binding)
				end
			end
		else
			if state == "Begin" then
				binding.Active = true
				if binding.Callback then
					binding.Callback(true, "Hold", binding)
				end
			end
		end
	end
	if binding.Connection then
		binding.Connection:Disconnect()
	end
	binding.Connection = self.Host.inputBind(binding.Key, handler)
end

function Keybinder:Bind(name, key, callback, options)
	options = options or {}
	assert(type(name) == "string" and name ~= "", "Keybinder:Bind expects a name")
	if self.Bindings[name] then
		self:Unbind(name)
	end
	local binding = {
		Name = name,
		Key = key,
		Callback = callback,
		Mode = options.Mode or "Hold",
		Enabled = options.Enabled ~= false,
		Bound = key ~= nil and key ~= false and key ~= "None",
		Active = false,
		Order = options.Order or #self.Order + 1,
		Owner = options.Owner,
	}
	self.Bindings[name] = binding
	table.insert(self.Order, name)
	if binding.Bound then
		self:_connects(binding)
	end
	self:_refreshConflicts()
	return binding
end

function Keybinder:Unbind(name)
	local binding = self.Bindings[name]
	if not binding then
		return false
	end
	if binding.Connection then
		binding.Connection:Disconnect()
		binding.Connection = nil
	end
	self.Bindings[name] = nil
	for index, candidate in ipairs(self.Order) do
		if candidate == name then
			table.remove(self.Order, index)
			break
		end
	end
	self:_refreshConflicts()
	return true
end

function Keybinder:SetKey(name, key)
	local binding = self.Bindings[name]
	if not binding then
		return false, ("unknown binding %q"):format(tostring(name))
	end
	binding.Key = key
	binding.Bound = key ~= nil and key ~= false and key ~= "None"
	if binding.Bound then
		self:_connects(binding)
	elseif binding.Connection then
		binding.Connection:Disconnect()
		binding.Connection = nil
	end
	self:_refreshConflicts()
	return true
end

function Keybinder:Get(name)
	return self.Bindings[name]
end

function Keybinder:List()
	local out = {}
	for _, name in ipairs(self.Order) do
		local binding = self.Bindings[name]
		table.insert(out, {
			Name = binding.Name,
			Key = binding.Key,
			Mode = binding.Mode,
			Enabled = binding.Enabled,
			Bound = binding.Bound,
			Active = binding.Active,
			Owner = binding.Owner,
		})
	end
	return out
end

function Keybinder:_refreshConflicts()
	local byKey = {}
	local duplicates = {}
	for _, name in ipairs(self.Order) do
		local binding = self.Bindings[name]
		if binding.Bound then
			local existing = byKey[binding.Key]
			if existing then
				if not duplicates[binding.Key] then
					duplicates[binding.Key] = { existing }
				end
				table.insert(duplicates[binding.Key], binding)
			else
				byKey[binding.Key] = binding
			end
		end
	end
	self.Conflicts = duplicates
	for key, list in pairs(duplicates) do
		if self.WarnOnConflict and self.OnConflict then
			self.OnConflict(key, list)
		end
	end
	return duplicates
end

function Keybinder:GetConflicts()
	local out = {}
	for key, list in pairs(self.Conflicts) do
		local names = {}
		for _, binding in ipairs(list) do
			table.insert(names, binding.Name)
		end
		table.insert(out, { Key = key, Names = names })
	end
	table.sort(out, function(a, b)
		return tostring(a.Key) < tostring(b.Key)
	end)
	return out
end

function Keybinder:SetEnabled(enabled)
	self.Enabled = enabled ~= false
	return self.Enabled
end

function Keybinder:IsKeyActive(key)
	for _, name in ipairs(self.Order) do
		local binding = self.Bindings[name]
		if binding.Key == key then
			return binding.Active == true
		end
	end
	return false
end

-- Programmatic trigger, used by tests and by custom component tooling.
function Keybinder:Fire(key, state)
	local fired = 0
	for _, name in ipairs(self.Order) do
		local binding = self.Bindings[name]
		if binding.Bound and binding.Enabled and binding.Key == key then
			fired += 1
			if binding.Mode == "Toggle" then
				binding.Active = not binding.Active
				if binding.Callback then
					binding.Callback(binding.Active, "Toggle", binding)
				end
			else
				binding.Active = state ~= "End"
				if binding.Callback then
					binding.Callback(binding.Active, "Hold", binding)
				end
			end
		end
	end
	return fired
end

function Keybinder:Save()
	local out = {}
	for _, name in ipairs(self.Order) do
		local binding = self.Bindings[name]
		out[name] = { Key = binding.Key, Mode = binding.Mode, Enabled = binding.Enabled }
	end
	return out
end

function Keybinder:Load(data)
	if type(data) ~= "table" then
		return false, "expected a table of bindings"
	end
	for name, entry in pairs(data) do
		if type(entry) == "table" and self.Bindings[name] then
			if entry.Key ~= nil then
				self:SetKey(name, entry.Key)
			end
			if entry.Mode ~= nil then
				self.Bindings[name].Mode = entry.Mode
			end
			if entry.Enabled ~= nil then
				self.Bindings[name].Enabled = entry.Enabled ~= false
			end
		end
	end
	return true
end

function Keybinder:Destroy()
	for _, name in ipairs(self.Order) do
		local binding = self.Bindings[name]
		if binding.Connection then
			binding.Connection:Disconnect()
		end
	end
	self.Bindings = {}
	self.Order = {}
	self.Conflicts = {}
end

return Keybinder
