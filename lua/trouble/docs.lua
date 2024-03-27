local Config = require("trouble.config")
local Docs = require("lazy.docs")
local LazyUtil = require("lazy.util")

local M = {}

function M.update()
  local config = Docs.extract("lua/trouble/config/init.lua", "\n(--@class trouble%.Config.-\n})")
  config = config:gsub("%s*debug = false.\n", "\n")
  Docs.save({
    config = config,
    colors = Docs.colors({
      modname = "trouble.config.highlights",
      path = "lua/trouble/config/highlights.lua",
      name = "Trouble",
    }),
    modes = M.modes(),
    api = M.api(),
  })
end

---@return ReadmeBlock
function M.modes()
  ---@type string[]
  local lines = {}

  local modes = Config.modes()
  for _, mode in ipairs(modes) do
    local m = Config.get(mode)
    lines[#lines + 1] = ("- **%s**: %s"):format(mode, m.desc or "")
  end

  return { content = table.concat(lines, "\n") }
end

---@return ReadmeBlock
function M.api()
  local lines = vim.split(LazyUtil.read_file("lua/trouble/api.lua"), "\n")

  local funcs = {}

  ---@type string[]
  local f = {}

  for _, line in ipairs(lines) do
    if line:match("^%-%-") then
      f[#f + 1] = line
    elseif line:match("^function") then
      f[#f + 1] = line:gsub("^function M", [[require("trouble")]])
      funcs[#funcs + 1] = table.concat(f, "\n")
      f = {}
    else
      f = {}
    end
  end
  local Actions = require("trouble.config.actions")
  local names = vim.tbl_keys(Actions)
  table.sort(names)

  for _, k in ipairs(names) do
    local desc = k:gsub("_", " ")
    local action = Actions[k]
    if type(Actions[k]) == "table" then
      desc = action.desc or desc
      action = action.action
    end
    if type(action) == "function" then
      funcs[#funcs + 1] = ([[
-- %s
require("trouble").%s()]]):format(desc, k)
    end
  end
  return { content = table.concat(funcs, "\n\n"), lang = "lua" }
end

M.update()
-- M.api()

return M
