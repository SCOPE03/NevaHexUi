--[[
	NEVAHEXUI example 01 - Quick start
	The smallest complete interface: a window, one tab, a button, a toggle and a
	label, plus a notification.
]]

local NEVAHEXUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/SCOPE03/NevaHexUi/main/build/NEVAHEXUI.luau"))()

local Window = NEVAHEXUI:CreateWindow({
	Name = "NEVAHEXUI - Quick Start",
	Subtitle = "v1.0.0",
	Layout = "Sidebar",
	Theme = "dark",
	Configuration = { Theme = "dark", SaveConfigs = true, ConfigFolder = "NEVAHEXUI" },
})

local Tab = Window:CreateTab({ Name = "Main" })
local Section = Tab:CreateSection({ Name = "Welcome" })

Section:CreateLabel({
	Name = "Greeting",
	Default = "This window is built entirely from NEVAHEXUI components.",
})

Section:CreateButton({
	Name = "Say hello",
	Flag = "HelloButton",
	Style = { Id = "button.modern" },
	Callback = function(clicks)
		print("Hello from NEVAHEXUI (click " .. tostring(clicks) .. ")")
	end,
})

Section:CreateToggle({
	Name = "Enabled",
	Flag = "Enabled",
	Default = true,
	Style = { Id = "toggle.rounded" },
	Callback = function(value)
		print("Enabled:", value)
	end,
})

Section:CreateSlider({
	Name = "Volume",
	Flag = "Volume",
	Min = 0,
	Max = 100,
	Default = 40,
	Suffix = "%",
	Style = { Id = "slider.filled" },
	Callback = function(value)
		print("Volume:", value)
	end,
})

Window:Notify({ Title = "Ready", Message = "NEVAHEXUI loaded with " .. tostring(#NEVAHEXUI:ListStyles()) .. " styles.", Level = "Success" })
print("Example 01 ready:", Window:Summary().Components .. " components")
