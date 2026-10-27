--[[
	NEVAHEXUI example 04 - Floating layout
	A compact draggable panel: drag the title bar, minimise it, and use the
	minimal-density styling.
]]

local NEVAHEXUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/SCOPE03/NevaHexUi/main/build/NEVAHEXUI.luau"))()

local Window = NEVAHEXUI:CreateWindow({
	Name = "NEVAHEXUI - Floating",
	Layout = "Floating",
	Theme = "minimal",
	Size = "compact",
})

local Tab = Window:CreateTab({ Name = "Panel" })
local Section = Tab:CreateSection({ Name = "Quick actions" })

Section:CreateButton({ Name = "Respawn", Flag = "Respawn", Style = { Id = "button.glass" }, Callback = function() print("respawn") end })
Section:CreateButton({ Name = "Server hop", Flag = "Hop", Style = { Id = "button.flat" }, Callback = function() print("hop") end })
Section:CreateIconButton({ Name = "Settings", Flag = "IconSettings", Icon = "rbxassetid://6031075931", Style = { Id = "iconbutton.rounded" } })
Section:CreateProgressBar({ Name = "Loading", Default = 0.42, ShowValue = true, Style = { Id = "progressbar.bar" } })

Window:SetPosition(40, 40)
Window:Drag = true
print("Example 04 ready: layout", Window:GetLayout(), "draggable:", NEVAHEXUI.Layouts.get("Floating").Draggable)
