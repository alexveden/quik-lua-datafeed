---@class Event
---@field eid EventID unique event id
---@field data table | nil arbitrary event data

---@enum EventID
local EVENTS = {
	ON_IDLE = "OnIdle",
	ON_QUOTE = "OnQuote",
}

return EVENTS
