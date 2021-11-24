local util = require("trouble.util")
local qf = require("trouble.providers.qf")
local telescope = require("trouble.providers.telescope")
local lsp = require("trouble.providers.lsp")

local M = {}

M.providers = {
  lsp_workspace_diagnostics = lsp.diagnostics,
  lsp_document_diagnostics = lsp.diagnostics,
  lsp_references = lsp.references,
  lsp_implementations = lsp.implementations,
  lsp_definitions = lsp.definitions,
  lsp_type_definitions = lsp.type_definitions,
  quickfix = qf.qflist,
  loclist = qf.loclist,
  telescope = telescope.telescope,
}

---@param options TroubleOptions
function M.get(win, buf, cb, options)
  local name = options.mode
  local provider = M.providers[name]

  if not provider then
    local ok, mod = pcall(require, "trouble.providers." .. name)
    if ok then
      M.providers[name] = mod
      provider = mod
    end
  end

  if not provider then
    util.error(("invalid provider %q"):format(name))
    return {}
  end

  provider(win, buf, function(items)
    table.sort(items, function(a, b)
      if a.severity == b.severity then
        return a.lnum < b.lnum
      else
        return a.severity < b.severity
      end
    end)
    cb(items)
  end, options)
end

---@param items Item[]
---@return table<string, Item[]>
function M.group(items)
  local ret = {}
  for _, item in ipairs(items) do
    if ret[item.filename] == nil then
      ret[item.filename] = {}
    end
    table.insert(ret[item.filename], item)
  end
  return ret
end

return M
