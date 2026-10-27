--[[
	NEVAHEXUI - Animation/Presets
	Named animation presets shared by every component so that timing and easing
	stay consistent across styles and can be overridden per component.
]]

local Presets = {}

Presets.Definitions = {
	none = {
		Name = "None",
		Description = "Apply the target values instantly.",
		Duration = 0,
		Easing = "Linear",
		Direction = "Out",
	},
	fade = {
		Name = "Fade",
		Description = "Cross-fade transparency only.",
		Duration = 0.18,
		Easing = "Sine",
		Direction = "Out",
	},
	quick = {
		Name = "Quick",
		Description = "Short transition for small affordances.",
		Duration = 0.1,
		Easing = "Quad",
		Direction = "Out",
	},
	smooth = {
		Name = "Smooth",
		Description = "Default interface transition.",
		Duration = 0.2,
		Easing = "Quad",
		Direction = "Out",
	},
	pop = {
		Name = "Pop",
		Description = "Overshoot used for toggles and selections.",
		Duration = 0.24,
		Easing = "Back",
		Direction = "Out",
	},
	springy = {
		Name = "Springy",
		Description = "Elastic settle for large movement.",
		Duration = 0.35,
		Easing = "Elastic",
		Direction = "Out",
	},
	bounce = {
		Name = "Bounce",
		Description = "Bouncy settle for value changes.",
		Duration = 0.3,
		Easing = "Bounce",
		Direction = "Out",
	},
	slide = {
		Name = "Slide",
		Description = "Directional movement preset.",
		Duration = 0.22,
		Easing = "Cubic",
		Direction = "Out",
	},
	slow = {
		Name = "Slow",
		Description = "Deliberate transition for large panels.",
		Duration = 0.4,
		Easing = "Sine",
		Direction = "InOut",
	},
}

Presets.Names = {
	"none",
	"fade",
	"quick",
	"smooth",
	"pop",
	"springy",
	"bounce",
	"slide",
	"slow",
}

function Presets.get(name)
	if name == nil then
		return Presets.Definitions.smooth, "smooth"
	end
	if type(name) == "table" then
		local duration = name.Duration or Presets.Definitions.smooth.Duration
		local easing = name.Easing or Presets.Definitions.smooth.Easing
		local direction = name.Direction or Presets.Definitions.smooth.Direction
		return { Name = name.Name or "Custom", Description = "Inline animation specification.", Duration = duration, Easing = easing, Direction = direction }, "custom"
	end
	local preset = Presets.Definitions[name]
	if preset then
		return preset, name
	end
	return Presets.Definitions.smooth, "smooth"
end

function Presets.info(host, spec)
	local resolved = Presets.get(spec)
	return host.tweenInfo(resolved.Duration, resolved.Easing, resolved.Direction)
end

-- Tweens `goal` on `instance` using the resolved preset.
function Presets.play(host, instance, goal, spec)
	local resolved = Presets.get(spec)
	if resolved.Duration <= 0 then
		return host.set(instance, goal)
	end
	return host.tween(instance, goal, Presets.info(host, resolved))
end

function Presets.list()
	local out = {}
	for _, name in ipairs(Presets.Names) do
		local preset = Presets.Definitions[name]
		table.insert(out, {
			Name = name,
			Label = preset.Name,
			Description = preset.Description,
			Duration = preset.Duration,
			Easing = preset.Easing,
			Direction = preset.Direction,
		})
	end
	return out
end

function Presets.register(name, definition)
	assert(type(name) == "string" and name ~= "", "Presets.register expects a name")
	assert(not Presets.Definitions[name], ("animation preset %q already exists"):format(name))
	assert(type(definition) == "table", "Presets.register expects a definition table")
	Presets.Definitions[name] = {
		Name = definition.Name or name,
		Description = definition.Description or "",
		Duration = definition.Duration or 0.2,
		Easing = definition.Easing or "Quad",
		Direction = definition.Direction or "Out",
	}
	table.insert(Presets.Names, name)
	return name
end

return Presets
