local M = {}

function M.setup()
  local msg = "trouble.nvim v3 is merged on main.\nThe dev branch is EOL."
  vim.notify_once(msg, vim.log.levels.ERROR, { title = "trouble.nvim" })
  error(msg)
end

return M
