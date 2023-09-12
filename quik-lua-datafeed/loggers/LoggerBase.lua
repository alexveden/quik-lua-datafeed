---@class LoggerBase
---@field name string simple logger name
LoggerBase = {
}
LoggerBase.__index = LoggerBase

---Creates new instance of LoggerBase class
---@param config table - configuration table
---@return LoggerBase
function LoggerBase.new(config)
	---@class LoggerBase
	assert(type(config) == "table", 'LoggerBase: config must be a table or empty table `{}`')
	local self = setmetatable({}, LoggerBase)
	self.name = 'LoggerBase'

	return self
end

function LoggerBase:init()
	error("You must implement init() function in custom logger class")
end

---@diagnostic disable-next-line
function LoggerBase:log(msg_templ, ...)
	error("You must implement log(msg_templ, ...) function in custom logger class")
end

function LoggerBase:stop()
	error("You must implement stop() function in custom logger class")
end

function LoggerBase.validate_custom_logger(custom_logger)
	assert(custom_logger, 'custom_logger is nil')
	assert(type(custom_logger) == "table", ": custom_logger expected to be a table")
	assert(custom_logger['name'], "custom logger must have a name")

	for _, m in pairs({ "init", "log", "stop" }) do
		assert(custom_logger[m], custom_logger['name'] .. ": custom_logger expected to have " .. m .. "()")
		assert(
			type(custom_logger[m]) == "function",
			custom_logger['name'] .. ": custom_logger expected to have " .. m .. "() as a function"
		)
	end
end

return LoggerBase
