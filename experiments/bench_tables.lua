local function timeit(name, n, func)
	local t_begin = os.clock()
	for _ = 1, n, 1 do
		func()
	end

	local elapsed = os.clock() - t_begin
	print(name .. "> elapsed: " .. elapsed .. "sec, avg. per call: " .. elapsed / n)
end

local t = {
	OnTrade = true,
	OnAccount = true,
	OnParam = true,
	OnQuote = true,
}

ON_TRADE = true
ON_ACCOUNT = true
ON_PARAM = true
ON_QUOTE = true
ON_ACCOUNT = false

local n = 0
timeit("table", 10000000, function()
	if t["ON_ACCOUNT"] then
		n = n + 1
	end
end)

timeit("localvar", 10000000, function()
	if ON_QUOTE then
		n = n + 1
	end
end)
