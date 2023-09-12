package.path = "../quik-lua-datafeed/?.lua;../quik-lua-datafeed/lib/lua/?.lua;" .. package.path

local ev = require('core.events')
local local_ev = ev.ON_QUOTE
MY_EVENT = 1

local function timeit(name, n, func)
	local t_begin = os.clock()
	for _ = 1, n, 1 do
		func()
	end

	local elapsed = os.clock() - t_begin
	print(string.format("%s> steps: %s elapsed: %ssec, avg. per call: %s", name, n, elapsed, elapsed/n))
end


local cnt = 0
timeit("event_modul", 1000000, function()
	cnt = cnt + ev.ON_QUOTE
end)

timeit("event_my", 1000000, function()
	cnt = cnt + MY_EVENT
end)

timeit("localev", 1000000, function()
	cnt = cnt + local_ev
end)
