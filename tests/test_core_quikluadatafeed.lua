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
local QuikLuaDatafeed = require("core.QuikLuaDatafeed")
local TransportLog = require("transports.TransportLog")

TestQuikLuaDatafeed = {}
function TestQuikLuaDatafeed:setUp() end

function TestQuikLuaDatafeed:tearDown()
	Mock.release_all()
	lu.assertEquals(Mock.global_count(), 0)
	lu.assertEquals(Mock.objects_count(), 0)
end

local function mock_logger(is_invalid)
	is_invalid = is_invalid or false
	local stop = nil

	if not is_invalid then
		stop = Mock.func()
	end

	local custom = {
		name = "custom",
		init = Mock.func(),
		log = Mock.func(),
		stop = stop,
	}
	return custom
end

local function mock_transport(is_invalid)
	is_invalid = is_invalid or false
	local stop = nil

	if not is_invalid then
		stop = Mock.func()
	end
	return {
		name = "custom",
		init = Mock.func(),
		send = Mock.func(),
		is_init = Mock.func(),
		serialize_key = TransportLog.serialize_key,
		serialize_value = TransportLog.serialize_value,
		stop = stop
	}

end

local function mock_handler(transport, is_invalid)
	is_invalid = is_invalid or false
	local events = {}
	if not is_invalid then
		events = {[ev.ON_QUOTE]=true, [ev.ON_IDLE]=true}
	end

	local h = {
		name = "CustomHandler",
		transport = transport,
		events = events,
		init = Mock.func(),
		stop = Mock.func(),
		on_event = Mock.func(),
	}
	return h
end

function TestQuikLuaDatafeed:test_feed_new_config_basic_logger_validation()

    local config = {}
    lu.assertErrorMsgContains('logger is not set in config.logger', QuikLuaDatafeed.new, config)
    config.logger = mock_logger(true)

    lu.assertErrorMsgContains('Logger validation error:', QuikLuaDatafeed.new, config)
    lu.assertErrorMsgContains('custom: custom_logger expected to have stop', QuikLuaDatafeed.new, config)
    lu.assertErrorMsgContains('stack traceback:', QuikLuaDatafeed.new, config)

    config.logger = mock_logger()
    config.logger.init.side_effect = function ()
    	error('side_effect init')
    end
    lu.assertErrorMsgContains('Logger initialization error:', QuikLuaDatafeed.new, config)
    lu.assertErrorMsgContains('side_effect init', QuikLuaDatafeed.new, config)
    lu.assertErrorMsgContains('stack traceback:', QuikLuaDatafeed.new, config)

    config.logger = mock_logger()
end

function TestQuikLuaDatafeed:test_feed_new_config_handlers()
    local config = {
    	logger = mock_logger(),
	}
    lu.assertErrorMsgContains('No config.handlers given', QuikLuaDatafeed.new, config)

    local transport = mock_transport()
    local h = mock_handler(transport, true)
    config = {
    	logger = mock_logger(),
    	handlers = {h},
    }
    lu.assertErrorMsgContains('Handler validation failed:', QuikLuaDatafeed.new, config)
    lu.assertErrorMsgContains('no events or custom_handler events must be a dictionary', QuikLuaDatafeed.new, config)
    lu.assertErrorMsgContains('stack traceback:', QuikLuaDatafeed.new, config)

    transport = mock_transport(true)
    h = mock_handler(transport)
    config = {
    	logger = mock_logger(),
    	handlers = {h},
    }
    lu.assertErrorMsgContains('Transport validation failed:', QuikLuaDatafeed.new, config)
    lu.assertErrorMsgContains('custom_transport expected to have stop', QuikLuaDatafeed.new, config)
    lu.assertErrorMsgContains('stack traceback:', QuikLuaDatafeed.new, config)

    transport = mock_transport()
    transport.init.side_effect = function ()
    	error('side_effect transport init')
    end
    h = mock_handler(transport)
    config = {
    	logger = mock_logger(),
    	handlers = {h},
    }
    lu.assertErrorMsgContains('Transport initialization failed:', QuikLuaDatafeed.new, config)
    lu.assertErrorMsgContains('side_effect transport init', QuikLuaDatafeed.new, config)
    lu.assertErrorMsgContains('stack traceback:', QuikLuaDatafeed.new, config)

    transport = mock_transport()
    h = mock_handler(transport)
    h.init.side_effect = function ()
    	error('side_effect handler init')
    end
    config = {
    	logger = mock_logger(),
    	handlers = {h},
    }
    lu.assertErrorMsgContains('Handler initialization failed:', QuikLuaDatafeed.new, config)
    lu.assertErrorMsgContains('side_effect handler init', QuikLuaDatafeed.new, config)
    lu.assertErrorMsgContains('stack traceback:', QuikLuaDatafeed.new, config)
end

function TestQuikLuaDatafeed:test_feed_new_config_defaults()
    local transport = mock_transport()
    local h = mock_handler(transport)
    local config = {
    	logger = mock_logger(),
    	handlers = {h},
    }

    lu.assertIsNil(h.log_func)
    local df = QuikLuaDatafeed.new(config)

    lu.assertNotIsNil(h.log_func)

    lu.assertEquals(df.verbosity_level, 1)
    lu.assertEquals(df.raise_event_errors, false)
    lu.assertEquals(df.logger, config.logger)
    lu.assertEquals(df.handlers, config.handlers)
    lu.assertNotIsNil(df.stats.handlers[h.name])
end

function TestQuikLuaDatafeed:test_feed_new_config_params()
    local transport = mock_transport()
    local h = mock_handler(transport)
    local config = {
    	logger = mock_logger(),
    	handlers = {h},
    	verbosity_level = 2,
    	raise_event_errors = true,
    }

    lu.assertIsNil(h.log_func)
    local df = QuikLuaDatafeed.new(config)

    lu.assertEquals(df.verbosity_level, 2)
    lu.assertEquals(df.raise_event_errors, true)
end

function TestQuikLuaDatafeed:test_log_level()
    local transport = mock_transport()
    local h = mock_handler(transport)
	local l = mock_logger()
    local config = {
    	logger = l,
    	handlers = {h},
    	verbosity_level = 2,
    }

    lu.assertIsNil(h.log_func)
    local df = QuikLuaDatafeed.new(config)
    l.log:reset_mock()
	lu.assertEquals(l.log.call_count, 0)

	df:log(0, "Hi", 0)
	df:log(1, "Hi", 1)
	df:log(2, "Hi", 2)
	df:log(3, "Hi", 3)

	lu.assertEquals(l.log.call_count, 3)
	lu.assertEquals(l.log.call_args[1][2], "Hi")
	lu.assertEquals(l.log.call_args[1][3], 0)
	lu.assertEquals(l.log.call_args[2][3], 1)
	lu.assertEquals(l.log.call_args[3][3], 2)

	h.log_func(-1, 'logfunc') -- called without self!
	lu.assertEquals(l.log.call_args[4][2], 'logfunc')

end

function TestQuikLuaDatafeed:test_quik_notify_que_length()
    local transport = mock_transport()
    local h = mock_handler(transport)
	local l = mock_logger()
    local config = {
    	logger = l,
    	handlers = {h},
    	verbosity_level = 2,
    }

    lu.assertIsNil(h.log_func)
    local df = QuikLuaDatafeed.new(config)
    df:quik_notify_que_length(5)
    df:quik_notify_que_length(2)

    lu.assertEquals(df.stats.max_que_length, 5)
    lu.assertEquals(df.stats.current_que_length, 2)
end


function TestQuikLuaDatafeed:test_quik_get_subscribed_events()
    local transport = mock_transport()
    local h = mock_handler(transport)
    local h2 = mock_handler(transport)
    h.events = {[ev.ON_PARAM] = true}
    h2.events = {[ev.ON_QUOTE] = true}
	local l = mock_logger()
    local config = {
    	logger = l,
    	handlers = {h, h2},
    	verbosity_level = 2,
    }

    lu.assertIsNil(h.log_func)
    local df = QuikLuaDatafeed.new(config)

    local events = df:quik_subscribe_events()

    lu.assertEquals(events, {[ev.ON_PARAM] = true, [ev.ON_QUOTE] = true})

    lu.assertNotIsNil(df.stats.subscriptions[ev.ON_QUOTE])
    lu.assertNotIsNil(df.stats.subscriptions[ev.ON_PARAM])
end

function TestQuikLuaDatafeed:test_quik_on_event()
    local transport = mock_transport()
    local h = mock_handler(transport)
    h.events = {[ev.ON_PARAM] = true}
    h.on_event.return_value = true

	local l = mock_logger()
    local config = {
    	logger = l,
    	handlers = {h},
    	verbosity_level = 2,
    }

    local df = QuikLuaDatafeed.new(config)

    local events = df:quik_subscribe_events()
    lu.assertEquals(events, {[ev.ON_PARAM] = true})
    lu.assertEquals(df:quik_on_event({eid = ev.ON_QUOTE}), false)
    lu.assertEquals(df:quik_on_event({eid = ev.ON_IDLE}), false)
    lu.assertEquals(df.stats.handlers[h.name].n, 0)
    lu.assertEquals(df.stats.subscriptions[ev.ON_PARAM].n, 0)

	-- Event was processed, stats were reported
    lu.assertEquals(df:quik_on_event({eid = ev.ON_PARAM}), true)
    lu.assertEquals(df.stats.handlers[h.name].n, 1)
    lu.assertEquals(df.stats.subscriptions[ev.ON_PARAM].n, 1)
end

function TestQuikLuaDatafeed:test_quik_on_event_errors()
    local transport = mock_transport()
    local h = mock_handler(transport)
    h.events = {[ev.ON_PARAM] = true}

	local l = mock_logger()
    local config = {
    	logger = l,
    	handlers = {h},
    	verbosity_level = 2,
    	raise_event_errors = true,
    }

    local df = QuikLuaDatafeed.new(config)

    df:quik_subscribe_events()

	-- Event was processed, stats were reported
	h.on_event.side_effect = function ()
		error('on_event side_effect')
	end
    lu.assertErrorMsgContains("Handler[CustomHandler] on_event error:", df.quik_on_event, df, {eid = ev.ON_PARAM})
    lu.assertErrorMsgContains("on_event side_effect", df.quik_on_event, df, {eid = ev.ON_PARAM})
    lu.assertErrorMsgContains("stack traceback", df.quik_on_event, df, {eid = ev.ON_PARAM})


	df.raise_event_errors = false
	l.log:reset_mock()
    lu.assertEquals(df:quik_on_event({eid = ev.ON_PARAM}), false)
	lu.assertEquals(l.log.call_count, 1)
	lu.assertStrContains(l.log.call_args[1][2], "Handler[%s] on_event error:")
	lu.assertStrContains(l.log.call_args[1][3], h.name)
	lu.assertStrContains(l.log.call_args[1][4], "on_event side_effect")
	lu.assertStrContains(l.log.call_args[1][4], "stack traceback")

end

function TestQuikLuaDatafeed:test_stop()
    local transport = mock_transport()

    local h = mock_handler(transport)
    local h2 = mock_handler(transport)
    h.events = {[ev.ON_PARAM] = true}
    h2.events = {[ev.ON_QUOTE] = true}
	local l = mock_logger()
    local config = {
    	logger = l,
    	handlers = {h, h2},
    	verbosity_level = 2,
    }

    local df = QuikLuaDatafeed.new(config)
    transport.is_init.side_effect = {true, false}
    transport.is_init:reset_mock()
    df:stop()

    lu.assertEquals(transport.is_init.call_count, 2)
    lu.assertEquals(transport.stop.call_count, 1)
    lu.assertEquals(h.stop.call_count, 1)
    lu.assertEquals(h2.stop.call_count, 1)
    lu.assertEquals(l.stop.call_count, 1)

end

os.exit(lu.LuaUnit.run())
