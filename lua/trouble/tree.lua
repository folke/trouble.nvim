---@class trouble.Node
---@field id string
---@field depth number
---@field parent? trouble.Node
---@field count? number
---@field item? trouble.Item
---@field items? trouble.Item[]
---@field nodes? trouble.Node[]
---@field index? table<string, trouble.Node>
local M = {}

---@param opts {id: string, depth: number, item?: trouble.Item}
function M.new(opts)
  local self = setmetatable(opts, { __index = M })
  self.nodes = {}
  self.index = {}
  self.items = {}
  self.count = 0
  return self
end

---@param idx number|string
function M:get(idx)
  return type(idx) == "number" and self.nodes[idx] or self.index[idx]
end

function M:add(node)
  assert(self.index[node.id] == nil, "node already exists")
  self.index[node.id] = node
  node.parent = self
  table.insert(self.nodes, node)
  return node
end

function M:is_leaf()
  return not self:is_group()
end

function M:is_group()
  return self.nodes and #self.nodes > 0
end

---@param item trouble.Item
---@param group trouble.Group
function M.get_group_id(item, group)
  local fields = group.fields
  if #fields == 0 then
    return group.format
  end
  local id = tostring(item[fields[1]])
  if #fields > 1 then
    for i = 2, #fields do
      id = id .. "|" .. tostring(item[fields[i]])
    end
  end
  return id
end

---@param items trouble.Item[]
---@param section trouble.Section
function M.build(items, section)
  local root = M.new({ depth = 0, id = "" })
  for i, item in ipairs(items) do
    if section.max_items and i > section.max_items then
      break
    end
    local node = root
    for depth, group in ipairs(section.groups) do
      -- id is based on the parent id and the group fields
      local id = node.id .. "#" .. M.get_group_id(item, group)
      local child = node:get(id)
      if not child then
        child = M.new({ depth = depth, id = id, item = item })
        node:add(child)
      end
      node = child
      node.count = node.count + 1
    end
    table.insert(node.items, item)
  end
  -- dd(root)
  return root
end

return M
