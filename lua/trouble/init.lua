local M = {}

---@param opts? trouble.Config
function M.setup(opts)
  require("trouble.config").setup(opts)
end

---@param opts trouble.Config|string
function M.open(opts)
  opts = require("trouble.config").get(opts)
  require("trouble.view").new(opts):open()
end

return M
