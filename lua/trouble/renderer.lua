local util = require("trouble.util")
local config = require("trouble.config")

---@class Renderer
local renderer = {}

renderer.signs = {}

function renderer.get_icon(file)
  local ok, icons = pcall(require, "nvim-web-devicons")
  if not ok then
    util.warn(
      "'nvim-web-devicons' is not installed. Install it, or set icons=false in your configuration to disable this message"
    )
    return ""
  end
  local fname = vim.fn.fnamemodify(file, ":t")
  local ext = vim.fn.fnamemodify(file, ":e")
  return icons.get_icon(fname, ext, { default = true })
end

function renderer.update_signs()
  renderer.signs = config.options.signs
  if config.options.use_diagnostic_signs then
    local lsp_signs = require("trouble.providers.diagnostic").get_signs()
    renderer.signs = vim.tbl_deep_extend("force", {}, renderer.signs, lsp_signs)
  end
end

return renderer
