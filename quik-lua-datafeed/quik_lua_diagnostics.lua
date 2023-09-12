package.cpath = '.\\lib\\?.dll;' .. package.cpath
package.path = '.\\lib\\lua\\?.lua;' .. package.path

--[
--
--  Main Entry Point
--
--]
local function check_socket()
    local socket = require('socket')
end

function main()
    check_socket()
    error(package.cpath)
end
