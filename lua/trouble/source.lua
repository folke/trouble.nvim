local Util = require("trouble.util")

---@class trouble.Source
---@field highlights? table<string, string>
---@field modes? table<string,trouble.Mode>
---@field setup? fun()
---@field get fun(cb:trouble.Source.Callback, ctx: trouble.Source.ctx)

---@alias trouble.Source.ctx {filter?:trouble.Filter, view:trouble.View}
---@alias trouble.Source.Callback fun(items:trouble.Item[])

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
  if source and source.setup then
    source.setup()
    require("trouble.config.highlights").source(name, source.highlights)
  end
  if source and source.modes then
    require("trouble.config").register(source.modes)
  end
  M.sources[name] = source
  return source
end

---@param source string
---@param cb trouble.Source.Callback
---@param ctx trouble.Source.ctx
function M.get(source, cb, ctx)
  local s = M.sources[source] or M.register(source)
  s.get(cb, ctx)
end

function M.load()
  local rtp = vim.api.nvim_get_runtime_file("lua/trouble/sources/*.lua", true)
  for _, file in ipairs(rtp) do
    local name = file:match("lua/trouble/sources/(.*)%.lua")
    if name and not M.sources[name] and package.loaded["trouble.sources." .. name] == nil then
      Util.try(function()
        M.register(name)
      end, { msg = "Error loading source: " .. name })
    end
  end
end

return M
