--[[
--  TransportLog simply prints all transport:send() into log (useful for debugging)
--]]
local cjson = require("cjson")
cjson.encode_invalid_numbers(true) -- enable Nan serialization in JSON

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

---Serializes key in transport specific notation (i.e. removing special chars from path)
---@param key string[] array of strings, like {'a', 'b', 'c'}
---@return string # serialized key, like a#b#c
---@diagnostic disable-next-line
function TransportLog:serialize_key(key)
	-- This one is mandatory for every custom transport
	TransportBase.validate_key(key)
	return table.concat(key, "#")
end

---Serializes key in transport specific data (i.e. JSON)
---@param value {[string]: boolean | string | number | table | nil} table of data {a = 1, b = 'ok'}
---@return string # serialized value, like {"a": 1, "b": "ok"}
---@diagnostic disable-next-line
function TransportLog:serialize_value(value)
	return cjson.encode(value)
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
