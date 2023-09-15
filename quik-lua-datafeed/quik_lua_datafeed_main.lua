package.cpath = '.\\lib\\?.dll;' .. package.cpath
package.path = '.\\lib\\lua\\?.lua;' .. package.path

local QuikLuaDatafeed = require("core.QuikLuaDatafeed")
local ev = require('core.events')

local config_isok, config = pcall(require, "config")
if not config_isok then
	error(string.format("Missing config.lua, or error in config. \r\nError: %s", config))
end


--[
--
--  Quik events
--
--]

function OnInit()
	IS_RUNNING = false
	MAIN_QUEUE = {}
	SUBSCRIBED_EVENTS = {}
end

function OnQuote(class_code, sec_code)
	if IS_RUNNING and SUBSCRIBED_EVENTS[ev.ON_QUOTE] then
		table.sinsert(MAIN_QUEUE, {
			eid = ev.ON_QUOTE,
			data = { class_code = class_code, sec_code = sec_code },
		})
	end
end

function OnStop()
	IS_RUNNING = false
	return 5000
end

--[
--
--  Main Entry Point
--
--]
---@diagnostic disable-next-line
function main()
	---@type QuikLuaDataFeed
	local feed = QuikLuaDatafeed.new(config)

	SUBSCRIBED_EVENTS = feed:quik_subscribe_events()

	IS_RUNNING = true
	while IS_RUNNING do
		-- collectgarbage("collect")
		feed:quik_notify_que_length(#MAIN_QUEUE)

		if #MAIN_QUEUE > 0 then
			feed:quik_on_event(MAIN_QUEUE[1])
			table.sremove(MAIN_QUEUE, 1)
		else
			feed:quik_on_event({eid = ev.ON_IDLE})
			sleep(1)
		end
	end

	feed:log(2, "main: stopping")
	local stats = feed.stats:get_stats(true)
	feed:log(2, "feed stats:\n %s", stats)
	feed:stop()
	error('\n'..stats)
end
