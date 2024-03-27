local Filter = require("trouble.filter")

local M = {}

---@alias trouble.Sort.ctx {opts:trouble.Config, main?:trouble.Main}

---@type table<string, trouble.SorterFn>
M.sorters = {
  pos = function(obj)
    -- Use large multipliers for higher priority fields to ensure their precedence in sorting
    local primaryScore = obj.pos[1] * 1000000 + obj.pos[2] * 1000
    local secondaryScore = obj.end_pos[1] * 1000000 + obj.end_pos[2] * 1000

    return primaryScore + secondaryScore
  end,
}

---@param items trouble.Item[]
---@param opts? trouble.Sort[]
---@param ctx trouble.Sort.ctx
function M.sort(items, opts, ctx)
  if not opts or #opts == 0 then
    return items
  end

  local keys = {} ---@type table<trouble.Item, any[]>
  local desc = {} ---@type boolean[]

  -- pre-compute fields
  local fields = {} ---@type trouble.Sort[]
  for f, field in ipairs(opts) do
    if field.field then
      ---@diagnostic disable-next-line: no-unknown
      local sorter = ctx.opts.sorters and ctx.opts.sorters[field.field] or M.sorters[field.field]
      if sorter then
        fields[f] = { sorter = sorter }
      else
        fields[f] = { field = field.field }
      end
    else
      fields[f] = field
    end
    desc[f] = field.desc or false
  end

  -- pre-compute keys
  for _, item in ipairs(items) do
    local item_keys = {} ---@type any[]
    for f, field in ipairs(fields) do
      local key = nil
      if field.sorter then
        key = field.sorter(item)
      elseif field.field then
        ---@diagnostic disable-next-line: no-unknown
        key = item[field.field]
      elseif field.filter then
        key = Filter.is(item, field.filter, ctx)
      end
      if type(key) == "boolean" then
        key = key and 0 or 1
      end
      item_keys[f] = key
    end
    keys[item] = item_keys
  end

  -- sort items
  table.sort(items, function(a, b)
    local ka = keys[a]
    local kb = keys[b]
    for i = 1, #ka do
      local fa = ka[i]
      local fb = kb[i]
      if fa ~= fb then
        if desc[i] then
          return fa > fb
        else
          return fa < fb
        end
      end
    end
    return false
  end)
  return items
end

return M
