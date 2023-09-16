-- Варианты логгеров
local LoggerSocket = require('loggers.LoggerSocket')
local LoggerPrintDbgStr = require('loggers.LoggerPrintDbgStr')

-- Варианты транспорта
local TransportLog = require('transports.TransportLog')
local TransportMemcached = require('transports.TransportMemcached')
local TransportSocket = require('transports.TransportSocket')

-- Handlers - это модули обработки информации от Квика
local QuikStats = require('handlers.QuikStats')


-- local logger = LoggerSocket.new({host = 'localhost', port = 17000})
local logger = LoggerPrintDbgStr.new({})

local transport = TransportLog.new({logger = logger})
-- local transport = TransportMemcached.new({ host = "localhost", port = 11211, exptime_sec = 60*30})
-- local transport = TransportSocket.new({host = 'localhost', port = 17001})

CONFIG = {
    verbosity_level = 5,
    logger = logger,
    handlers = {
        QuikStats.new({transport = transport}),
    }
}

return CONFIG
