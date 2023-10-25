local M = {}

---@alias trouble.FilterFn fun(item:trouble.Item, value: any, view:trouble.View): boolean
---@type table<string, trouble.FilterFn>
M.filters = {
  buf = function(item, buf, view)
    local main = view:main()
    buf = buf == 0 and main and main.buf or buf
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
  kind = function(item, kind, view)
    kind = type(kind) == "table" and kind or { kind }
    return vim.tbl_contains(kind, item.kind)
  end,
}

---@param item trouble.Item
---@param filter trouble.Filter
---@param view trouble.View
function M.is(item, filter, view)
  filter = type(filter) == "table" and filter or { filter }
  local is = true
  for k, v in pairs(filter) do
    if type(k) == "number" then
      if type(v) == "function" then
        if not v(item) then
          is = false
          break
        end
      elseif not item[v] then
        is = false
        break
      end
    elseif view.opts.filters[k] or M.filters[k] then
      local f = view.opts.filters[k] or M.filters[k]
      if not f(item, v, view) then
        is = false
        break
      end
    elseif item[k] ~= v then
      is = false
      break
    end
  end
  return is
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
