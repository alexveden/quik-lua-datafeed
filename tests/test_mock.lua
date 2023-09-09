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
	Mock.release_all()
	lu.assertEquals(Mock.global_count(), 0)
	lu.assertEquals(Mock.objects_count(), 0)
end

function TestMock:test_mock_global__init()
	local m = Mock.global("getInfoParam")
	lu.assertEquals(m.return_value, nil)
	lu.assertEquals(m.call_count, 0)
	lu.assertEquals(m.func_path, "getInfoParam")

	lu.assertErrorMsgContains(
		"function is not found (or try with create_missing=true).",
		Mock.global,
		"some-not_existing_global_func"
	)
	lu.assertErrorMsgContains("Global object was already mocked:", Mock.global, "getInfoParam")
	lu.assertErrorMsgContains("Empty func path ``, in table _G", Mock.global, "")
	lu.assertErrorMsgContains("Empty func path ``, in table _G", Mock.global, nil)
	lu.assertEquals(Mock.global_count(), 1)
end

function TestMock:test_mock_object__init()
	local obj = {
		test = 1,
		add = function(a, b)
			return a + b
		end,
	}

	lu.assertEquals(obj.add(2, 3), 5)

	local m = Mock.object(obj, "add")
	lu.assertEquals(m.return_value, nil)
	lu.assertEquals(m.call_count, 0)
	lu.assertEquals(m.func_path, "add")

	m.return_value = 77

	lu.assertEquals(obj.add(1, 2), 77)
	lu.assertEquals(m.call_count, 1)
	lu.assertEquals(#m.call_args, 1)
	lu.assertEquals(m.call_args[1], { 1, 2 })

	m:release()
	lu.assertEquals(obj.add(2, 3), 5)
end

function TestMock:test_mock_object__with_dots()
	local obj = {
		test = 1,
		math = {
			add = function(a, b)
				return a + b
			end,
		},
	}

	lu.assertEquals(obj.math.add(2, 3), 5)

	local m = Mock.object(obj, "math.add")
	lu.assertEquals(m.return_value, nil)
	lu.assertEquals(m.call_count, 0)
	lu.assertEquals(m.func_path, "math.add")

	m.return_value = 77

	lu.assertEquals(obj.math.add(1, 2), 77)
	lu.assertEquals(m.call_count, 1)
	lu.assertEquals(#m.call_args, 1)
	lu.assertEquals(m.call_args[1], { 1, 2 })

	Mock.release_all()
	lu.assertEquals(obj.math.add(2, 3), 5)
end

function TestMock:test_mock_global_with_dots__release_all()
	-- WARNING: setting internal functions is possible but may lead to weird side effects!
	local m = Mock.global("os.clock")
	m.return_value = 77.01
	lu.assertEquals(m.return_value, 77.01)
	lu.assertEquals(m.call_count, 0)
	lu.assertEquals(m.func_path, "os.clock")

	lu.assertEquals(os.clock(), 77.01)
	lu.assertEquals(m.call_count, 1)

	Mock.release_all()
	lu.assertNotEquals(os.clock(), 77.01)
end

function TestMock:test_mock_global_release_self()
	local m = Mock.global("os.clock")
	m.return_value = 77.01
	lu.assertEquals(m.return_value, 77.01)
	lu.assertEquals(m.call_count, 0)
	lu.assertEquals(m.func_path, "os.clock")

	lu.assertEquals(os.clock(), 77.01)
	lu.assertEquals(m.call_count, 1)

	m:release()
	lu.assertNotEquals(os.clock(), 77.01)
end

function TestMock:test_mock_global__forbidden()
	lu.assertErrorMsgContains("Forbidden mocking for global ", Mock.global, "error")
	lu.assertErrorMsgContains("Forbidden mocking for global ", Mock.global, "setmetatable")
	lu.assertErrorMsgContains("Forbidden mocking for global ", Mock.global, "type")
	lu.assertErrorMsgContains("Forbidden mocking for global ", Mock.global, "pairs")
	lu.assertErrorMsgContains("Forbidden mocking for global ", Mock.global, "assert")
end

function TestMock:test_mock_global__init_create_non_existing()
	local m = Mock.global("getInfoParamNoExists", true)
	lu.assertEquals(m.return_value, nil)
	lu.assertEquals(m.call_count, 0)
	lu.assertEquals(m.func_path, "getInfoParamNoExists")

	--- This one now created by Mock!
	---@diagnostic disable-next-line
	getInfoParamNoExists()
	lu.assertEquals(m.call_count, 1)
end

function TestMock:test_mock_global__reset_mock()
	local m = Mock.global("getInfoParamNoExists", true)
	lu.assertEquals(m.return_value, nil)
	lu.assertEquals(m.call_count, 0)
	lu.assertEquals(m.func_path, "getInfoParamNoExists")

	--- This one now created by Mock!
	---@diagnostic disable-next-line
	getInfoParamNoExists()
	lu.assertEquals(m.call_count, 1)
	m:reset_mock()

	lu.assertEquals(m.call_count, 0)
end

function TestMock:test_mock_call_from_another_module()
	local m = Mock.global("getInfoParam", true)
	m.return_value = 124
	local module_param = mock_test_module.param("mock test module")
	lu.assertEquals(module_param, 124)
	lu.assertEquals(m.call_count, 1)
end

function TestMock:test_mock_side_effect_function()
	local m = Mock.global("getInfoParam", true)

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
	local m = Mock.global("getInfoParam", true)
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
