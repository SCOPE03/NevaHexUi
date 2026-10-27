--[[
	NEVAHEXUI - Core/Signal
	Minimal deterministic event emitter used for framework-internal signals.
]]

local Signal = {}
Signal.__index = Signal

function Signal.new(name)
	return setmetatable({
		Name = name or "Signal",
		_handlers = {},
		_destroyed = false,
	}, Signal)
end

function Signal:Connect(callback)
	assert(type(callback) == "function", "Signal:Connect expects a function")
	assert(not self._destroyed, "cannot connect to a destroyed signal")
	local handler = { callback = callback, connected = true, _owner = self }
	self._handlers[handler] = true
	local connection = {}
	function connection:Disconnect()
		if not handler.connected then
			return
		end
		handler.connected = false
		self._handlers[handler] = nil
	end
	-- keep a reference so Signal:Fire can iterate without exposing internals
	connection._handler = handler
	return connection
end

function Signal:Once(callback)
	local connection
	connection = self:Connect(function(...)
		connection:Disconnect()
		callback(...)
	end)
	return connection
end

function Signal:Fire(...)
	if self._destroyed then
		return 0
	end
	local fired = 0
	-- snapshot so handlers can disconnect during dispatch
	local snapshot = {}
	for handler in pairs(self._handlers) do
		if handler.connected then
			table.insert(snapshot, handler)
		end
	end
	for _, handler in ipairs(snapshot) do
		if handler.connected then
			fired += 1
			handler.callback(...)
		end
	end
	return fired
end

function Signal:GetConnectionCount()
	local total = 0
	for handler in pairs(self._handlers) do
		if handler.connected then
			total += 1
		end
	end
	return total
end

function Signal:DisconnectAll()
	for handler in pairs(self._handlers) do
		handler.connected = false
	end
	self._handlers = {}
end

function Signal:Destroy()
	self:DisconnectAll()
	self._destroyed = true
end

return Signal
