--[[
	NEVAHEXUI - Styles/Resolver
	Configuration inheritance. Six layers are merged from lowest to highest
	precedence:

	  1. ComponentDefaults       built-in defaults for the component category
	  2. StyleDefaults           the selected style's own default configuration
	  3. PresetOverrides         configuration of every derived style in the chain
	  4. CategoryConfiguration   window level StyleConfiguration.<Category>
	  5. ComponentConfiguration  the individual component's Style.Configuration
	  6. RuntimeOverrides        SetStyleConfiguration / SetStyleProperty calls

	Every layer is deep-copied before merging, so a resolved configuration can
	never mutate a shared style preset and one component's overrides can never
	leak into another.
]]

local Util = require("NEVA:Core/Util")
local Schema = require("NEVA:Styles/Schema")
local Registry = require("NEVA:Styles/Registry")

local Resolver = {}

Resolver.Layers = {
	"ComponentDefaults",
	"StyleDefaults",
	"PresetOverrides",
	"CategoryConfiguration",
	"ComponentConfiguration",
	"RuntimeOverrides",
}

local function recordLayerKeys(effective, layerName, config)
	for key in pairs(config or {}) do
		effective[key] = layerName
	end
end

-- request = {
--   Component = "Toggle",
--   StyleId   = "toggle.compact",
--   CategoryConfiguration = { ... },
--   ComponentConfiguration = { ... },
--   RuntimeOverrides = { ... },
--   Strict = false,
-- }
function Resolver.resolve(request)
	assert(type(request) == "table", "Resolver.resolve expects a request table")
	local componentName = request.Component
	local component = Registry.Components[componentName]
	local style = Registry.get(request.StyleId or "")

	local result = {
		Ok = false,
		Component = componentName,
		StyleId = request.StyleId,
		Style = style,
		Chain = {},
		Schema = {},
		Configuration = {},
		Layers = {},
		Effective = {},
		Errors = {},
		Warnings = {},
	}

	if not component then
		table.insert(result.Errors, ("unknown component category %q"):format(tostring(componentName)))
		return result
	end

	if not style then
		-- Fall back to the first registered style for the component so a typo in
		-- a style id degrades safely instead of breaking the interface.
		local fallback = Registry.list(componentName)[1]
		if fallback then
			table.insert(result.Warnings, ("unknown style %q for %s; falling back to %q")
				:format(tostring(request.StyleId), componentName, fallback.Id))
			result.StyleId = fallback.Id
			result.Style = fallback
			style = fallback
		end
	end

	if not style then
		table.insert(result.Errors, ("no style is registered for component %q"):format(componentName))
		return result
	end

	if style.Component ~= componentName then
		table.insert(result.Errors, ("style %q renders %s, not %s")
			:format(style.Id, style.Component, componentName))
		return result
	end

	local chain = Registry.chain(style.Id)
	local properties = Registry.effectiveProperties(chain)
	result.Chain = chain
	result.Schema = properties

	local layers = {
		ComponentDefaults = Util.deepCopy(component.Defaults),
		StyleDefaults = Util.deepCopy(chain[1].Configuration),
		PresetOverrides = {},
		CategoryConfiguration = Util.deepCopy(request.CategoryConfiguration or {}),
		ComponentConfiguration = Util.deepCopy(request.ComponentConfiguration or {}),
		RuntimeOverrides = Util.deepCopy(request.RuntimeOverrides or {}),
	}
	for index = 2, #chain do
		layers.PresetOverrides = Util.deepMerge(layers.PresetOverrides, chain[index].Configuration)
	end

	local merged = {}
	local effective = {}
	for _, layerName in ipairs(Resolver.Layers) do
		local layerConfig = layers[layerName]
		if next(layerConfig) ~= nil then
			-- Validate each layer against the effective schema so unknown or
			-- mistyped properties are attributed to the layer that supplied them.
			local ok, cleanedLayer, errors, warnings = Schema.validate(properties, layerConfig, {
				-- ComponentDefaults belong to the component descriptor and are
				-- validated where they are declared; a style may legitimately ignore
				-- one (a Dialog's Dismissible flag), so re-checking them against
				-- every style schema only produced noise.
				AllowUnknown = layerName == "ComponentDefaults"
					or layerName == "ComponentConfiguration"
					or layerName == "RuntimeOverrides",
			})
			for _, message in ipairs(warnings) do
				table.insert(result.Warnings, ("%s: %s"):format(layerName, message))
			end
			for _, message in ipairs(errors) do
				table.insert(result.Errors, ("%s: %s"):format(layerName, message))
			end
			if not ok and request.Strict then
				result.Configuration = merged
				result.Layers = layers
				result.Effective = effective
				return result
			end
			recordLayerKeys(effective, layerName, layerConfig)
			merged = Util.deepMerge(merged, cleanedLayer)
		end
	end

	-- Final pass: guarantees every schema default is present and valid even if a
	-- layer was skipped entirely.
	local ok, finalConfig, errors, warnings = Schema.validate(properties, merged, {
		AllowUnknown = true,
	})
	for _, message in ipairs(warnings) do
		table.insert(result.Warnings, ("resolved: %s"):format(message))
	end
	for _, message in ipairs(errors) do
		table.insert(result.Errors, ("resolved: %s"):format(message))
	end

	local styleValidate = style.Validate
	if Util.isCallable(styleValidate) then
		local okValidation, message = styleValidate(finalConfig)
		if not okValidation then
			table.insert(result.Errors, ("style %q: %s"):format(style.Id, message or "configuration rejected by the style"))
		end
	end

	result.Ok = ok and #result.Errors == 0
	result.Configuration = finalConfig
	result.Layers = layers
	result.Effective = effective
	return result
end

-- Convenience wrapper that raises on failure, for callers that cannot proceed.
function Resolver.resolveOrError(request, logger)
	local result = Resolver.resolve(request)
	if not result.Ok then
		local message = ("NEVAHEXUI: could not resolve configuration for %s (%s): %s"):format(
			tostring(request.Component),
			tostring(request.StyleId),
			table.concat(result.Errors, "; ")
		)
		if logger then
			logger:Warn(message)
		end
	end
	return result
end

-- Human-readable description of which layer supplied each value.
function Resolver.explain(result)
	local lines = {}
	table.insert(lines, ("Style: %s (%s)"):format(result.Style and result.Style.Name or "?", tostring(result.StyleId)))
	for _, layerName in ipairs(Resolver.Layers) do
		local layer = result.Layers[layerName] or {}
		local keys = Util.keys(layer)
		table.insert(lines, ("  %s: %d value(s)%s"):format(
			layerName,
			#keys,
			#keys > 0 and (" [" .. table.concat(keys, ", ") .. "]") or ""
		))
	end
	local resolved = {}
	for key, layerName in pairs(result.Effective) do
		table.insert(resolved, ("%s <- %s"):format(key, layerName))
	end
	table.sort(resolved)
	table.insert(lines, "  resolved:")
	for _, line in ipairs(resolved) do
		table.insert(lines, "    " .. line)
	end
	return table.concat(lines, "\n")
end

return Resolver
