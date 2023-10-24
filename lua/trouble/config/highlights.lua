local Util = require("trouble.util")

local M = {}

local defaults = {
  -- General
  Normal = "NormalFloat",
  Text = "Normal",
  Preview = "Visual",
  -- Item
  FileName = "Directory",
  Source = "Comment",
  Pos = "LineNr",
  Count = "TabLineSel",
  -- Indent Guides
  Indent = "LineNr",
  IndentFoldClosed = "CursorLineNr",
  IndentFoldOpen = "TroubleIndent",
  IndentTop = "TroubleIndent",
  IndentMiddle = "TroubleIndent",
  IndentLast = "TroubleIndent",
  IndentWs = "TroubleIndent",
}

function M.setup()
  M.link(defaults)
end

---@param prefix? string
---@param links table<string, string>
function M.link(links, prefix)
  for k, v in pairs(links) do
    k = (prefix or "Trouble") .. k
    vim.api.nvim_set_hl(0, k, { link = v, default = true })
  end
end

---@param source string
---@param links? table<string, string>
function M.source(source, links)
  ---@type table<string, string>
  links = vim.tbl_extend("force", {
    FileName = "TroubleFileName",
    Source = "TroubleSource",
    Pos = "TroublePos",
    Count = "TroubleCount",
  }, links or {})
  M.link(links, "Trouble" .. Util.camel(source))
end

return M
