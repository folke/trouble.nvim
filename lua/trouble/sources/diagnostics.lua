---@diagnostic disable: inject-field
local Item = require("trouble.item")

---@class trouble.Source.diagnostics: trouble.Source
local M = {}

M.highlights = {
  Message = "TroubleText",
  ItemSource = "Comment",
  Code = "Comment",
}

M.config = {
  modes = {
    diagnostics = {
      desc = "diagnostics",
      events = { "DiagnosticChanged", "BufEnter" },
      -- Trouble classic for other buffers,
      -- but only if they are in the current directory
      source = "diagnostics",
      groups = {
        -- { format = "{hl:Special}󰚢 {hl} {hl:Title}Diagnostics{hl} {count}" },
        -- { "severity", format = "{severity_icon} {severity} {count}" },
        -- { "dirname", format = "{hl:Special} {hl} {dirname} {count}" },
        { "directory" },
        { "filename", format = "{file_icon} {basename} {count}" },
      },
      sort = { "severity", "filename", "pos", "message" },
      format = "{severity_icon} {message:md} {item.source} {code} {pos}",
      -- filter = {
      -- ["not"] = {
      --   any = {
      --     { severity = vim.diagnostic.severity.ERROR },
      --     { buf = 0 },
      --   },
      -- },
      -- function(item)
      --   return item.filename:find((vim.loop or vim.uv).cwd(), 1, true)
      -- end,
      -- },
    },
    -- {
    --   -- error from all files
    --   source = "diagnostics",
    --   groups = { "severity", "code", "filename" },
    --   filter = {
    --     -- severity = 1,
    --   },
    --   sort = { "filename", "pos" },
    --   format = "sig {severity_sign} {severity} file: {filename} pos: {pos}",
    -- },
    -- {
    --   -- diagnostics from current buffer
    --   source = "diagnostics",
    --   groups = { "severity", "filename" },
    --   filter = {
    --     buf = 0,
    --   },
    --   sort = { "pos" },
    -- },
  },
}

---@type table<number, trouble.Item[]>
local cache = {}

function M.setup()
  vim.api.nvim_create_autocmd("DiagnosticChanged", {
    group = vim.api.nvim_create_augroup("trouble.diagnostics", { clear = true }),
    callback = function(event)
      -- NOTE: unfortunately, we can't use the event.data.diagnostics table here,
      -- since multiple namespaces exist and we can't tell which namespace the
      -- diagnostics are from.
      cache[event.buf] = vim.tbl_map(M.item, vim.diagnostic.get(event.buf))
      cache[0] = nil
    end,
  })
  for _, diag in ipairs(vim.diagnostic.get()) do
    local buf = diag.bufnr
    if buf and vim.api.nvim_buf_is_valid(buf) then
      cache[buf] = cache[buf] or {}
      table.insert(cache[buf], M.item(diag))
      Item.add_id(cache[buf], { "item.source", "severity", "code" })
    end
  end
end

---@param diag vim.Diagnostic
function M.item(diag)
  return Item.new({
    source = "diagnostics",
    buf = diag.bufnr,
    pos = { diag.lnum + 1, diag.col },
    end_pos = { diag.end_lnum and (diag.end_lnum + 1) or nil, diag.end_col },
    item = diag,
  })
end

---@param cb trouble.Source.Callback
---@param ctx trouble.Source.ctx)
function M.get(cb, ctx)
  -- PERF: pre-filter when possible
  local buf = type(ctx.opts.filter) == "table" and ctx.opts.filter.buf or nil

  if buf == 0 then
    buf = ctx.main.buf
  end

  if buf then
    cb(cache[buf] or {})
  else
    if not cache[0] then
      cache[0] = {}
      for b, items in pairs(cache) do
        if b ~= 0 then
          if vim.api.nvim_buf_is_valid(b) then
            for _, item in ipairs(items) do
              table.insert(cache[0], item)
            end
          else
            cache[b] = nil
          end
        end
      end
    end
    cb(cache[0])
  end
end

return M
