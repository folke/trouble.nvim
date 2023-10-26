local Config = require("trouble.config")
local Parser = require("trouble.config.parser")
local Util = require("trouble.util")

local M = {}

---@param prefix string
---@param line string
---@param col number
function M.complete(prefix, line, col)
  line = line:sub(1, col):match("Trouble%s*(.*)$")
  local parsed = M.parse(line)
  local candidates = {} ---@type string[]
  if vim.tbl_isempty(parsed.opts) then
    if not parsed.mode then
      vim.list_extend(candidates, Config.modes())
    else
      if not parsed.action then
        vim.list_extend(candidates, M.actions())
      end
      vim.list_extend(candidates, M.complete_opts())
    end
  else
    vim.list_extend(candidates, M.complete_opts())
  end
  candidates = vim.tbl_filter(function(x)
    return tostring(x):find(prefix, 1, true) == 1
  end, candidates)
  table.sort(candidates)
  return candidates
end

function M.complete_opts()
  local candidates = {} ---@type string[]
  local stack = { { k = "", t = Config.get() } }
  while #stack > 0 do
    local top = table.remove(stack)
    for k, v in pairs(top.t) do
      if k:match("^[a-z_]+$") then
        k = "." .. k
      else
        k = ("[%q]"):format(k)
      end
      local kk = top.k .. k
      candidates[#candidates + 1] = kk:gsub("^%.", "") .. "="
      if type(v) == "table" and not vim.tbl_islist(v) then
        table.insert(stack, { k = kk, t = v })
      end
    end
  end
  vim.list_extend(candidates, {
    "focus=true",
    "jump=true",
    "win.type=float",
    "win.type=split",
    "win.position=top",
    "win.position=bottom",
    "win.position=left",
    "win.position=right",
    "win.relative=editor",
    "win.relative=win",
  })
  return candidates
end

function M.actions()
  local actions = vim.tbl_keys(require("trouble.api"))
  vim.list_extend(actions, vim.tbl_keys(require("trouble.config.actions")))
  return actions
end

---@param input string
function M.parse(input)
  ---@type {mode: string, action: string, opts: trouble.Config, errors: string[], args: string[]}
  local ret = Parser.parse(input)
  local modes = Config.modes()
  local actions = M.actions()

  -- Args can be mode and/or action
  for _, a in ipairs(ret.args) do
    if vim.tbl_contains(modes, a) then
      ret.mode = a
    elseif vim.tbl_contains(actions, a) then
      ret.action = a
    else
      table.insert(ret.errors, "Unknown argument: " .. a)
    end
  end

  return ret
end

function M.execute(input)
  if input.args:match("^%s*$") then
    vim.ui.select(Config.modes(), { prompt = "Select Trouble Mode:" }, function(mode)
      if mode then
        require("trouble").open({ mode = mode })
      end
    end)
  else
    local ret = M.parse(input.args)
    ret.action = ret.action or "open"
    ret.opts.mode = ret.opts.mode or ret.mode
    if #ret.errors > 0 then
      Util.error("Error parsing command:\n- input: `" .. input.args .. "`\nErrors:\n" .. table.concat(ret.errors, "\n"))
      return
    end
    require("trouble")[ret.action](ret.opts)
  end
end

return M
