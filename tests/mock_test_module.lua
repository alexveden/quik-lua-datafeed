M = {}


function M.param(s)
    -- This module uses some global function
    --   intended just for testing if Mock works on imported modules as well
    return getInfoParam(s)
end

return M
