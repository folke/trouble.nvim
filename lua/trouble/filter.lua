local M = {}

---@alias trouble.FilterFn fun(item:trouble.Item, value: any, view:trouble.View): boolean
---@class trouble.Filters: {[string]: trouble.FilterFn}
M.filters = {
  buf = function(item, buf, view)
    local main = view:main()
    if buf == 0 then
      return main and main.path == item.filename or false
    end
    return item.buf == buf
  end,
  ["not"] = function(item, filter, view)
    ---@cast filter trouble.Filter
    return not M.is(item, filter, view)
  end,
  any = function(item, any, view)
    ---@cast any trouble.Filter[]
    for _, f in ipairs(any) do
      if M.is(item, f, view) then
        return true
      end
    end
    return false
  end,
}

---@param item trouble.Item
---@param filter trouble.Filter
---@param view trouble.View
function M.is(item, filter, view)
  filter = type(filter) == "table" and filter or { filter }
  for k, v in pairs(filter) do
    ---@type trouble.FilterFn?
    local filter_fn = view.opts.filters[k] or M.filters[k]
    if filter_fn then
      if not filter_fn(item, v, view) then
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
---@param view trouble.View
function M.filter(items, filter, view)
  -- fast path for empty filter
  if not filter or (type(filter) == "table" and vim.tbl_isempty(filter)) then
    return items, {}
  end
  if type(filter) == "function" then
    return filter(items)
  end
  local ret = {} ---@type trouble.Item[]
  for _, item in ipairs(items) do
    if M.is(item, filter, view) then
      ret[#ret + 1] = item
    end
  end
  return ret
end

return M
