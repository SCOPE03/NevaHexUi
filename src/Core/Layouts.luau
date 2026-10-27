--[[
	NEVAHEXUI - Core/Layouts
	Window layout definitions. A layout owns the arrangement of the window chrome:
	where navigation lives, how the content area is sized, whether the window is
	draggable or resizable, and how touch friendly the spacing is. Components, tabs
	and styles are identical across layouts, so switching layout never recreates a
	single component.
]]

local Layouts = {}
local definitions = {}
local order = {}

function Layouts.register(definition)
	assert(type(definition) == "table", "Layouts.register expects a table")
	assert(type(definition.Id) == "string" and definition.Id ~= "", "layout definitions need an Id")
	if definitions[definition.Id] then
		return definitions[definition.Id]
	end
	local record = {
		Id = definition.Id,
		Name = definition.Name or definition.Id,
		Description = definition.Description or "",
		Nav = definition.Nav or "Left",
		NavWidth = definition.NavWidth or 156,
		Draggable = definition.Draggable ~= false,
		Resizable = definition.Resizable == true,
		TouchFriendly = definition.TouchFriendly == true,
		Density = definition.Density or 1,
		Chrome = definition.Chrome or "Standard",
		-- Modest fixed default: adding a large offset to a viewport fraction made
		-- the window wider and taller than the screen it was opening on.
		Sizing = definition.Sizing or {
			Size = { 0, 620, 0, 420 },
			MinSize = { 360, 260 },
			MaxSize = { 1080, 760 },
		},
		Build = definition.Build,
	}
	definitions[record.Id] = record
	table.insert(order, record.Id)
	return record
end

function Layouts.get(id)
	return definitions[id or "Sidebar"]
end

function Layouts.has(id)
	return definitions[id] ~= nil
end

function Layouts.ids()
	local out = {}
	for _, id in ipairs(order) do
		table.insert(out, id)
	end
	return out
end

function Layouts.list()
	local out = {}
	for _, id in ipairs(order) do
		local definition = definitions[id]
		table.insert(out, {
			Id = definition.Id,
			Name = definition.Name,
			Description = definition.Description,
			Nav = definition.Nav,
			Draggable = definition.Draggable,
			Resizable = definition.Resizable,
			TouchFriendly = definition.TouchFriendly,
		})
	end
	return out
end

Layouts.register({
	Id = "Sidebar",
	Name = "Sidebar",
	Description = "Vertical navigation column with grouped content on the right.",
	Nav = "Left",
	NavWidth = 156,
	Draggable = true,
	Resizable = true,
})

Layouts.register({
	Id = "TopTabs",
	Name = "Top tabs",
	Description = "Horizontal tab strip above the content, with overflow scrolling.",
	Nav = "Top",
	NavWidth = 0,
	Draggable = true,
	Resizable = true,
})

Layouts.register({
	Id = "Floating",
	Name = "Floating",
	Description = "Compact floating panel with minimal chrome and a header drag handle.",
	Nav = "Left",
	NavWidth = 132,
	Draggable = true,
	Resizable = true,
	Density = 0.9,
	Chrome = "Minimal",
})

Layouts.register({
	Id = "Compact",
	Name = "Compact / mobile",
	Description = "Touch friendly single-column layout with a horizontal nav strip.",
	Nav = "Top",
	NavWidth = 0,
	TouchFriendly = true,
	Resizable = false,
	Density = 1.15,
	Sizing = {
		Size = { 0.94, 0, 0.9, 0 },
		MinSize = { 280, 240 },
		MaxSize = { 720, 760 },
	},
})

Layouts.register({
	Id = "IconSidebar",
	Name = "Icon sidebar",
	Description = "Narrow icon-only navigation column that expands to reveal tab labels.",
	Nav = "Left",
	NavWidth = 52,
	Draggable = true,
	Resizable = true,
	Density = 0.95,
})

Layouts.register({
	Id = "MultiColumn",
	Name = "Multi-column dashboard",
	Description = "Sidebar navigation with a two-column card grid for dashboard content.",
	Nav = "Left",
	NavWidth = 148,
	Draggable = true,
	Resizable = true,
})

return Layouts
