local Cache = require("trouble.cache")
local Util = require("trouble.util")

local M = {}

---@alias trouble.spec.format string|trouble.Format|(string|trouble.Format)[]
---@alias trouble.Format {text:string, hl?:string}

---@alias trouble.Formatter fun(ctx: trouble.Formatter.ctx): trouble.spec.format?
---@alias trouble.Formatter.ctx {item: trouble.Item, node:trouble.Node, field:string, value:string, opts:trouble.Render.opts}

---@param source string
---@param field string
function M.default_hl(source, field)
  local key = source .. field
  local value = Cache.default_hl[key]
  if value then
    return value
  end
  local hl = "Trouble" .. Util.camel(source) .. Util.camel(field)
  Cache.default_hl[key] = hl
  return hl
end

---@param fn trouble.Formatter
---@param field string
function M.cached_formatter(fn, field)
  local cache = {}
  ---@param ctx trouble.Formatter.ctx
  return function(ctx)
    local key = ctx.item.source .. field .. (ctx.item[field] or "")
    local result = cache[key]
    if result then
      return result
    end
    result = fn(ctx)
    cache[key] = result
    return result
  end
end

---@type table<string, trouble.Formatter>
M.formatters = {
  pos = function(ctx)
    return {
      text = "[" .. (ctx.item.pos[1] + 1) .. ", " .. ctx.item.pos[2] .. "]",
    }
  end,
  severity = function(ctx)
    local severity = ctx.item.severity or vim.diagnostic.severity.ERROR
    local name = vim.diagnostic.severity[severity] or "OTHER"
    return {
      text = name,
      hl = "Diagnostic" .. Util.camel(name:lower()),
    }
  end,
  severity_icon = function(ctx)
    local severity = ctx.item.severity or vim.diagnostic.severity.ERROR
    if not vim.diagnostic.severity[severity] then
      return
    end
    local name = Util.camel(vim.diagnostic.severity[severity]:lower())
    local sign = vim.fn.sign_getdefined("DiagnosticSign" .. name)[1]
    return sign and { text = sign.text, hl = sign.texthl } or { text = name or ctx.value }
  end,
  file_icon = function(ctx)
    local item = ctx.item --[[@as Diagnostic|trouble.Item]]
    local ok, icons = pcall(require, "nvim-web-devicons")
    if not ok then
      return ""
    end
    local fname = vim.fn.fnamemodify(item.filename, ":t")
    local ext = vim.fn.fnamemodify(item.filename, ":e")
    local icon, color = icons.get_icon(fname, ext, { default = true })
    return { text = icon .. " ", hl = color }
  end,
  count = function(ctx)
    return {
      text = (" %d "):format(ctx.node.count or 0),
    }
  end,
  filename = function(ctx)
    return {
      text = vim.fn.fnamemodify(ctx.item.filename, ":p:~:."),
    }
  end,
  dirname = function(ctx)
    return {
      text = vim.fn.fnamemodify(ctx.item.dirname, ":p:~:."),
    }
  end,
}
M.formatters.severity_icon = M.cached_formatter(M.formatters.severity_icon, "severity")
M.formatters.severity = M.cached_formatter(M.formatters.severity, "severity")

---@param ctx trouble.Formatter.ctx
function M.field(ctx)
  ---@type trouble.Format[]
  local format = { { fi = ctx.field, text = vim.trim(tostring(ctx.item[ctx.field] or "")) } }

  local formatter = ctx.opts and ctx.opts.formatters and ctx.opts.formatters[ctx.field] or M.formatters[ctx.field]

  if formatter then
    local result = formatter(ctx)
    if not result then
      return
    end
    result = type(result) == "table" and vim.tbl_islist(result) and result or { result }
    format = {}
    ---@cast result (string|trouble.Format)[]
    for _, f in ipairs(result) do
      ---@diagnostic disable-next-line: assign-type-mismatch
      format[#format + 1] = type(f) == "string" and { text = f } or f
    end
  end
  for _, f in ipairs(format) do
    f.hl = f.hl or M.default_hl(ctx.item.source, ctx.field)
  end
  return format
end

---@param format string
---@param ctx {item: trouble.Item, node:trouble.Node, opts:trouble.Render.opts}
function M.format(format, ctx)
  ---@type trouble.Format[]
  local ret = {}
  local hl ---@type string?
  while true do
    ---@type string?,string,string
    local before, fields, after = format:match("^(.-){(.-)}(.*)$")
    if not before then
      break
    end
    format = after
    if #before > 0 then
      ret[#ret + 1] = { text = before, hl = hl }
    end

    for _, field in Util.split(fields, "|") do
      ---@type string,string
      local field_name, field_hl = field:match("^(.-):(.+)$")
      if field_name then
        field = field_name
      end
      if field == "hl" then
        hl = field_hl
      else
        ---@cast ctx trouble.Formatter.ctx
        ctx.field = field
        ctx.value = ctx.item[field]
        local ff = M.field(ctx)
        if ff then
          for _, f in ipairs(ff) do
            if hl or field_hl then
              f.hl = field_hl or hl
            end
            ret[#ret + 1] = f
          end
          -- only render the first field
          break
        end
      end
    end
  end
  if #format > 0 then
    ret[#ret + 1] = { text = format, hl = hl }
  end
  return ret
end

return M
