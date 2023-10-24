local Render = require("trouble.view.render")
local Util = require("trouble.util")

local M = {}
M.preview = nil ---@type {win:number,buf:number,view:table,cursor:number[]}?

function M.close()
  local preview = M.preview
  M.preview = nil
  if not (preview and vim.api.nvim_buf_is_valid(preview.buf)) then
    return
  end
  Render.reset(preview.buf)
  if vim.api.nvim_win_is_valid(preview.win) then
    local other = vim.api.nvim_win_get_buf(preview.win)
    Render.reset(other)
    Util.noautocmd(function()
      vim.api.nvim_win_set_buf(preview.win, preview.buf)
      vim.api.nvim_win_call(preview.win, function()
        vim.fn.winrestview(preview.view)
      end)
      -- if the buffer we are previewing wasn't previously loaded,
      -- unload it again
      if vim.b[other].trouble_preview then
        vim.api.nvim_buf_delete(other, { unload = true })
        vim.b[other].trouble_preview = nil
      end
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
    cursor = vim.api.nvim_win_get_cursor(main.win),
  }

  -- prevent the buffer from being loaded with eventignore
  -- highlight with treesitter if possible, otherwise use syntax
  -- no autocmds should be triggered. So LSP's etc won't attach in the preview
  Util.noautocmd(function()
    if not vim.api.nvim_buf_is_loaded(item.buf) then
      vim.bo[item.buf].swapfile = false
      pcall(vim.fn.bufload, item.buf)
      -- vim.api.nvim_del_autocmd(autocmd)
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

  vim.api.nvim_buf_set_extmark(item.buf, Render.ns, item.pos[1] - 1, 0, {
    end_row = end_pos[1],
    -- end_col = end_pos[2],
    hl_group = "CursorLine",
    hl_eol = true,
    strict = false,
  })
  -- only highlight the range if it's on the same line
  vim.api.nvim_buf_set_extmark(item.buf, Render.ns, item.pos[1] - 1, item.pos[2], {
    end_row = end_pos[1] - 1,
    end_col = end_pos[2],
    hl_group = "TroublePreview",
    strict = false,
  })
  return item
end

return M
