local M = {}

function M.count(tab)
    local count = 0
    for _ in pairs(tab) do count = count + 1 end
    return count
end

function M.log(msg, hl)
    hl = hl or "MsgArea"
    vim.api.nvim_command('echohl ' .. hl)
    vim.api.nvim_command("echom '[LspTrouble] " .. msg:gsub("'", "''") .. "'")
    vim.api.nvim_command('echohl None')
end

function M.warn(msg) M.log(msg, "WarningMsg") end

return M
