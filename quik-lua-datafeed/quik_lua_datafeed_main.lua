local QuikLuaDatafeed = require("core.QuikLuaDatafeed")
local config_exists, config = pcall(require, "config")
if not config_exists then
	error(string.format("Missing config.lua, in '%s' folder.", getScriptPath()))
end


--[
--
--  Quik events
--
--]

function OnInit()
	IS_RUNNING = true
	MAIN_QUEUE = {}
	SUBSCRIBED_EVENTS = {}
end

function OnAllTrade(all_trade)
	if IS_RUNNING and SUBSCRIBED_EVENTS["OnAllTrade"] then
		table.sinsert(MAIN_QUEUE, { callback = "OnAllTrade", value = all_trade })
	end
end

function OnQuote(class_code, sec_code)
	if IS_RUNNING and SUBSCRIBED_EVENTS["OnQuote"] then
		table.sinsert(MAIN_QUEUE, {
			callback = "OnQuote",
			t = { class_code = class_code, sec_code = sec_code },
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

	feed:log("Initializing QuikLuaDatafeed")

	SUBSCRIBED_EVENTS = feed:quik_get_subscribed_events()
	for k, _ in pairs(SUBSCRIBED_EVENTS) do
		feed:log("Subscribed: %s", k)
	end

	while IS_RUNNING do
		-- collectgarbage("collect")
		feed:quik_notify_que_length(#MAIN_QUEUE)

		if #MAIN_QUEUE > 0 then
			feed:quik_on_event(MAIN_QUEUE[1])
			table.sremove(MAIN_QUEUE, 1)
		else
			-- TODO: implement timer event in the case if no other event waiting
			sleep(1)
		end
	end

	feed:log("main: stopping")
	feed:log("feed stats: %s", feed:get_stats(true))
	feed:log("stopped")
	error(feed:get_stats(true))
end
