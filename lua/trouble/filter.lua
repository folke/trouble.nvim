local M = {}

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
    if not main then
      return false
    end
    local range = item.range --[[@as trouble.Item]]
    if range then
      return main.cursor[1] >= range.pos[1] and main.cursor[1] <= range.end_pos[1]
    else
      return main.cursor[1] >= item.pos[1] and main.cursor[1] <= item.end_pos[1]
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
