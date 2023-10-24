---@diagnostic disable: inject-field
local Item = require("trouble.item")

---Represents an item in a Neovim quickfix/loclist.
---@class qf.item
---@field bufnr? number The buffer number where the item originates.
---@field filename? string
---@field lnum number The start line number for the item.
---@field end_lnum? number The end line number for the item.
---@field pattern string A pattern related to the item. It can be a search pattern or any relevant string.
---@field col? number The column number where the item starts.
---@field end_col? number The column number where the item ends.
---@field module? string Module information (if any) associated with the item.
---@field nr? number A unique number or ID for the item.
---@field text? string A description or message related to the item.
---@field type? string The type of the item. E.g., "W" might stand for "Warning".
---@field valid number A flag indicating if the item is valid (1) or not (0).
---@field user_data? any Any user data associated with the item.
---@field vcol? number Visual column number. Indicates if the column number is a visual column number (when set to 1) or a byte index (when set to 0).

---@type trouble.Source
local M = {}

---@type trouble.spec.section[]
local sections = {
  {
    source = "qf.qflist",
    groups = {
      { "filename", format = "{file_icon} {filename} {count}" },
    },
    sort = { { buf = 0 }, "severity", "filename", "pos", "message" },
    format = "{severity_icon|item.type:DiagnosticSignWarn} {text} {pos}",
  },
}

M.modes = {
  qflist = {
    events = { "BufEnter", "QuickFixCmdPost" },
    sections = sections,
  },
  loclist = {
    events = { "BufEnter" },
    sections = sections,
  },
}

local severities = {
  E = vim.diagnostic.severity.ERROR,
  W = vim.diagnostic.severity.WARN,
  I = vim.diagnostic.severity.INFO,
  H = vim.diagnostic.severity.HINT,
  N = vim.diagnostic.severity.HINT,
}

M.get = {
  qflist = function(cb)
    cb(M.get_list())
  end,
  loclist = function(cb)
    cb(M.get_list({ win = vim.api.nvim_get_current_win() }))
  end,
}

---@param opts? {win:number}
function M.get_list(opts)
  opts = opts or {}
  local list = opts.win == nil and vim.fn.getqflist({ all = true }) or vim.fn.getloclist(opts.win, { all = true })
  ---@cast list {items?:qf.item[]}?

  local ret = {} ---@type trouble.Item[]
  for _, item in pairs(list and list.items or {}) do
    local row = item.lnum or 1
    local col = math.max(0, (item.col or 1) - 1)
    local end_row = item.end_lnum or row
    local end_col = math.max(0, (item.end_col or col) - 1)

    if item.valid == 1 then
      ret[#ret + 1] = Item.new({
        pos = { row, col },
        end_pos = { end_row, end_col },
        text = item.text,
        severity = severities[item.type] or 0,
        buf = item.bufnr,
        filename = item.filename,
        item = item,
        source = "qf",
      })
    elseif #ret > 0 and ret[#ret].item.text and item.text then
      ret[#ret].item.text = ret[#ret].item.text .. "\n" .. item.text
    end
  end
  Item.add_text(ret)
  return ret
end

return M
