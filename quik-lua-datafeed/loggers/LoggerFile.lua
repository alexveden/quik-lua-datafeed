--
--  Text file logger
--
local LoggerBase = require("loggers.LoggerBase")

---@class LoggerFile: LoggerBase
---@field filename string path to log file
---@field file file*? open file instance
---@field filemode string config file mode
local LoggerFile = {}
LoggerFile.__index = LoggerFile

function LoggerFile.new(config)
	local super = LoggerBase.new(config)
	local self = setmetatable(super, LoggerFile)

	-- setting derived values
	self.name = "LoggerFile"

	assert(config.file, "Config table must contain `file`")
	assert(not config.filemode or (config.filemode == "a" or config.filemode == "w"), 'config.filemode must be "w" or "a"')
	assert(type(config.file) == "string", "config.file must be a string")

	self.filename = config.file
	self.filemode = config.filemode or "a"
	self.file = nil

	LoggerBase.validate_custom_logger(self)
	return self
end

function LoggerFile:init()
	self.file = io.open(self.filename, self.filemode)
	return true
end

function LoggerFile:stop()
	-- Just a placeholder, nothing special to free
	if self.file then
		self.file:close()
		self.file = nil
	end
	return true
end

function LoggerFile:log(msg_templ, ...)
	assert(self.file, "Log file not open, missing init?")
	local result = self.file:write(string.format(msg_templ .. "\r\n", ...))
	self.file:flush()
	return result
end

return LoggerFile
