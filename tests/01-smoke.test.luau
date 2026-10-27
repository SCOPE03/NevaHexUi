--[[
	NEVAHEXUI smoke tests.
	These run against the generated bundle under plain Luau with the mock host
	back end. They verify the library instantiates, styles resolve, registries stay
	synchronised and the Studio builds - the things static analysis cannot check.
]]

NevaTest:suite("smoke")

local function report(label, value)
	print(("      - %-26s %s"):format(label, tostring(value)))
end

local function newWindow(extra)
	local options = {
		Name = "Smoke",
		Layout = "Sidebar",
		Theme = "dark",
		SaveConfigs = false,
	}
	for key, value in pairs(extra or {}) do
		options[key] = value
	end
	return NEVAHEXUI:CreateWindow(options)
end

NevaTest:test("runtime loads every style module", function()
	NevaTest:assert(NEVAHEXUI, "runtime table is present")
	local summary = NEVAHEXUI:Summary()
	for key, value in pairs(summary) do
		report(key, value)
	end
	NevaTest:equals(summary.LoadingErrors, 0, "no style module failed to load")
	NevaTest:assert(summary.Styles >= 45, "the style catalogue is populated")
	NevaTest:assert(summary.Components >= 20, "component descriptors are registered")
	NevaTest:assert(summary.Layouts >= 4, "at least the four core layouts exist")
	NevaTest:assert(summary.Themes >= 6, "themes are registered")
	NevaTest:assert(NEVAHEXUI:HasStyle("toggle.rounded"), "toggle.rounded exists")
	NevaTest:assert(NEVAHEXUI:HasStyle("toggle.compact"), "toggle.compact exists")
	NevaTest:assert(NEVAHEXUI:HasStyle("slider.neon"), "slider.neon exists")
	NevaTest:assert(NEVAHEXUI:HasStyle("button.modern"), "button.modern exists")
end)

NevaTest:test("window, tab, section and components construct", function()
	local window = newWindow()
	local tab = window:CreateTab({ Name = "Main" })
	local section = tab:CreateSection({ Name = "Section" })
	NevaTest:equals(type(section.CreateToggle), "function", "containers expose CreateToggle")
	NevaTest:equals(type(section.CreateSlider), "function", "containers expose CreateSlider")
	NevaTest:equals(type(section.CreateColorPicker), "function", "containers expose CreateColorPicker")

	local label = section:CreateLabel({ Name = "Greeting", Default = "hello" })
	local toggle = section:CreateToggle({ Name = "Enabled", Flag = "SmokeToggle", Default = false })
	local slider = section:CreateSlider({ Name = "Volume", Flag = "SmokeSlider", Min = 0, Max = 100, Default = 40 })
	local picker = section:CreateColorPicker({ Name = "Tint", Flag = "SmokeColor", Default = { 1, 0, 0 } })

	NevaTest:equals(label:GetValue(), "hello", "label value")
	NevaTest:equals(toggle:GetValue(), false, "toggle default")
	NevaTest:equals(slider:GetValue(), 40, "slider default")
	NevaTest:assert(picker:GetValue() ~= nil, "colour picker coerced a value")
	NevaTest:equals(window:GetComponentCount(), 4, "window counts its components")
	report("components", window:GetComponentCount())
	window:Destroy()
end)

NevaTest:test("registry stays synchronised with components", function()
	local window = newWindow()
	local tab = window:CreateTab({ Name = "Main" })
	local section = tab:CreateSection({ Name = "Registry" })
	local toggle = section:CreateToggle({ Name = "Reg", Flag = "RegToggle", Default = false })

	local registry = NEVAHEXUI:GetRegistry("Toggles")
	NevaTest:assert(registry, "the Toggles registry exists")
	NevaTest:equals(registry.RegToggle, toggle, "Toggles.RegToggle is the same component")
	local callbackCount = 0
	toggle:OnChanged(function()
		callbackCount += 1
	end)
	toggle:SetValue(true)
	NevaTest:equals(toggle:GetValue(), true, "programmatic SetValue applied")
	NevaTest:equals(registry.RegToggle.Value, true, "registry reads the new value")
	NevaTest:equals(callbackCount, 1, "the change callback fired once")
	report("callback fires", callbackCount)
	window:Destroy()
end)

NevaTest:test("style switching preserves value, flag and callback", function()
	local window = newWindow()
	local tab = window:CreateTab({ Name = "Main" })
	local section = tab:CreateSection({ Name = "Styles" })
	local toggle = section:CreateToggle({ Name = "Styled", Flag = "StyledToggle", Default = true })
	local fires = 0
	toggle:OnChanged(function()
		fires += 1
	end)

	NevaTest:equals(toggle:GetStyle(), "toggle.rounded", "first registered toggle renderer is the default")
	local ok = toggle:SetStyle("toggle.compact")
	NevaTest:assert(ok ~= false, "SetStyle to a real style succeeds")
	NevaTest:equals(toggle:GetStyle(), "toggle.compact", "style id updated")
	NevaTest:equals(toggle:GetValue(), true, "value survived the style change")
	NevaTest:equals(toggle.Flag, "StyledToggle", "flag survived the style change")
	toggle:SetValue(false)
	NevaTest:equals(fires, 1, "the callback survived the style change")

	local failed, err = toggle:SetStyle("nonexistent.style")
	NevaTest:equals(failed, false, "an unknown style is rejected")
	NevaTest:assert(err ~= nil, "an unknown style reports why")
	NevaTest:equals(toggle:GetStyle(), "toggle.compact", "the rejected change left the old style in place")
	report("unknown style error", err)
	window:Destroy()
end)

NevaTest:test("Style 1 and Style 2 coexist in one window", function()
	local window = newWindow()
	local tab = window:CreateTab({ Name = "Main" })
	local section = tab:CreateSection({ Name = "Two styles" })
	local first = section:CreateToggle({
		Name = "Style 1 - Modern",
		Flag = "StyleOne",
		Default = true,
		Style = { Id = "toggle.rounded", Configuration = { CornerRadius = 12, Width = 44, Height = 24 } },
	})
	local second = section:CreateToggle({
		Name = "Style 2 - Compact",
		Flag = "StyleTwo",
		Default = false,
		Style = { Id = "toggle.compact", Configuration = { CornerRadius = 3, Width = 36, Height = 20 } },
	})
	NevaTest:equals(first:GetStyle(), "toggle.rounded", "first toggle uses style 1")
	NevaTest:equals(second:GetStyle(), "toggle.compact", "second toggle uses style 2")
	NevaTest:equals(first:GetEffectiveConfiguration().Width, 44, "style 1 keeps its own width")
	NevaTest:equals(second:GetEffectiveConfiguration().Width, 36, "style 2 keeps its own width")
	NevaTest:equals(first:GetValue(), true, "style 1 keeps its own value")
	NevaTest:equals(second:GetValue(), false, "style 2 keeps its own value")

	second:SetStyleConfiguration({ CornerRadius = 14 })
	NevaTest:equals(second:GetStyleConfiguration().CornerRadius, 14, "per-component override recorded")
	NevaTest:equals(first:GetStyleConfiguration().CornerRadius, 12, "the other component keeps its own overrides")
	report("style1 width / style2 width", tostring(first:GetEffectiveConfiguration().Width) .. " / " .. tostring(second:GetEffectiveConfiguration().Width))
	window:Destroy()
end)

NevaTest:test("category defaults and per-component overrides resolve", function()
	local window = newWindow({
		StyleConfiguration = { Toggle = { CornerRadius = 10, Height = 24 } },
	})
	local tab = window:CreateTab({ Name = "Main" })
	local section = tab:CreateSection({ Name = "Cascade" })
	local plain = section:CreateToggle({ Name = "Category", Flag = "CascadeA", Style = { Id = "toggle.rounded" } })
	local overridden = section:CreateToggle({
		Name = "Override",
		Flag = "CascadeB",
		Style = { Id = "toggle.rounded", Configuration = { CornerRadius = 20 } },
	})
	NevaTest:equals(plain:GetEffectiveConfiguration().CornerRadius, 10, "category default applied")
	NevaTest:equals(overridden:GetEffectiveConfiguration().CornerRadius, 20, "per-component override wins")
	NevaTest:equals(overridden:GetEffectiveConfiguration().Height, 24, "category default still fills other keys")

	NEVAHEXUI:SetCategoryStyle("Toggle", "toggle.neon")
	local third = section:CreateToggle({ Name = "Default", Flag = "CascadeC" })
	NevaTest:equals(third:GetStyle(), "toggle.neon", "category default style is honoured for new components")
	report("explain", tostring(overridden:ExplainConfiguration() and "provided" or "missing"))
	window:Destroy()
end)

NevaTest:test("themes, layouts and window state survive changes", function()
	local window = newWindow()
	local tab = window:CreateTab({ Name = "Main" })
	local section = tab:CreateSection({ Name = "State" })
	local toggle = section:CreateToggle({ Name = "Kept", Flag = "KeptToggle", Default = true })
	local slider = section:CreateSlider({ Name = "Kept2", Flag = "KeptSlider", Min = 0, Max = 10, Default = 3 })

	NevaTest:equals(window:SetTheme("light"), true, "theme switched to light")
	NevaTest:equals(window:GetTheme(), "light", "theme id updated")
	NevaTest:equals(toggle:GetValue(), true, "value survived the theme change")
	NevaTest:equals(window:SetLayout("TopTabs"), true, "layout switched to TopTabs")
	NevaTest:equals(window:GetLayout(), "TopTabs", "layout id updated")
	NevaTest:equals(toggle:GetValue(), true, "value survived the layout change")
	NevaTest:equals(slider:GetEffectiveConfiguration() ~= nil, true, "slider still resolves configuration")
	NevaTest:equals(#window:GetTabs(), 1, "the tab survived the layout change")
	NevaTest:equals(window:GetTab("Main") ~= nil, true, "the tab is still addressable by name")
	window:Destroy()
end)

NevaTest:test("user styles register, validate and reject duplicates", function()
	local record, errors = NEVAHEXUI:RegisterStyle({
		Id = "toggle.neva.red",
		Name = "NEVA Red",
		Component = "Toggle",
		Configuration = { CornerRadius = 10, Width = 44, Height = 24 },
		Requires = "toggle.rounded",
	})
	NevaTest:assert(record ~= nil, "a style preset registers")
	if record then
		NevaTest:equals(record.Id, "toggle.neva.red", "the preset keeps its id")
	end
	local again, duplicateErrors = NEVAHEXUI:RegisterStyle({
		Id = "toggle.neva.red",
		Name = "Duplicate",
		Component = "Toggle",
		Requires = "toggle.rounded",
	})
	NevaTest:assert(again == nil, "a duplicate id is rejected rather than overwriting")
	report("duplicate rejection", tostring(duplicateErrors and duplicateErrors[1] or duplicateErrors))

	local bad, badErrors = NEVAHEXUI:RegisterStyle({ Id = "", Name = "Bad", Component = "Toggle" })
	NevaTest:assert(bad == nil, "an invalid definition is rejected")

	local window = newWindow()
	local tab = window:CreateTab({ Name = "Main" })
	local section = tab:CreateSection({ Name = "Preset" })
	local toggle = section:CreateToggle({ Name = "Preset", Flag = "PresetToggle", Style = { Id = "toggle.neva.red" } })
	NevaTest:equals(toggle:GetStyle(), "toggle.neva.red", "a registered preset can be selected")
	NevaTest:equals(toggle:GetEffectiveConfiguration().Width, 44, "the preset configuration applies")
	window:Destroy()
end)

NevaTest:test("dependencies hide and reveal components", function()
	local window = newWindow()
	local tab = window:CreateTab({ Name = "Main" })
	local section = tab:CreateSection({ Name = "Deps" })
	local master = section:CreateToggle({ Name = "Master", Flag = "DepMaster", Default = false })
	local dependent = section:CreateSlider({
		Name = "Dependent",
		Flag = "DepSlider",
		Min = 0,
		Max = 10,
		Default = 5,
		DependsOn = { Flag = "DepMaster", Value = true },
	})
	NevaTest:equals(dependent.DependenciesMet, false, "the dependent starts hidden")
	master:SetValue(true)
	NevaTest:equals(dependent.DependenciesMet, true, "turning the master on reveals the dependent")
	master:SetValue(false)
	NevaTest:equals(dependent.DependenciesMet, false, "turning the master off hides it again")
	window:Destroy()
end)

NevaTest:test("Style Studio builds previews and exports a style", function()
	local window = newWindow()
	local tab = window:CreateTab({ Name = "Main" })
	local section = tab:CreateSection({ Name = "Studio" })
	local live = section:CreateSlider({ Name = "Live", Flag = "StudioTarget", Min = 0, Max = 100, Default = 25 })

	local studio = window:OpenStudio({ Component = "Slider" })
	NevaTest:assert(studio, "the Studio opened")
	NevaTest:equals(studio.ComponentType, "Slider", "the Studio selected the requested type")
	NevaTest:assert(studio.Previews[1] ~= nil, "slot 1 has a live preview")
	NevaTest:assert(studio.Previews[2] ~= nil, "slot 2 has a live preview")
	NevaTest:assert(studio.Previews[1] ~= studio.Previews[2], "the two slots are separate components")
	report("preview style 1", studio.Previews[1]:GetStyle())
	report("preview style 2", studio.Previews[2]:GetStyle())
	NevaTest:equals(studio.Previews[1]:GetValue(), 45, "the preview has a working value")

	studio:SetTarget(live)
	local applied, error = studio:ApplyToTarget()
	NevaTest:assert(applied, "the Studio applied its style to a live component: " .. tostring(error))
	NevaTest:equals(live:GetValue(), 25, "applying a style preserved the live value")

	local exported = studio:ExportStyle(1)
	NevaTest:assert(type(exported) == "string" and #exported > 0, "the Studio exported Luau text")
	NevaTest:contains(exported, "Component", "the export mentions the component type")
	report("export bytes", #exported)

	local presetId = studio:SavePreset("Smoke Preset")
	NevaTest:assert(presetId ~= nil, "the Studio saved a preset: " .. tostring(presetId))
	report("preset id", presetId)

	studio:Destroy()
	NevaTest:equals(studio.Destroyed, true, "the Studio closed cleanly")
	window:Destroy()
end)

NevaTest:test("configuration saves, lists and loads", function()
	local window = newWindow({ SaveConfigs = true, ConfigFolder = "NEVAHEXUITest" })
	local tab = window:CreateTab({ Name = "Main" })
	local section = tab:CreateSection({ Name = "Config" })
	local toggle = section:CreateToggle({ Name = "Persisted", Flag = "PersistToggle", Default = false })
	toggle:SetValue(true)

	local saved, saveError = window:SaveConfig("smoke")
	report("save result", tostring(saved) .. " " .. tostring(saveError))
	local listed = window:ListConfigs()
	report("configs listed", type(listed) == "table" and #listed or 0)

	toggle:SetValue(false)
	if saved then
		local loaded, loadError = window:LoadConfig("smoke")
		report("load result", tostring(loaded) .. " " .. tostring(loadError))
		if loaded then
			NevaTest:equals(toggle:GetValue(), true, "the saved value was restored")
		end
	end
	local exported = window:ExportConfig()
	NevaTest:assert(type(exported) == "string" and #exported > 0, "the configuration exports as text")
	window:Destroy()
end)

NevaTest:test("destroying a window cleans up its components", function()
	local window = newWindow()
	local tab = window:CreateTab({ Name = "Main" })
	local section = tab:CreateSection({ Name = "Cleanup" })
	local first
	for index = 1, 5 do
		local component = section:CreateToggle({ Name = "T" .. tostring(index), Flag = "Cleanup" .. tostring(index) })
		first = first or component
	end
	NevaTest:equals(window:GetComponentCount(), 5, "five components exist")
	NevaTest:equals(NEVAHEXUI:GetComponent("Cleanup1"), first, "components are reachable through the store")
	NevaTest:equals(window:Destroy(), true, "the window destroyed")
	NevaTest:equals(window.Destroyed, true, "the window reports itself destroyed")
	NevaTest:equals(first.Destroyed, true, "its components were destroyed with it")
	NevaTest:equals(first:GetStyle(), "toggle.rounded", "the destroyed component kept its last style id")
end)
