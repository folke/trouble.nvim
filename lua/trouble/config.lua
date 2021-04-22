local M = {}

M.namespace = vim.api.nvim_create_namespace('LspTrouble')

---@class Options
local defaults = {
    height = 10,
    icons = true,
    mode = "document", -- "workspace" or "document"
    fold_open = "",
    fold_closed = "",
    actions = {
        ["<cr>"] = "jump",
        ["<tab>"] = "jump",
        ["<esc>"] = "cancel",
        q = "close",
        r = "refresh",
        zR = "open_folds",
        zM = "close_folds",
        j = "next",
        k = "previous",
        m = "toggle_mode"
    },
    indent_lines = false,
    auto_open = false,
    auto_close = true,
    signs = {error = "", warning = "", hint = "", information = ""},
    use_lsp_diagnostic_signs = false
}

---@type Options
M.options = {}

---@return Options
function M.setup(options)
    M.options = vim.tbl_deep_extend("force", {}, defaults, options or {})
end

M.setup()

return M
