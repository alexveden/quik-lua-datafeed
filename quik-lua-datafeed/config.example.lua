-- Варианты логгеров
local LoggerSocket = require('loggers.LoggerSocket')
local LoggerPrintDbgStr = require('loggers.LoggerPrintDbgStr')

-- Варианты транспортов
local TransportLog = require('transports.TransportLog')
local TransportMemcached = require('transports.TransportMemcached')

-- Handlers - это модули обработки информации от Квика
local QuikStats = require('handlers.QuikStats')


-- local logger = LoggerSocket.new({host = 'localhost', port = 17000})
local logger = LoggerPrintDbgStr.new({})
local transport = TransportLog.new({logger = logger})
-- local transport = TransportMemcached.new({ host = "localhost", port = 11211, exptime_sec = 60*30})

CONFIG = {
    verbosity_level = 5,
    logger = logger,
    handlers = {
        QuikStats.new({transport = transport}),
    }
}

return CONFIG
