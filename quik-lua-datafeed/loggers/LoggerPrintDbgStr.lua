local LoggerBase = require('loggers.LoggerBase')

---@class LoggerPrintDbgStr: LoggerBase
local LoggerPrintDbgStr = {}
LoggerPrintDbgStr.__index = LoggerPrintDbgStr

function LoggerPrintDbgStr.new(config)
	local self = LoggerBase.new(config, LoggerPrintDbgStr)

	self.name = "LoggerPrintDbgStr"

	LoggerBase.validate_custom_logger(self)
	return self
end

function LoggerPrintDbgStr:init()
    -- Just a placeholder, nothing special to init
    return true
end

function LoggerPrintDbgStr:stop()
    -- Just a placeholder, nothing special to free
    return true
end

function LoggerPrintDbgStr:log(msg_templ, ...)
    PrintDbgStr(string.format(msg_templ, ...))
end

return LoggerPrintDbgStr
