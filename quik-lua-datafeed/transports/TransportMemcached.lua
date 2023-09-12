local memcached = require("memcached")
local cjson = require("cjson")
cjson.encode_invalid_numbers(true) -- enable Nan serialization in json

local TransportBase = require('transports.TransportBase')

---@class TransportMemcached: TransportBase
---@field host string? memcached host, default 'localhost'
---@field port number? memcached port, default 11211
---@field exptime_sec number? memcached record expiration time, in seconds, default 1 hour
---@field memcached table memcached connection
local TransportMemcached = {}
TransportMemcached.__index = TransportMemcached

function TransportMemcached.new(config)
	local super = TransportBase.new(config)
	local self = setmetatable(super, TransportMemcached)

    -- setting derived values
	self.name = "TransportMemcached"
	self.host = config.host or 'localhost'
	self.port = config.port or 11211
	self.exptime_sec = config.exptime_sec or (60 * 60)
	self.serialize_key = config.serialize_key or TransportMemcached.serialize_key
	self.serialize_value = config.serialize_value or TransportMemcached.serialize_value
	self.memcached = nil

	TransportBase.validate_custom_transport(self)

	return self
end

function TransportMemcached:init()
	self.memcached = memcached.connect(self.host, self.port)
    return self.memcached or false
end

function TransportMemcached:stop()
	if self.memcached then
		self.memcached:quit()
		self.memcached = nil
	end
    return true
end

---Serializes key in transport specific notation (i.e. removing special chars from path)
---@param key string[] array of strings, like {'a', 'b', 'c'}
---@return string # serialized key, like a#b#c 
---@diagnostic disable-next-line
function TransportMemcached:serialize_key(key)
	-- This one is mandatory for every custom transport
	TransportBase.validate_key(key)

	return table.concat(key, '#')
end

---Serializes key in transport specific data (i.e. json)
---@param value {[string]: boolean | string | number | table | nil} table of data {a = 1, b = 'ok'}
---@return string # serialized value, like {"a": 1, "b": "ok"} 
---@diagnostic disable-next-line
function TransportMemcached:serialize_value(value)
	return cjson.encode(value)
end

---Sends key-value via transport route
---@param key string[] array of strings
---@param value {[string]: boolean | string | number | table | nil} table of data
---@diagnostic disable-next-line
function TransportMemcached:send(key, value)
	assert(self.memcached, 'memcached connection not initialized')
	self.memcached:set(
		self:serialize_key(key), self:serialize_value(value), self.exptime_sec
	)
end

return TransportMemcached
