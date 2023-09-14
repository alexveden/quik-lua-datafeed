package.path = "../quik-lua-datafeed/?.lua;../quik-lua-datafeed/lib/lua/?.lua;" .. package.path
-- Uses luaunit
-- requires `luarocks install luaunit`
--  https://github.com/bluebird75/luaunit
--
--  To LSP autocompletion make sure...
--  NeoVim: lua_ls (requires adding config.setting.Lua.workspace.library=<luarocks path>)
--
local ev = require("core.events")
local lu = require("luaunit")
local Mock = require("Mock")
local FeedStats = require("core.FeedStats")

TestFeedStats = {}
function TestFeedStats:setUp() end

function TestFeedStats:tearDown()
	Mock.release_all()
	lu.assertEquals(Mock.global_count(), 0)
	lu.assertEquals(Mock.objects_count(), 0)
end

function TestFeedStats:test_feedstats_new()
    local stats = FeedStats.new()
    lu.assertEquals(stats.n_events, 0)
    lu.assertEquals(stats.max_que_length, 0)
    lu.assertEquals(stats.current_que_length, 0)
    lu.assertEquals(stats.subscriptions, {})
    lu.assertEquals(stats.handlers, {})
end

function TestFeedStats:test_report_handler_duration()
    local stats = FeedStats.new()
    local handler = {name = 'test'}

    stats:set_handler(handler)

    stats:report_handler_duration(handler, 5)
    stats:report_handler_duration(handler, 10)

    local hs = stats.handlers[handler.name]
    lu.assertEquals(hs.n, 2)
    lu.assertEquals(hs.time_sum, 15)
end

function TestFeedStats:test_report_event_duration()
    local stats = FeedStats.new()

    stats:set_event(ev.ON_QUOTE)

    stats:report_event_duration(ev.ON_QUOTE, 5)

    local hs = stats.subscriptions[ev.ON_QUOTE]
    lu.assertEquals(hs.n, 1)
    lu.assertEquals(hs.time_sum, 5)
end

function TestFeedStats:test_report_quik_que()
    local stats = FeedStats.new()

    stats:report_quik_que_length(5)
    stats:report_quik_que_length(2)
    lu.assertEquals(stats.current_que_length, 2)
    lu.assertEquals(stats.max_que_length, 5)
end

function TestFeedStats:test_get_stats()
    local stats = FeedStats.new()
    local handler = {name = 'test'}

    stats:set_handler(handler)
    stats:set_event(ev.ON_QUOTE)

    stats:report_handler_duration(handler, 5)
    stats:report_handler_duration(handler, 10)

    stats:report_quik_que_length(5)
    stats:report_quik_que_length(2)

    stats:report_event_duration(ev.ON_QUOTE, 5)
    stats:report_event_duration(ev.ON_QUOTE, 12)

    local s = stats:get_stats(false)

    lu.assertEquals(s.current_que_length, 2)
    lu.assertEquals(s.max_que_length, 5)
    lu.assertEquals(s.subscriptions[ev.ON_QUOTE].avg_per_call, (12+5)/2)
    lu.assertEquals(s.subscriptions[ev.ON_QUOTE].count, 2)
    lu.assertEquals(s.subscriptions[ev.ON_QUOTE].total_time, 12+5)

    lu.assertEquals(s.handlers[handler.name].avg_per_call, (10+5)/2)
    lu.assertEquals(s.handlers[handler.name].count, 2)
    lu.assertEquals(s.handlers[handler.name].total_time, 10+5)

    s = stats:get_stats(true) -- as json
    lu.assertStrContains(s, 'current_que_length')

end
os.exit(lu.LuaUnit.run())
