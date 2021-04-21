---@class Lsp
local M = {}

local lsp_type_diagnostic = {
    [1] = "Error",
    [2] = "Warning",
    [3] = "Information",
    [4] = "Hint"
}

local function preprocess_diag(diag, bufnr)
    local filename = vim.api.nvim_buf_get_name(bufnr)
    local start = diag.range['start']
    local finish = diag.range['end']
    local row = start.line
    local col = start.character

    ---@class Diagnostics
    ---@field is_file boolean
    local ret
    ret = {
        bufnr = bufnr,
        filename = filename,
        lnum = row + 1,
        col = col + 1,
        start = start,
        finish = finish,
        -- remove line break to avoid display issues
        text = vim.trim(diag.message:gsub("[\n]", "")),
        type = lsp_type_diagnostic[diag.severity] or lsp_type_diagnostic[1],
        code = diag.code,
        source = diag.source,
        severity = diag.severity or 1
    }
    return ret
end

---@return Diagnostics[]
function M.diagnostics(opts)
    opts = opts or {}
    local items = {}

    local buffer_diags = opts.bufnr and
                             {
            [opts.bufnr] = vim.lsp.diagnostic.get(opts.bufnr, nil)
        } or vim.lsp.diagnostic.get_all()

    for bufnr, diags in pairs(buffer_diags) do
        for _, diag in pairs(diags) do
            -- workspace diagnostics may include empty tables for unused bufnr
            if not vim.tbl_isempty(diag) then
                table.insert(items, preprocess_diag(diag, bufnr))
            end
        end
    end
    table.sort(items, function(a, b)
        if a.severity == b.severity then
            return a.lnum < b.lnum
        else
            return a.severity < b.severity
        end
    end)
    return items
end

---@param items Diagnostics[]
---@return table<string, Diagnostics[]>
function M.group(items)
    local ret = {}
    for _, item in ipairs(items) do
        if ret[item.filename] == nil then ret[item.filename] = {} end
        table.insert(ret[item.filename], item)
    end
    return ret
end

function M.get_signs()
    local signs = {}
    for _, v in pairs(lsp_type_diagnostic) do
        -- pcall to catch entirely unbound or cleared out sign hl group
        local status, sign = pcall(function()
            return vim.trim(vim.fn.sign_getdefined("LspDiagnosticsSign" .. v)[1]
                                .text)
        end)
        if not status then sign = v:sub(1, 1) end
        signs[string.lower(v)] = sign
    end
    return signs
end

return M
