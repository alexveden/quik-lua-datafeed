---@class Event
---@field eid EventID unique event id
---@field data table | nil arbitrary event data


---@enum EventID
return {
    ON_IDLE = 'I',
    ON_QUOTE = 'Q',
}
