local Config = require("trouble.config")
local Docs = require("lazy.docs")
local LazyUtil = require("lazy.util")

local M = {}

function M.update()
  local config = Docs.extract("lua/trouble/config/init.lua", "\n(--@class trouble%.Mode.-\n})")
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

  local exclude = { "fs", "todo" }
  local modes = Config.modes()
  for _, mode in ipairs(modes) do
    if not vim.tbl_contains(exclude, mode) then
      local m = Config.get(mode)
      lines[#lines + 1] = ("- **%s**: %s"):format(mode, m.desc or "")
    end
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
    elseif line:match("^function") and not line:match("^function M%._") then
      f[#f + 1] = line:gsub("^function M", [[require("trouble")]])
      funcs[#funcs + 1] = table.concat(f, "\n")
      f = {}
    else
      f = {}
    end
  end

  lines = vim.split(LazyUtil.read_file("lua/trouble/config/actions.lua"), "\n")
  f = {}
  ---@type table<string, string>
  local comments = {}

  for _, line in ipairs(lines) do
    if line:match("^%s*%-%-") then
      f[#f + 1] = line:gsub("^%s*[%-]*%s*", "")
    elseif line:match("^%s*[%w_]+ = function") then
      local name = line:match("^%s*([%w_]+)")
      if not name:match("^_") and #f > 0 then
        comments[name] = table.concat(f, "\n")
      end
      f = {}
    else
      f = {}
    end
  end
  local Actions = require("trouble.config.actions")
  local names = vim.tbl_keys(Actions)
  table.sort(names)

  local exclude = { "close" }

  for _, k in ipairs(names) do
    local desc = comments[k] or k:gsub("_", " ")
    local action = Actions[k]
    if type(Actions[k]) == "table" then
      desc = action.desc or desc
      action = action.action
    end
    desc = table.concat(
      vim.tbl_map(function(line)
        return ("-- %s"):format(line)
      end, vim.split(desc, "\n")),
      "\n"
    )
    if type(action) == "function" and not vim.tbl_contains(exclude, k) then
      funcs[#funcs + 1] = ([[
%s
---@param opts? trouble.Mode | { new? : boolean } | string
---@return trouble.View
require("trouble").%s(opts)]]):format(desc, k)
    end
  end
  return { content = table.concat(funcs, "\n\n"), lang = "lua" }
end

M.update()
print("Updated docs")
-- M.api()

return M
