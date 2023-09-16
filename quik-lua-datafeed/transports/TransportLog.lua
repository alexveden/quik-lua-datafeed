--[[
--  TransportLog simply prints all transport:send() into log (useful for debugging)
--]]

local TransportBase = require("transports.TransportBase")

---@class TransportLog: TransportBase
---@field logger LoggerBase generic function for logger output
local TransportLog = {}
TransportLog.__index = TransportLog

function TransportLog.new(config)
	local self = TransportBase.new(config, TransportLog)

	-- setting derived values
	assert(config.logger, "You must set config.logger (logger instance)")
	assert(config.logger.log, "You must set config.logger.log function missing")
	self.name = "TransportLog"
	self.logger = config.logger

	TransportBase.validate_custom_transport(self)

	return self
end

function TransportLog:init()
	return true
end

function TransportLog:is_init()
	return true
end

function TransportLog:stop()
	return true
end

---Sends key-value via transport route
---@param key string[] array of strings
---@param value {[string]: boolean | string | number | table | nil} table of data
---@diagnostic disable-next-line
function TransportLog:send(key, value)
	assert(self.logger, "loger is not set")
	self.logger:log("TransportLog:send() -> %s: %s", self:serialize_key(key), self:serialize_value(value))
end

return TransportLog
