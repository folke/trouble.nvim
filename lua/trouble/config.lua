local M = {}

M.namespace = vim.api.nvim_create_namespace('LspTrouble')

---@class Options
local defaults = {
    height = 10, -- height of the trouble list
    icons = true, -- use devicons for filenames
    mode = "workspace", -- "workspace" or "document"
    fold_open = "", -- icon used for open folds
    fold_closed = "", -- icon used for closed folds
    action_keys = { -- key mappings for actions in the trouble list
        close = "q", -- close the list
        cancel = "<esc>", -- cancel the preview and get back to your last window / buffer / cursor
        refresh = "r", -- manually refresh
        jump = {"<cr>", "<tab>"}, -- jump to the diagnostic or open / close folds
        toggle_mode = "m", -- toggle between "workspace" and "document" mode
        toggle_preview = "P", -- toggle auto_preview
        preview = "p", -- preview the diagnostic location
        close_folds = {"zM", "zm"}, -- close all folds
        open_folds = {"zR", "zr"}, -- open all folds
        previous = "k", -- preview item
        next = "j" -- next item
    },
    indent_lines = true, -- add an indent guide below the fold icons
    auto_open = false, -- automatically open the list when you have diagnostics
    auto_close = false, -- automatically close the list when you have no diagnostics
    auto_preview = true, -- automatyically preview the location of the diagnostic. <esc> to close preview and go back to last window
    signs = {
        -- icons / text used for a diagnostic
        error = "",
        warning = "",
        hint = "",
        information = ""
    },
    use_lsp_diagnostic_signs = false -- enabling this will use the signs defined in your lsp client
}

---@type Options
M.options = {}

---@return Options
function M.setup(options)
    M.options = vim.tbl_deep_extend("force", {}, defaults, options or {})
end

M.setup()

return M
