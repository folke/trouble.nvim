---@diagnostic disable: inject-field
local methods = vim.lsp.protocol.Methods
local Item = require("trouble.item")
local get_col = vim.lsp.util._get_line_byte_from_position

---@type trouble.Source
local M = {}

M.config = {
  views = {},
  modes = {
    lsp = {
      sections = { "lsp_definitions", "lsp_references", "lsp_implementations", "lsp_type_definitions" },
    },
  },
}

for _, mode in ipairs({ "definitions", "references", "implementations", "type_definitions" }) do
  M.config.views["lsp_" .. mode] = {
    title = "{hl:Title}" .. mode:gsub("^%l", string.upper) .. "{hl} {count}",
    events = { "CursorHold" },
    -- events = { "CursorHold", "CursorMoved" },
    source = "lsp." .. mode,
    groups = {
      { "filename", format = "{file_icon} {filename} {count}" },
    },
    sort = { { buf = 0 }, "filename", "pos", "text" },
    format = "{text:ts} ({item.client}) {pos}",
  }
end

---@param method string
---@param cb trouble.Source.Callback
---@param context? any lsp params context
function M.get_locations(method, cb, context)
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_get_current_buf()
  ---@type lsp.TextDocumentPositionParams
  local params = vim.lsp.util.make_position_params(win)
  ---@diagnostic disable-next-line: inject-field
  params.context = context

  local clients = vim.lsp.get_clients({ method = method, bufnr = buf })

  local items = {} ---@type trouble.Item[]
  local done = 0
  if #clients == 0 then
    return cb(items)
  end
  for _, client in ipairs(clients) do
    vim.lsp.buf_request(buf, method, params, function(_, result)
      done = done + 1
      if result then
        vim.list_extend(items, M.get_items(client, result))
      end
      if done == #clients then
        cb(items)
      end
    end)
  end
end

---@param client lsp.Client
---@param locations? lsp.Location[]|lsp.LocationLink[]|lsp.Location
function M.get_items(client, locations)
  locations = locations or {}
  locations = vim.tbl_islist(locations) and locations or { locations }
  ---@cast locations (lsp.Location|lsp.LocationLink)[]
  local items = {} ---@type trouble.Item[]

  for _, loc in ipairs(locations) do
    local range = loc.range or loc.targetSelectionRange
    local uri = loc.uri or loc.targetUri
    local buf = vim.uri_to_bufnr(uri)
    local pos = { range.start.line + 1, get_col(buf, range.start, client.offset_encoding) }
    local end_pos = { range["end"].line + 1, get_col(buf, range["end"], client.offset_encoding) }
    items[#items + 1] = Item.new({
      buf = buf,
      filename = vim.uri_to_fname(uri),
      pos = pos,
      end_pos = end_pos,
      item = {
        client_id = client.id,
        client = client.name,
        location = loc,
      },
      source = "lsp",
    })
  end

  Item.add_text(items)
  return items
end

M.get = {}

---@param cb trouble.Source.Callback
function M.get.references(cb)
  M.get_locations(methods.textDocument_references, cb, { includeDeclaration = true })
end

---@param cb trouble.Source.Callback
function M.get.definitions(cb)
  M.get_locations(methods.textDocument_definition, cb)
end

---@param cb trouble.Source.Callback
function M.get.implementations(cb)
  M.get_locations(methods.textDocument_implementation, cb)
end

-- Type Definitions
---@param cb trouble.Source.Callback
function M.get.type_definitions(cb)
  M.get_locations(methods.textDocument_typeDefinition, cb)
end

return M
