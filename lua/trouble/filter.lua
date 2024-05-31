local Util = require("trouble.util")

local M = {}

---@class trouble.ViewFilter.opts
---@field id? string
---@field template? string
---@field data? table<string, any>
---@field toggle? boolean
---@field del? boolean

---@class trouble.ViewFilter
---@field id string
---@field filter trouble.Filter
---@field template? string
---@field data? table<string, any>

---@param opts? {lines:boolean}
---@param range trouble.Range
---@param pos trouble.Pos
function M.overlaps(pos, range, opts)
  if opts and opts.lines then
    return pos[1] >= range.pos[1] and pos[1] <= range.end_pos[1]
  else
    return (pos[1] > range.pos[1] or (pos[1] == range.pos[1] and pos[2] >= range.pos[2]))
      and (pos[1] < range.end_pos[1] or (pos[1] == range.end_pos[1] and pos[2] <= range.end_pos[2]))
  end
end

---@alias trouble.Filter.ctx {opts:trouble.Config, main?:trouble.Main}
---@alias trouble.FilterFn fun(item:trouble.Item, value: any, ctx:trouble.Filter.ctx): boolean
---@class trouble.Filters: {[string]: trouble.FilterFn}
M.filters = {
  buf = function(item, buf, ctx)
    if buf == 0 then
      return ctx.main and ctx.main.filename == item.filename or false
    end
    return item.buf == buf
  end,
  ---@param fts string|string[]
  ft = function(item, fts, _)
    fts = type(fts) == "table" and fts or { fts }
    local ft = item.buf and vim.bo[item.buf].filetype
    return ft and vim.tbl_contains(fts, ft) or false
  end,
  range = function(item, buf, ctx)
    local main = ctx.main
    if not main or (main.buf ~= item.buf) then
      return false
    end
    local range = item.range --[[@as trouble.Range]]
    if range then
      return M.overlaps(main.cursor, range, { lines = true })
    else
      return M.overlaps(main.cursor, item, { lines = true })
    end
  end,
  ["not"] = function(item, filter, ctx)
    ---@cast filter trouble.Filter
    return not M.is(item, filter, ctx)
  end,
  any = function(item, any, ctx)
    ---@cast any trouble.Filter[]
    for k, f in pairs(any) do
      if type(k) == "string" then
        f = { [k] = f }
      end
      if M.is(item, f, ctx) then
        return true
      end
    end
    return false
  end,
}

---@param item trouble.Item
---@param filter trouble.Filter
---@param ctx trouble.Filter.ctx
function M.is(item, filter, ctx)
  if type(filter) == "table" and Util.islist(filter) then
    for _, f in ipairs(filter) do
      if not M.is(item, f, ctx) then
        return false
      end
    end
    return true
  end

  filter = type(filter) == "table" and filter or { filter }
  for k, v in pairs(filter) do
    ---@type trouble.FilterFn?
    local filter_fn = ctx.opts.filters and ctx.opts.filters[k] or M.filters[k]
    if filter_fn then
      if not filter_fn(item, v, ctx) then
        return false
      end
    elseif type(k) == "number" then
      if type(v) == "function" then
        if not v(item) then
          return false
        end
      elseif not item[v] then
        return false
      end
    elseif type(v) == "table" then
      if not vim.tbl_contains(v, item[k]) then
        return false
      end
    elseif item[k] ~= v then
      return false
    end
  end
  return true
end

---@param items trouble.Item[]
---@param filter? trouble.Filter
---@param ctx trouble.Filter.ctx
function M.filter(items, filter, ctx)
  -- fast path for empty filter
  if not filter or (type(filter) == "table" and vim.tbl_isempty(filter)) then
    return items, {}
  end
  if type(filter) == "function" then
    return filter(items)
  end
  local ret = {} ---@type trouble.Item[]
  for _, item in ipairs(items) do
    if M.is(item, filter, ctx) then
      ret[#ret + 1] = item
    end
  end
  return ret
end

return M
