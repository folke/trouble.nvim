local Render = require("trouble.view.render")
local Util = require("trouble.util")

local M = {}
M.preview = nil ---@type {win:number,buf:number,view:table}?

function M.close()
  local preview = M.preview
  if not (preview and vim.api.nvim_buf_is_valid(preview.buf)) then
    return
  end
  M.preview = nil
  Render.reset(preview.buf)
  if vim.api.nvim_win_is_valid(preview.win) then
    Util.noautocmd(function()
      vim.api.nvim_win_set_buf(preview.win, preview.buf)
      vim.api.nvim_win_call(preview.win, function()
        vim.fn.winrestview(preview.view)
      end)
    end)
  end
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

  M.preview = {
    win = main.win,
    buf = main.buf,
    view = vim.api.nvim_win_call(main.win, vim.fn.winsaveview),
  }

  -- prevent the buffer from being loaded with eventignore
  -- highlight with treesitter if possible, otherwise use syntax
  -- no autocmds should be triggered. So LSP's etc won't attach in the preview
  Util.noautocmd(function()
    if not vim.api.nvim_buf_is_loaded(item.buf) then
      vim.b[item.buf].trouble_preview = true
      local ft = vim.filetype.match({ buf = item.buf })
      if ft then
        local lang = vim.treesitter.language.get_lang(ft)
        if not pcall(vim.treesitter.start, item.buf, lang) then
          vim.bo[item.buf].syntax = ft
        end
      end
    end
    vim.api.nvim_win_set_buf(main.win, item.buf)
    vim.api.nvim_win_set_cursor(main.win, item.pos)
  end)

  local end_pos = item.end_pos or item.pos
  end_pos[1] = end_pos[1] or item.pos[1]
  end_pos[2] = end_pos[2] or item.pos[2]
  if end_pos[1] == item.pos[1] and end_pos[2] == item.pos[2] then
    end_pos[2] = end_pos[2] + 1
  end
  vim.api.nvim_buf_set_extmark(item.buf, Render.ns, item.pos[1] - 1, item.pos[2], {
    end_row = end_pos[1] - 1,
    end_col = end_pos[2],
    hl_group = "TroublePreview",
    strict = false,
  })
  vim.api.nvim_buf_set_extmark(item.buf, Render.ns, item.pos[1] - 1, 0, {
    end_row = end_pos[1],
    -- end_col = end_pos[2],
    hl_group = "CursorLine",
    hl_eol = true,
    strict = false,
  })
  return item
end

return M
