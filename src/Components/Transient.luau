--[[
	NEVAHEXUI - Components/Transient
	Notification and Dialog are components like any other: they resolve styles and
	render through the style engine. They differ in ownership -- the window
	creates and destroys them in its overlay area rather than inside a tab.
]]

local Component = require("NEVA:Core/Component")
local Signal = require("NEVA:Core/Signal")

local Transient = {}

Transient.Notification = Component.define({
	Type = "Notification",
	Default = nil,
	Description = "Transient message card with a level, message and dismiss action.",
	Coerce = function(value)
		return type(value) == "table" and value or {}
	end,
	State = function(self)
		local body = self.Spec.Body or {}
		return {
			Body = body,
			Message = body.Message or self.Description,
			Level = body.Level or self.Spec.Level or "Info",
		}
	end,
	Wire = function(self, view)
		self.Dismissed = Signal.new("NotificationDismissed")
		if view.Dismiss then
			self:Connect(view.Dismiss, "MouseButton1Click", function()
				self:Dismiss("UserClosed")
			end)
		end
	end,
})

function Transient.Notification:Dismiss(reason)
	if self.Dismissed2 == true then
		return false
	end
	self.Dismissed2 = true
	self.Dismissing = true
	local view = self.View
	if view and view.Root then
		view.Root.Visible = false
	end
	if self.Dismissed then
		self.Dismissed:Fire(reason or "Dismissed")
	end
	self:Destroy()
	return true
end

Transient.Dialog = Component.define({
	Type = "Dialog",
	Default = nil,
	Description = "Modal dialog with a title, body text and action buttons.",
	Coerce = function(value)
		return type(value) == "table" and value or {}
	end,
	State = function(self)
		local body = self.Spec.Body or {}
		return {
			Body = body,
			Title = body.Title or self.Name,
			Message = body.Message or self.Description,
			Actions = body.Actions or { { Label = "OK", Value = true, Style = "Primary" } },
		}
	end,
	Wire = function(self, view)
		self.Answered = Signal.new("DialogAnswered")
		for _, entry in ipairs(view.ActionButtons or {}) do
			self:Connect(entry.Button, "MouseButton1Click", function()
				self:Answer(entry.Value, entry.Label)
			end)
		end
	end,
})

function Transient.Dialog:Answer(value, label)
	if self.Answered2 == true then
		return false
	end
	self.Answered2 = true
	if self.Answered then
		self.Answered:Fire(value, label)
	end
	if self.Spec.OnChoose then
		self:_invoke(self.Spec.OnChoose, value, { Source = "Dialog" })
	end
	self:Destroy()
	return true
end

Transient.classes = { Transient.Notification, Transient.Dialog }

return Transient
