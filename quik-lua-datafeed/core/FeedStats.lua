local cjson = require("cjson")

---@class FeedStats
---@field n_events number count of events processed by datafeed
---@field max_que_length number maximum number of events waiting for processing in Quik que
---@field current_que_length number most recent que length
---@field subscriptions table per-event type statistics
---@field handlers table per-handler event processing stats
FeedStats = { }
FeedStats.__index = FeedStats


---Creates new instance of FeedStats class
---@return FeedStats
function FeedStats.new()
    local self = setmetatable({
		n_events = 0,
		max_que_length = 0,
		current_que_length = 0,
		subscriptions = {},
		handlers = {}
	    }, FeedStats)

	return self
end

---Set zero stats for given handler
---@param handler HandlerBase
function FeedStats:set_handler(handler)
	self.handlers[handler.name] = {n = 0, time_sum = 0.0}
end


---Set zero stats for given event
---@param eid EventID
function FeedStats:set_event(eid)
	self.subscriptions[eid] = {n = 0, time_sum = 0.0}
end

---Report total duration of event processing
---@param eid EventID event id
---@param elapsed number time in fractional seconds
function FeedStats:report_event_duration(eid, elapsed)
	-- Recording event performance stats
	self.n_events = self.n_events + 1
	local n = self.subscriptions[eid].n
	self.subscriptions[eid].n = n + 1

	local time = self.subscriptions[eid].time_sum
	self.subscriptions[eid].time_sum = time + elapsed
end

---Report total duration of event processing
---@param handler HandlerBase
---@param elapsed number time in fractional seconds
function FeedStats:report_handler_duration(handler, elapsed)
    assert(self.handlers[handler.name], 'non registered handler')

	-- h.on_event returned true, this means event was processed
	local time = self.handlers[handler.name].time_sum
	local n = self.handlers[handler.name].n

	self.handlers[handler.name].time_sum = time + elapsed
	self.handlers[handler.name].n = n + 1
end

---Report total quik queue length
---@param  current_que_length number quik que length
function FeedStats:report_quik_que_length(current_que_length)
	assert(current_que_length, "current_que_length nil")

	self.max_que_length = math.max(self.current_que_length, current_que_length)
	self.current_que_length = current_que_length
end

---Returns QuikLuaDataFeed stats
--
---@param as_json? boolean - return result as json string (default false)
---@return table | string
function FeedStats:get_stats(as_json)
	as_json = as_json or false

	local result = {}
	for k, v in pairs(self) do
		if k == "subscriptions" or k == 'handlers' then
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
		return cjson.encode(result)
	else
		return result
	end
end

return FeedStats
