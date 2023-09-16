local cjson = require("cjson")
cjson.encode_invalid_numbers(true) -- enable Nan serialization in JSON

---@class TransportBase
---@field name string simple transport name
TransportBase = {}
TransportBase.__index = TransportBase


---Creates new instance of TransportBase class
---@generic TransportChildMeta: TransportBase 
---@param config table - configuration table
---@param child_meta? TransportChildMeta child meta class
---@return TransportChildMeta
function TransportBase.new(config, child_meta)
	---@class TransportBase
	assert(type(config) == "table", "TransportBase: config must be a table or empty table `{}`")
	local self = setmetatable({}, TransportBase)


	-- child class method overriding
	child_meta = child_meta or {}
	assert(type(child_meta) == "table", "HandlerBase: child_meta must be a table or empty table `{}`")
	if child_meta.__index then
		assert(type(child_meta.__index) == 'table', 'child_meta.__index expected table')

		for field, func in pairs(child_meta.__index) do
			if field ~= 'new' and field ~= "__index" then
				self[field] = func
			end
		end
	end
	--- end child class method overriding

	self.name = "TransportBase"

	return self
end

function TransportBase:init()
	error("You must implement init() function in custom transport class")
end

---Sends key-value via transport route
---@param key string[] array of strings
---@param value {[string]: boolean | string | number | table | nil} table of data
---@diagnostic disable-next-line
function TransportBase:send(key, value)
	error("You must implement send(key, value) function in custom transport class")
end

---Serializes key in transport specific notation (i.e. removing special chars from path)
---@param key string[] array of strings, like {'a', 'b', 'c'}
---@return string # serialized key, like a#b#c
---@diagnostic disable-next-line
function TransportBase:serialize_key(key)
	-- This one is mandatory for every custom transport
	TransportBase.validate_key(key)
	return table.concat(key, "#")
end

---Serializes key in transport specific data (i.e. JSON)
---@param value {[string]: boolean | string | number | table | nil} table of data {a = 1, b = 'ok'}
---@return string # serialized value, like {"a": 1, "b": "ok"}
---@diagnostic disable-next-line
function TransportBase:serialize_value(value)
	return cjson.encode(value)
end

function TransportBase:stop()
	error("You must implement stop() function in custom transport class")
end

function TransportBase:is_init()
	error("You must implement is_init() function in custom transport class")
end

function TransportBase.validate_key(key)
	assert(key, "key is nil")
	assert(type(key) == "table", "key must be a table")
	local key_len = #key
	assert(key_len > 0, "key is zero length")
	assert(key_len <= 5, "key is too long")

	-- Weird way to handle nil in the middle of the key {'a', nil, 'b'} (fvck the lua!)
	for i = 1, 5, 1 do
		local v = key[i]
		if i > key_len then
			if v ~= nil then
				error("key array has nil in the middle")
			end
		else
			assert(type(v) == "string", "key i=" .. i .. " expected to be string, got " .. type(v))

			assert(not string.match(v, "[^%w_%-+]"), "key must be alphanumeric [A-Za-z0-9_-], got `" .. v .. "`")
		end
	end
end

function TransportBase.validate_custom_transport(custom_transport)
	assert(custom_transport, "custom_transport is nil")
	assert(type(custom_transport) == "table", ": custom_transport expected to be a table")
	assert(custom_transport["name"], "custom_transport must have a name")

	for _, m in pairs({ "init", "send", "stop", "is_init", "serialize_key", "serialize_value" }) do
		assert(custom_transport[m], custom_transport["name"] .. ": custom_transport expected to have " .. m .. "()")
		assert(
			type(custom_transport[m]) == "function" or custom_transport[m].__call or (custom_transport.__index and custom_transport.__index[m]),
			custom_transport["name"] .. ": custom_transport expected to have " .. m .. "() as a function"
		)
	end

	if custom_transport.name ~= "TransportBase" then
		local ser_key = custom_transport:serialize_key({ "A-Za-z0-9_", "--", "valid" })
		assert(type(ser_key) == "string", "serialized key expected a string, got " .. type(ser_key))
		assert(#ser_key > 0, "serialized key string is empty")

		-- Check bad keys and make sure transport also fails on them
		for _, s in pairs({ { "test", nil, "fail" }, { nil }, {}, { "nonalpha!"}, {'no', ' whitespaces'} }) do
			local isok, _ = pcall(custom_transport.serialize_key, custom_transport, s)
			if isok then
				error(
					"custom_transport.serialize_key() test failed passed one of the malformed keys, call TransportBase.validate_key() in custom_transport.serialize_key()"
				)
			end
		end

		local nan = 0 / 0
		local ser_value = custom_transport:serialize_value({
			["A-Za-z0-9_"] = "юникод?",
			["fo!@)(#*!@#)"] = true,
			another_key = { name = "Alex", skill = 45.12, profit = nan },
			bid = nan,
			allocation = -1,
		})
		assert(type(ser_value) == "string", "serialized value expected a string, got " .. type(ser_value))
		assert(#ser_value > 0, "serialized value string is empty")
	end
end

return TransportBase
