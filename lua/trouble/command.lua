local Config = require("trouble.config")
local Parser = require("trouble.config.parser")
local Util = require("trouble.util")

local M = {}

---@param input string
function M.parse(input)
  local source, args = input:match("%s*(%S+)%s*(.*)$")
  if not source then
    Util.error("Invalid arguments: " .. input)
    return
  end
  return source, Parser.parse(args)
end

---@param line string
---@param col number
function M.complete(_, line, col)
  line = line:sub(1, col)
  local candidates = {} ---@type string[]
  local prefix = ""
  local source = line:match("Trouble%s+(%S*)$")
  if source then
    prefix = source
    candidates = Config.modes()
  else
    local args = line:match("Trouble%s+%S+%s*.*%s+(%S*)$")
    if args then
      prefix = args
      candidates = vim.tbl_keys(Config.get())
      candidates = vim.tbl_map(function(x)
        return x .. "="
      end, candidates)
    end
  end

  candidates = vim.tbl_filter(function(x)
    return tostring(x):find(prefix, 1, true) ~= nil
  end, candidates)
  table.sort(candidates)
  return candidates
end

function M.execute(input)
  if input.args:match("^%s*$") then
    vim.ui.select(Config.modes(), { prompt = "Select Trouble Mode:" }, function(mode)
      if mode then
        require("trouble").open({ mode = mode })
      end
    end)
  else
    local mode, opts = M.parse(input.args)
    if mode and opts then
      opts.mode = mode
      require("trouble").open(opts)
    end
  end
end

return M
