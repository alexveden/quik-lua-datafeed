--
-- Simple LUA mocks
--
--

---@class Mock
---@field name? string name of the mocked function or object
---@field return_value any return value of the mock function
---@field side_effect nil| function | table custom function when mock called
---@field call_count number number of times mock was called
Mock = {
	name = "",
	return_value = nil,
	side_effect = nil,
	call_count = 0,
}
Mock.__index = Mock

-- In case if print is mocked, too
local __print = print
local GLOBAL_MOCKS = {}
local GLOBAL_FORBIDDEN = {
	["error"] = true,
	["setmetatable"] = true,
	["type"] = true,
	["pairs"] = true,
	["assert"] = true,
}

---Creates mock for a global function
---@param global_name string global function name, for example 'print', 'os.clock', 'math.abs'
---@param create_missing? boolean force mock creation even if it's not found in _G (default: false)
---@return Mock
function Mock.g(global_name, create_missing)
	---@class Mock
	local self = setmetatable({}, Mock)
	self.name = global_name

	if GLOBAL_FORBIDDEN[global_name] then
		error("Forbidden mocking for global `" .. global_name .. "`")
	end
	if GLOBAL_MOCKS[global_name] ~= nil then
		error("Global object was already mocked: " .. global_name)
	end

	local _g_func = nil
	local _is_missing = false

	if string.find(global_name, "%.") then
		-- name with dots!
		local _g = _G
		for t in string.gmatch(global_name, "([^.]+)") do
			if _g[t] == nil then
				_is_missing = true

				if not create_missing then
					error("Global object is not found (or try with create_missing=true): " .. global_name)
				end
			end

			if type(_g[t]) == "table" then
				_g = _g[t]
			else
				_g_func = _g[t]

				if type(_g_func) == "function" or (create_missing and _is_missing) then
					GLOBAL_MOCKS[global_name] = _g_func
					_g[t] = function(...)
						return self:__call(...)
					end
				else
					error(string.format("_G[%s] is not a function, but %s", global_name, type(_g_func)))
				end
			end
		end
	else
		if _G[global_name] == nil then
			_is_missing = true
			if not create_missing then
				error("Global object is not found (or try with create_missing=true): " .. global_name)
			end
		end

		_g_func = _G[global_name]
		if type(_g_func) == "function" or (create_missing and _is_missing) then
			GLOBAL_MOCKS[global_name] = _g_func
			_G[global_name] = function(...)
				return self:__call(...)
			end
		else
			error(string.format("_G[%s] is not a function, but %s", global_name, type(_G[global_name])))
		end
	end

	return self
end

function Mock:__call(...)
	self.call_count = self.call_count + 1
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
function Mock.finalize()
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

function Mock.global_count()
	local cnt = 0
	for _, _ in pairs(GLOBAL_MOCKS) do
		cnt = cnt + 1
	end
	return cnt
end

return Mock
