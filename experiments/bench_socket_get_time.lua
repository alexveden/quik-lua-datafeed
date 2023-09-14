package.path = "../quik-lua-datafeed/?.lua;../quik-lua-datafeed/lib/lua/?.lua;" .. package.path
local socket = require('socket')

local function timeit(name, n, func)
	local t_begin = os.clock()
	for _ = 1, n, 1 do
		func()
	end

	local elapsed = os.clock() - t_begin
	print(string.format("%s> steps: %s elapsed: %ssec, avg. per call: %s", name, n, elapsed, elapsed/n))
end


timeit("socket_gettime", 1000000, function()
	socket.gettime()
end)

