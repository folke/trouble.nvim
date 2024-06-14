---@diagnostic disable: inject-field
local Item = require("trouble.item")

---Represents an item in a Neovim quickfix/loclist.
---@class fzf.Item
---@field stripped string the fzf item without any highlighting.
---@field bufnr? number The buffer number of the item.
---@field bufname? string
---@field terminal? boolean
---@field path string
---@field uri? string
---@field line number 1-indexed line number
---@field col number 1-indexed column number

---@class fzf.Opts

---@class trouble.Source.fzf: trouble.Source
local M = {}

---@type trouble.Item[]
M.items = {}

M.config = {
  modes = {
    fzf = {
      desc = "FzfLua results previously opened with `require('trouble.sources.fzf').open()`.",
      source = "fzf",
      groups = {
        { "cmd", format = "{hl:Title}fzf{hl} {cmd:Comment} {count}" },
        { "filename", format = "{file_icon} {filename} {count}" },
      },
      sort = { "filename", "pos" },
      format = "{text:ts} {pos}",
    },
    fzf_files = {
      desc = "FzfLua results previously opened with `require('trouble.sources.fzf').open()`.",
      source = "fzf",
      groups = {
        { "cmd", format = "{hl:Title}fzf{hl} {cmd:Comment} {count}" },
      },
      sort = { "filename", "pos" },
      format = "{file_icon} {filename}",
    },
  },
}

---@param item fzf.Item
function M.item(item)
  item.text = item.stripped:match(":%d+:%d?%d?%d?%d?:?(.*)$")
  local word = item.text and item.text:sub(item.col):match("%S+")
  return Item.new({
    source = "fzf",
    buf = item.bufnr,
    filename = item.bufname or item.path or item.uri,
    pos = { item.line, item.col - 1 },
    end_pos = word and { item.line, item.col - 1 + #word } or nil,
    item = item,
  })
end

---@param cb trouble.Source.Callback
---@param _ctx trouble.Source.ctx)
function M.get(cb, _ctx)
  cb(M.items)
end

-- Returns the mode based on the items.
function M.mode()
  for _, item in ipairs(M.items) do
    if item.text then
      return "fzf"
    end
  end
  return "fzf_files"
end

-- Append the current fzf buffer to the trouble list.
---@param selected string[]
---@param fzf_opts fzf.Opts
---@param opts? trouble.Mode|string
function M.add(selected, fzf_opts, opts)
  local cmd = fzf_opts.__INFO.cmd
  local path = require("fzf-lua.path")
  for _, line in ipairs(selected) do
    local item = M.item(path.entry_to_file(line, fzf_opts))
    item.item.cmd = cmd
    table.insert(M.items, item)
  end

  vim.schedule(function()
    opts = opts or {}
    if type(opts) == "string" then
      opts = { mode = opts }
    end
    opts = vim.tbl_extend("force", { mode = M.mode() }, opts)
    require("trouble").open(opts)
  end)
end

-- Opens the current fzf buffer in the trouble list.
-- This will clear the existing items.
---@param selected string[]
---@param fzf_opts fzf.Opts
---@param opts? trouble.Mode|string
function M.open(selected, fzf_opts, opts)
  M.items = {}
  M.add(selected, fzf_opts, opts)
end

local smart_prefix = require("trouble.util").is_win() and "transform(IF %FZF_SELECT_COUNT% LEQ 0 (echo select-all))"
  or "transform([ $FZF_SELECT_COUNT -eq 0 ] && echo select-all)"

M.actions = {
  -- Open selected or all items in the trouble list.
  open = { fn = M.open, prefix = smart_prefix, desc = "smart-open-with-trouble" },
  -- Open selected items in the trouble list.
  open_selected = { fn = M.open, desc = "open-with-trouble" },
  -- Open all items in the trouble list.
  open_all = { fn = M.open, prefix = "select-all", desc = "open-all-with-trouble" },
  -- Add selected or all items to the trouble list.
  add = { fn = M.add, prefix = smart_prefix, desc = "smart-add-to-trouble" },
  -- Add selected items to the trouble list.
  add_selected = { fn = M.add, desc = "add-to-trouble" },
  -- Add all items to the trouble list.
  add_all = { fn = M.add, prefix = "select-all", desc = "add-all-to-trouble" },
}

return M
