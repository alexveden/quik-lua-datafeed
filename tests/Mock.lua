--
-- Simple LUA mocks
--
--

---@class Mock
---@field name? string name of the mocked function or object
---@field return_value any return value of the mock function
---@field side_effect nil| function | table custom function when mock called
---@field call_count number number of times mock was called
---@field call_args table sequence of all mock calls
Mock = {
	name = "",
	return_value = nil,
	side_effect = nil,
	call_count = 0,
	call_args = {},
}
Mock.__index = Mock

-- In case if print is mocked, too
local __print = print
local GLOBAL_MOCKS = {}
local GLOBAL_MOCKS_FORBIDDEN = {
	["error"] = true,
	["setmetatable"] = true,
	["type"] = true,
	["pairs"] = true,
	["assert"] = true,
}

local function patch_table(tbl, fpath, create_missing, table_name, patch_func)
	local _is_missing = false
	local _tbl = tbl
	local _t_orig_func = nil

	-- name with dots!
	for t in string.gmatch(fpath, "([^.]+)") do
		if _tbl[t] == nil then
			_is_missing = true

			if not create_missing then
				error(
					string.format(
						"%s[%s]function is not found (or try with create_missing=true).",
						table_name,
						fpath
					)
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

	assert(_t_orig_func or create_missing, 'Expected to be patched or created, but not...')
	return _t_orig_func
end

---Creates mock for a global function
---@param global_name string global function name, for example 'print', 'os.clock', 'math.abs'
---@param create_missing? boolean force mock creation even if it's not found in _G (default: false)
---@return Mock
function Mock.g(global_name, create_missing)
	---@class Mock
	local self = setmetatable({}, Mock)
	self.name = global_name
	self.call_args = {}

	if not global_name or #global_name == 0 then
		error("Empty global_name")
	end

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
			-- TODO: implement array based side effects
			assert(false, "TODO: implement array based side effect too")
		end
	else
		return self.return_value
	end
	-- __print("Mock.__call[" .. self.name .. "] ", ...)
end

---Releases all aquired mocks
function Mock.global_finalize()
	for k, v in pairs(GLOBAL_MOCKS) do
		if string.find(k, "%.") then
			-- name with dots!
			local _g = _G
			for t in string.gmatch(k, "([^.]+)") do
				if type(_g[t]) == "table" then
					_g = _g[t]
				else
					_g[t] = v
				end
			end
		else
			_G[k] = v
		end

		GLOBAL_MOCKS[k] = nil
	end
end

---Total count of currently mocked global functions
---@return number
function Mock.global_count()
	local cnt = 0
	for _, _ in pairs(GLOBAL_MOCKS) do
		cnt = cnt + 1
	end
	return cnt
end

return Mock
