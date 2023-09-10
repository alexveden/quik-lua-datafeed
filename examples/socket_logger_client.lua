package.path = '../quik-lua-datafeed/?.lua;' .. package.path

local LoggerSocket = require('loggers.LoggerSocket')
local log = LoggerSocket.new({host = 'localhost', port = 17000})
log:init()

local t_begin = os.clock()
local n_msg = 100
local n_errors = 0
local n_success = 0
for i = 1, n_msg do
    local n_sent, err = log:log("anything: %s", i)
    if not n_sent then
        print(err)
        n_errors = n_errors + 1
    else
        -- print(ret)
        n_success = n_success + 1
    end
end
local t_end = os.clock()
print(string.format(
    'Sent: %s messages in %s seconds, avg per call: %s Success: %s Errors: %s',
    n_msg,
    t_end-t_begin,
    (t_end-t_begin)/n_msg,
    n_success,
    n_errors))
-- contact daytime host
