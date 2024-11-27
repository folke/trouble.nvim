local Render = require("trouble.view.render")
local Util = require("trouble.util")

---@alias trouble.Preview {item:trouble.Item, win:number, buf: number, close:fun()}

local M = {}
M.preview = nil ---@type trouble.Preview?

function M.is_open()
  return M.preview ~= nil
end

function M.is_win(win)
  return M.preview and M.preview.win == win
end

function M.item()
  return M.preview and M.preview.item
end

function M.close()
  local preview = M.preview
  M.preview = nil
  if not preview then
    return
  end
  Render.reset(preview.buf)
  preview.close()
end

--- Create a preview buffer for an item.
--- If the item has a loaded buffer, use that,
--- otherwise create a new buffer.
---@param item trouble.Item
---@param opts? {scratch?:boolean}
function M.create(item, opts)
  opts = opts or {}

  local buf = item.buf or vim.fn.bufnr(item.filename)

  if item.filename and vim.fn.isdirectory(item.filename) == 1 then
    return
  end

  -- create a scratch preview buffer when needed
  if not (buf and vim.api.nvim_buf_is_loaded(buf)) then
    if opts.scratch then
      buf = vim.api.nvim_create_buf(false, true)
      vim.bo[buf].bufhidden = "wipe"
      vim.bo[buf].buftype = "nofile"
      local lines = Util.get_lines({ path = item.filename, buf = item.buf })
      if not lines then
        return
      end
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
      local ft = item:get_ft(buf)
      if ft then
        local lang = vim.treesitter.language.get_lang(ft)
        if not pcall(vim.treesitter.start, buf, lang) then
          vim.bo[buf].syntax = ft
        end
      end
    else
      item.buf = vim.fn.bufadd(item.filename)
      buf = item.buf

      if not vim.api.nvim_buf_is_loaded(item.buf) then
        vim.fn.bufload(item.buf)
      end
      if not vim.bo[item.buf].buflisted then
        vim.bo[item.buf].buflisted = true
      end
    end
  end

  return buf
end

---@param view trouble.View
---@param item trouble.Item
---@param opts? {scratch?:boolean}
function M.open(view, item, opts)
  if M.item() == item then
    return
  end
  if M.preview and M.preview.item.filename ~= item.filename then
    M.close()
  end

  if not M.preview then
    local buf = M.create(item, opts)
    if not buf then
      return
    end

    M.preview = M.preview_win(buf, view)

    M.preview.buf = buf
  end
  M.preview.item = item

  Render.reset(M.preview.buf)

  -- make sure we highlight at least one character
  local end_pos = { item.end_pos[1], item.end_pos[2] }
  if end_pos[1] == item.pos[1] and end_pos[2] == item.pos[2] then
    end_pos[2] = end_pos[2] + 1
  end

  -- highlight the line
  Util.set_extmark(M.preview.buf, Render.ns, item.pos[1] - 1, 0, {
    end_row = end_pos[1],
    hl_group = "CursorLine",
    hl_eol = true,
    strict = false,
    priority = 150,
  })

  -- highlight the range
  Util.set_extmark(M.preview.buf, Render.ns, item.pos[1] - 1, item.pos[2], {
    end_row = end_pos[1] - 1,
    end_col = end_pos[2],
    hl_group = "TroublePreview",
    strict = false,
    priority = 160,
  })
  local _, source = require("trouble.sources").get(item.source)
  if source and source.preview then
    source.preview(item, M.preview)
  end

  -- no autocmds should be triggered. So LSP's etc won't try to attach in the preview
  Util.noautocmd(function()
    if pcall(vim.api.nvim_win_set_cursor, M.preview.win, item.pos) then
      vim.api.nvim_win_call(M.preview.win, function()
        vim.cmd("norm! zzzv")
      end)
    end
  end)

  return item
end

---@param buf number
---@param view trouble.View
function M.preview_win(buf, view)
  if view.opts.preview.type == "main" then
    local main = view:main()
    if not main then
      Util.debug("No main window")
      return
    end
    view.preview_win.opts.win = main.win
  else
    view.preview_win.opts.win = view.win.win
  end

  view.preview_win:open()
  Util.noautocmd(function()
    view.preview_win:set_buf(buf)
    view.preview_win:set_options("win")
    vim.w[view.preview_win.win].trouble_preview = true
  end)

  return {
    win = view.preview_win.win,
    close = function()
      view.preview_win:close()
    end,
  }
end

return M
