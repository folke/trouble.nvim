local Util = require("trouble.util")

---@class TextSegment
---@field str string Text
---@field hl? string Extmark hl group
---@field ts? string TreeSitter language
---@field line? number line number in a multiline segment
---@field width? number

---@alias Extmark {hl_group?:string, col?:number, row?:number, end_col?:number}

---@class trouble.Text.opts
---@field padding? number
---@field multiline? boolean

---@class trouble.Text
---@field _lines TextSegment[][]
---@field _col number
---@field _indents string[]
---@field opts trouble.Text.opts
local M = {}
M.__index = M

M.ns = vim.api.nvim_create_namespace("trouble.text")

function M.reset(buf)
  vim.api.nvim_buf_clear_namespace(buf, M.ns, 0, -1)
end

---@param opts? trouble.Text.opts
function M.new(opts)
  local self = setmetatable({}, M)
  self._lines = {}
  self._col = 0
  self.opts = opts or {}
  self.opts.padding = self.opts.padding or 0
  self._indents = {}
  for i = 0, 100, 1 do
    self._indents[i] = (" "):rep(i)
  end
  return self
end

function M:height()
  return #self._lines
end

function M:width()
  local width = 0
  for _, line in ipairs(self._lines) do
    local w = 0
    for _, segment in ipairs(line) do
      w = w + vim.fn.strdisplaywidth(segment.str)
    end
    width = math.max(width, w)
  end
  return width + ((self.opts.padding or 0) * 2)
end

---@param text string|TextSegment[]
---@param opts? string|{ts?:string, hl?:string, line?:number}
function M:append(text, opts)
  opts = opts or {}
  if #self._lines == 0 then
    self:nl()
  end

  if type(text) == "table" then
    for _, s in ipairs(text) do
      s.width = s.width or #s.str
      self._col = self._col + s.width
      table.insert(self._lines[#self._lines], s)
    end
    return self
  end

  opts = type(opts) == "string" and { hl = opts } or opts
  if opts.hl == "md" then
    opts.ts = "markdown"
  elseif opts.hl and opts.hl:sub(1, 3) == "ts." then
    opts.ts = opts.hl:sub(4)
  end

  for _, line in Util.lines(text) do
    local width = #line
    self._col = self._col + width
    table.insert(self._lines[#self._lines], {
      str = line,
      width = width,
      hl = opts.hl,
      ts = opts.ts,
      line = opts.line,
    })
  end
  return self
end

function M:nl()
  table.insert(self._lines, {})
  self._col = 0
  return self
end

function M:render(buf)
  local lines = {}

  local padding = (" "):rep(self.opts.padding)
  for _, line in ipairs(self._lines) do
    local parts = { padding }
    for _, segment in ipairs(line) do
      parts[#parts + 1] = segment.str
    end
    table.insert(lines, table.concat(parts, ""))
  end

  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_clear_namespace(buf, M.ns, 0, -1)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  local regions = {} ---@type table<string, number[][]>

  for l, line in ipairs(self._lines) do
    local col = self.opts.padding or 0
    local row = l - 1

    for _, segment in ipairs(line) do
      local width = segment.width
      if segment.ts then
        regions[segment.ts] = regions[segment.ts] or {}
        table.insert(regions[segment.ts], {
          row,
          col,
          row,
          col + width + 1,
        })
      elseif segment.hl then
        M.set_extmark(buf, row, col, { hl_group = segment.hl, end_col = col + width })
      end
      col = col + width
    end
  end

  for lang, r in pairs(regions) do
    local TS = require("trouble.view.treesitter")
    TS.highlight(buf, lang, r)
  end
  vim.bo[buf].modifiable = false
end

---@param buf number
---@param row number
---@param col number
---@param opts vim.api.keyset.set_extmark
---@param debug_info? any
function M.set_extmark(buf, row, col, opts, debug_info)
  local ok, err = pcall(vim.api.nvim_buf_set_extmark, buf, M.ns, row, col, opts)
  if not ok then
    vim.notify(
      "Failed to set extmark. Please report a bug with this info:\n"
        .. vim.inspect({ info = debug_info, row = row, col = col, opts = opts, error = err }),
      vim.log.levels.ERROR,
      { title = "trouble.nvim" }
    )
  end
end

function M:trim()
  while #self._lines > 0 and #self._lines[#self._lines] == 0 do
    table.remove(self._lines)
  end
end

function M:row()
  return #self._lines == 0 and 1 or #self._lines
end

---@param opts? {display:boolean}
function M:col(opts)
  if opts and opts.display then
    local ret = 0
    for _, segment in ipairs(self._lines[#self._lines] or {}) do
      ret = ret + vim.fn.strdisplaywidth(segment.str)
    end
    return ret
  end
  return self._col
end

return M
