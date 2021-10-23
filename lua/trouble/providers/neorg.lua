local util = require("trouble.util")

local M = {}

M.results = {}


function M.traverse_headings(win, _buf, cb, _options)
    M.results = {}

    local lines = vim.api.nvim_buf_get_lines(_buf, 0, -1, true)

    for row, line in ipairs(lines) do
        local match = line:match("^%s*%*+%s+")
        if match then
            local row = row - 1
            local col = match:len()
            local pitem = {
                row = row,
                col = col,
                message = line,
                severity = 0,
                range = {
                    start = { line = row, character = col },
                    ["end"] = { line = row, character = -1 },
                },
            }
            table.insert(M.results, util.process_item(pitem, _buf))
        end
    end

    cb(M.results)
end


return M
