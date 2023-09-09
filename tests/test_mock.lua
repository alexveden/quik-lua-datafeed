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
TestMock = {}
function TestMock:setUp() end

function TestMock:tearDown()
	Mock.global_finalize()
	lu.assertEquals(Mock.global_count(), 0)
end

function TestMock:test_mock_global__init()
	local m = Mock.g("getInfoParam")
	lu.assertEquals(m.return_value, nil)
	lu.assertEquals(m.call_count, 0)
	lu.assertEquals(m.name, "getInfoParam")

	lu.assertErrorMsgContains("function is not found (or try with create_missing=true).", Mock.g, "some-not_existing_global_func")
	lu.assertErrorMsgContains("Global object was already mocked:", Mock.g, "getInfoParam")
	lu.assertErrorMsgContains("Empty global_name", Mock.g, "")
	lu.assertErrorMsgContains("Empty global_name", Mock.g, nil)
	lu.assertEquals(Mock.global_count(), 1)
end

function TestMock:test_mock_global_with_dots()
	-- WARNING: setting internal functions is possible but may lead to weird side effects!
	local m = Mock.g("os.clock")
	m.return_value = 77.01
	lu.assertEquals(m.return_value, 77.01)
	lu.assertEquals(m.call_count, 0)
	lu.assertEquals(m.name, "os.clock")

	lu.assertEquals(os.clock(), 77.01)
	lu.assertEquals(m.call_count, 1)

	Mock.global_finalize()
	lu.assertNotEquals(os.clock(), 77.01)
end

function TestMock:test_mock_global__forbidden()
	lu.assertErrorMsgContains("Forbidden mocking for global ", Mock.g, "error")
	lu.assertErrorMsgContains("Forbidden mocking for global ", Mock.g, "setmetatable")
	lu.assertErrorMsgContains("Forbidden mocking for global ", Mock.g, "type")
	lu.assertErrorMsgContains("Forbidden mocking for global ", Mock.g, "pairs")
	lu.assertErrorMsgContains("Forbidden mocking for global ", Mock.g, "assert")
end

function TestMock:test_mock_global__init_create_non_existing()
	local m = Mock.g("getInfoParamNoExists", true)
	lu.assertEquals(m.return_value, nil)
	lu.assertEquals(m.call_count, 0)
	lu.assertEquals(m.name, "getInfoParamNoExists")

	--- This one now created by Mock!
	---@diagnostic disable-next-line
	getInfoParamNoExists()
	lu.assertEquals(m.call_count, 1)
end

function TestMock:test_mock_global__reset_mock()
	local m = Mock.g("getInfoParamNoExists", true)
	lu.assertEquals(m.return_value, nil)
	lu.assertEquals(m.call_count, 0)
	lu.assertEquals(m.name, "getInfoParamNoExists")

	--- This one now created by Mock!
	---@diagnostic disable-next-line
	getInfoParamNoExists()
	lu.assertEquals(m.call_count, 1)
	m:reset_mock()

	lu.assertEquals(m.call_count, 0)
end

function TestMock:test_mock_call_from_another_module()
	local m = Mock.g("getInfoParam", true)
	m.return_value = 124
	local module_param = mock_test_module.param("mock test module")
	lu.assertEquals(module_param, 124)
	lu.assertEquals(m.call_count, 1)
end

function TestMock:test_mock_side_effect_function()
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

function TestMock:test_mock_call_args()
	local m = Mock.g("getInfoParam", true)
	m.return_value = 124
	mock_test_module.param("param1")
	mock_test_module.param("param2")

	lu.assertEquals(m.call_count, 2)
	lu.assertEquals(#m.call_args, 2)
	lu.assertEquals(m.call_args[1], { "param1" })
	lu.assertEquals(m.call_args[2], { "param2" })
	lu.assertEquals(m.call_args[1][1], "param1")

	m:reset_mock()
	lu.assertEquals(#m.call_args, 0)
	lu.assertEquals(m.call_args, {})
end

os.exit(lu.LuaUnit.run())
