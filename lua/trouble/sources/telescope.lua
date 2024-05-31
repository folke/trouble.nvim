---@diagnostic disable: inject-field
local Item = require("trouble.item")

---Represents an item in a Neovim quickfix/loclist.
---@class telescope.Item
---@field lnum? number The start line number for the item.
---@field col? number The column number where the item starts.
---@field bufnr? number The buffer number where the item originates.
---@field filename? string The filename of the item.
---@field cwd? string The current working directory of the item.

---@class trouble.Source.telescope: trouble.Source
local M = {}

---@type trouble.Item[]
M.items = {}

M.config = {
  modes = {
    telescope = {
      desc = "Telescope results previously opened with `require('trouble.sources.telescope').open()`.",
      -- events = { "BufEnter", "QuickFixCmdPost" },
      source = "telescope",
      groups = {
        { "filename", format = "{file_icon} {filename} {count}" },
      },
      sort = { "filename", "pos" },
      format = "{text:ts} {pos}",
    },
  },
}

---@param item telescope.Item
function M.item(item)
  local filename = item.filename
  if item.cwd then
    filename = item.cwd .. "/" .. filename
  end
  return Item.new({
    source = "telescope",
    buf = item.bufnr,
    filename = filename,
    pos = (item.lnum and item.col) and { item.lnum, item.col - 1 } or nil,
    item = item,
  })
end

---@param cb trouble.Source.Callback
---@param _ctx trouble.Source.ctx)
function M.get(cb, _ctx)
  cb(M.items)
end

-- Append the current telescope buffer to the trouble list.
---@param opts? trouble.Mode|string
function M.add(prompt_bufnr, opts)
  local action_state = require("telescope.actions.state")
  ---@type Picker
  local picker = action_state.get_current_picker(prompt_bufnr)

  if #picker:get_multi_selection() > 0 then
    for _, item in ipairs(picker:get_multi_selection()) do
      table.insert(M.items, M.item(item))
    end
  else
    for item in picker.manager:iter() do
      table.insert(M.items, M.item(item))
    end
  end
  Item.add_text(M.items, { mode = "after" })

  vim.schedule(function()
    require("telescope.actions").close(prompt_bufnr)
    opts = opts or {}
    if type(opts) == "string" then
      opts = { mode = opts }
    end
    opts = vim.tbl_extend("force", { mode = "telescope" }, opts)
    require("trouble").open(opts)
  end)
end

-- Opens the current telescope buffer in the trouble list.
-- This will clear the existing items.
---@param opts? trouble.Mode|string
function M.open(prompt_bufnr, opts)
  M.items = {}
  M.add(prompt_bufnr, opts)
end

return M
