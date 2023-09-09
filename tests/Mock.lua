--
-- Simple LUA mocks with pythonic flavor
--
--   Aleksandr Vedeneev (c) 2023
--
--   MIT License
--

---@class Mock
---@field func_path? string name of the mocked function or object
---@field return_value any return value of the mock function
---@field side_effect nil| function | table custom function when mock called
---@field call_count number number of times mock was called
---@field call_args table sequence of all mock calls
Mock = {
	func_path = "",
	return_value = nil,
	side_effect = nil,
	call_count = 0,
	call_args = {},
}
Mock.__index = Mock

-- In case if print is mocked, too
-- local __print = print
local GLOBAL_MOCKS = {}
local GLOBAL_MOCKS_FORBIDDEN = {
	["error"] = true,
	["setmetatable"] = true,
	["type"] = true,
	["pairs"] = true,
	["assert"] = true,
}
local MOCKED_OBJECTS = {}

---Counts lenght of a table
---@param tbl table
---@return number
local function tlen(tbl)
	assert(type(tbl) == "table")
	local cnt = 0
	for _, _ in pairs(tbl) do
		cnt = cnt + 1
	end
	return cnt
end

---Patches table function
---@param tbl table table to patch (can be also _G)
---@param fpath string func name or path ("os.clock", "class.sub.func")
---@param create_missing boolean creates if not exist
---@param table_name any tbl meaningful name
---@param patch_func function patch function
---@return function|nil
local function patch_table(tbl, fpath, create_missing, table_name, patch_func)
	if not fpath or #fpath == 0 then
		error("Empty func path ``, in table " .. table_name)
	end

	local _is_missing = false
	local _tbl = tbl
	local _t_orig_func = nil

	for t in string.gmatch(fpath, "([^.]+)") do
		if _tbl[t] == nil then
			_is_missing = true

			if not create_missing then
				error(
					string.format("%s[%s]function is not found (or try with create_missing=true).", table_name, fpath)
				)
			end
		end

		if type(_tbl[t]) == "table" then
			_tbl = _tbl[t]
		else
			_t_orig_func = _tbl[t]

			if type(_t_orig_func) == "function" or (create_missing and _is_missing) then
				_tbl[t] = patch_func
			else
				error(string.format("%s[%s] is not a function, but %s", table_name, fpath, type(_t_orig_func)))
			end
		end
	end

	assert(_t_orig_func or create_missing, "Expected to be patched or created, but not...")
	return _t_orig_func
end

---Revert object patch
---@param tbl table table to undo patch (can also be _G)
---@param fpath string func name or path ("os.clock", "class.sub.func")
---@param table_name string tbl meaningful name
---@param orig_func function original object func (must be cached somewhere)
---@return boolean
local function unpatch_table(tbl, fpath, table_name, orig_func)
	local _tbl = tbl

	for t in string.gmatch(fpath, "([^.]+)") do
		if _tbl[t] == nil then
			error(string.format("%s[%s]function is not found.", table_name, fpath))
		end

		if type(_tbl[t]) == "table" then
			_tbl = _tbl[t]
		else
			assert(type(_tbl[t]) == "function")

			_tbl[t] = orig_func
		end
	end

	return orig_func ~= nil
end

---Releases mocks and unpatch objects
---@param mock_table table global mock cache
---@param orig_object table object to unpatch
---@param func_path string path to patched function
local function release_mock(mock_table, orig_object, func_path)
	if mock_table and mock_table[func_path] then
		unpatch_table(orig_object, func_path, "release", mock_table[func_path])
		mock_table[func_path] = nil
	end
end

---Creates mock for a global function
---@param global_name string global function name, for example 'print', 'os.clock', 'math.abs'
---@param create_missing? boolean force mock creation even if it's not found in _G (default: false)
---@return Mock
function Mock.global(global_name, create_missing)
	create_missing = create_missing or false

	---@class Mock
	local self = setmetatable({}, Mock)
	self.func_path = global_name
	self.call_args = {}

	if GLOBAL_MOCKS_FORBIDDEN[global_name] then
		error("Forbidden mocking for global `" .. global_name .. "`")
	end
	if GLOBAL_MOCKS[global_name] ~= nil then
		error("Global object was already mocked: " .. global_name)
	end

	local mock_func = function(...)
		return self.__call(self, ...)
	end

	local orig_func = patch_table(_G, global_name, create_missing, "_G", mock_func)

	if orig_func then
		GLOBAL_MOCKS[global_name] = orig_func
	end

	return self
end

---Creates mock for a table's function
---@param object table object to patch
---@param func_path string global function name, for example 'print', 'os.clock', 'math.abs'
---@param create_missing? boolean force mock creation even if it's not found in _G (default: false)
---@return Mock
function Mock.object(object, func_path, create_missing)
	assert(type(object) == "table")
	create_missing = create_missing or false

	if MOCKED_OBJECTS[object] and MOCKED_OBJECTS[object][func_path] then
		error(string.format("object(%s)[%s] already mocked my another mock.", tostring(object), func_path))
	end

	---@class Mock
	local self = setmetatable({}, Mock)
	self.func_path = func_path
	self._object = object
	self.call_args = {}

	local mock_func = function(...)
		return self.__call(self, ...)
	end

	local orig_func = patch_table(object, func_path, create_missing, "object", mock_func)

	if not MOCKED_OBJECTS[object] then
		MOCKED_OBJECTS[object] = {}
	end

	MOCKED_OBJECTS[object][func_path] = orig_func

	return self
end

---Releases mock (unpatch global or object mock)
function Mock:release()
	if self._object then
		-- looks line object mock
		release_mock(MOCKED_OBJECTS[self._object], self._object, self.func_path)

		if tlen(MOCKED_OBJECTS[self._object]) == 0 then
			MOCKED_OBJECTS[self._object] = nil
		end
	else
		-- Global cleanup
		release_mock(GLOBAL_MOCKS, _G, self.func_path)
	end
end

---Reset mock call statistics
function Mock:reset_mock()
	self.call_count = 0
	self.call_args = {}
end

---Magic method for mocked function calls
function Mock:__call(...)
	self.call_count = self.call_count + 1
	table.insert(self.call_args, { ... })

	if self.side_effect then
		if type(self.side_effect) == "function" then
			return self.side_effect(...)
		else
			if type(self.side_effect) == "table" then
				if self.call_count > #self.side_effect then
					error("side_effect table is empty, or call count overflow happened")
				end

				return self.side_effect[self.call_count]
			else
				error("side_effect expected function or table, use `Mock.return_value` for static results")
			end
		end
	else
		return self.return_value
	end

	-- __print("Mock.__call[" .. self.name .. "] ", ...)
end

---Releases all aquired mocks for this module (useful in Test:tearDown())
function Mock.release_all()
	for k, _ in pairs(GLOBAL_MOCKS) do
		release_mock(GLOBAL_MOCKS, _G, k)
	end

	for obj, mock_table in pairs(MOCKED_OBJECTS) do
		for func_path, _ in pairs(mock_table) do
			release_mock(mock_table, obj, func_path)
		end
		MOCKED_OBJECTS[obj] = nil
	end
end

---Total count of currently mocked global functions
---@return number
function Mock.global_count()
	return tlen(GLOBAL_MOCKS)
end

---Total count of currently mocked objects
---@return number
function Mock.objects_count()
	return tlen(MOCKED_OBJECTS)
end

return Mock
