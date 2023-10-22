---@class TextSegment
---@field str string
---@field hl? string|Extmark
---@field width? number

---@alias Extmark {hl_group?:string, col?:number, end_col?:number}

---@class trouble.Text.opts
---@field padding? number

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

---@param text string|TextSegment[]
---@param hl? string|Extmark
---@param opts? {next_indent?: TextSegment[]}
function M:append(text, hl, opts)
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

  local nl = text:find("\n", 1, true)
  if nl then
    local start_col = 0
    local last = self._lines[#self._lines]
    for _, segment in ipairs(last) do
      start_col = start_col + vim.fn.strdisplaywidth(segment.str, start_col)
    end
    self:append(text:sub(1, nl - 1), hl, opts)
    -- change indent for next lines to the indent of the first line
    local extra_indent ---@type TextSegment?
    if opts.next_indent then
      local indent_width = 0
      for _, s in ipairs(opts.next_indent) do
        indent_width = indent_width + vim.fn.strdisplaywidth(s.str)
      end
      if start_col > indent_width then
        extra_indent = {
          str = (" "):rep(start_col - indent_width),
          width = start_col - indent_width,
        }
      end
    end
    local c = 0
    while nl do
      self:nl()
      c = nl + 1
      nl = text:find("\n", c, true)
      if opts.next_indent then
        self:append(opts.next_indent)
        if extra_indent then
          self:append({ extra_indent })
        end
      end
      self:append(text:sub(c, nl and (nl - 1) or nil), hl, opts)
    end
  else
    local width = #text
    self._col = self._col + width
    table.insert(self._lines[#self._lines], {
      str = text,
      width = width,
      hl = hl,
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
    local has_extmark = false
    for _, segment in ipairs(line) do
      parts[#parts + 1] = segment.str
      if type(segment.hl) == "table" then
        has_extmark = true
      end
    end
    local str = table.concat(parts, "")
    if not (has_extmark or str:find("%S")) then
      str = ""
    end
    table.insert(lines, str)
  end

  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_clear_namespace(buf, M.ns, 0, -1)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  for l, line in ipairs(self._lines) do
    if lines[l] ~= "" then
      local col = self.opts.padding

      for _, segment in ipairs(line) do
        local width = segment.width

        local extmark = segment.hl
        if extmark then
          if type(extmark) == "string" then
            extmark = { hl_group = extmark, end_col = col + width }
          end
          ---@cast extmark Extmark

          local extmark_col = extmark.col or col
          extmark.col = nil
          local ok, err = pcall(vim.api.nvim_buf_set_extmark, buf, M.ns, l - 1, extmark_col, extmark)
          if not ok then
            vim.notify(
              "Failed to set extmark. Please report a bug with this info:\n"
                .. vim.inspect({ segment = segment, line = line, error = err }),
              vim.log.levels.ERROR,
              { title = "trouble.nvim" }
            )
          end
        end

        col = col + width
      end
    end
  end
  vim.bo[buf].modifiable = false
end

---@param patterns table<string,string>
function M:highlight(patterns)
  local col = self.opts.padding
  local last = self._lines[#self._lines]
  ---@type TextSegment?
  local text
  for s, segment in ipairs(last) do
    if s == #last then
      text = segment
      break
    end
    col = col + vim.fn.strlen(segment.str)
  end
  if text then
    for pattern, hl in pairs(patterns) do
      local from, to, match = text.str:find(pattern)
      while from do
        if match then
          from, to = text.str:find(match, from, true)
        end
        self:append("", {
          col = col + from - 1,
          end_col = col + to,
          hl_group = hl,
        })
        from, to = text.str:find(pattern, to + 1)
      end
    end
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

function M:col()
  return self._col
end

return M
