--
--  Multisource logger (can combine different loggers together)
--
local LoggerBase = require("loggers.LoggerBase")

---@class LoggerMulti: LoggerBase
---@field loggers table[table] array of multiple loggers
local LoggerMulti = {}
LoggerMulti.__index = LoggerMulti

function LoggerMulti.new(config)
	local super = LoggerBase.new(config)
	local self = setmetatable(super, LoggerMulti)

	-- setting derived values
	self.name = "LoggerMulti"

	assert(config.loggers, "Config table must contain `loggers`")
	assert(#config.loggers > 0, "config.loggers empty, expected array table of LoggerBase objects")

	for i = 1, #config.loggers do
	    LoggerBase.validate_custom_logger(config.loggers[i])
	end

	self.loggers = config.loggers

	return self
end

function LoggerMulti:init()
	for i = 1, #self.loggers do
	    self.loggers[i]:init()
	end
	return true
end

function LoggerMulti:stop()
	-- Just a placeholder, nothing special to free
	for i = 1, #self.loggers do
	    self.loggers[i]:stop()
	end
	return true
end

function LoggerMulti:log(msg_templ, ...)
	for i = 1, #self.loggers do
	    self.loggers[i]:log(msg_templ, ...)
	end
	return true
end

return LoggerMulti
