
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
local TransportBase = require("transports.TransportBase")

local function mock_transport()
	return {
		name = "custom",
		init = function() end,
		is_init = function() end,
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

function TestHandlerQuikStats:test_is_interval_allowed()
	local t = mock_transport()
	local l = Mock.func()
	local h = QuikStats.new({
		transport = t,
	})
	h.log_func = function(level, msg_templ, ...)
		l(l, level, msg_templ, ...)
	end

	-- lu.assertEquals(nil, h)
	lu.assertEquals(100, h:my_method())
	lu.assertNotEquals(nil, h.is_interval_allowed)

	lu.assertEquals(h:is_interval_allowed('myint', 1000), true)
	lu.assertEquals(h:is_interval_allowed('myint', 1000), false)
end

os.exit(lu.LuaUnit.run())
