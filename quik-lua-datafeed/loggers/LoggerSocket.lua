--
--  UDP Socket Logger in case if you need to listen log remotely or on Linux
--    Without connection all log records just dropped
--
local LoggerBase = require('loggers.LoggerBase')

---@class LoggerSocket: LoggerBase
---@field socket table luasocket UDP socket instance
---@field host string log listener host
---@field port number log listener port
local LoggerSocket = {}
LoggerSocket.__index = LoggerSocket

function LoggerSocket.new(config)
	local super = LoggerBase.new(config)
	local self = setmetatable(super, LoggerSocket)

    -- setting derived values
	self.name = "LoggerSocket"

	assert(config.host, 'Config table must contain `host`')
	assert(type(config.host) == "string", 'config.host must be a string')
	assert(config.port, 'Config table must contain `port`')
	assert(type(config.port) == "number", 'config.port must be a number')

	self.socket = nil
	self.host = config.host
	self.port = config.port

	return self
end

function LoggerSocket:init()
    local isok, luasocket = pcall(require, "socket")
    if not isok then
        error('luasocket module is not found, try to install it via luarocks or probably shared dll issue')
    end

    -- convert host name to ip address
    local ip = assert(luasocket.dns.toip(self.host))

    -- create a new UDP object
    self.socket = assert(luasocket.udp())
    assert(self.socket:setpeername(ip, self.port))
    return true
end

function LoggerSocket:stop()
    -- Just a placeholder, nothing special to free
    return true
end

function LoggerSocket:log(msg_templ, ...)
    assert(self.socket, 'self.socket not initialized, skipped init()?')

    return self.socket:send(string.format(msg_templ, ...))
end

return LoggerSocket
