local Cache = require("trouble.cache")
local Util = require("trouble.util")

---@alias trouble.Pos {[1]:number, [2]:number}
---@class trouble.Range
---@field pos trouble.Pos
---@field end_pos trouble.Pos

---@class trouble.Item: {[string]: any}
---@field id? string
---@field parent? trouble.Item
---@field buf? number
---@field filename string
---@field pos trouble.Pos (1,0)-indexed
---@field end_pos? trouble.Pos (1,0)-indexed
---@field item table<string,any>
---@field source string
---@field cache table<string,any>
---@field range? trouble.Range
local M = {}

---@param opts trouble.Item | {filename?:string}
function M.new(opts)
  local self = opts
  assert(self.source, "source is required")
  self.pos = self.pos or { 1, 0 }
  self.pos[1] = math.max(self.pos[1] or 1, 1)
  self.pos[2] = math.max(self.pos[2] or 0, 0)
  self.end_pos = self.end_pos or self.pos
  self.item = self.item or {}
  if self.buf and not self.filename then
    self.filename = vim.api.nvim_buf_get_name(self.buf)
    if self.filename == "" then
      self.filename = "[buffer:" .. self.buf .. "]"
    end
  end
  assert(self.filename, "filename is required")
  if self.filename then
    self.filename = vim.fs.normalize(self.filename)
    local parts = vim.split(self.filename, "/", { plain = true })
    self.basename = table.remove(parts)
    self.dirname = table.concat(parts, "/")
  end
  self.cache = Cache.new("item")
  return setmetatable(self, M)
end

---@param items trouble.Item[]
---@param fields? string[]
function M.add_id(items, fields)
  for _, item in ipairs(items) do
    if not item.id then
      local id = {
        item.source,
        item.filename,
        item.pos[1] or "",
        item.pos[2] or "",
        item.end_pos[1] or "",
        item.end_pos[2] or "",
      }
      for _, field in ipairs(fields or {}) do
        table.insert(id, item[field] or "")
      end
      item.id = table.concat(id, ":")
    end
  end
end

---@return string?
function M:get_ft(buf)
  if self.buf and vim.api.nvim_buf_is_loaded(self.buf) then
    return vim.bo[self.buf].filetype
  end
  if not self.filename then
    return
  end
  local ft = Cache.ft[self.filename]
  if ft == nil then
    -- HACK: make sure we always pass a valid buf,
    -- otherwise some detectors will fail hard (like ts)
    ft = vim.filetype.match({ filename = self.filename, buf = buf or 0 })
    Cache.ft[self.filename] = ft or false -- cache misses too
  end
  return ft
end

function M:get_lang(buf)
  local ft = self:get_ft(buf)
  return ft and ft ~= "" and vim.treesitter.language.get_lang(ft) or nil
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
    }) or {}
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
