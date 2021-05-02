local config = require("trouble.config")

local M = {}

function M.count(tab)
    local count = 0
    for _ in pairs(tab) do count = count + 1 end
    return count
end

function M.log(msg, hl)
    hl = hl or "MsgArea"
    vim.api.nvim_echo({{'[LspTrouble] ', hl}, {msg}}, true, {})
end

function M.warn(msg) M.log(msg, "WarningMsg") end

function M.debug(msg) if config.options.debug then M.log(msg) end end

function M.debounce(ms, fn)
    local timer = vim.loop.new_timer()
    return function(...)
        local argv = {...}
        timer:start(ms, 0, function()
            timer:stop()
            vim.schedule_wrap(fn)(unpack(argv))
        end)
    end
end

return M
