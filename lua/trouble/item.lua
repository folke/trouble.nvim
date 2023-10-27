local Cache = require("trouble.cache")
local Util = require("trouble.util")

---@alias trouble.Pos {[1]:number, [2]:number}

---@class trouble.Item: {[string]: any}
---@field id? string
---@field parent? trouble.Item
---@field buf number
---@field filename string
---@field pos trouble.Pos (1,0)-indexed
---@field end_pos? trouble.Pos (1,0)-indexed
---@field item table<string,any>
---@field source string
---@field cache table<string,any>
local M = {}

---@param opts trouble.Item | {filename?:string}
function M.new(opts)
  local self = opts
  assert(self.buf, "buf is required")
  assert(self.source, "source is required")
  self.pos = self.pos or { 1, 0 }
  self.end_pos = self.end_pos or self.pos
  self.item = self.item or {}
  self.filename = self.filename or vim.fn.bufname(self.buf)
  self.filename = vim.fn.fnamemodify(self.filename, ":p")
  self.basename = vim.fn.fnamemodify(self.filename, ":t")
  self.dirname = self.dirname or vim.fn.fnamemodify(self.filename, ":h")
  self.cache = Cache.new("item")
  return setmetatable(self, M)
end

function M:__index(k)
  if type(k) ~= "string" then
    return
  end
  if M[k] then
    return M[k]
  end
  local item = rawget(self, "item")
  ---@cast k string
  if item and item[k] ~= nil then
    return item[k]
  end

  local obj = self
  local start = 1
  while type(obj) == "table" do
    local dot = k:find(".", start, true)
    if not dot then
      if start == 1 then
        return
      end
      local ret = obj[k:sub(start)]
      rawset(self, k, ret)
      return ret
    end
    local key = k:sub(start, dot - 1)
    obj = obj[key]
    start = dot + 1
  end
end

---@param item trouble.Item
function M:add_child(item)
  item.parent = self
end

---@param items trouble.Item[]
---@param opts? {mode?:"range"|"full"|"after", multiline?:boolean}
function M.add_text(items, opts)
  opts = opts or {}
  opts.mode = opts.mode or "range"
  local todo = {} ---@type table<string, {buf?:number, rows:number[]}>

  for _, item in ipairs(items) do
    if not item.item.text and item.filename then
      -- schedule to get the lines
      todo[item.filename] = todo[item.filename] or { rows = {} }
      todo[item.filename].buf = todo[item.filename].buf or item.buf
      for r = item.pos[1], item.end_pos and item.end_pos[1] or item.pos[1] do
        table.insert(todo[item.filename].rows, r)
        if not opts.multiline then
          break
        end
      end
    end
  end

  -- get the lines and range text
  local buf_lines = {} ---@type table<string, table<number, string>>
  for path, t in pairs(todo) do
    buf_lines[path] = Util.get_lines({
      rows = t.rows,
      buf = t.buf,
      path = path,
    })
  end
  for _, item in ipairs(items) do
    if not item.item.text and item.filename then
      local lines = {} ---@type string[]
      for row = item.pos[1], item.end_pos[1] do
        local line = buf_lines[item.filename][row] or ""
        if row == item.pos[1] and row == item.end_pos[1] then
          if opts.mode == "after" then
            line = line:sub(item.pos[2] + 1)
          elseif opts.mode == "range" then
            line = line:sub(item.pos[2] + 1, item.end_pos[2])
          end
        elseif row == item.pos[1] then
          line = line:sub(item.pos[2] + 1)
        elseif row == item.end_pos[1] then
          line = line:sub(1, item.end_pos[2]) --[[@as string]]
        end
        if line ~= "" then
          lines[#lines + 1] = line
        end
      end
      item.item.text = table.concat(lines, "\n")
    end
  end
  return items
end

return M
