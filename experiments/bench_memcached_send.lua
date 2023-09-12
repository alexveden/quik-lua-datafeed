package.path = "../quik-lua-datafeed/?.lua;../quik-lua-datafeed/lib/lua/?.lua;" .. package.path

local TransportMemcached = require('transports.TransportMemcached')

local function timeit(name, n, func)
	local t_begin = os.clock()
	for _ = 1, n, 1 do
		func()
	end

	local elapsed = os.clock() - t_begin
	print(string.format("%s> steps: %s elapsed: %ssec, avg. per call: %s", name, n, elapsed, elapsed/n))
end

local transport = TransportMemcached.new({})
transport:init()

timeit("table", 1000, function()
	transport:send({'my', 'benchmark', 'key'}, {bid = 1902, ask= 9090, last=1231})
end)
transport:stop()

