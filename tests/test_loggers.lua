package.path = "../quik-lua-datafeed/?.lua;" .. package.path
-- Uses luaunit
-- requires `luarocks install luaunit`
--  https://github.com/bluebird75/luaunit
--
--  To LSP autocompletion make sure...
--  NeoVim: lua_ls (requires adding config.setting.Lua.workspace.library=<luarocks path>)
--
local lu = require("luaunit")
local Mock = require("Mock")
local LoggerBase = require("loggers.LoggerBase")
local LoggerPrintDbgStr = require("loggers.LoggerPrintDbgStr")
local LoggerSocket = require("loggers.LoggerSocket")

TestLoggerBase = {}
function TestLoggerBase:setUp() end

function TestLoggerBase:tearDown()
	Mock.release_all()
	lu.assertEquals(Mock.global_count(), 0)
	lu.assertEquals(Mock.objects_count(), 0)
end

function TestLoggerBase:test_logger_new()
	local l = LoggerBase.new({})
	lu.assertEquals(type(l), "table")
	lu.assertEquals(l.name, "LoggerBase")
end

function TestLoggerBase:test_logger_methods()
	local l = LoggerBase.new({})

	lu.assertErrorMsgContains("You must implement init() function in custom logger class", l.init)
	lu.assertErrorMsgContains("You must implement log(msg_templ, ...) function in custom logger class", l.log)
	lu.assertErrorMsgContains("You must implement stop() function in custom logger class", l.stop)
end

function TestLoggerBase:test_validate_custom_logger()
	local custom = {
		name = "custom",
		init = function() end,
		log = function() end,
		stop = function() end,
	}

	LoggerBase.validate_custom_logger(custom)

	lu.assertErrorMsgContains("custom_logger is nil", LoggerBase.validate_custom_logger, nil)
	lu.assertErrorMsgContains("custom_logger expected to be a table", LoggerBase.validate_custom_logger, "table?")
	lu.assertErrorMsgContains("custom logger must have a name", LoggerBase.validate_custom_logger, {})
	lu.assertErrorMsgContains(
		"custom_logger expected to have init()",
		LoggerBase.validate_custom_logger,
		{ name = "as" }
	)
	lu.assertErrorMsgContains(
		"custom_logger expected to have init() as a function",
		LoggerBase.validate_custom_logger,
		{ name = "as", init = "asda" }
	)
	lu.assertErrorMsgContains(
		"custom_logger expected to have log()",
		LoggerBase.validate_custom_logger,
		{ name = "as", init = custom.init }
	)
	lu.assertErrorMsgContains(
		"custom_logger expected to have log() as a function",
		LoggerBase.validate_custom_logger,
		{ name = "as", init = custom.init, log = "assdfs" }
	)
	lu.assertErrorMsgContains(
		"custom_logger expected to have stop()",
		LoggerBase.validate_custom_logger,
		{ name = "as", init = custom.init, log = custom.log }
	)
	lu.assertErrorMsgContains(
		"custom_logger expected to have stop() as a function",
		LoggerBase.validate_custom_logger,
		{ name = "as", init = custom.init, log = custom.log, stop = "ada" }
	)
end

function TestLoggerBase:test_logger_print_dbg_str()
	local l = LoggerPrintDbgStr.new({})
	LoggerBase.validate_custom_logger(l)

	lu.assertEquals(l.name, "LoggerPrintDbgStr")
	assert(l:init())
	assert(l:stop())

	local mock_pringdbgstr = Mock.global("PrintDbgStr", true)
	l:log("test %s", l.name)

	lu.assertEquals(mock_pringdbgstr.call_count, 1)
	lu.assertEquals(mock_pringdbgstr.call_args[1], { "test LoggerPrintDbgStr" })
end

function TestLoggerBase:test_logger_socket()
	local l = LoggerSocket.new({ host = "localhost", port = 17123 })
	LoggerBase.validate_custom_logger(l)

	lu.assertEquals(l.name, "LoggerSocket")
	assert(l:init())
	lu.assertEquals("127.0.0.1", l.socket:getpeername())

	assert(l:stop())

	local mock_socket_send = Mock.object(l.socket, 'send')
	l:log("test %s", l.name)

	lu.assertEquals(mock_socket_send.call_count, 1)
	lu.assertEquals(mock_socket_send.call_args[1], { "test LoggerPrintDbgStr" })
end

os.exit(lu.LuaUnit.run())
