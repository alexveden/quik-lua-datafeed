local HandlerBase = require("handlers.HandlerBase")
local ev = require("core.events")
local cjson = require("cjson")

---@class QuikStats: HandlerBase
local QuikStats = {}
QuikStats.__index = QuikStats

function QuikStats.new(config)
	local super = HandlerBase.new(config)
	local self = setmetatable(super, QuikStats)

	-- setting derived values
	self.name = "QuikStats"
	self.events = {
		[ev.ON_IDLE] = { last_idle_event = 0 },
	}

	HandlerBase.validate_custom_handler(self)
	return self
end

function QuikStats:init()
	self:log(0, "QuikStats init")
	return true
end

function QuikStats:stop()
	return true
end

---Main event processing
---@param event Event
function QuikStats:on_event(event)
	local resp = getSecurityInfo("SPBFUT", "RIU3")
	self.transport:send({ "quik", "stats", "RIU3" }, resp)
end

return QuikStats
