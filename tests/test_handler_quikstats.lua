
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
local QuikStats = require("handlers.QuikStats")

local function mock_transport()
	return {
		name = "custom",
		init = function() end,
		is_init = function() end,
		send = Mock.func(),
		serialize_key = function(self, key) end,
		serialize_value = function() end,
		stop = function() end,
	}
end

TestHandlerQuikStats = {}
function TestHandlerQuikStats:setUp() end

function TestHandlerQuikStats:tearDown()
	Mock.release_all()
	lu.assertEquals(Mock.global_count(), 0)
	lu.assertEquals(Mock.objects_count(), 0)
end

function TestHandlerQuikStats:test_handler_new()
	local t = mock_transport()
	local l = Mock.func()
	local h = QuikStats.new({ transport = t})
	h.log_func = l.__call

	lu.assertEquals(type(h), "table")
	lu.assertEquals(h.name, "QuikStats")

	for _,e in pairs({ev.ON_IDLE}) do
	   lu.assertEquals(h.events[e], true)
	end

end

function TestHandlerQuikStats:test_init_stop()
	local t = mock_transport()
	local l = Mock.func()
	local h = QuikStats.new({
		transport = t,
	})
	---@diagnostic disable-next-line
	h.log_func = l

	lu.assertEquals(h:init(), true)
	lu.assertEquals(h:stop(), true)

	lu.assertEquals(l.call_count, 2)
	lu.assertEquals(l.call_args[1][1], 0)
	lu.assertEquals(l.call_args[1][2], "QuikStats init")

	lu.assertEquals(l.call_args[2][1], 0)
	lu.assertEquals(l.call_args[2][2], "QuikStats stopped")

end

function TestHandlerQuikStats:test_on_event()
	local t = mock_transport()
	local l = Mock.func()
	local h = QuikStats.new({
		transport = t,
	})
	---@diagnostic disable
	h.log_func = l
	h:init()

	local mock_getinfoparam = Mock.global('getInfoParam', true)
	mock_getinfoparam.side_effect = function (param) return param end

	local res = h:on_event(nil) -- event doesn't matter
	lu.assertEquals(res, true)
	
	-- next event is too fast skipped
	res = h:on_event(nil) -- event doesn't matter
	lu.assertEquals(res, false)

    lu.assertEquals(h.transport.send.call_count, 1)
    lu.assertEquals(h.transport.send.call_args[1][2], {'quik', 'status'})

    call_status = h.transport.send.call_args[1][3]
    lu.assertNotIsNil(call_status['VERSION'])
    lu.assertNotIsNil(call_status['MAXPINGDURATION'])
	---@diagnostic enable
end
os.exit(lu.LuaUnit.run())
