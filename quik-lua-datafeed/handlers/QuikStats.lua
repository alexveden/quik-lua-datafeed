local HandlerBase = require("handlers.HandlerBase")
local ev = require("core.events")

---@class QuikStats: HandlerBase
local QuikStats = {}
QuikStats.__index = QuikStats

local params_status_list = {
	"VERSION",
	"TRADEDATE",
	"SERVERTIME",
	"LASTRECORDTIME",
	"NUMRECORDS",
	"LASTRECORD",
	"LATERECORD",
	"CONNECTION",
	"IPADDRESS",
	"IPPORT",
	"IPCOMMENT",
	"SERVER",
	"SESSIONID",
	"USER",
	"USERID",
	"ORG",
	"MEMORY",
	"LOCALTIME",
	"CONNECTIONTIME",
	"MESSAGESSENT",
	"ALLSENT",
	"BYTESSENT",
	"BYTESPERSECSENT",
	"MESSAGESRECV",
	"BYTESRECV",
	"ALLRECV",
	"BYTESPERSECRECV",
	"AVGSENT",
	"AVGRECV",
	"LASTPINGTIME",
	"LASTPINGDURATION",
	"AVGPINGDURATION",
	"MAXPINGTIME",
	"MAXPINGDURATION",
}


function QuikStats.new(config)
	local self = HandlerBase.new(config, QuikStats)

	-- setting derived values
	self.name = "QuikStats"
	self.events = {
		[ev.ON_IDLE] = true,
	}

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

---Main event processing
---@param event Event
function QuikStats:on_event(event)
	assert(self, 'self is nil, calling obj.method instead of obj:method?')

	if self:is_interval_allowed("stats", 5000) then
		local status = {}
		for _, p in pairs(params_status_list) do
			status[p] = getInfoParam(p)
		end
		self.transport:send({ "quik", "status" }, status)
		return true
	end

	return false
end

return QuikStats
