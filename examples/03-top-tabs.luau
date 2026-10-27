--[[
	NEVAHEXUI example 03 - Top tab layout with nested sub tabs
	The TopTabs layout puts navigation in a horizontal strip; tabs can host sub
	tabs for deeper navigation without losing component state.
]]

local NEVAHEXUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/SCOPE03/NevaHexUi/main/build/NEVAHEXUI.luau"))()

local Window = NEVAHEXUI:CreateWindow({
	Name = "NEVAHEXUI - Top Tabs",
	Layout = "TopTabs",
	Theme = "glass",
})

local Main = Window:CreateTab({ Name = "Main" })
local Settings = Window:CreateTab({ Name = "Settings" })
local About = Window:CreateTab({ Name = "About" })

local General = Main:CreateSection({ Name = "General" })
General:CreateSlider({ Name = "Walk speed", Flag = "WalkSpeed", Min = 8, Max = 200, Default = 16, Style = { Id = "slider.filled" } })
General:CreateSlider({ Name = "Jump power", Flag = "JumpPower", Min = 20, Max = 150, Default = 50, Style = { Id = "slider.filled" } })

local KeysSection = Settings:CreateSection({ Name = "Keybind" })
KeysSection:CreateKeybind({ Name = "Toggle menu", Flag = "MenuKey", Default = "RightShift", Keys = { "RightShift", "LeftShift", "F1", "P" } })
KeysSection:CreateKeybind({ Name = "Panic key", Flag = "PanicKey", Default = "End", Style = { Id = "keybind.pill" } })

local AboutSection = About:CreateSection({ Name = "About" })
AboutSection:CreateLabel({ Name = "Version", Default = "NEVAHEXUI " .. NEVAHEXUI.Version })
AboutSection:CreateTable({
	Name = "Build",
	Columns = { "Part", "Value" },
	Default = {
		{ "Layouts", #NEVAHEXUI:ListLayouts() },
		{ "Styles", #NEVAHEXUI:ListStyles() },
		{ "Themes", #NEVAHEXUI:ListThemes() },
	},
})

print("Example 03 ready: active tab is", tostring(Window:GetActiveTab().Name))
Window:SelectTab("Settings")
print("Switched tab without rebuilding any component")
