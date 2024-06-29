---@diagnostic disable: inject-field
local Item = require("trouble.item")
local Util = require("trouble.util")

---Represents an item in a Neovim quickfix/loclist.
---@class telescope.Item
---@field lnum? number The start line number for the item.
---@field col? number The column number where the item starts.
---@field bufnr? number The buffer number where the item originates.
---@field filename? string The filename of the item.
---@field text? string The text of the item.
---@field cwd? string The current working directory of the item.
---@field path? string The path of the item.

---@class trouble.Source.telescope: trouble.Source
local M = {}

---@type trouble.Item[]
M.items = {}

M.config = {
  modes = {
    telescope = {
      desc = "Telescope results previously opened with `require('trouble.sources.telescope').open()`.",
      source = "telescope",
      title = "{hl:Title}Telescope{hl} {count}",
      groups = {
        { "filename", format = "{file_icon} {filename} {count}" },
      },
      sort = { "filename", "pos" },
      format = "{text:ts} {pos}",
    },
    telescope_files = {
      desc = "Telescope results previously opened with `require('trouble.sources.telescope').open()`.",
      source = "telescope",
      title = "{hl:Title}Telescope{hl} {count}",
      sort = { "filename", "pos" },
      format = "{file_icon} {filename}",
    },
  },
}

---@param item telescope.Item
function M.item(item)
  ---@type string
  local filename
  if item.path then
    filename = item.path
  else
    filename = item.filename
    if item.cwd then
      filename = item.cwd .. "/" .. filename
    end
  end
  local word = item.text and item.col and item.text:sub(item.col):match("%S+")
  local pos = item.lnum and { item.lnum, item.col and item.col - 1 or 0 } or nil
  return Item.new({
    source = "telescope",
    buf = item.bufnr,
    filename = filename,
    pos = pos,
    end_pos = word and pos and { pos[1], pos[2] + #word } or nil,
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
      return "telescope"
    end
  end
  return "telescope_files"
end

-- Append the current telescope buffer to the trouble list.
---@param opts? trouble.Mode|string
function M.add(prompt_bufnr, opts)
  local action_state = require("telescope.actions.state")
  ---@type Picker
  local picker = action_state.get_current_picker(prompt_bufnr)
  if not picker then
    return Util.error("No Telescope picker found?")
  end

  if #picker:get_multi_selection() > 0 then
    for _, item in ipairs(picker:get_multi_selection()) do
      table.insert(M.items, M.item(item))
    end
  else
    for item in picker.manager:iter() do
      table.insert(M.items, M.item(item))
    end
  end
  -- Item.add_text(M.items, { mode = "after" })

  vim.schedule(function()
    require("telescope.actions").close(prompt_bufnr)
    opts = opts or {}
    if type(opts) == "string" then
      opts = { mode = opts }
    end
    opts = vim.tbl_extend("force", { mode = M.mode() }, opts)
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
