--[[
	NEVAHEXUI - State/Store
	Component and flag registry. Component objects and registry entries stay
	synchronised because the component is the only thing that writes state: the
	store holds references, never copies of values.

	Duplicate flags are handled deterministically: the first component registered
	with a flag becomes the canonical registry entry, later duplicates stay
	reachable through Store.getAll(flag) and are reported as warnings.
]]

local Util = require("NEVA:Core/Util")

local Store = {}

Store.Components = {}
Store.ByFlag = {}
Store.ByFlagAll = {}
Store.ByType = {}
Store.Order = {}
Store.Duplicates = {}
Store.Warnings = {}

function Store.reset()
	Store.Components = {}
	Store.ByFlag = {}
	Store.ByFlagAll = {}
	Store.ByType = {}
	Store.Order = {}
	Store.Duplicates = {}
	Store.Warnings = {}
end

function Store.register(component)
	assert(component and component.Id, "Store.register expects a component with an Id")
	if Store.Components[component.Id] then
		return false, ("component id %q is already registered"):format(component.Id)
	end
	Store.Components[component.Id] = component
	table.insert(Store.Order, component.Id)

	local flag = component.Flag
	if flag and flag ~= "" then
		local list = Store.ByFlagAll[flag]
		if not list then
			list = {}
			Store.ByFlagAll[flag] = list
		end
		if Store.ByFlag[flag] == nil then
			Store.ByFlag[flag] = component
		else
			component.DuplicateOf = Store.ByFlag[flag]
			table.insert(Store.Duplicates, {
				Flag = flag,
				Canonical = Store.ByFlag[flag].Id,
				Duplicate = component.Id,
				Type = component.Type,
			})
			table.insert(Store.Warnings, ("duplicate flag %q registered by %s; the first component stays canonical")
				:format(flag, component.Type))
		end
		table.insert(list, component)
	end

	local typeTable = Store.ByType[component.Type]
	if not typeTable then
		typeTable = {}
		Store.ByType[component.Type] = typeTable
	end
	typeTable[flag or component.Id] = component

	return true, nil
end

function Store.unregister(component)
	if type(component) == "string" then
		component = Store.Components[component]
	end
	if not component then
		return false
	end
	if Store.Components[component.Id] ~= component then
		return false
	end
	Store.Components[component.Id] = nil
	for index, id in ipairs(Store.Order) do
		if id == component.Id then
			table.remove(Store.Order, index)
			break
		end
	end
	local flag = component.Flag
	if flag and Store.ByFlagAll[flag] then
		local list = Store.ByFlagAll[flag]
		for index, candidate in ipairs(list) do
			if candidate == component then
				table.remove(list, index)
				break
			end
		end
		if #list == 0 then
			Store.ByFlagAll[flag] = nil
		end
		if Store.ByFlag[flag] == component then
			Store.ByFlag[flag] = list[1]
			if Store.ByFlag[flag] then
				Store.ByFlag[flag].DuplicateOf = nil
			end
		end
	end
	local typeTable = Store.ByType[component.Type]
	if typeTable then
		if typeTable[flag or component.Id] == component then
			typeTable[flag or component.Id] = nil
		end
		if next(typeTable) == nil then
			Store.ByType[component.Type] = nil
		end
	end
	return true
end

function Store.get(flag)
	if flag == nil then
		return nil
	end
	return Store.ByFlag[flag] or Store.Components[flag]
end

function Store.getById(id)
	return Store.Components[id]
end

function Store.getAll(flag)
	local list = Store.ByFlagAll[flag]
	if not list then
		return {}
	end
	local copy = {}
	for _, component in ipairs(list) do
		table.insert(copy, component)
	end
	return copy
end

function Store.list(typeName)
	local typeTable = Store.ByType[typeName]
	if not typeTable then
		return {}
	end
	local out = {}
	for _, key in ipairs(Util.keys(typeTable)) do
		table.insert(out, typeTable[key])
	end
	return out
end

function Store.typeNames()
	return Util.keys(Store.ByType)
end

function Store.count()
	return #Store.Order
end

function Store.duplicates()
	return Store.Duplicates
end

function Store.flags()
	return Util.keys(Store.ByFlagAll)
end

function Store.snapshot()
	local values = {}
	for _, component in ipairs(Store.list("__all")) do
		values[component.Flag or component.Id] = component:GetValue()
	end
	return values
end

-- Reading every value pretty-prints through Component:Serialize so that config
-- persistence and diagnostics share one representation.
function Store.serialize(types)
	local out = {}
	local names = types or Store.typeNames()
	for _, typeName in ipairs(names) do
		for _, component in ipairs(Store.list(typeName)) do
			if Util.isCallable(component.Serialize) then
				out[component.Flag or component.Id] = component:Serialize()
			end
		end
	end
	return out
end

function Store.all()
	local out = {}
	for _, id in ipairs(Store.Order) do
		table.insert(out, Store.Components[id])
	end
	return out
end

return Store
