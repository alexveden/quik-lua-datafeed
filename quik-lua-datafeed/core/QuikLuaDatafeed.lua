local ev = require("core.events")
local LoggerBase = require("loggers.LoggerBase")
local HandlerBase = require("handlers.HandlerBase")
local TransportBase = require("transports.TransportBase")
local FeedStats = require("core.FeedStats")

---@class QuikLuaConfig
---@field verbosity_level number
---@field raise_event_errors boolean? raises lua error and stops script on handler.on_event error (default: false)
---@field logger LoggerBase
---@field handlers HandlerBase[]

---@class QuikLuaDataFeed
---@field verbosity_level number level of logging verbosity
---@field raise_event_errors boolean? raises lua error and stops script on handler.on_event error (default: false)
---@field stats FeedStats aggregated datafeed stats
---@field logger LoggerBase logging engine instance
---@field handlers HandlerBase[] list of active handlers
QuikLuaDataFeed = {
	verbosity_level = 5,
}
QuikLuaDataFeed.__index = QuikLuaDataFeed

---Creates new instance of QuikLuaDataFeed class
---@param config table - configuration table
---@return QuikLuaDataFeed
function QuikLuaDataFeed.new(config)
	---@class QuikLuaDataFeed
	local self = setmetatable({}, QuikLuaDataFeed)
	self:initialize(config)
	return self
end

---Initializes QuikLuaDataFeed instance and handlers
---@param config QuikLuaConfig initial QuikLuaDataFeed configuration table
---@return nil
function QuikLuaDataFeed:initialize(config)
	assert(config, "no config")
	self.stats = FeedStats.new()
	self.verbosity_level = config.verbosity_level or 1
	self.logger = config.logger or error("logger is not set in config.logger")
	self.raise_event_errors = config.raise_event_errors or false

	local isok, err = xpcall(LoggerBase.validate_custom_logger, debug.traceback, self.logger)
	if not isok then
		error("Logger validation error: \n" .. err)
	end

	isok, err = xpcall(self.logger.init, debug.traceback, self.logger)
	if not isok then
		error("Logger initialization error: \n" .. err)
	end
	self:log(1, "---------------------")
	self:log(1, "Starting QuikLuaDataFeed")
	self:log(2, "QuikLuaDataFeed: initialized logger engine")

	self:log(2, "QuikLuaDataFeed: initializing handlers")

	local function log_func(level, msg_templ, ...)
		assert(self)
		self:log(level, msg_templ, ...)
	end

	assert(config.handlers, "No config.handlers given")

	for _, handler in pairs(config.handlers) do
		self:log(3, "Validating handler: %s", handler.name)

		isok, err = xpcall(HandlerBase.validate_custom_handler, debug.traceback, handler)
		if not isok then
			error("Handler validation failed: \n" .. err)
		end

		if not handler.transport:is_init() then
			self:log(3, "Validating transport: %s", handler.name)
			isok, err = xpcall(TransportBase.validate_custom_transport, debug.traceback, handler.transport)
			if not isok then
				error("Transport validation failed: \n" .. err)
			end

			self:log(3, "initializing transport: %s", handler.name)
			isok, err = xpcall(handler.transport.init, debug.traceback, handler.transport)
			if not isok then
				error("Transport initialization failed: \n" .. err)
			end
		end

		self.stats:set_handler(handler)

		handler.log_func = log_func

		isok, err = xpcall(handler.init, debug.traceback, handler)
		if not isok then
			error("Handler initialization failed: \n" .. err)
		end
	end

	self.handlers = config.handlers

	self:log(2, "QuikLuaDataFeed: initialize succeeded")
end

--
---Log debug information using pre-configured logger
---@param level number verbosity_level of the log message
---@param msg_templ string log message optionally with string.format() magics
---@vararg table | string | number | boolean | nil
function QuikLuaDataFeed:log(level, msg_templ, ...)
	assert(level, "level is nil")
	assert(self.verbosity_level, "self.verbosity_level is nil")
	if level <= self.verbosity_level then
		self.logger:log(msg_templ, ...)
	end
end

---Notification by Quik about length of current queue (just for stats)
---@param current_que_length number
function QuikLuaDataFeed:quik_notify_que_length(current_que_length)
	self.stats:report_quik_que_length(current_que_length)
end

---Returns a table of all Quik Data events handlers \
---keys: the same as Quik event functions i.e. `AllQuote = true` \
---values: simple true \
---@return {string: boolean}
function QuikLuaDataFeed:quik_subscribe_events()
	local e_subs = {}
	for _, h in pairs(self.handlers) do
		for e, is_subs in pairs(h.events) do
			assert(is_subs)
			self.stats:set_event(e)
			e_subs[e] = true
			self:log(2, "Subscribed events: [%s] %s", h.name, e)
		end
	end

	return e_subs
end

---Main Quik Event Handler
---@param event Event incoming event
function QuikLuaDataFeed:quik_on_event(event)
	local time_begin = os.clock()

	assert(event, "nil event given")
	assert(event.eid, "expected to have eid")
	if event.eid ~= ev.ON_IDLE then
		self:log(3, "Event %s", event.eid)
	end

	local has_handled = false
	for _, h in pairs(self.handlers) do
		if h.events[event.eid] then
			local handler_begin = os.clock()
			local isok, ret = xpcall(h.on_event, debug.traceback, h, event)
			if not isok then
				if self.raise_event_errors then
					error('Handler['.. h.name ..'] on_event error: \n' ..ret)
				else
					self:log(0, "Handler[%s] on_event error: \n %s", h.name, ret)
				end
			end

			if ret == true then
				self.stats:report_handler_duration(h, os.clock() - handler_begin)
				has_handled = true
			end
		end
	end
	if has_handled then
		self.stats:report_event_duration(event.eid, os.clock() - time_begin)
	end
	return has_handled
end

---Closes QuikLuaDataFeed and frees its resources
function QuikLuaDataFeed:stop()
	self:log(3, "Stopping: handlers")
	for _, handler in pairs(self.handlers) do
		if handler.transport:is_init() then
			handler.transport:stop()
		end
		handler:stop()
	end

	self:log(3, "Stopping: loggers")
	self.logger:stop()
end

-- Returns class
return QuikLuaDataFeed
