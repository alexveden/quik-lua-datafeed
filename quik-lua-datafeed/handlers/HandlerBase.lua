local ev = require("core.events")

---@class HandlerBase
---@field name string simple handler name
---@field transport TransportBase transport engine assigned to handler
---@field events {string: boolean} table of handler events
---@field log_func function logger log function (typically QuiLuaDatafeed.log)
HandlerBase = {}
HandlerBase.__index = HandlerBase

---@class HandlerConfig
---@field transport TransportBase instance of transport

---Creates new instance of HandlerBase class
---@param config HandlerConfig - configuration table
---@return HandlerBase
function HandlerBase.new(config)
	---@class HandlerBase
	assert(type(config) == "table", "HandlerBase: config must be a table or empty table `{}`")
	local self = setmetatable({}, HandlerBase)
	self.name = "HandlerBase"
	self.transport = config.transport
	self.events = {}
	self.log_func = nil -- must be set externally by QuiLuaDatafeed
	self.log = HandlerBase.log

	return self
end

function HandlerBase:init()
	error("You must implement init() function in custom handler class")
end

function HandlerBase:stop()
	error("You must implement stop() function in custom handler class")
end

function HandlerBase:log(level, msg_templ, ...)
	assert(self.log_func, "self.log_func is not set in constructor or config")
	self.log_func(level, msg_templ, ...)
end

---Main event processing function
---@param event Event event data passed from quik or ON_TIME event
---@diagnostic disable-next-line
function HandlerBase:on_event(event)
	error("You must implement on_event() function in custom handler class")
end

function HandlerBase.validate_custom_handler(custom_handler)
	assert(custom_handler, "custom_handler is nil")
	assert(type(custom_handler) == "table", ": custom_handler expected to be a table")
	assert(custom_handler["name"], "custom_handler must have a name")
	assert(custom_handler["transport"], "custom_handler must have transport")
	-- assert(custom_handler['log_func'], 'custom_handler must have log_func' )
	-- assert(type(custom_handler['log_func']) == 'function', 'custom_handler.log_func is not a function' )

	for _, m in pairs({ "init", "stop", "on_event" }) do
		assert(custom_handler[m], custom_handler["name"] .. ": custom_handler expected to have " .. m .. "()")
		assert(
			type(custom_handler[m]) == "function",
			custom_handler["name"] .. ": custom_handler expected to have " .. m .. "() as a function"
		)
	end

	if custom_handler.name ~= "HandlerBase" then
		assert(custom_handler.events, "custom_handler.events is nil")

		local all_events = {}
		for _, v in pairs(ev) do
			all_events[v] = true
		end

		local n_events = 0
		for k, v in pairs(custom_handler.events) do
			assert(
				type(k) == "string",
				"Event key must be core.events[ON_] -> string, got " .. tostring(k) .. " type: " .. type(k)
			)
			assert(v, "Event value must pass `if event then`, got " .. tostring(v))
			assert(all_events[k], "Event key " .. k .. " not found in core.events")
			n_events = n_events + 1
		end

		assert(
			n_events > 0,
			"no events or custom_handler events must be a dictionary of {eid = true, core.events.ON_TIME = true}, maybe passed simple array?"
		)
	end
end

return HandlerBase
