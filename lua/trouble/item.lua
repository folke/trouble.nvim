local Cache = require("trouble.cache")
local Util = require("trouble.util")

---@alias trouble.Pos {[1]:number, [2]:number}

---@class trouble.Item: {[string]: any}
---@field idx? number
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
  local self = setmetatable(opts, M)
  self.filename = self.filename or vim.fn.bufname(self.buf)
  self.filename = vim.fn.fnamemodify(self.filename, ":p")
  self.basename = vim.fn.fnamemodify(self.filename, ":t")
  self.dirname = vim.fn.fnamemodify(self.filename, ":h")
  self.cache = Cache.new("item")
  return self
end

function M:__index(k)
  if type(k) ~= "string" then
    return
  end
  ---@cast k string
  if self.item[k] ~= nil then
    return self.item[k]
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

---@param items trouble.Item[]
function M.add_text(items)
  local buf_rows = {} ---@type table<number, number[]>

  for _, item in ipairs(items) do
    if not item.item.text then
      -- schedule to get the lines
      buf_rows[item.buf] = buf_rows[item.buf] or {}
      for r = item.pos[1], item.end_pos and item.end_pos[1] or item.pos[1] do
        table.insert(buf_rows[item.buf], r)
      end
    end
  end

  -- get the lines and range text
  local buf_lines = {} ---@type table<number, table<number, string>>
  for buf, rows in pairs(buf_rows) do
    buf_lines[buf] = Util.get_lines(buf, rows)
  end
  for _, item in ipairs(items) do
    if not item.item.text then
      local lines = {} ---@type string[]
      for row = item.pos[1], item.end_pos[1] do
        local line = buf_lines[item.buf][row] or ""
        if row == item.pos[1] and row == item.end_pos[1] then
          line = line
        elseif row == item.pos[1] then
          line = line:sub(item.pos[2] + 1)
        elseif row == item.end_pos[1] then
          line = line:sub(1, item.end_pos[2]) --[[@as string]]
        end
        lines[#lines + 1] = line
      end
      item.item.text = table.concat(lines, "\n")
    end
  end
  return items
end

return M
