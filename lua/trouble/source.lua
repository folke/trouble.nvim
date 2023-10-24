local Config = require("trouble.config")
local Util = require("trouble.util")

---@class trouble.Source
---@field highlights? table<string, string>
---@field config? trouble.Config
---@field setup? fun()
---@field get trouble.Source.get|table<string, trouble.Source.get>

---@class trouble.Source.

---@alias trouble.Source.ctx {filter?:trouble.Filter, view:trouble.View}
---@alias trouble.Source.Callback fun(items:trouble.Item[])
---@alias trouble.Source.get fun(cb:trouble.Source.Callback, ctx: trouble.Source.ctx)

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
      source.config.modes = source.config.modes or {}
      for view in pairs(source.config.views or {}) do
        source.config.modes[view] = source.config.modes[view] or {
          sections = { view },
        }
      end
      Config.defaults(source.config)
    end
  end
  M.sources[name] = source
  return source
end

---@param source string
---@param cb trouble.Source.Callback
---@param ctx trouble.Source.ctx
function M.get(source, cb, ctx)
  local parent, child = source:match("^(.-)%.(.*)$")
  source = parent or source
  local s = M.sources[source] or M.register(source)
  if child and type(s.get) ~= "table" then
    Util.error("source does not support sub-sources: " .. source)
    return cb({})
  elseif child and type(s.get[child]) ~= "function" then
    Util.error("source does not support sub-source: " .. source .. "." .. child)
    return cb({})
  end
  local get = child and s.get[child] or s.get
  M.call_in_main(function()
    get(cb, ctx)
  end, ctx)
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

---@param fn function
---@param ctx trouble.Source.ctx
function M.call_in_main(fn, ctx)
  local current = {
    win = vim.api.nvim_get_current_win(),
    buf = vim.api.nvim_get_current_buf(),
    cursor = vim.api.nvim_win_get_cursor(0),
  }
  local main = ctx and ctx.view and ctx.view:main() or current

  -- if we're still in the main window,
  -- we can just call the function directly
  if
    main.win == current.win
    and main.buf == current.buf
    and main.cursor[1] == current.cursor[1]
    and main.cursor[2] == current.cursor[2]
  then
    return fn()
  end

  -- otherwise, we need to temporarily move to the main window
  vim.api.nvim_win_call(main.win, function()
    Util.noautocmd(function()
      local buf = vim.api.nvim_win_get_buf(main.win)
      local view = vim.fn.winsaveview()
      vim.api.nvim_win_set_buf(main.win, main.buf)
      vim.api.nvim_win_set_cursor(main.win, main.cursor)
      fn()
      vim.api.nvim_win_set_buf(main.win, buf)
      vim.fn.winrestview(view)
    end)
  end)
end

return M
