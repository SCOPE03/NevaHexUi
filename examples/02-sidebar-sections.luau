--[[
	NEVAHEXUI example 02 - Sidebar layout with sections and group boxes
	Shows the Sidebar layout, grouped content, a collapsible section and a
	dependency box that appears only when its parent toggle is on.
]]

local NEVAHEXUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/SCOPE03/NevaHexUi/main/build/NEVAHEXUI.luau"))()

local Window = NEVAHEXUI:CreateWindow({
	Name = "NEVAHEXUI - Sidebar",
	Layout = "Sidebar",
	Theme = "neon",
	Accent = Color3.fromRGB(0, 255, 200),
})

local Home = Window:CreateTab({ Name = "Home" })
local Combat = Window:CreateTab({ Name = "Combat" })
local Visuals = Window:CreateTab({ Name = "Visuals" })

local Basics = Home:CreateGroupbox({ Name = "Basics" })
Basics:CreateLabel({ Name = "Note", Default = "Sections stack inside a tab; group boxes frame related controls." })
Basics:CreateBadge({ Name = "Status", Default = "Stable", Style = { Id = "badge.pill" } })

local Advanced = Home:CreateCollapsible({ Name = "Advanced options", Collapsible = true, Collapsed = true })
Advanced:CreateToggle({ Name = "Advanced mode", Flag = "AdvancedMode", Default = false, Style = { Id = "toggle.neon" } })

local Aim = Combat:CreateSection({ Name = "Aim assistance" })
local AimToggle = Aim:CreateToggle({ Name = "Enable aim assist", Flag = "AimAssist", Default = false })

local AimOptions = Combat:CreateDependencyBox({
	Name = "Aim settings",
	Dependency = { Flag = "AimAssist", Value = true },
})
AimOptions:CreateSlider({ Name = "Field of view", Flag = "AimFOV", Min = 10, Max = 180, Default = 60, Style = { Id = "slider.neon" } })
AimOptions:CreateSlider({ Name = "Smoothing", Flag = "AimSmooth", Min = 0, Max = 1, Default = 0.25, Step = 0.05, Style = { Id = "slider.minimal" } })

local Esp = Visuals:CreateSection({ Name = "ESP" })
Esp:CreateCheckbox({ Name = "Highlight players", Flag = "EspPlayers", Default = true })
Esp:CreateCheckbox({ Name = "Draw tracers", Flag = "EspTracers" })

print("Example 02 ready:", #Window:GetTabs() .. " tabs")
print("Toggle registry access:", AimToggle.Value, NEVAHEXUI:GetRegistry("Toggles").AimAssist == AimToggle)
