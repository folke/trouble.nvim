local Cache = require("trouble.cache")
local Format = require("trouble.format")
local Indent = require("trouble.view.indent")
local Text = require("trouble.view.text")
local Util = require("trouble.util")

---@class trouble.Render: trouble.Text
---@field _locations {item?: trouble.Item, node?: trouble.Item}[] Maps line numbers to items.
---@field _folded table<string, true>
---@field root_nodes trouble.Node[]
---@field foldlevel? number
---@field foldenable boolean
---@field max_depth number
---@field opts trouble.Render.opts
local M = setmetatable({}, Text)
M.__index = M

---@class trouble.Render.opts: trouble.Text.opts
---@field indent? trouble.Indent.symbols
---@field formatters? table<string, trouble.Formatter>

---@param opts? trouble.Render.opts|trouble.Text.opts
function M.new(opts)
  local text = Text.new(opts)
  ---@type trouble.Render
  ---@diagnostic disable-next-line: assign-type-mismatch
  local self = setmetatable(text, M)
  self._folded = {}
  self.foldenable = true
  self:clear()
  return self
end

---@alias trouble.Render.fold_opts {action?: "open"|"close"|"toggle", recursive?: boolean}
---@param node trouble.Node
---@param opts? trouble.Render.fold_opts
function M:fold(node, opts)
  self.foldenable = true
  opts = opts or {}
  local action = opts.action or "toggle"
  local id = node.id
  if action == "toggle" then
    if self._folded[id] then
      action = "open"
    else
      action = "close"
    end
  end
  local stack = { node }
  while #stack > 0 do
    local n = table.remove(stack)
    if action == "open" then
      self._folded[n.id] = nil
      local parent = n.parent
      while parent do
        self._folded[parent.id] = nil
        parent = parent.parent
      end
    else
      self._folded[n.id] = true
    end
    if opts.recursive then
      for _, c in ipairs(n.nodes or {}) do
        table.insert(stack, c)
      end
    end
  end
end

---@param opts {level?:number, add?:number}
function M:fold_level(opts)
  self.foldenable = true
  self.foldlevel = self.foldlevel or self.max_depth or 0
  if opts.level then
    self.foldlevel = opts.level
  end
  if opts.add then
    self.foldlevel = self.foldlevel + opts.add
  end
  self.foldlevel = math.min(self.max_depth, self.foldlevel)
  self.foldlevel = math.max(0, self.foldlevel)
  local stack = {}
  for _, node in ipairs(self.root_nodes) do
    table.insert(stack, node)
  end
  while #stack > 0 do
    local node = table.remove(stack)
    if node.depth > self.foldlevel then
      self._folded[node.id] = true
    else
      self._folded[node.id] = nil
    end
    for _, c in ipairs(node.nodes or {}) do
      table.insert(stack, c)
    end
  end
end

function M:clear()
  Cache.langs:clear()
  self.max_depth = 0
  self._lines = {}
  self.ts_regions = {}
  self._locations = {}
  self.root_nodes = {}
end

---@param section trouble.Section
---@param nodes trouble.Node[]
function M:section(section, nodes)
  self.max_depth = math.max(self.max_depth, #section.groups)
  for n, node in ipairs(nodes) do
    table.insert(self.root_nodes, node)
    self:node(node, section, Indent.new(self.opts.indent), n == #nodes)
  end
end

function M:is_folded(node)
  return self.foldenable and self._folded[node.id]
end

---@param node trouble.Node
---@param section trouble.Section
---@param indent trouble.Indent
---@param is_last boolean
function M:node(node, section, indent, is_last)
  if node.item then
    ---@type trouble.Indent.type
    local symbol = self:is_folded(node) and "fold_closed"
      or node.depth == 1 and "fold_open"
      or is_last and "last"
      or "middle"
    indent:add(symbol)
    self:item(node.item, node, section.groups[node.depth].format, true, indent)
    indent:del()
  end

  if self:is_folded(node) then
    return -- don't render children
  end

  indent:add(is_last and "ws" or "top")

  -- internal node
  for i, n in ipairs(node.nodes or {}) do
    self:node(n, section, indent, i == #node.nodes)
  end

  -- leaf node
  for i, item in ipairs(node.items or {}) do
    local symbol = i == #node.items and "last" or "middle"
    indent:add(symbol)
    self:item(item, node, section.format, false, indent)
    indent:del()
  end

  indent:del()
end

--- Returns the item and node at the given row.
--- For a group, only the node is returned.
--- To get the group item used for formatting, use `node.items[1]`.
---@param row number
---@return {item?: trouble.Item, node?: trouble.Node}
function M:at(row)
  return self._locations[row] or {}
end

function M.get_lang(buf)
  local ret = Cache.langs[buf]
  if ret ~= nil then
    return ret
  end
  local ft = vim.api.nvim_buf_is_loaded(buf) and not vim.b[buf].trouble_preview and vim.bo[buf].filetype
    or vim.filetype.match({ buf = buf })
  if ft then
    local lang = vim.treesitter.language.get_lang(ft)
    if lang then
      Cache.langs[buf] = lang
      return lang
    end
  end
  Cache.langs[buf] = false
end

---@param item trouble.Item
---@param node trouble.Node
---@param format_string string
---@param is_group boolean
---@param indent trouble.Indent
function M:item(item, node, format_string, is_group, indent)
  local row = self:row()
  local cache_key = "render:" .. node.depth .. format_string

  ---@type TextSegment[]?
  local segments = not is_group and item.cache[cache_key]

  self:append(indent)
  if segments then
    self:append(segments)
  else
    local format = Format.format(format_string, { item = item, node = node, opts = self.opts })
    indent:multi_line()
    for _, ff in ipairs(format) do
      local text = self.opts.multiline and ff.text or ff.text:gsub("[\n\r]+", " ")
      local offset ---@type number? start column of the first line
      local first ---@type string? first line
      if ff.hl == "ts" then
        local lang = M.get_lang(item.buf)
        if lang then
          ff.hl = "ts." .. lang
        else
          ff.hl = nil
        end
      end
      for l, line in Util.lines(text) do
        if l == 1 then
          first = line
        else
          -- PERF: most items are single line, so do heavy lifting only when more than one line
          offset = offset or (self:col({ display = true }) - vim.fn.strdisplaywidth(first or ""))
          self:nl()
          self:append(indent)
          local indent_width = indent:width({ display = true })
          -- align to item column
          if offset > indent_width then
            self:append((" "):rep(offset - indent_width))
          end
        end
        self:append(line, {
          hl = ff.hl,
          line = l,
        })
      end
    end
    -- NOTE:
    -- * don't cache groups, since they can contain aggregates.
    -- * don't cache multi-line items
    -- * don't cache the indent part of the line
    if not is_group and self:row() == row then
      item.cache[cache_key] = vim.list_slice(self._lines[#self._lines], #indent + 1)
    end
  end

  for r = row, self:row() do
    self._locations[r] = {
      item = not is_group and item or nil,
      node = node,
    }
  end

  self:nl()
end

return M
