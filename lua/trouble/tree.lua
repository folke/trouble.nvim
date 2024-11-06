local Item = require("trouble.item")
local Util = require("trouble.util")

---@class trouble.Node
---@field id string
---@field parent? trouble.Node
---@field item? trouble.Item
---@field index? table<string, trouble.Node>
---@field group? trouble.Group
---@field folded? boolean
---@field children? trouble.Node[]
---@field private _depth number
---@field private _count? number
---@field private _degree? number
local M = {}

---@alias trouble.GroupFn fun(item: trouble.Item, parent: trouble.Node, group: trouble.Group): trouble.Node

---@param opts {id: string, item?: trouble.Item}
function M.new(opts)
  local self = setmetatable(opts, { __index = M })
  self.id = self.id or self.item and self.item.id or nil
  self.children = {}
  self.index = {}
  return self
end

function M:delete()
  local parent = self.parent
  if not parent then
    return
  end
  if parent.children then
    parent.children = vim.tbl_filter(function(c)
      return c ~= self
    end, parent.children)
  end
  if parent.index and self.id then
    parent.index[self.id] = nil
  end
  parent._count = nil
  parent._degree = nil
  if parent:count() == 0 then
    parent:delete()
  end
end

-- Max depth of the tree
function M:degree()
  if not self._degree then
    self._degree = 0
    for _, child in ipairs(self.children or {}) do
      self._degree = math.max(self._degree, child:degree())
    end
    self._degree = self._degree + 1
  end
  return self._degree
end

-- Depth of this node
function M:depth()
  if not self._depth then
    self._depth = self.parent and (self.parent:depth() + 1) or 0
  end
  return self._depth
end

-- Number of actual items in the tree
-- This excludes internal group nodes
function M:count()
  if not self._count then
    self._count = 0
    for _, child in ipairs(self.children or {}) do
      self._count = self._count + child:count()
    end
    if not self.group and self.item then
      self._count = self._count + 1
    end
  end
  return self._count
end

--- Gets all the items in the tree, recursively.
---@param ret trouble.Item[]?
function M:flatten(ret)
  ret = ret or {}
  for _, child in ipairs(self.children or {}) do
    child:flatten(ret)
  end
  if not self.group and self.item then
    ret[#ret + 1] = self.item
  end
  return ret
end

---@param idx number|string
---@return trouble.Node?
function M:get(idx)
  return type(idx) == "number" and self.children[idx] or self.index[idx]
end

-- Source of the item of this node
function M:source()
  return self.item and self.item.source
end

-- Width of the node (number of children)
function M:width()
  return self.children and #self.children or 0
end

-- Item of the parent node
function M:parent_item()
  return self.parent and self.parent.item
end

function M:add(node)
  if node.id then
    if self.index[node.id] then
      Util.debug("node already exists:\n" .. node.id)
      node.id = node.id .. "_"
    end
    self.index[node.id] = node
  end
  node.parent = self
  table.insert(self.children, node)
  return node
end

function M:is_leaf()
  return self.children == nil or #self.children == 0
end

---@param other? trouble.Node
function M:is(other)
  if not other then
    return false
  end

  if self == other then
    return true
  end

  if self.id ~= other.id then
    return false
  end

  if self.group ~= other.group then
    return false
  end

  if self.group then
    return true
  end
  assert(self.item, "missing item")

  if not other.item then
    return false
  end

  if self.item == other.item then
    return true
  end

  return self.item.id and (self.item.id == other.item.id)
end

--- Build a tree from a list of items and a section.
---@param items trouble.Item[]
---@param section trouble.Section.opts
function M.build(items, section)
  local root = M.new({ id = "$root" })
  local node_items = {} ---@type table<trouble.Node, trouble.Item[]>

  -- create the group nodes
  for i, item in ipairs(items) do
    if section.max_items and i > section.max_items then
      break
    end
    local node = root
    for _, group in ipairs(section.groups) do
      local builder = M.builders[group.directory and "directory" or "fields"]
      if not builder then
        assert(builder, "unknown group type: " .. vim.inspect(group))
      end
      node = builder.group(item, node, group)
    end
    node_items[node] = node_items[node] or {}
    table.insert(node_items[node], item)
  end

  -- add the items to the nodes.
  -- this will structure items by their parent node unless flatten is true
  for node, nitems in pairs(node_items) do
    M.add_items(node, nitems, { flatten = section.flatten })
  end

  -- post process the tree
  for _, group in ipairs(section.groups) do
    local builder = M.builders[group.directory and "directory" or "fields"]
    if builder.post then
      root = builder.post(root) or root
    end
  end
  return root
end

--- This will add all the items to the root node,
--- structured by their parent item, unless flatten is true.
---@param root trouble.Node
---@param items trouble.Item[]
---@param opts? {flatten?: boolean}
function M.add_items(root, items, opts)
  opts = opts or {}
  local item_nodes = {} ---@type table<trouble.Item, trouble.Node>
  for _, item in ipairs(items) do
    item_nodes[item] = M.new({ item = item })
  end
  for _, item in ipairs(items) do
    local node = item_nodes[item]
    local parent_node = root
    if not opts.flatten then
      local parent = item.parent
      while parent do
        if item_nodes[parent] then
          parent_node = item_nodes[parent]
          break
        end
        parent = parent.parent
      end
    end
    parent_node:add(node)
  end
end

---@alias trouble.Group.builder {group:trouble.GroupFn, post?:(fun(node: trouble.Node):trouble.Node?)}
---@type table<"directory"|"fields", trouble.Group.builder>
M.builders = {
  fields = {
    group = function(item, parent, group)
      -- id is based on the parent id and the group fields
      local id = group.format
      if #group.fields > 0 then
        local values = {} ---@type string[]
        for i = 1, #group.fields do
          values[#values + 1] = tostring(item[group.fields[i]])
        end
        id = table.concat(values, "|")
      end
      id = parent.id .. "#" .. id
      local child = parent:get(id)
      if not child then
        child = M.new({ id = id, item = item, group = group })
        parent:add(child)
      end
      return child
    end,
  },

  directory = {
    group = function(item, root, group)
      if not item.dirname then
        return root
      end
      local directory = ""
      local parent = root
      for _, part in Util.split(item.dirname, "/") do
        directory = directory .. part .. "/"
        local id = (root.id or "") .. "#" .. directory
        local child = parent:get(id)
        if not child then
          local dir = Item.new({
            filename = directory,
            source = "fs",
            id = id,
            pos = { 1, 0 },
            end_pos = { 1, 0 },
            dirname = directory,
            item = { directory = directory, type = "directory" },
          })
          child = M.new({ id = id, item = dir, group = group })
          parent:add(child)
        end
        parent = child
      end
      return parent
    end,
    post = function(root)
      ---@param node trouble.Node
      local function collapse(node)
        if node:source() == "fs" then
          if node:width() == 1 then
            local child = node.children[1]
            if child:source() == "fs" and child.item.type == "directory" then
              child.parent = node.parent
              return collapse(child)
            end
          end
        end
        for c, child in ipairs(node.children or {}) do
          node.children[c] = collapse(child)
        end
        return node
      end
      return collapse(root)
    end,
  },
}

return M
