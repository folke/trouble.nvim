---@diagnostic disable: inject-field
local Item = require("trouble.item")

---@module 'snacks'

---@class trouble.Source.snacks: trouble.Source
local M = {}

---@type trouble.Item[]
M.items = {}

M.config = {
  modes = {
    snacks = {
      desc = "Snacks results previously opened with `require('trouble.sources.snacks').open()`.",
      source = "snacks",
      groups = {
        { "cmd", format = "{hl:Title}Snacks{hl} {cmd:Comment} {count}" },
        { "filename", format = "{file_icon} {filename} {count}" },
      },
      sort = { "filename", "pos" },
      format = "{text:ts} {pos}",
    },
    snacks_files = {
      desc = "Snacks results previously opened with `require('trouble.sources.snacks').open()`.",
      source = "snacks",
      groups = {
        { "cmd", format = "{hl:Title}Snacks{hl} {cmd:Comment} {count}" },
      },
      sort = { "filename", "pos" },
      format = "{file_icon} {filename}",
    },
  },
}

---@param item snacks.picker.Item
function M.item(item)
  return Item.new({
    source = "snacks",
    buf = item.buf,
    filename = item.file,
    pos = item.pos,
    end_pos = item.end_pos,
    text = item.line or item.comment or item.label or item.name or item.detail or false,
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
      return "snacks"
    end
  end
  return "snacks_files"
end

---@param picker snacks.Picker
---@param opts? { type?: "all" | "selected" | "smart", add?: boolean }
function M.open(picker, opts)
  opts = opts or {}
  if not opts.add then
    M.items = {}
  end
  local sitems = {} ---@type snacks.picker.Item[]
  local selected = picker:selected()
  opts.type = opts.type or "smart"
  if opts.type == "smart" then
    opts.type = #selected == 0 and "all" or "selected"
  end
  if opts.type == "all" then
    vim.list_extend(sitems, picker:items())
  else
    vim.list_extend(sitems, selected)
  end
  for _, i in ipairs(sitems) do
    local item = M.item(i)
    table.insert(M.items, item)
  end
  picker:close()
  vim.schedule(function()
    require("trouble").open({ mode = M.mode() })
  end)
end

---@param opts? { type?: "all" | "selected" | "smart", add?: boolean }
function M.wrap(opts)
  ---@param picker snacks.Picker
  return function(picker)
    M.open(picker, vim.deepcopy(opts or {}))
  end
end

---@type table<string, snacks.picker.Action.spec>
M.actions = {
  -- Open selected or all items in the trouble list.
  trouble_open = { action = M.wrap({ type = "smart" }), desc = "smart-open-with-trouble" },
  -- Open selected items in the trouble list.
  trouble_open_selected = { action = M.wrap({ type = "selected" }), desc = "open-with-trouble" },
  -- Open all items in the trouble list.
  trouble_open_all = { action = M.wrap({ type = "all" }), desc = "open-all-with-trouble" },
  -- Add selected or all items to the trouble list.
  trouble_add = { action = M.wrap({ type = "smart", add = true }), desc = "smart-add-to-trouble" },
  -- Add selected items to the trouble list.
  trouble_add_selected = { action = M.wrap({ type = "selected", add = true }), desc = "add-to-trouble" },
  -- Add all items to the trouble list.
  trouble_add_all = { action = M.wrap({ type = "all" }), desc = "add-all-to-trouble" },
}

return M
