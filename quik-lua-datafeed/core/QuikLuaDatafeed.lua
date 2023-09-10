local json = require("core.json")

---@class FeedStats
---@field n_events number count of events processed by datafeed
---@field max_que_length number maximum number of events waiting for processing in Quik que
---@field current_que_length number most recent que length
---@field subscriptions table per-event type statistics

---@class QuikLuaDataFeed
---@field debug_level number level of logging verbosity
---@field stats FeedStats aggregated datafeed stats
QuikLuaDataFeed = {
    debug_level = 0,
	stats = {
		n_events = 0,
		max_que_length = 0,
		current_que_length = 0,
		subscriptions = {},
	},
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
---@param config table initial QuikLuaDataFeed configuration table
---@return nil
function QuikLuaDataFeed:initialize(config)
	assert(config, "no config")
	self:log("QuikLuaDataFeed: Initialized log")
	-- Read config
	-- Validate config
	-- Setup handlers
	-- Setup loggers
	-- Setup serializers
end

---Log debug information using pre-configured logger
---@param msg_templ string log message optionally with string.format() magics
---@vararg table | string | number | boolean | nil
function QuikLuaDataFeed:log(msg_templ, ...)
	PrintDbgStr(string.format(msg_templ, ...))
end

---Notification by Quik about length of current queue (just for stats)
---@param current_que_length number
function QuikLuaDataFeed:quik_notify_que_length(current_que_length)
	assert(current_que_length, "current_que_length nil")

	self.stats.current_que_length = current_que_length
	self.stats.max_que_length = math.max(self.stats.current_que_length, current_que_length)
end

---Returns a table of all Quik Data events handlers \
---keys: the same as Quik event functions i.e. `AllQuote = true` \
---values: simple true \
---@return table
function QuikLuaDataFeed:quik_get_subscribed_events()
	-- TODO: implement handler / subscriptions
	local e_subs = {
		OnAllTrade = true,
		OnQuote = true,
	}

	for k, _ in pairs(e_subs) do
		assert(not self.stats.subscriptions[k], "subscribed_events already called")
		self.stats.subscriptions[k] = { n = 0, time_sum = 0.0 }
	end

	return e_subs
end

---Main Quik Event Handler
---@param event table
function QuikLuaDataFeed:quik_on_event(event)
	local time_begin = os.clock()

	assert(event, "nil event given")
	assert(event.callback, "expected to have callback name")
	self:log("Event %s", event.callback)

	-- Recording event performance stats
	self.stats.n_events = self.stats.n_events + 1
	local n = self.stats.subscriptions[event.callback].n
	self.stats.subscriptions[event.callback].n = n + 1

	local time = self.stats.subscriptions[event.callback].time_sum
	local elapsed = os.clock() - time_begin
	self.stats.subscriptions[event.callback].time_sum = time + elapsed
end

---Returns QuikLuaDataFeed stats
---@param as_json? boolean - return result as json string (default false)
---@return table | string
function QuikLuaDataFeed:get_stats(as_json)
	as_json = as_json or false

	local result = {}
	for k, v in pairs(self.stats) do
		if k == "subscriptions" then
			assert(type(v) == "table")

			local s = {}
			for sk, sv in pairs(v) do
				local avg_per_call = 0
				if sv.n > 0 then
					avg_per_call = sv.time_sum / sv.n
				end
				s[sk] = {
					count = sv.n,
					avg_per_call = avg_per_call,
					total_time = sv.time_sum,
				}
			end
			result[k] = s
		else
			result[k] = v
		end
	end

	if as_json then
		return json.encode(result)
	else
		return result
	end
end


---Closes QuikLuaDataFeed and frees its resources
function QuikLuaDataFeed:stop()
	self:log("stopped")
end

-- Returns class
return QuikLuaDataFeed
