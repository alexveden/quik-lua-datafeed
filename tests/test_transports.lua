package.path = "../quik-lua-datafeed/?.lua;../quik-lua-datafeed/lib/lua/?.lua;" .. package.path
-- Uses luaunit
-- requires `luarocks install luaunit`
--  https://github.com/bluebird75/luaunit
--
--  To LSP autocompletion make sure...
--  NeoVim: lua_ls (requires adding config.setting.Lua.workspace.library=<luarocks path>)
--
local lu = require("luaunit")
local Mock = require("Mock")
local TransportBase = require("transports.TransportBase")
local TransportMemcached = require("transports.TransportMemcached")

TestTransportBase = {}
function TestTransportBase:setUp() end

function TestTransportBase:tearDown()
	Mock.release_all()
	lu.assertEquals(Mock.global_count(), 0)
	lu.assertEquals(Mock.objects_count(), 0)
end

function TestTransportBase:test_transport_new()
	local l = TransportBase.new({})
	lu.assertEquals(type(l), "table")
	lu.assertEquals(l.name, "TransportBase")
end

function TestTransportBase:test_transport_methods()
	local l = TransportBase.new({})

	lu.assertErrorMsgContains("You must implement init() function in custom transport class", l.init)
	lu.assertErrorMsgContains("You must implement stop() function in custom transport class", l.stop)
	lu.assertErrorMsgContains("You must implement send(key, value) function in custom transport class", l.send)
	lu.assertErrorMsgContains(
		"You must implement serialize_key(key) function in custom transport class",
		l.serialize_key
	)
	lu.assertErrorMsgContains(
		"You must implement serialize_value(value) function in custom transport class",
		l.serialize_value
	)
end

function TestTransportBase:test_validate_custom_transport()
	local custom = {
		name = "custom",
		init = function() end,
		send = function() end,
		serialize_key = function(_, key)
			TransportBase.validate_key(key)
			return "adsa"
		end,
		serialize_value = function()
			return "asdad"
		end,
		stop = function() end,
	}

	TransportBase.validate_custom_transport(custom)

	lu.assertErrorMsgContains("custom_transport is nil", TransportBase.validate_custom_transport, nil)
	lu.assertErrorMsgContains(
		"custom_transport expected to be a table",
		TransportBase.validate_custom_transport,
		"table?"
	)
	lu.assertErrorMsgContains("custom_transport must have a name", TransportBase.validate_custom_transport, {})
	lu.assertErrorMsgContains(
		"custom_transport expected to have init()",
		TransportBase.validate_custom_transport,
		{ name = "as" }
	)
	lu.assertErrorMsgContains(
		"custom_transport expected to have init() as a function",
		TransportBase.validate_custom_transport,
		{ name = "as", init = "asda" }
	)
	lu.assertErrorMsgContains(
		"custom_transport expected to have send()",
		TransportBase.validate_custom_transport,
		{ name = "as", init = custom.init }
	)
	lu.assertErrorMsgContains(
		"custom_transport expected to have stop()",
		TransportBase.validate_custom_transport,
		{ name = "as", init = custom.init, send = custom.send }
	)
	lu.assertErrorMsgContains(
		"custom_transport expected to have serialize_key()",
		TransportBase.validate_custom_transport,
		{ name = "as", init = custom.init, send = custom.send, stop = custom.stop }
	)
	lu.assertErrorMsgContains(
		"custom_transport expected to have serialize_value()",
		TransportBase.validate_custom_transport,
		{
			name = "as",
			init = custom.init,
			send = custom.send,
			stop = custom.stop,
			serialize_key = custom.serialize_key,
		}
	)
end

function TestTransportBase:test_key_validation()
	local l = TransportBase.new({})

	lu.assertEquals(type(l), "table")
	lu.assertEquals(l.name, "TransportBase")
	lu.assertErrorMsgContains("key is nil", l.validate_key, nil)
	lu.assertErrorMsgContains("key is zero length", l.validate_key, {})
	lu.assertErrorMsgContains("key must be a table", l.validate_key, "asda")
	lu.assertErrorMsgContains("key is too long", l.validate_key, { "1", "2", "3", "4", "5", "6" })
	lu.assertErrorMsgContains("key i=2 expected to be string, got nil", l.validate_key, { "key", nil, "val" })
	lu.assertErrorMsgContains("key i=1 expected to be string, got nil", l.validate_key, { nil, "val" })

	-- No way to check last nil :( Because every missing index is nil
	-- lu.assertErrorMsgContains('key i=2 expected to be string, got nil', l.validate_key, {'key', nil})
	-- lu.assertErrorMsgContains('key i=5 expected to be string, got nil', l.validate_key, {'1', '2', '3', '4', nil})
	lu.assertErrorMsgContains("key is zero length", l.validate_key, { nil })
	lu.assertErrorMsgContains("key must be alphanumeric", l.validate_key, { "val_#" })
	lu.assertErrorMsgContains("key must be alphanumeric", l.validate_key, { "AZaz09_", "val_луа" })

	-- Valid key
	l.validate_key({ "AZa-z09_", "something", "else", "9991AllGood" })
end

function TestTransportBase:test_validate_custom_transport_serialization_validation_key()
    ---@diagnostic disable
	local custom = {
		name = "custom",
		init = function() end,
		send = function() end,
		serialize_key = function()
			return "adsa"
		end,
		serialize_value = function()
			return "asdad"
		end,
		stop = function() end,
	}

	custom.serialize_key = function() end
	lu.assertErrorMsgContains(
		"serialized key expected a string, got nil",
		TransportBase.validate_custom_transport,
		custom
	)

	custom.serialize_key = function()
		return ""
	end
	lu.assertErrorMsgContains("serialized key string is empty", TransportBase.validate_custom_transport, custom)
	---@diagnostic enable
end

function TestTransportBase:test_validate_custom_transport_serialization_validation_value()
    ---@diagnostic disable
	local custom = {
		name = "custom",
		init = function() end,
		send = function() end,
		serialize_key = function(self, key)
			TransportBase.validate_key(key)
			return "adsa"
		end,
		serialize_value = function()
			return "asdad"
		end,
		stop = function() end,
	}
	custom.serialize_value = function() end
	lu.assertErrorMsgContains(
		"serialized value expected a string, got nil",
		TransportBase.validate_custom_transport,
		custom
	)

	custom.serialize_value = function()
		return ""
	end
	lu.assertErrorMsgContains("serialized value string is empty", TransportBase.validate_custom_transport, custom)

	custom.serialize_value = function()
		return { a = 1 }
	end
	lu.assertErrorMsgContains(
		"serialized value expected a string, got table",
		TransportBase.validate_custom_transport,
		custom
	)
    ---@diagnostic enable
end

function TestTransportBase:test_memcached_new()
	local l = TransportMemcached.new({})
	lu.assertEquals(type(l), "table")
	lu.assertEquals(l.name, "TransportMemcached")
	lu.assertEquals(l.host, "localhost")
	lu.assertEquals(l.port, 11211)
	lu.assertEquals(l.exptime_sec, 3600)
	lu.assertEquals(l.memcached, nil)
	lu.assertEquals(l.serialize_key, TransportMemcached.serialize_key)
	lu.assertEquals(l.serialize_value, TransportMemcached.serialize_value)
end

function TestTransportBase:test_memcached_new_config()
	local function fkey(_, key)
		TransportBase.validate_key(key)
		return "abvsa"
	end
	local function fvalue()
		return "bbbbsds"
	end
	local config =
		{ host = "192.168.11.1", port = 777, exptime_sec = 1, serialize_key = fkey, serialize_value = fvalue }
	local l = TransportMemcached.new(config)
	lu.assertEquals(type(l), "table")
	lu.assertEquals(l.name, "TransportMemcached")
	lu.assertEquals(l.host, "192.168.11.1")
	lu.assertEquals(l.port, 777)
	lu.assertEquals(l.exptime_sec, 1)
	lu.assertEquals(l.memcached, nil)
	lu.assertEquals(l.serialize_key, fkey)
	lu.assertEquals(l.serialize_value, fvalue)
end

function TestTransportBase:test_memcached_serialize()
	local t = TransportMemcached.new({})

	lu.assertEquals('my#key#test', t:serialize_key({'my', 'key', 'test'}))
	local nan = 0/0
    local data = {
			    ["A-Za-z0-9_"] = "юникод?",
			    ["fo!@)(#*!@#)"] = true,
			    another_key = {name = "Alex", skill = 45.12, profit = false},
			    bid = nan,
			    allocation = -1
		    }
    local ser_data = t:serialize_value(data)
    lu.assertEquals(type(ser_data), 'string')
    for k, v in pairs(data) do
        if type(v) == "table" then
            for k1, v1 in pairs(v) do
                lu.assertNotIsNil(string.find(ser_data, tostring(k1), 1, true), 'key: '..tostring(k1))
                lu.assertNotIsNil(string.find(ser_data, tostring(v1), 1, true), 'value: '..tostring(v1))
            end
        else
            lu.assertNotIsNil(string.find(ser_data, tostring(k), 1, true), 'key: '..tostring(k))
            if v ~= v then
                v = 'NaN'
            end
            lu.assertNotIsNil(string.find(ser_data, tostring(v), 1, true), 'value: '..tostring(v))
        end
    end

    -- Not order by keys is changing every call, weird, fvk the lua!
	-- lu.assertEquals('{"A-Za-z0-9_":"юникод?","bid":NaN,"fo!@)(#*!@#)":true,"another_key":{"profit":NaN,"skill":45.12,"name":"Alex"},"allocation":-1}', t:serialize_value(data))

end

function TestTransportBase:test_memcached_connect_set_get()
	local t = TransportMemcached.new({})
	lu.assertIsNil(t.memcached)

	t:init()
	lu.assertNotIsNil(t.memcached)
	t:send({'test', 'my', 'key'}, {test = 'data'})

	local memcached_data = t.memcached:get('test#my#key')
	lu.assertEquals('{"test":"data"}', memcached_data)

	t:stop()
	lu.assertIsNil(t.memcached)
end

os.exit(lu.LuaUnit.run())
