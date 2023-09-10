local LoggerBase = require('loggers.LoggerBase')

local LoggerPrintDbgStr = {}
-- inherit all special methods of BaseClass
LoggerPrintDbgStr.__index = LoggerPrintDbgStr

function LoggerPrintDbgStr.new(config)
	local super = LoggerBase.new(config)
	local self = setmetatable(super, LoggerPrintDbgStr)

    -- setting derived values
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
