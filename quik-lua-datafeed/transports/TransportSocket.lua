--
--  UDP Socket transport
--
--
local TransportBase = require('transports.TransportBase')
local luasocket = require('socket')

---@class TransportSocket: TransportBase
---@field socket table luasocket UDP socket instance
---@field host string log listener host
---@field port number log listener port
local TransportSocket = {}
TransportSocket.__index = TransportSocket

function TransportSocket.new(config)
	local self = TransportBase.new(config, TransportSocket)

    -- setting derived values
	self.name = "TransportSocket"

	assert(config.host, 'Config table must contain `host`')
	assert(type(config.host) == "string", 'config.host must be a string')
	assert(config.port, 'Config table must contain `port`')
	assert(type(config.port) == "number", 'config.port must be a number')

	self.socket = nil
	self.host = config.host
	self.port = config.port

	self.serialize_key = config.serialize_key or TransportBase.serialize_key
	self.serialize_value = config.serialize_value or TransportBase.serialize_value

	TransportBase.validate_custom_transport(self)

	return self
end

function TransportSocket:init()
    -- convert host name to ip address
    local ip = assert(luasocket.dns.toip(self.host))

    -- create a new UDP object
    self.socket = assert(luasocket.udp())
    assert(self.socket:setpeername(ip, self.port))
    return true
end

function TransportSocket:is_init()
	return self.socket ~= nil
end

function TransportSocket:stop()
    -- Just a placeholder, nothing special to free
    self.socket = nil
    return true
end

---Sends key-value via transport route
---@param key string[] array of strings
---@param value {[string]: boolean | string | number | table | nil} table of data
---@diagnostic disable-next-line
function TransportSocket:send(key, value)
	assert(self.socket, "socket connection not initialized")
	local skey = self:serialize_key(key)
	local svalue = self:serialize_value(value)
	local data = table.concat({skey, svalue}, " ")
	self.socket:send(data)
end


return TransportSocket
