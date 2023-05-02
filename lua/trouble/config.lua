local M = {}

M.namespace = vim.api.nvim_create_namespace("Trouble")

---@class TroubleOptions
---@field buf number|nil
---@field win number|nil
-- TODO: make some options configurable per mode
-- TODO: make it possible to have multiple trouble lists open at the same time
local defaults = {
  debug = false,
  cmd_options = {},
  group = true, -- group results by file
  padding = true, -- add an extra new line on top of the list
  position = "bottom", -- position of the list can be: bottom, top, left, right
  height = 10, -- height of the trouble list when position is top or bottom
  width = 50, -- width of the list when position is left or right
  icons = true, -- use devicons for filenames
  mode = "workspace_diagnostics", -- "workspace_diagnostics", "document_diagnostics", "quickfix", "lsp_references", "loclist"
  fold_open = "", -- icon used for open folds
  fold_closed = "", -- icon used for closed folds
  action_keys = { -- key mappings for actions in the trouble list
    close = "q", -- close the list
    cancel = "<esc>", -- cancel the preview and get back to your last window / buffer / cursor
    refresh = "r", -- manually refresh
    jump = { "<cr>", "<tab>" }, -- jump to the diagnostic or open / close folds
    open_split = { "<c-x>" }, -- open buffer in new split
    open_vsplit = { "<c-v>" }, -- open buffer in new vsplit
    open_tab = { "<c-t>" }, -- open buffer in new tab
    jump_close = { "o" }, -- jump to the diagnostic and close the list
    toggle_mode = "m", -- toggle between "workspace" and "document" mode
    toggle_preview = "P", -- toggle auto_preview
    hover = "K", -- opens a small popup with the full multiline message
    preview = "p", -- preview the diagnostic location
    close_folds = { "zM", "zm" }, -- close all folds
    open_folds = { "zR", "zr" }, -- open all folds
    toggle_fold = { "zA", "za" }, -- toggle fold of current file
    previous = "k", -- preview item
    next = "j", -- next item
    incr_min_severity = {"+", "="}, -- increase the minimum severity, or enables if disabled
    decr_min_severity = {"-", "_"}, -- decrease the minimum severity, or disable if below Information
    incr_cascading_severity = ")", -- increase the cascading severity threshold, enables if disabled
    decr_cascading_severity = "(", -- decrease the cascading severity threshold, or disables
  },
  indent_lines = true, -- add an indent guide below the fold icons
  auto_open = false, -- automatically open the list when you have diagnostics
  auto_close = false, -- automatically close the list when you have no diagnostics
  auto_preview = true, -- automatically preview the location of the diagnostic. <esc> to close preview and go back to last window
  auto_fold = false, -- automatically fold a file trouble list at creation
  auto_jump = { "lsp_definitions" }, -- for the given modes, automatically jump if there is only a single result
  signs = {
    -- icons / text used for a diagnostic
    error = "",
    warning = "",
    hint = "",
    information = "",
    other = "",
  },
  use_diagnostic_signs = false, -- enabling this will use the signs defined in your lsp client
  sort_keys = {
    "severity",
    "filename",
    "lnum",
    "col",
  },
  min_severity = nil, -- setting to "Information", "Warning", or "Error" will filter out any less severe LSP diagnostics
  cascading_severity_threshold = nil, -- with this set, attempts to display one severity of LSP diagnostic at a time.
                                      -- useful if you want to deal with errors (that stop your code compiling) before
                                      -- dealing with warnings etc. set to "Hint" to simply enable; set to a higher
                                      -- severity to display that and all lower severities in one layer.
                                      -- for example, set to "Information" and once you get rid of errors, and then
                                      -- get rid of warnings, you are shown info and hints.

}

---@type TroubleOptions
M.options = {}
---@return TroubleOptions

function M.setup(options)
  M.options = vim.tbl_deep_extend("force", {}, defaults, options or {})
  M.fix_severity(M.options)
end

-- this is a bit overboard to validate these settings, but fun
local DiagnosticSeverity = vim.lsp.protocol.DiagnosticSeverity
local to_severity = function(severity)
  if not severity then return nil end
  return type(severity) == 'string' and DiagnosticSeverity[severity] or severity
end
local severity_keys = vim.tbl_keys(DiagnosticSeverity)
local severity_names = vim.tbl_filter(function(a) return type(a) == "string" end, severity_keys)
table.sort(severity_names, function (a, b) return to_severity(a) < to_severity(b) end)
local severity_names_joined = table.concat(severity_names, ", ")
local severity_expected = "nil, number in range 1..=4, or {"..severity_names_joined .. "}"
function sev_validate(s)
  -- Diagnostics
  return vim.tbl_contains(severity_keys, s)
end
function opt_sev_validate(s)
  if s == nil then return true end
  if type(s) == 'number' then return s end
  return sev_validate(s)
end

function M.fix_severity(opts)
  vim.validate {
    min_severity = { opts.min_severity, opt_sev_validate, severity_expected },
    cascading_severity = { opts.cascading_severity, opt_sev_validate, severity_expected },
  }
  -- make them 1..=4 or nil
  opts.min_severity = to_severity(opts.min_severity)
  -- min_severity being Hint just runs a no-op filter, so ignore it
  if opts.min_severity == 4 then
    opts.min_severity = nil
  end
  opts.cascading_severity = to_severity(opts.cascading_severity)
end

M.setup()

return M
