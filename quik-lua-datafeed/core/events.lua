---@class Event
---@field eid EventID unique event id
---@field data table | nil arbitrary event data

---@enum EventID
local EventID = {
	ON_IDLE = "OnIdle",
	ON_QUOTE = "OnQuote",
	ON_PARAM = "OnParam"
}

return EventID
