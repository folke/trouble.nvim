---@class trouble.CacheM: {[string]: trouble.Cache}
local M = {}

---@type table<string, {name:string, hit: number, miss: number, ratio?:number}>
M.stats = {}

---@class trouble.Cache: {[string]: any}
---@field data table<string, any>
---@field name string
---@field size number
local C = {}

function C:__index(key)
  local ret = C[key]
  if ret then
    return ret
  end
  ret = self.data[key]
  M.stats[self.name] = M.stats[self.name] or { name = self.name, hit = 0, miss = 0 }
  local stats = M.stats[self.name]
  if ret ~= nil then
    stats.hit = stats.hit + 1
  else
    stats.miss = stats.miss + 1
  end
  return ret
end

function C:__newindex(key, value)
  if self.data[key] ~= nil and value == nil then
    self.size = self.size - 1
  elseif self.data[key] == nil and value ~= nil then
    self.size = self.size + 1
  end
  self.data[key] = value
end

function C:clear()
  self.data = {}
  self.size = 0
end

function M.new(name)
  return setmetatable({ data = {}, name = name, size = 0 }, C)
end

function M.report()
  for _, v in pairs(M.stats) do
    v.ratio = math.ceil(v.hit / (v.hit + v.miss) * 100)
  end
  return M.stats
end

function M.__index(_, k)
  M[k] = M.new(k)
  return M[k]
end

local ret = setmetatable(M, M)
return ret
