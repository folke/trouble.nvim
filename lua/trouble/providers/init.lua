local util = require("trouble.util")
local qf = require("trouble.providers.qf")
local M = {}

local lsp = require("trouble.providers.lsp")

M.providers = {
    lsp_workspace_diagnostics = lsp.diagnostics,
    lsp_document_diagnostics = lsp.diagnostics,
    lsp_references = lsp.references,
    quickfix = qf.qflist,
    loclist = qf.loclist
}

---@param options Options
function M.get(win, buf, cb, options)
    local name = options.mode
    local provider = M.providers[name]

    if not provider then
        util.error(("invalid provider %q"):format(name))
        return {}
    end

    provider(win, buf, function(items)
        table.sort(items, function(a, b)
            if a.severity == b.severity then
                return a.lnum < b.lnum
            else
                return a.severity < b.severity
            end
        end)
        cb(items)
    end, options)
end

---@param items Item[]
---@return table<string, Item[]>
function M.group(items)
    local ret = {}
    for _, item in ipairs(items) do
        if ret[item.filename] == nil then ret[item.filename] = {} end
        table.insert(ret[item.filename], item)
    end
    return ret
end

return M
