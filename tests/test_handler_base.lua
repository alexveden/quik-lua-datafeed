package.path = "../quik-lua-datafeed/?.lua;../quik-lua-datafeed/lib/lua/?.lua;" .. package.path
-- Uses luaunit
-- requires `luarocks install luaunit`
--  https://github.com/bluebird75/luaunit
--
--  To LSP autocompletion make sure...
--  NeoVim: lua_ls (requires adding config.setting.Lua.workspace.library=<luarocks path>)
--
local ev = require("core.events")
local lu = require("luaunit")
local Mock = require("Mock")
local HandlerBase = require("handlers.HandlerBase")
local TransportBase = require("transports.TransportBase")

local function mock_transport()
	return {
		name = "custom",
		init = function() end,
		is_init = function() end,
		send = function() end,
		serialize_key = function(self, key) end,
		serialize_value = function() end,
		stop = function() end,
	}
end

TestHandlerBase = {}
function TestHandlerBase:setUp() end

function TestHandlerBase:tearDown()
	Mock.release_all()
	lu.assertEquals(Mock.global_count(), 0)
	lu.assertEquals(Mock.objects_count(), 0)
end

function TestHandlerBase:test_handler_new()
	local t = mock_transport()
	local l = Mock.func()
	local h = HandlerBase.new({ transport = t, log_func = l.__call })
	lu.assertEquals(type(h), "table")
	lu.assertEquals(h.name, "HandlerBase")
	lu.assertEquals(h.transport, t)

	lu.assertErrorMsgContains("You must implement init() function in custom handler class", h.init, h)
	lu.assertErrorMsgContains("You must implement stop() function in custom handler class", h.stop, h)
	lu.assertErrorMsgContains("You must implement on_event() function in custom handler class", h.on_event, h)
end

function TestHandlerBase:test_handler_log()
	local t = mock_transport()
	local l = Mock.func()
	local h = HandlerBase.new({
		transport = t,
	})
	h.log_func = function(level, msg_templ, ...)
		l(l, level, msg_templ, ...)
	end

	h:log(2, "Hello", 1)

	lu.assertEquals(l.call_count, 1)
	lu.assertEquals(l.call_args[1][1], l)
	lu.assertEquals(l.call_args[1][2], 2)
	lu.assertEquals(l.call_args[1][3], "Hello")
	lu.assertEquals(l.call_args[1][4], 1)
end

function TestHandlerBase:test_handler_validation()
	local t = mock_transport()
	local l = Mock.func()
	local h = {
		name = "CustomHandler",
		transport = t,
		log_func = l.__call,
		events = {
			[ev.ON_IDLE] = { last_idle_time = 0 },
			[ev.ON_QUOTE] = true,
		},
		init = function() end,
		stop = function() end,
		on_event = function() end,
	}
	lu.assertEquals(type(h), "table")
	lu.assertEquals(h.name, "CustomHandler")
	lu.assertEquals(h.transport, t)
	HandlerBase.validate_custom_handler(h)

	h.events = nil
	lu.assertErrorMsgContains("custom_handler.events is nil", HandlerBase.validate_custom_handler, h)
	h.events = {}
	lu.assertErrorMsgContains(
		"no events or custom_handler events must be a dictionary of ",
		HandlerBase.validate_custom_handler,
		h
	)
	h.events = { ["ZUNKNOWN"] = true }
	lu.assertErrorMsgContains("Event key ZUNKNOWN not found in core.events", HandlerBase.validate_custom_handler, h)
	h.events = { [ev.ON_IDLE] = false }
	lu.assertErrorMsgContains("Event value must pass `if event then`,", HandlerBase.validate_custom_handler, h)
	h.events = { ev.ON_IDLE }
	lu.assertErrorMsgContains(
		"Event key must be core.events[ON_] -> string, got 1 type: number",
		HandlerBase.validate_custom_handler,
		h
	)

	h.events = { [ev.ON_IDLE] = true }
	h.transport = nil
	lu.assertErrorMsgContains("custom_handler must have transport", HandlerBase.validate_custom_handler, h)

	h.transport = t
	h.name = nil
	lu.assertErrorMsgContains("custom_handler must have a name", HandlerBase.validate_custom_handler, h)
end

function TestHandlerBase:test_is_interval_allowed()
	local t = mock_transport()
	local l = Mock.func()
	local h = HandlerBase.new({
		transport = t,
	})
	h.log_func = function()	end

	lu.assertIsNil(h.event_intervals['myint'])
	lu.assertEquals(h:is_interval_allowed('myint', 1000), true)
	lu.assertNotIsNil(h.event_intervals['myint'])
	lu.assertEquals(h:is_interval_allowed('myint', 1000), false)
	lu.assertEquals(h:is_interval_allowed('myint', 1000), false)
	lu.assertEquals(h:is_interval_allowed('myint', 0), true)
end

os.exit(lu.LuaUnit.run())
