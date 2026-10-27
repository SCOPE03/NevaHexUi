--[[
	NEVAHEXUI example 05 - Compact / mobile layout
	Touch friendly density, horizontal navigation, large hit targets and a
	responsive window that shrinks to the viewport.
]]

local NEVAHEXUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/SCOPE03/NevaHexUi/main/build/NEVAHEXUI.luau"))()

local Window = NEVAHEXUI:CreateWindow({
	Name = "NEVAHEXUI - Mobile",
	Layout = "Compact",
	Theme = "light",
	StyleConfiguration = {
		Button = { RowHeight = 40 },
		Toggle = { RowHeight = 40, Width = 52, Height = 28 },
		Slider = { RowHeight = 40, TrackHeight = 8 },
	},
})

local Tab = Window:CreateTab({ Name = "Main" })
local Section = Tab:CreateSection({ Name = "Touch controls" })

Section:CreateToggle({ Name = "Auto sprint", Flag = "AutoSprint", Default = true, Style = { Id = "toggle.neon" } })
Section:CreateSlider({ Name = "Sensitivity", Flag = "Sensitivity", Min = 1, Max = 10, Default = 5, Style = { Id = "slider.stepped" } })
Section:CreateDropdownPlaceholder = nil
Section:CreateButton({ Name = "Apply", Flag = "ApplyMobile", Style = { Id = "button.modern" }, Callback = function() Window:Notify({ Message = "Applied", Level = "Success" }) end })
Section:CreateLoader({ Name = "Syncing", Default = true, Style = { Id = "loader.dots" } })

print("Example 05 ready: layout", Window:GetLayout())
