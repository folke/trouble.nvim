local Cache = require("trouble.cache")
local Util = require("trouble.util")

local M = {}

---@alias trouble.spec.format string|trouble.Format|(string|trouble.Format)[]
---@alias trouble.Format {text:string, hl?:string}

---@alias trouble.Formatter fun(ctx: trouble.Formatter.ctx): trouble.spec.format?
---@alias trouble.Formatter.ctx {item: trouble.Item, node:trouble.Node, field:string, value:string, opts:trouble.Config}

---@param source string
---@param field string
function M.default_hl(source, field)
  if not source then
    return "Trouble" .. Util.camel(field)
  end
  local key = source .. field
  local value = Cache.default_hl[key]
  if value then
    return value
  end
  local hl = "Trouble" .. Util.camel(source) .. Util.camel(field)
  Cache.default_hl[key] = hl
  return hl
end

---@type (fun(file: string, ext: string): string, string)[]
local icons = {
  function(file)
    return require("mini.icons").get("file", file)
  end,
  function(file, ext)
    return require("nvim-web-devicons").get_icon(file, ext, { default = true })
  end,
}
function M.get_icon(file, ext)
  while #icons > 0 do
    local ok, icon, hl = pcall(icons[1], file, ext)
    if ok then
      return icon, hl
    end
    table.remove(icons, 1)
  end
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
      text = "[" .. ctx.item.pos[1] .. ", " .. (ctx.item.pos[2] + 1) .. "]",
    }
  end,
  code = function(ctx)
    if not ctx.item.code or ctx.item.code == vim.NIL then
      return
    end
    return {
      text = "(" .. ctx.item.code .. ")",
      hl = "TroubleCode",
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
    if type(severity) == "string" then
      severity = vim.diagnostic.severity[severity:upper()] or vim.diagnostic.severity.ERROR
    end
    local name = Util.camel(vim.diagnostic.severity[severity]:lower())
    local sign = vim.fn.sign_getdefined("DiagnosticSign" .. name)[1]
    if vim.fn.has("nvim-0.10.0") == 1 then
      local config = vim.diagnostic.config() or {}
      if config.signs == nil or type(config.signs) == "boolean" then
        return { text = sign and sign.text or name:sub(1, 1), hl = "DiagnosticSign" .. name }
      end
      local signs = config.signs or {}
      if type(signs) == "function" then
        signs = signs(0, 0) --[[@as vim.diagnostic.Opts.Signs]]
      end
      return {
        text = type(signs) == "table" and signs.text and signs.text[severity] or sign and sign.text or name:sub(1, 1),
        hl = "DiagnosticSign" .. name,
      }
    else
      return sign and { text = sign.text, hl = sign.texthl } or { text = name } or nil
    end
  end,
  file_icon = function(ctx)
    local item = ctx.item --[[@as Diagnostic|trouble.Item]]
    local file = vim.fn.fnamemodify(item.filename, ":t")
    local ext = vim.fn.fnamemodify(item.filename, ":e")
    local icon, color = M.get_icon(file, ext)
    return icon and { text = icon .. " ", hl = color } or ""
  end,
  count = function(ctx)
    return {
      text = (" %d "):format(ctx.node:count()),
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
  filter = function(ctx)
    return {
      text = vim.inspect(ctx.item.filter):gsub("%s+", " "),
      hl = "ts.lua",
    }
  end,
  kind_icon = function(ctx)
    if not ctx.item.kind then
      return
    end
    local icon = ctx.opts.icons.kinds[ctx.item.kind]
    if icon then
      return {
        text = icon,
        hl = "TroubleIcon" .. ctx.item.kind,
      }
    end
  end,
  directory = function(ctx)
    if ctx.node:source() == "fs" then
      local directory = ctx.item.directory or ""
      local parent = ctx.node:parent_item()
      if parent and parent.directory then
        directory = directory:sub(#parent.directory + 1)
        return { text = directory, hl = "TroubleDirectory" }
      end
      return { text = vim.fn.fnamemodify(directory, ":~"), hl = "TroubleDirectory" }
    end
  end,
  directory_icon = function(ctx)
    if ctx.node:source() == "fs" then
      local text = ctx.node.folded and ctx.opts.icons.folder_closed or ctx.opts.icons.folder_open
      return { text = text, hl = "TroubleIconDirectory" }
    end
  end,
}
M.formatters.severity_icon = M.cached_formatter(M.formatters.severity_icon, "severity")
M.formatters.severity = M.cached_formatter(M.formatters.severity, "severity")

---@param ctx trouble.Formatter.ctx
function M.field(ctx)
  ---@type trouble.Format[]
  local format = { { fi = ctx.field, text = vim.trim(tostring(ctx.item[ctx.field] or "")) } }

  local opts = ctx.opts

  local formatter = opts.formatters and opts.formatters[ctx.field] or M.formatters[ctx.field]

  if formatter then
    local result = formatter(ctx)
    if not result then
      return
    end
    result = type(result) == "table" and Util.islist(result) and result or { result }
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
---@param ctx {item: trouble.Item, node:trouble.Node, opts:trouble.Config}
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
