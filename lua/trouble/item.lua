local Cache = require("trouble.cache")

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

return M
