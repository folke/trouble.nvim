local config = require("trouble.config")

local M = {}

function M.count(tab)
  local count = 0
  for _ in pairs(tab) do
    count = count + 1
  end
  return count
end

function M.log(msg, hl)
  hl = hl or "MsgArea"
  vim.api.nvim_echo({ { "[Trouble] ", hl }, { msg } }, true, {})
end

function M.warn(msg)
  M.log(msg, "WarningMsg")
end

function M.error(msg)
  M.log(msg, "Error")
end

function M.debug(msg)
  if config.options.debug then
    M.log(msg)
  end
end

function M.debounce(ms, fn)
  local timer = vim.loop.new_timer()
  return function(...)
    local argv = { ... }
    timer:start(ms, 0, function()
      timer:stop()
      vim.schedule_wrap(fn)(unpack(argv))
    end)
  end
end

function M.throttle(ms, fn)
  local timer = vim.loop.new_timer()
  local running = false
  return function(...)
    if not running then
      local argv = { ... }
      local argc = select("#", ...)

      timer:start(ms, 0, function()
        running = false
        pcall(vim.schedule_wrap(fn), unpack(argv, 1, argc))
      end)
      running = true
    end
  end
end

M.severity = {
  [0] = "Other",
  [1] = "Error",
  [2] = "Warning",
  [3] = "Information",
  [4] = "Hint",
}

-- based on the Telescope diagnostics code
-- see https://github.com/nvim-telescope/telescope.nvim/blob/0d6cd47990781ea760dd3db578015c140c7b9fa7/lua/telescope/utils.lua#L85

function M.process_item(item, bufnr)
  local filename = vim.api.nvim_buf_get_name(bufnr)
  local uri = vim.uri_from_bufnr(bufnr)
  local start = item.range["start"]
  local finish = item.range["end"]
  local row = start.line
  local col = start.character

  if not item.message then
    local line
    if vim.lsp.util.get_line then
      line = vim.lsp.util.get_line(uri, row)
    else
      -- load the buffer when needed
      vim.fn.bufload(bufnr)
      line = (vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false) or { "" })[1]
    end

    item.message = item.message or line or ""
  end

  ---@class Item
  ---@field is_file boolean
  ---@field fixed boolean
  local ret
  ret = {
    bufnr = bufnr,
    filename = filename,
    lnum = row + 1,
    col = col + 1,
    start = start,
    finish = finish,
    sign = item.sign,
    sign_hl = item.sign_hl,
    -- remove line break to avoid display issues
    text = vim.trim(item.message:gsub("[\n]", "")):sub(0, vim.o.columns),
    full_text = vim.trim(item.message),
    type = M.severity[item.severity] or M.severity[0],
    code = item.code,
    source = item.source,
    severity = item.severity or 0,
  }
  return ret
end

-- takes either a table indexed by bufnr, or an lsp result with uri
---@return Item[]
function M.locations_to_items(results, default_severity)
  default_severity = default_severity or 0
  local ret = {}
  for bufnr, locs in pairs(results or {}) do
    for _, loc in pairs(locs.result or locs) do
      if not vim.tbl_isempty(loc) then
        local buf = loc.uri and vim.uri_to_bufnr(loc.uri) or bufnr
        loc.severity = loc.severity or default_severity
        table.insert(ret, M.process_item(loc, buf))
      end
    end
  end
  return ret
end

-- @private
local function make_position_param(win, buf)
  local row, col = unpack(vim.api.nvim_win_get_cursor(win))
  row = row - 1
  local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, true)[1]
  if not line then
    return { line = 0, character = 0 }
  end
  col = vim.str_utfindex(line, col)
  return { line = row, character = col }
end

function M.make_text_document_params(buf)
  return { uri = vim.uri_from_bufnr(buf) }
end

--- Creates a `TextDocumentPositionParams` object for the current buffer and cursor position.
---
-- @returns `TextDocumentPositionParams` object
-- @see https://microsoft.github.io/language-server-protocol/specifications/specification-current/#textDocumentPositionParams
function M.make_position_params(win, buf)
  return {
    textDocument = M.make_text_document_params(buf),
    position = make_position_param(win, buf),
  }
end

return M
