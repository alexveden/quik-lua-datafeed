-- Uses luaunit
-- requires `luarocks install luaunit`
--  https://github.com/bluebird75/luaunit
--
--  To LSP autocompletion make sure...
--  NeoVim: lua_ls (requires adding config.setting.Lua.workspace.library=<luarocks path>)
--
local lu = require("luaunit")
local mock_test_module = require("mock_test_module")
local Mock = require("Mock")

--[[
--
-- OOP style with setup and tearDown
--
--]]
--
TestQuikMock = {}
function TestQuikMock:setUp() end

function TestQuikMock:test_mock_global__init()
	local m = Mock.g("getInfoParam")
	lu.assertEquals(m.return_value, nil)
	lu.assertEquals(m.call_count, 0)
	lu.assertEquals(m.name, "getInfoParam")

	lu.assertErrorMsgContains("Global object is not found", Mock.g, "some-not_existing_global_func")
	lu.assertErrorMsgContains("Global object was already mocked:", Mock.g, "getInfoParam")
	lu.assertEquals(Mock.global_count(), 1)
end

function TestQuikMock:test_mock_global__forbidden()
	lu.assertErrorMsgContains("Forbidden mocking for global ", Mock.g, "error")
	lu.assertErrorMsgContains("Forbidden mocking for global ", Mock.g, "setmetatable")
	lu.assertErrorMsgContains("Forbidden mocking for global ", Mock.g, "type")
	lu.assertErrorMsgContains("Forbidden mocking for global ", Mock.g, "pairs")
	lu.assertErrorMsgContains("Forbidden mocking for global ", Mock.g, "assert")
end
function TestQuikMock:test_mock_global__init_create_non_existing()
	local m = Mock.g("getInfoParamNoExists", true)
	lu.assertEquals(m.return_value, nil)
	lu.assertEquals(m.call_count, 0)
	lu.assertEquals(m.name, "getInfoParamNoExists")

	--- This one now created by Mock!
	---@diagnostic disable-next-line
	getInfoParamNoExists()
	lu.assertEquals(m.call_count, 1)
end

function TestQuikMock:test_mock_call_from_another_module()
	local m = Mock.g("getInfoParam", true)
	m.return_value = 124
	local module_param = mock_test_module.param("mock test module")
	lu.assertEquals(module_param, 124)
	lu.assertEquals(m.call_count, 1)
end

function TestQuikMock:test_mock_side_effect_function()
	local m = Mock.g("getInfoParam", true)

	-- IMPORTANT: return_value overriden by side_effect
	m.return_value = 124
	m.side_effect = function(s)
		return "side_effect with s: " .. s
	end

	local module_param = mock_test_module.param("mock test module")
	lu.assertEquals(module_param, "side_effect with s: mock test module")
	lu.assertEquals(m.call_count, 1)
end

function TestQuikMock:test_mock_global_with_dots()
	-- WARNING: setting internal functions is possible but may lead to weird side effects!
	local m = Mock.g("os.clock")
	m.return_value = 77.01
	lu.assertEquals(m.return_value, 77.01)
	lu.assertEquals(m.call_count, 0)
	lu.assertEquals(m.name, 'os.clock')

	lu.assertEquals(os.clock(), 77.01)
	lu.assertEquals(m.call_count, 1)

	Mock.finalize()
	lu.assertNotEquals(os.clock(), 77.01)

end

function TestQuikMock:tearDown()
	Mock.finalize()
	lu.assertEquals(Mock.global_count(), 0)
end

-- end of table TestLogger

os.exit(lu.LuaUnit.run())
