--[[
	NEVAHEXUI - Core/Logger
	Diagnostics, warnings and debug output.
]]

local Logger = {}
Logger.__index = Logger

Logger.Levels = {
	Debug = 10,
	Info = 20,
	Warn = 30,
	Error = 40,
	Silent = 100,
}

function Logger.new(options)
	options = options or {}
	return setmetatable({
		Level = options.Level or Logger.Levels.Info,
		Prefix = options.Prefix or "NEVAHEXUI",
		Sink = options.Sink,
		History = {},
		MaxHistory = options.MaxHistory or 200,
	}, Logger)
end

function Logger:_write(level, message)
	local line = ("[%s][%s] %s"):format(self.Prefix, level, message)
	table.insert(self.History, { level = level, message = message, line = line })
	while #self.History > self.MaxHistory do
		table.remove(self.History, 1)
	end
	if self.Sink then
		self.Sink(level, message, line)
		return line
	end
	if level == "Error" then
		-- `warn` exists in Roblox but not in every Luau runtime (the CLI test
		-- host included); logging must never be the thing that crashes a caller.
		if type(warn) == "function" then
			warn(line)
		else
			print(line)
		end
	elseif self.Level <= Logger.Levels[level] then
		print(line)
	end
	return line
end

function Logger:Debug(message)
	if self.Level <= Logger.Levels.Debug then
		return self:_write("Debug", message)
	end
	return nil
end

function Logger:Info(message)
	if self.Level <= Logger.Levels.Info then
		return self:_write("Info", message)
	end
	return nil
end

function Logger:Warn(message)
	if self.Level <= Logger.Levels.Warn then
		return self:_write("Warn", message)
	end
	return nil
end

function Logger:Error(message)
	return self:_write("Error", message)
end

function Logger:GetHistory()
	return self.History
end

function Logger:SetLevel(level)
	if type(level) == "string" then
		local resolved = Logger.Levels[level]
		assert(resolved, ("unknown log level %q"):format(level))
		self.Level = resolved
	else
		self.Level = level
	end
end

return Logger
