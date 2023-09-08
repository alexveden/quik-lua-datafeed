local json = require("core.json")

QuikLuaDataFeed = {
	config = {},
	valid = false,
	stats = {
		n_events = 0,
		max_que_length = 0,
		current_que_length = 0,
		subscriptions = {},
	},
}
QuikLuaDataFeed.__index = QuikLuaDataFeed

function QuikLuaDataFeed.new(config)
	assert(config, "no config")

	local self = setmetatable({}, QuikLuaDataFeed)
	-- self.config = config
	self:initialize()
	return self
	-- return setmetatable(self, QuikLuaDataFeed)
end

function QuikLuaDataFeed:log(msg_templ, ...)
	PrintDbgStr(string.format(msg_templ, ...))
end

function QuikLuaDataFeed:initialize()
	self:log("QuikLuaDataFeed: Initialized log")
	-- Read config
	-- Validate config
	-- Setup handlers
	-- Setup loggers
	-- Setup serializers
end

function QuikLuaDataFeed:stats_que_length(current_que_length)
	assert(current_que_length, "current_que_length nil")
	self.stats.current_que_length = current_que_length
	self.stats.max_que_length = math.max(self.stats.current_que_length, current_que_length)
end

-- Returns a table of all Quik Data events handlers
--  keys: the same as Quik event functions i.e. `AllQuote = true`
--  values: simple true
function QuikLuaDataFeed:subscribed_events()
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

function QuikLuaDataFeed:get_stats(as_json)
	as_json = as_json or false

	local result = {}
	for k, v in pairs(self.stats) do
		if k == "subscriptions" then
		    assert(type(v) == 'table')

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

function QuikLuaDataFeed:on_event(event)
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

return QuikLuaDataFeed
