local HandlerBase = require("handlers.HandlerBase")
local ev = require("core.events")

---@class QuikStats: HandlerBase
local QuikStats = {}
QuikStats.__index = QuikStats

function QuikStats.new(config)
	local self = HandlerBase.new(config, QuikStats)

	-- setting derived values
	self.name = "QuikStats"
	self.events = {
		[ev.ON_IDLE] = true,
	}

	HandlerBase.validate_custom_handler(self)
	return self
end

function QuikStats:init()
	self:log(0, "QuikStats init")
	return true
end

function QuikStats:stop()
	self:log(0, "QuikStats stopped")
	return true
end

function QuikStats:my_method()
	return 100
end

---Main event processing
---@param event Event
function QuikStats:on_event(event)
	if self:is_interval_allowed('stats', 1000) then
		local resp = getSecurityInfo("SPBFUT", "RIU3")
		self.transport:send({ "quik", "stats", "RIU3" }, resp)
	end
end

return QuikStats
