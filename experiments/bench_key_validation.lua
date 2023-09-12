package.path = "../quik-lua-datafeed/?.lua;../quik-lua-datafeed/lib/lua/?.lua;" .. package.path

local TransportBase = require('transports.TransportBase')

local function timeit(name, n, func)
	local t_begin = os.clock()
	for _ = 1, n, 1 do
		func()
	end

	local elapsed = os.clock() - t_begin
	print(name .. "> elapsed: " .. elapsed .. "sec, avg. per call: " .. elapsed / n)
end

timeit("table", 1000, function()
	TransportBase.validate_key({'quik', 'params', 'q', 'RIH23'})
end)

