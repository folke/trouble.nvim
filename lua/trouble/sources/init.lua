local Config = require("trouble.config")
local Util = require("trouble.util")

---@class trouble.Source
---@field highlights? table<string, string>
---@field config? trouble.Config
---@field setup? fun()
---@field get trouble.Source.get|table<string, trouble.Source.get>
---@field preview? fun(item:trouble.Item, ctx:trouble.Preview)

---@alias trouble.Source.ctx {main: trouble.Main, opts:trouble.Mode}
---@alias trouble.Source.Callback fun(items:trouble.Item[])
---@alias trouble.Source.get fun(cb:trouble.Source.Callback, ctx:trouble.Source.ctx)

local M = {}
---@type table<string, trouble.Source>
M.sources = {}

---@param name string
---@param source? trouble.Source
function M.register(name, source)
  if M.sources[name] then
    error("source already registered: " .. name)
  end
  source = source or require("trouble.sources." .. name)
  if source then
    if source.setup then
      source.setup()
    end
    require("trouble.config.highlights").source(name, source.highlights)
    if source.config then
      Config.defaults(source.config)
    end
  end
  M.sources[name] = source
  return source
end

---@param source string
function M.get(source)
  local parent, child = source:match("^(.-)%.(.*)$")
  source = parent or source
  local s = M.sources[source] or M.register(source)
  if child and type(s.get) ~= "table" then
    error("source does not support sub-sources: " .. source)
  elseif child and type(s.get[child]) ~= "function" then
    error("source does not support sub-source: " .. source .. "." .. child)
  end
  return (child and s.get[child] or s.get), s
end

function M.load()
  local rtp = vim.api.nvim_get_runtime_file("lua/trouble/sources/*.lua", true)
  for _, file in ipairs(rtp) do
    local name = file:match("lua[/\\]trouble[/\\]sources[/\\](.*)%.lua")
    if name and name ~= "init" and not M.sources[name] then
      Util.try(function()
        M.register(name)
      end, { msg = "Error loading source: " .. name })
    end
  end
end

return M
