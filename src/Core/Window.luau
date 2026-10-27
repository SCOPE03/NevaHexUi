--[[
	NEVAHEXUI - Core/Window  (part 1 of 2: construction and chrome)

	The window owns the chrome, navigation, page containers, the overlay used for
	notifications and dialogs, and the layout.

	Design rules enforced here:
	  * Changing layout or theme never recreates a component. A layout change only
	    re-parents the existing tab containers into the new content area.
	  * Tab containers are ordinary Containers, so every Create<Type> method comes
	    from the component factory table rather than a hand-written list here.
	  * Transient surfaces (Notify, Dialog) are components too, created through the
	    same pipeline and destroyed when dismissed.
]]

local Util = require("NEVA:Core/Util")
local Signal = require("NEVA:Core/Signal")
local Container = require("NEVA:Core/Container")
local Layouts = require("NEVA:Core/Layouts")
local Helpers = require("NEVA:Styles/Helpers")
local Surface = require("NEVA:Styles/Surface")

local Window = {}
Window.__index = Window

local function pointerOf(host)
	if not host.pointerPosition then
		return nil
	end
	local position = host.pointerPosition()
	if position == nil then
		return nil
	end
	return { X = position.X or position.x or 0, Y = position.Y or position.y or 0 }
end

local function viewportOf(host)
	if not host.viewportSize then
		return { X = 0, Y = 0 }
	end
	local size = host.viewportSize()
	return { X = size.X or size.x or 0, Y = size.Y or size.y or 0 }
end

function Window.new(context, options)
	options = options or {}
	assert(context, "Window.new expects a render context")
	local self = setmetatable({}, Window)
	self.Context = context
	self.Host = context.Host
	self.Options = options
	self.Name = tostring(options.Name or "NEVAHEXUI")
	self.Subtitle = options.Subtitle
	self.Icon = options.Icon
	self.Destroyed = false
	self.Minimized = false
	self.Dragging = false
	self.Tabs = {}
	self.Notifications = {}
	self.ConnectionList = {}
	self.CreatedAt = Util.uniqueId("Window")
	self.Closed = Signal.new("WindowClosed")
	self.TabChanged = Signal.new("TabChanged")
	self.LayoutChanged = Signal.new("LayoutChanged")

	self.LayoutId = options.Layout or "Sidebar"
	if not Layouts.has(self.LayoutId) then
		context:Diagnostic("Warn", ("unknown layout %q, falling back to Sidebar"):format(tostring(self.LayoutId)))
		self.LayoutId = "Sidebar"
	end
	self.Layout = Layouts.get(self.LayoutId)

	local configuration = options.Configuration or {}
	local theme = options.Theme or configuration.Theme
	if theme then
		context:SetTheme(theme)
	end
	local accent = options.Accent or configuration.Accent
	if accent then
		context.ThemeOverrides = context.ThemeOverrides or {}
		context.ThemeOverrides.Accent = accent
		context:RefreshTheme()
	end
	if options.Styles then
		for component, styleId in pairs(options.Styles) do
			context:SetStyleDefault(component, styleId)
		end
	end
	if options.StyleConfiguration then
		for component, categoryConfiguration in pairs(options.StyleConfiguration) do
			context:SetCategoryConfiguration(component, categoryConfiguration)
		end
	end

	self:BuildChrome()
	context:RegisterScope(self)
	return self
end

-- Chrome ---------------------------------------------------------------------

function Window:ComputeRootSize()
	local sizing = self.Layout.Sizing or {}
	local size = sizing.Size or { 0.62, 480, 0.68, 360 }
	return (size[1] or 0), (size[2] or 480), (size[3] or 0), (size[4] or 360)
end

function Window:BuildChrome()
	local host = self.Host
	local tokens = self.Context.Tokens
	local widthScale, widthOffset, heightScale, heightOffset = self:ComputeRootSize()
	local sizing = self.Layout.Sizing or {}

	if self.Root then
		host.destroy(self.Root)
		self.Root = nil
	end

local parent = self.Options.Parent or host.Root
	if not parent and host.newRoot then
		-- A window tree hanging off nothing is built and then never shown, so the
		-- ScreenGui root is created on demand. Where it landed is recorded on the
		-- window (Window.GuiParent) and on the host (Host.ParentSource).
		parent = host.newRoot({
			Name = "NEVAHEXUI",
			ResetOnSpawn = false,
			IgnoreGuiInset = true,
			DisplayOrder = 999,
			ZIndexBehavior = host.enumItem("ZIndexBehavior", "Sibling"),
		})
	end
	self.GuiParent = host.ParentSource or "unknown"
	if not parent then
		self.Context:Diagnostic("Error", "NEVAHEXUI: no GUI container was available (tried gethui(), CoreGui and PlayerGui), so the interface was built but cannot be displayed")
	end
	self.Root = host.new("Frame", {
		Name = "NEVAHEXUI_" .. self.Name,
		BackgroundColor3 = tokens.Background,
		BorderSizePixel = 0,
		Size = host.udim2(widthScale, widthOffset, heightScale, heightOffset),
		Position = host.udim2(0.5, 0, 0.5, 0),
		AnchorPoint = host.vector2(0.5, 0.5),
		ClipsDescendants = false,
		ZIndex = 20,
	}, parent)
	if self.Options.Transparency ~= nil then
		self.Root.BackgroundTransparency = self.Options.Transparency
	end
	Helpers.corner(host, self.Root, tokens.CornerRadius or 8)
	Helpers.stroke(host, self.Root, tokens.Outline, 1, 0.25)

	if sizing.MinSize or sizing.MaxSize then
		local minimum = sizing.MinSize or { 320, 240 }
		local maximum = sizing.MaxSize or { 1200, 900 }
		host.new("UISizeConstraint", {
			MinSize = host.vector2(minimum[1], minimum[2]),
			MaxSize = host.vector2(maximum[1], maximum[2]),
		}, self.Root)
	end

	local chromeHeight = self.Layout.Chrome == "Minimal" and 34 or 40
	self.ChromeHeight = chromeHeight

	-- A TextButton, not a Frame: only GuiButton instances own MouseButton1Down/Up,
	-- and a Frame that is not Active never receives InputBegan either, so the
	-- title bar would neither drag nor report a press.
	self.TitleBar = host.new("TextButton", {
		Name = "TitleBar",
		BackgroundColor3 = tokens.Surface,
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
		Size = host.udim2(1, 0, 0, chromeHeight),
		Text = "",
		AutoButtonColor = false,
		ZIndex = 3,
	}, self.Root)
	Helpers.corner(host, self.TitleBar, tokens.CornerRadius or 8)

	self.TitleLabel = Surface.text(self.Context, self.TitleBar, {
		Name = "Title",
		Size = host.udim2(1, -210, 1, 0),
		Position = host.udim2(0, 14, 0, 0),
		Text = self.Name,
		TextColor3 = tokens.Text,
		Font = tokens.FontBold,
		TextSize = 15,
		TextTruncate = host.enumItem("TextTruncate", "AtEnd"),
	})
	if self.Subtitle then
		Surface.text(self.Context, self.TitleBar, {
			Name = "Subtitle",
			Size = host.udim2(1, -230, 1, 0),
			Position = host.udim2(0, 160, 0, 0),
			Text = tostring(self.Subtitle),
			TextColor3 = tokens.TextMuted,
			TextSize = 11,
			TextXAlignment = host.enumItem("TextXAlignment", "Right"),
		})
	end

	local buttonArea = host.new("Frame", {
		Name = "ChromeButtons",
		BackgroundTransparency = 1,
		Size = host.udim2(0, 148, 1, 0),
		Position = host.udim2(1, -156, 0, 0),
		ZIndex = 4,
	}, self.TitleBar)
	host.new("UIListLayout", {
		FillDirection = host.enumItem("FillDirection", "Horizontal"),
		HorizontalAlignment = host.enumItem("HorizontalAlignment", "Right"),
		VerticalAlignment = host.enumItem("VerticalAlignment", "Center"),
		Padding = host.udim(0, 6),
		SortOrder = host.enumItem("SortOrder", "LayoutOrder"),
	}, buttonArea)

	local function chromeButton(name, glyph, order, callback)
		local button = host.new("TextButton", {
			Name = name,
			BackgroundColor3 = tokens.SurfaceAlt,
			BackgroundTransparency = 0.25,
			BorderSizePixel = 0,
			Size = host.udim2(0, 26, 0, 26),
			Text = glyph,
			TextColor3 = tokens.Text,
			Font = tokens.FontBold,
			TextSize = 13,
			AutoButtonColor = false,
			LayoutOrder = order,
			ZIndex = 5,
		}, buttonArea)
		Helpers.corner(host, button, 6)
		self:Connect(button, "MouseButton1Click", callback)
		return button
	end

	self.StudioButton = chromeButton("Studio", "S", 1, function()
		self:OpenStudio()
	end)
	if self.Options.ToggleKey then
		self.ToggleButton = chromeButton("ToggleUI", "H", 2, function()
			self:Toggle()
		end)
	end
	self.MinimizeButton = chromeButton("Minimize", "-", 3, function()
		self:Minimize()
	end)
	self.CloseButton = chromeButton("Close", "x", 4, function()
		self:Close()
	end)

	self.Body = host.new("Frame", {
		Name = "Body",
		BackgroundTransparency = 1,
		Position = host.udim2(0, 0, 0, chromeHeight),
		Size = host.udim2(1, 0, 1, -chromeHeight),
	}, self.Root)

	local navHeight = self.Layout.Nav == "Top" and 34 or 0
	local navWidth = self.Layout.Nav == "Left" and (self.Layout.NavWidth or 156) or 0

	self.Nav = host.new("Frame", {
		Name = "Nav",
		BackgroundColor3 = tokens.SurfaceAlt,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		Size = self.Layout.Nav == "Top"
			and host.udim2(1, 0, 0, navHeight)
			or host.udim2(0, navWidth, 1, 0),
	}, self.Body)
	Helpers.corner(host, self.Nav, (tokens.CornerRadius or 8) - 2)
	host.new("UIPadding", {
		PaddingLeft = host.udim(0, 6),
		PaddingRight = host.udim(0, 6),
		PaddingTop = host.udim(0, 6),
		PaddingBottom = host.udim(0, 6),
	}, self.Nav)
	if self.Layout.Nav == "Top" then
		host.new("UIListLayout", {
			FillDirection = host.enumItem("FillDirection", "Horizontal"),
			Padding = host.udim(0, 4),
			SortOrder = host.enumItem("SortOrder", "LayoutOrder"),
		}, self.Nav)
	end

	self.Content = host.new("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		Position = self.Layout.Nav == "Top" and host.udim2(0, 0, 0, navHeight) or host.udim2(0, navWidth, 0, 0),
		Size = self.Layout.Nav == "Top"
			and host.udim2(1, 0, 1, -navHeight)
			or host.udim2(1, -navWidth, 1, 0),
	}, self.Body)

	self.PageHost = host.new("ScrollingFrame", {
		Name = "Pages",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = host.udim2(1, 0, 1, 0),
		CanvasSize = host.udim2(0, 0, 0, 0),
		ScrollBarThickness = 3,
		ScrollBarImageTransparency = 0.5,
	}, self.Content)
	self.PageLayout = host.new("UIListLayout", {
		Name = "PageLayout",
		FillDirection = host.enumItem("FillDirection", "Vertical"),
		Padding = host.udim(0, self.Context.Tokens.Spacing or 8),
		SortOrder = host.enumItem("SortOrder", "LayoutOrder"),
	}, self.PageHost)
	host.new("UIPadding", {
		PaddingLeft = host.udim(0, 10),
		PaddingRight = host.udim(0, 10),
		PaddingTop = host.udim(0, 10),
		PaddingBottom = host.udim(0, 10),
	}, self.PageHost)

	self.Overlay = host.new("Frame", {
		Name = "Overlay",
		BackgroundTransparency = 1,
		Size = host.udim2(1, 0, 1, 0),
		ZIndex = 60,
	}, self.Root)

	if self.Layout.Draggable then
		self:Connect(self.TitleBar, "MouseButton1Down", function()
			self:BeginDrag()
		end)
	end

	-- Existing tabs move into the new content area; nothing is recreated.
	for _, tab in ipairs(self.Tabs) do
		tab.Container.Parent = self.PageHost
	end
	self:BuildNav()
	self:RefreshLayout()
	return self.Root
end

function Window:BuildNav()
	local host = self.Host
	for _, child in ipairs(self.Nav:GetChildren()) do
		if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
			host.destroy(child)
		end
	end
	self.NavButtons = {}
	local iconOnly = self.LayoutId == "IconSidebar"
	for index, tab in ipairs(self.Tabs) do
		local compact = self.Layout.Nav == "Top"
		local button = host.new("TextButton", {
			Name = "Tab_" .. tab.Name,
			BackgroundColor3 = self.Context.Tokens.Surface,
			BackgroundTransparency = 0.5,
			BorderSizePixel = 0,
			Size = compact and host.udim2(0, 96, 1, 0) or host.udim2(1, 0, 0, 30),
			Text = iconOnly and "" or tab.Name,
			TextColor3 = self.Context.Tokens.Text,
			Font = self.Context.Tokens.Font,
			TextSize = 13,
			TextXAlignment = compact and host.enumItem("TextXAlignment", "Center") or host.enumItem("TextXAlignment", "Left"),
			AutoButtonColor = false,
			LayoutOrder = index,
			ZIndex = 4,
		}, self.Nav)
		Helpers.corner(host, button, 6)
		host.new("UIPadding", {
			PaddingLeft = host.udim(0, iconOnly and 0 or 8),
		}, button)
		tab.Button = button
		self.NavButtons[index] = button
		self:Connect(button, "MouseButton1Click", function()
			self:SelectTab(tab)
		end)
	end
	self:HighlightActiveTab()
end

-- Connection helpers ---------------------------------------------------------

function Window:Connect(instance, event, callback)
	local host = self.Host
	local connection
	if host.connect then
		connection = host.connect(instance, event, callback)
	elseif instance[event] and instance[event].Connect then
		connection = instance[event]:Connect(callback)
	end
	if connection then
		table.insert(self.ConnectionList, connection)
	end
	return connection
end

function Window:TrackConnection(connection)
	table.insert(self.ConnectionList, connection)
	return connection
end

-- Tabs -----------------------------------------------------------------------

function Window:CreateTab(options)
	options = options or {}
	assert(not self.Destroyed, "cannot create a tab on a destroyed window")
	local tab = Container.new(self.Context, {
		Kind = "Tab",
		Name = options.Name or ("Tab " .. tostring(#self.Tabs + 1)),
		Icon = options.Icon,
		Order = options.Order or (#self.Tabs + 1),
		Parent = self.PageHost,
		Window = self,
		Dependency = options.Dependency or options.DependsOn,
	})
	tab.Visible = false
	if tab.Container then
		tab.Container.Visible = false
	end
	self.Tabs[#self.Tabs + 1] = tab
	self:BuildNav()
	if #self.Tabs == 1 and options.Selected ~= false then
		self:SelectTab(tab)
	end
	return tab
end

function Window:GetTab(name)
	for _, tab in ipairs(self.Tabs) do
		if tab == name or tab.Name == name or tab.Id == name then
			return tab
		end
	end
	return nil
end

function Window:GetTabs()
	return self.Tabs
end

function Window:HighlightActiveTab()
	local tokens = self.Context.Tokens
	for _, tab in ipairs(self.Tabs) do
		if tab.Button then
			local active = tab == self.ActiveTab
			tab.Button.BackgroundTransparency = active and 0.05 or 0.5
			tab.Button.TextColor3 = active and tokens.Text or tokens.TextMuted
			local record = Helpers.attach(tab.Button)
			if active and not record.Stroke then
				record.Stroke = Helpers.stroke(self.Host, tab.Button, tokens.Accent, 1, 0.15)
			end
			if record.Stroke then
				record.Stroke.Transparency = active and 0.15 or 1
			end
		end
	end
end

function Window:SelectTab(target)
	local tab = self:GetTab(target) or target
	assert(tab, "SelectTab expects a tab or a tab name")
	self.ActiveTab = tab
	for _, candidate in ipairs(self.Tabs) do
		local active = candidate == tab
		candidate.Visible = active
		if candidate.Container then
			candidate.Container.Visible = active and candidate.DependenciesMet ~= false
		end
	end
	self:HighlightActiveTab()
	self:RefreshLayout()
	self.TabChanged:Fire(tab)
	return tab
end

function Window:GetActiveTab()
	return self.ActiveTab
end

-- Sections and cards ---------------------------------------------------------

local function sectionFactory(kind)
	return function(self, options)
		options = options or {}
		local parent = options.Parent or (self.ActiveTab and self.ActiveTab.Instance) or self.PageHost
		return Container.new(self.Context, {
			Kind = kind,
			Name = options.Name or kind,
			Icon = options.Icon,
			Order = options.Order,
			Collapsible = options.Collapsible,
			Collapsed = options.Collapsed,
			Padding = options.Padding,
			Dependency = options.Dependency or options.DependsOn,
			Parent = parent,
			Window = self,
		})
	end
end

Window.CreateSection = sectionFactory("Section")
Window.CreateGroupbox = sectionFactory("Groupbox")
Window.CreateCard = sectionFactory("Card")
Window.CreateCollapsible = sectionFactory("Collapsible")
Window.CreateDependencyBox = sectionFactory("DependencyBox")

function Window:CreateColumn(options)
	options = options or {}
	local parent = options.Parent or (self.ActiveTab and self.ActiveTab.Instance) or self.PageHost
	local column = Container.new(self.Context, {
		Kind = "Column",
		Name = options.Name or "Column",
		Parent = parent,
		Window = self,
		Order = options.Order,
	})
	if column.Container then
		column.Container.Size = self.Host.udim2(options.Width or 0.5, options.WidthOffset or -4, 0, options.Height or 0)
	end
	return column
end

-- Layout and theme -----------------------------------------------------------

function Window:SetLayout(layoutId)
	if not Layouts.has(layoutId) then
		return false, ("unknown layout %q"):format(tostring(layoutId))
	end
	self.LayoutId = layoutId
	self.Layout = Layouts.get(layoutId)
	self:BuildChrome()
	self.LayoutChanged:Fire(layoutId)
	return true
end

function Window:GetLayout()
	return self.LayoutId
end

function Window:RefreshLayout()
	if not self.PageHost or not self.PageLayout then
		return
	end
	if self.PageLayout.AbsoluteContentSize then
		self.PageHost.CanvasSize = self.Host.udim2(0, 0, 0, self.PageLayout.AbsoluteContentSize.Y + 20)
	end
	if self.Layout.TouchFriendly then
		local viewport = viewportOf(self.Host)
		if viewport.X > 0 and viewport.X < 420 then
			self.Root.Size = self.Host.udim2(0.98, 0, 0.94, 0)
		end
	end
end

function Window:SetTheme(themeId, overrides)
	local ok, err = self.Context:SetTheme(themeId, overrides)
	if not ok then
		return false, err
	end
	self:BuildChrome()
	return true
end

function Window:GetTheme()
	return self.Context:GetTheme()
end

function Window:SetStyleDefault(component, styleId)
	return self.Context:SetStyleDefault(component, styleId)
end

Window.SetComponentStyle = function(self, flagOrId, styleId)
	local component = self.Context:FindComponent(flagOrId)
	if not component then
		return false, ("no component registered for %q"):format(tostring(flagOrId))
	end
	return component:SetStyle(styleId)
end

function Window:SetCategoryStyle(component, styleId)
	return self.Context:SetStyleDefault(component, styleId)
end

function Window:SetCategoryConfiguration(component, categoryConfiguration, options)
	return self.Context:SetCategoryConfiguration(component, categoryConfiguration, options)
end

function Window:GetComponent(flagOrId)
	return self.Context:FindComponent(flagOrId)
end

-- Overlay surfaces -----------------------------------------------------------

function Window:Notify(options)
	if type(options) == "string" then
		options = { Message = options }
	else
		options = options or {}
	end
	local host = self.Host
	local holder = host.new("Frame", {
		Name = "NotificationHolder",
		BackgroundTransparency = 1,
		Size = host.udim2(1, -16, 1, -16),
		Position = host.udim2(0, 8, 0, 8),
		ZIndex = 61,
	}, self.Overlay)
	host.new("UIListLayout", {
		FillDirection = host.enumItem("FillDirection", "Vertical"),
		HorizontalAlignment = host.enumItem("HorizontalAlignment", "Right"),
		VerticalAlignment = host.enumItem("VerticalAlignment", "Top"),
		Padding = host.udim(0, 6),
		SortOrder = host.enumItem("SortOrder", "LayoutOrder"),
	}, holder)
	local proxy = {
		Id = Util.uniqueId("Overlay"),
		Window = self,
		Scope = self,
		Instance = holder,
		Kind = "Overlay",
		Context = self.Context,
		Name = "Overlay",
	}
	local spec = {
		Name = options.Title or options.Name or "Notification",
		Description = options.Message or "",
		Flag = options.Flag or Util.uniqueId("Notification"),
		Style = options.Style or { Id = options.StyleId or "notification.toast" },
		Level = options.Level,
		Body = {
			Message = options.Message,
			Level = options.Level or "Info",
		},
	}
	-- Context:Create registers the component exactly once; registering it again
	-- here would duplicate it in the store and inflate the component count.
	local component = self.Context:Create("Notification", proxy, spec)
	component.Window = self
	table.insert(self.Notifications, component)
	local duration = options.Duration
	if duration == nil then
		duration = component.Configuration and component.Configuration.Duration or 4
	end
	if duration and duration > 0 and host.delay then
		host.delay(duration, function()
			component:Dismiss("Timeout")
		end)
	end
	component.Dismissed:Connect(function()
		for index, entry in ipairs(self.Notifications) do
			if entry == component then
				table.remove(self.Notifications, index)
				break
			end
		end
		host.destroy(holder)
	end)
	return component
end

function Window:Dialog(options)
	options = options or {}
	local host = self.Host
	local actions = options.Actions or {
		{ Label = options.ConfirmLabel or "Confirm", Value = true, Style = "Primary" },
		{ Label = options.CancelLabel or "Cancel", Value = false, Style = "Cancel" },
	}
	local dim
	if options.Dim ~= false then
		dim = host.new("TextButton", {
			Name = "DialogDim",
			BackgroundColor3 = self.Context.Tokens.Background,
			BackgroundTransparency = 0.35,
			BorderSizePixel = 0,
			Size = host.udim2(1, 0, 1, 0),
			Text = "",
			AutoButtonColor = false,
			ZIndex = 62,
		}, self.Overlay)
	end
	local proxy = {
		Id = Util.uniqueId("Overlay"),
		Window = self,
		Scope = self,
		Instance = self.Overlay,
		Kind = "Overlay",
		Context = self.Context,
		Name = "Overlay",
	}
	local spec = {
		Name = options.Title or "Confirm",
		Description = options.Message or "",
		Flag = options.Flag or Util.uniqueId("Dialog"),
		Style = options.Style or { Id = options.StyleId or "dialog.modal" },
		Body = {
			Title = options.Title or "Confirm",
			Message = options.Message or "",
			Actions = actions,
		},
		OnChoose = options.OnChoose,
	}
	-- Registered by Context:Create; a second registration would double-count it.
	local component = self.Context:Create("Dialog", proxy, spec)
	component.Window = self
	local view = component.View
	if view and view.Root then
		view.Root.Position = host.udim2(0.5, 0, 0.5, 0)
		view.Root.AnchorPoint = host.vector2(0.5, 0.5)
		view.Root.ZIndex = 63
	end
	component.Answered:Connect(function()
		if dim then
			host.destroy(dim)
		end
	end)
	if dim and options.DimDismiss ~= false then
		self:Connect(dim, "MouseButton1Click", function()
			component:Answer(nil, "Cancelled")
		end)
	end
	return component
end

function Window:Confirm(options)
	return self:Dialog(options)
end

function Window:ClearNotifications()
	for _, component in ipairs(self.Notifications) do
		if not component.Destroyed then
			component:Dismiss("Cleared")
		end
	end
	self.Notifications = {}
	return true
end

-- Window behaviour -----------------------------------------------------------

function Window:BeginDrag()
	if not self.Layout.Draggable then
		return false
	end
	local host = self.Host
	if not host.trackPointer then
		return false
	end
	self.Dragging = true
	local startPointer = pointerOf(host)
	local startBounds = host.bounds(self.Root)
	self:TrackConnection(host.trackPointer(function()
		if not self.Dragging then
			return
		end
		local current = pointerOf(host)
		if not startPointer or not current then
			return
		end
		local viewport = viewportOf(host)
		local originX = viewport.X * 0.5 - ((startBounds.Width or 0) * 0.5)
		local originY = viewport.Y * 0.5 - ((startBounds.Height or 0) * 0.5)
		self.Root.AnchorPoint = host.vector2(0, 0)
		self.Root.Position = host.udim2(0, originX + (current.X - startPointer.X), 0, originY + (current.Y - startPointer.Y))
	end))
	self:Connect(self.TitleBar, "MouseButton1Up", function()
		self.Dragging = false
	end)
	return true
end

function Window:SetVisible(visible)
	self.Root.Visible = visible ~= false
	return self.Root.Visible
end

function Window:Show()
	return self:SetVisible(true)
end

function Window:Hide()
	return self:SetVisible(false)
end

function Window:IsVisible()
	return self.Root.Visible == true
end

function Window:Toggle()
	return self:SetVisible(not self:IsVisible())
end

function Window:Minimize()
	self.Minimized = not self.Minimized
	self.Body.Visible = not self.Minimized
	local widthScale, widthOffset = self.Root.Size.X.Scale, self.Root.Size.X.Offset
	self.Root.Size = self.Minimized
		and self.Host.udim2(widthScale, widthOffset, 0, self.ChromeHeight)
		or self.Host.udim2(widthScale, widthOffset, 0.68, 360)
	return self.Minimized
end

function Window:SetSize(widthScale, widthOffset, heightScale, heightOffset)
	self.Root.Size = self.Host.udim2(widthScale, widthOffset, heightScale, heightOffset)
	return self.Root.Size
end

function Window:SetPosition(x, y)
	self.Root.AnchorPoint = self.Host.vector2(0, 0)
	self.Root.Position = self.Host.udim2(0, x, 0, y)
	return self.Root.Position
end

function Window:Close()
	if self.Destroyed then
		return false
	end
	self.Closed:Fire()
	if self.Options.OnClose then
		self.Options.OnClose()
	end
	return self:Destroy()
end

-- Configuration --------------------------------------------------------------

-- The configuration manager lives on its own field: Context.Configuration is the
-- render-time table that the Surface helpers read while drawing window chrome.
function Window:Config()
	if not self.Context.ConfigManager then
		local Config = require("NEVA:Configuration/Config")
		self.Context.ConfigManager = Config.new(self.Context, {
			Folder = self.Options.ConfigFolder or (self.Options.Configuration and self.Options.Configuration.ConfigFolder) or "NEVAHEXUI",
			Enabled = self.Options.SaveConfigs ~= false,
		})
	end
	return self.Context.ConfigManager
end

function Window:SaveConfig(name)
	local config = self:Config()
	return config:Save(name or "default", config:Snapshot())
end

function Window:LoadConfig(name)
	local config = self:Config()
	local data = config:Load(name or "default")
	if not data then
		return false, "config not found"
	end
	return config:Apply(data)
end

function Window:ListConfigs()
	return self:Config():List()
end

function Window:DeleteConfig(name)
	return self:Config():Delete(name or "default")
end

function Window:ExportConfig()
	local config = self:Config()
	return config:Export(config:Snapshot())
end

function Window:ImportConfig(text, options)
	options = options or {}
	return self:Config():Import(text, options.Name or "imported", options)
end

-- Studio ---------------------------------------------------------------------

function Window:OpenStudio(options)
	local Studio = require("NEVA:Studio")
	self.Studio = self.Studio or Studio.new(self, options)
	return self.Studio
end

-- Lifecycle ------------------------------------------------------------------

function Window:GetComponentCount()
	local total = 0
	for _, tab in ipairs(self.Tabs) do
		total += tab:GetComponentCount()
	end
	return total
end

function Window:SetTitle(title)
	self.Name = tostring(title)
	if self.TitleLabel then
		self.TitleLabel.Text = self.Name
	end
	return self.Name
end

function Window:Summary()
	return {
		Name = self.Name,
		Layout = self.LayoutId,
		Theme = self:GetTheme(),
		Tabs = #self.Tabs,
		Components = self:GetComponentCount(),
		Notifications = #self.Notifications,
		Minimized = self.Minimized,
	}
end

function Window:Destroy()
	if self.Destroyed then
		return false
	end
	self.Destroyed = true
	self.Dragging = false
	for _, connection in ipairs(self.ConnectionList) do
		if connection and connection.Disconnect then
			pcall(function()
				connection:Disconnect()
			end)
		end
	end
	self.ConnectionList = {}
	for _, component in ipairs(self.Notifications) do
		if not component.Destroyed then
			pcall(function()
				component:Destroy()
			end)
		end
	end
	self.Notifications = {}
	for _, tab in ipairs(self.Tabs) do
		if not tab.Destroyed then
			pcall(function()
				tab:Destroy()
			end)
		end
	end
	self.Tabs = {}
	if self.Studio and self.Studio.Destroy then
		pcall(function()
			self.Studio:Destroy()
		end)
	end
	if self.Root then
		self.Host.destroy(self.Root)
		self.Root = nil
	end
	return true
end

return Window
