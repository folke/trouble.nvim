local Preview = require("trouble.view.preview")

---@class trouble.Main
---@field win number
---@field buf number
---@field filename string
---@field cursor trouble.Pos

local M = {}
M._main = nil ---@type trouble.Main?

function M.setup()
  local group = vim.api.nvim_create_augroup("trouble.main", { clear = true })
  vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
    group = group,
    callback = function()
      local buf = vim.api.nvim_get_current_buf()
      local win = vim.api.nvim_get_current_win()
      if M._valid(win, buf) then
        M.set(M._find())
      end
    end,
  })
  M.set(M._find())
end

---@param main trouble.Main
function M.set(main)
  M._main = main
end

function M._valid(win, buf)
  if Preview.is_win(win) or vim.w[win].trouble then
    return false
  end
  if vim.api.nvim_win_get_config(win).relative ~= "" then
    return false
  end
  if vim.bo[buf].buftype ~= "" then
    return false
  end
  return true
end

---@private
function M._find()
  local wins = vim.api.nvim_list_wins()
  table.insert(wins, 1, vim.api.nvim_get_current_win())
  for _, win in ipairs(wins) do
    local b = vim.api.nvim_win_get_buf(win)
    if M._valid(win, b) then
      return M._info(win)
    end
  end
end

---@private
---@return trouble.Main
function M._info(win)
  local b = vim.api.nvim_win_get_buf(win)
  return {
    win = win,
    buf = b,
    filename = vim.fs.normalize(vim.api.nvim_buf_get_name(b)),
    cursor = vim.api.nvim_win_get_cursor(win),
  }
end

---@param main? trouble.Main
---@return trouble.Main?
function M.get(main)
  main = main or M._main

  local valid = main
    and main.win
    and vim.api.nvim_win_is_valid(main.win)
    and main.buf
    and vim.api.nvim_buf_is_valid(main.buf)
    and M._valid(main.win, main.buf)

  if not valid then
    main = M._find()
  end
  -- Always return a main window even if it is not valid
  main = main or M._info(vim.api.nvim_get_current_win())
  -- update the cursor, unless the preview is showing in the main window
  if main and not Preview.is_win(main.win) and vim.api.nvim_win_get_buf(main.win) == main.buf then
    main.cursor = vim.api.nvim_win_get_cursor(main.win)
  end
  return main
end

return M
