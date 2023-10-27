local Render = require("trouble.view.render")
local Util = require("trouble.util")

local M = {}
M.preview = nil ---@type {win:number,buf:number,view:table,cursor:number[], preview_buf:number}?

function M.close()
  local preview = M.preview
  M.preview = nil
  if not (preview and vim.api.nvim_buf_is_valid(preview.buf)) then
    return
  end
  Render.reset(preview.preview_buf)
  if vim.api.nvim_win_is_valid(preview.win) then
    Util.noautocmd(function()
      vim.api.nvim_win_set_buf(preview.win, preview.buf)
      vim.api.nvim_win_call(preview.win, function()
        vim.fn.winrestview(preview.view)
      end)
    end)
  end
end

--- Create a preview buffer for an item.
--- If the item has a loaded buffer, use that,
--- otherwise create a new buffer.
---@param item trouble.Item
function M.create(item)
  local buf = item.buf or vim.fn.bufnr(item.filename)

  if buf and vim.api.nvim_buf_is_loaded(buf) then
    return buf
  end

  buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  local lines = Util.get_lines({ path = item.filename, buf = item.buf })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  local ft = item:get_ft()
  if ft then
    local lang = vim.treesitter.language.get_lang(ft)
    if not pcall(vim.treesitter.start, buf, lang) then
      vim.bo[buf].syntax = ft
    end
  end
  return buf
end

---@param view trouble.View
---@param item trouble.Item
function M.open(view, item)
  if M.preview then
    M.close()
  end

  local main = view:main()
  if not main then
    Util.debug("No main window")
    return
  end

  if not vim.api.nvim_buf_is_valid(item.buf) then
    Util.debug("Item has invalid buffer", item)
    return
  end

  local buf = M.create(item)

  M.preview = {
    win = main.win,
    buf = main.buf,
    view = vim.api.nvim_win_call(main.win, vim.fn.winsaveview),
    cursor = vim.api.nvim_win_get_cursor(main.win),
    preview_buf = buf,
  }

  -- no autocmds should be triggered. So LSP's etc won't try to attach in the preview
  Util.noautocmd(function()
    vim.api.nvim_win_set_buf(main.win, buf)
    vim.api.nvim_win_set_cursor(main.win, item.pos)
  end)

  local end_pos = item.end_pos or item.pos
  end_pos[1] = end_pos[1] or item.pos[1]
  end_pos[2] = end_pos[2] or item.pos[2]
  if end_pos[1] == item.pos[1] and end_pos[2] == item.pos[2] then
    end_pos[2] = end_pos[2] + 1
  end

  vim.api.nvim_buf_set_extmark(buf, Render.ns, item.pos[1] - 1, 0, {
    end_row = end_pos[1],
    -- end_col = end_pos[2],
    hl_group = "CursorLine",
    hl_eol = true,
    strict = false,
  })
  -- only highlight the range if it's on the same line
  vim.api.nvim_buf_set_extmark(buf, Render.ns, item.pos[1] - 1, item.pos[2], {
    end_row = end_pos[1] - 1,
    end_col = end_pos[2],
    hl_group = "TroublePreview",
    strict = false,
  })
  return item
end

return M
