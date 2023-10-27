local Actions = require("trouble.config.actions")
local Config = require("trouble.config")
local Util = require("trouble.util")
local View = require("trouble.view")

---@alias trouble.ApiFn fun(opts?: trouble.Config|string): trouble.View
---@alias trouble.Open trouble.Config|{focus?:boolean, new?:boolean}

---@class trouble.api: trouble.actions
local M = {}
M.last_mode = nil ---@type string?

--- Finds all open views matching the filter.
---@param opts? trouble.Config|string
---@param filter? trouble.View.filter
---@return trouble.View[], trouble.Config
function M.find(opts, filter)
  opts = Config.get(opts)
  if opts.mode == "last" then
    opts.mode = M.last_mode
    opts = Config.get(opts)
  end
  M.last_mode = opts.mode or M.last_mode
  filter = filter or { is_open = true, mode = opts.mode }
  return vim.tbl_map(function(v)
    return v.view
  end, View.get(filter)), opts
end

--- Finds the last open view matching the filter.
---@param opts? trouble.Open|string
---@param filter? trouble.View.filter
---@return trouble.View?, trouble.Open
function M.find_last(opts, filter)
  local views, _opts = M.find(opts, filter)
  return views[#views], _opts
end

--- Gets the last open view matching the filter or creates a new one.
---@param opts? trouble.Config|string
---@param filter? trouble.View.filter
---@return trouble.View, trouble.Open
function M.get(opts, filter)
  local view, _opts = M.find_last(opts, filter)
  if not view or _opts.new then
    if not _opts.mode then
      error("No mode specified")
    end
    view = View.new(_opts)
  end
  return view, _opts
end

---@param opts? trouble.Open|string
function M.open(opts)
  local view, _opts = M.get(opts)
  if view then
    view:open()
    if _opts.focus ~= false then
      view.win:focus()
    end
    return view, _opts
  end
end

--- Returns true if there is an open view matching the filter.
---@param opts? trouble.Config|string
function M.is_open(opts)
  return M.find_last(opts) ~= nil
end

---@param opts? trouble.Config|string
function M.close(opts)
  local view = M.find_last(opts)
  if view then
    view:close()
  end
end

---@param opts? trouble.Open|string
function M.toggle(opts)
  if M.is_open(opts) then
    M.close(opts)
  else
    M.open(opts)
  end
end

--- Special case for refresh. Refresh all open views.
---@param opts? trouble.Config|string
function M.refresh(opts)
  for _, view in ipairs(M.find(opts)) do
    view:refresh()
  end
end

--- Proxy to last view's action.
---@param action trouble.Action|string
function M.action(action)
  action = type(action) == "string" and Actions[action] or action
  ---@cast action trouble.Action
  return function(opts)
    local view = M.open(opts)
    view:action(action, opts)
    return view
  end
end

---@param opts? trouble.Config|string
function M.get_items(opts)
  local view = M.find_last(opts)
  local ret = {} ---@type trouble.Item[]
  if view then
    for _, items in pairs(view.items) do
      vim.list_extend(ret, items)
    end
  end
  return ret
end

return setmetatable(M, {
  __index = function(_, k)
    return M.action(k)
  end,
})
