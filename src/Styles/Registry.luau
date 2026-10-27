--[[
	NEVAHEXUI - Styles/Registry
	The style registry owns component descriptors (built-in defaults plus a
	property schema per component category) and style implementations
	(a distinct renderer per style Id, optionally derived from another style).

	Registration rules:
	  * Style Ids must be "<component>.<name>" in lowercase.
	  * Duplicate Ids are rejected unless the caller passes Replace = true.
	  * Every registered style must supply a callable Render function, so the
	    catalogue can never contain a style without a real implementation.
]]

local Util = require("NEVA:Core/Util")
local Schema = require("NEVA:Styles/Schema")

local Registry = {}

Registry.Components = {}
Registry.ComponentOrder = {}
Registry.Styles = {}
Registry.StyleOrder = {}
Registry.Replacements = {}
Registry.Warnings = {}

local ID_PATTERN = "^[a-z0-9_]+%.[a-z0-9_%-%.]+$"

local function describeErrors(errors)
	return table.concat(errors, "; ")
end

function Registry.registerComponent(definition)
	assert(type(definition) == "table", "registerComponent expects a table")
	assert(type(definition.Name) == "string" and definition.Name ~= "", "component descriptors need a Name")
	local existing = Registry.Components[definition.Name]
	if existing then
		return existing
	end
	local properties = {}
	for _, descriptor in ipairs(definition.Properties or {}) do
		table.insert(properties, Schema.property(descriptor))
	end
	local ok, errors = Schema.validateProperties(properties)
	if not ok then
		error(("NEVAHEXUI: component %s has an invalid property schema: %s"):format(definition.Name, describeErrors(errors)))
	end
	local record = {
		Name = definition.Name,
		RegistryName = definition.RegistryName or (definition.Name .. "s"),
		Category = definition.Category or "Controls",
		Description = definition.Description or "",
		Defaults = Util.deepCopy(definition.Defaults or {}),
		Properties = properties,
	}
	Registry.Components[record.Name] = record
	table.insert(Registry.ComponentOrder, record.Name)
	return record
end

function Registry.registerStyle(definition)
	assert(type(definition) == "table", "registerStyle expects a table")
	local errors = {}
	if type(definition.Id) ~= "string" or not definition.Id:match(ID_PATTERN) then
		table.insert(errors, ("style Id %q must look like \"toggle.rounded\" in lowercase"):format(tostring(definition.Id)))
	end
	if type(definition.Name) ~= "string" or definition.Name == "" then
		table.insert(errors, "style Name must be a non-empty string")
	end
	local component = Registry.Components[definition.Component]
	if not component then
		table.insert(errors, ("unknown component %q for style %q"):format(tostring(definition.Component), tostring(definition.Id)))
	end
	if not Util.isCallable(definition.Render) then
		table.insert(errors, ("style %q must provide a callable Render function"):format(tostring(definition.Id)))
	end
	if definition.Id and Registry.Styles[definition.Id] and not definition.Replace then
		table.insert(errors, ("style %q is already registered; pass Replace = true to replace it deliberately"):format(definition.Id))
	end
	local basedOn = definition.BasedOn
	if basedOn then
		local base = Registry.Styles[basedOn]
		if not base then
			table.insert(errors, ("style %q is BasedOn unknown style %q"):format(tostring(definition.Id), tostring(basedOn)))
		elseif component and base.Component ~= component.Name then
			table.insert(errors, ("style %q cannot derive from %q: different component types"):format(definition.Id, basedOn))
		end
	end
	local properties = {}
	for _, descriptor in ipairs(definition.Properties or {}) do
		table.insert(properties, Schema.property(descriptor))
	end
	local schemaOk, schemaErrors = Schema.validateProperties(properties)
	if not schemaOk then
		for _, message in ipairs(schemaErrors) do
			table.insert(errors, ("style %q: %s"):format(tostring(definition.Id), message))
		end
	end
	if #errors > 0 then
		return nil, errors
	end
	if definition.Id and Registry.Styles[definition.Id] then
		table.insert(Registry.Replacements, {
			Id = definition.Id,
			Replaced = Registry.Styles[definition.Id],
		})
	end
	local record = {
		Id = definition.Id,
		Name = definition.Name,
		Component = definition.Component,
		Category = definition.Category or component.Category,
		Description = definition.Description or "",
		BasedOn = basedOn,
		Configuration = Util.deepCopy(definition.Configuration or {}),
		Properties = properties,
		Render = definition.Render,
		Animate = definition.Animate,
		Preview = definition.Preview,
		Validate = definition.Validate,
		Compatibility = Util.deepCopy(definition.Compatibility or {}),
		Tags = Util.deepCopy(definition.Tags or {}),
		Author = definition.Author,
		Experimental = definition.Experimental == true,
		BuiltIn = definition.BuiltIn == true,
		Replace = definition.Replace == true,
	}
	if not Registry.Styles[record.Id] then
		table.insert(Registry.StyleOrder, record.Id)
	end
	Registry.Styles[record.Id] = record
	return record
end

-- Registers many styles, collecting failures instead of aborting the build.
function Registry.registerMany(definitions, options)
	options = options or {}
	local registered = {}
	local failures = {}
	for _, definition in ipairs(definitions) do
		local copy = Util.shallowCopy(definition)
		if options.BuiltIn then
			copy.BuiltIn = true
		end
		local record, errors = Registry.registerStyle(copy)
		if record then
			table.insert(registered, record)
		else
			table.insert(failures, { Id = copy.Id, Errors = errors })
			for _, message in ipairs(errors or {}) do
				table.insert(Registry.Warnings, message)
			end
		end
	end
	return registered, failures
end

function Registry.get(id)
	return Registry.Styles[id]
end

function Registry.require(id)
	local style = Registry.Styles[id]
	if not style then
		error(("NEVAHEXUI: unknown style %q. Use NEVAHEXUI:GetStyleCatalog() to list registered styles."):format(tostring(id)), 2)
	end
	return style
end

function Registry.has(id)
	return Registry.Styles[id] ~= nil
end

function Registry.unregister(id)
	local style = Registry.Styles[id]
	if not style then
		return false
	end
	Registry.Styles[id] = nil
	for index, candidate in ipairs(Registry.StyleOrder) do
		if candidate == id then
			table.remove(Registry.StyleOrder, index)
			break
		end
	end
	return true
end

-- Ancestor chain from root base style to the requested style.
function Registry.chain(id, seen)
	local style = Registry.require(id)
	seen = seen or {}
	if seen[id] then
		error(("NEVAHEXUI: style inheritance cycle detected at %q"):format(id), 2)
	end
	seen[id] = true
	local chain = {}
	if style.BasedOn then
		for _, ancestor in ipairs(Registry.chain(style.BasedOn, seen)) do
			table.insert(chain, ancestor)
		end
	end
	table.insert(chain, style)
	return chain
end

function Registry.effectiveProperties(chain)
	local lists = {}
	for _, style in ipairs(chain) do
		table.insert(lists, style.Properties)
	end
	if #chain > 0 then
		local component = Registry.Components[chain[1].Component]
		if component and #component.Properties > 0 then
			table.insert(lists, 1, component.Properties)
		end
	end
	return Schema.merge(table.unpack(lists))
end

function Registry.list(component)
	local out = {}
	for _, id in ipairs(Registry.StyleOrder) do
		local style = Registry.Styles[id]
		if not component or style.Component == component then
			table.insert(out, style)
		end
	end
	return out
end

function Registry.styleIds(component)
	local out = {}
	for _, style in ipairs(Registry.list(component)) do
		table.insert(out, style.Id)
	end
	return out
end

function Registry.listComponents()
	local out = {}
	for _, name in ipairs(Registry.ComponentOrder) do
		table.insert(out, Registry.Components[name])
	end
	return out
end

function Registry.count()
	return #Registry.StyleOrder
end

-- The default style for a component category is the first style registered for
-- it, unless the library/window configuration selects another one.
function Registry.defaultStyleId(componentName)
	for _, id in ipairs(Registry.StyleOrder) do
		if Registry.Styles[id].Component == componentName then
			return id
		end
	end
	return nil
end

function Registry.componentNames()
	local out = {}
	for _, name in ipairs(Registry.ComponentOrder) do
		table.insert(out, name)
	end
	return out
end

-- Catalogue used by the Style Studio and the generated style showcase.
function Registry.catalog()
	local components = {}
	for _, name in ipairs(Registry.ComponentOrder) do
		local descriptor = Registry.Components[name]
		local styles = {}
		for _, style in ipairs(Registry.list(name)) do
			local chain = Registry.chain(style.Id)
			table.insert(styles, {
				Id = style.Id,
				Name = style.Name,
				Component = style.Component,
				Category = style.Category,
				Description = style.Description,
				BasedOn = style.BasedOn,
				BuiltIn = style.BuiltIn,
				Experimental = style.Experimental,
				Tags = style.Tags,
				Compatibility = style.Compatibility,
				Configuration = Util.deepCopy(style.Configuration),
				Properties = Schema.describe(Registry.effectiveProperties(chain)),
				Groups = Schema.groups(Registry.effectiveProperties(chain)),
				Chain = (function()
					local ids = {}
					for _, entry in ipairs(chain) do
						table.insert(ids, entry.Id)
					end
					return ids
				end)(),
			})
		end
		table.insert(components, {
			Name = descriptor.Name,
			RegistryName = descriptor.RegistryName,
			Category = descriptor.Category,
			Description = descriptor.Description,
			Defaults = Util.deepCopy(descriptor.Defaults),
			StyleCount = #styles,
			Styles = styles,
		})
	end
	return { Components = components, StyleCount = Registry.count(), ComponentCount = #components }
end

return Registry
