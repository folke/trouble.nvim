---@diagnostic disable: inject-field
local methods = vim.lsp.protocol.Methods
local Item = require("trouble.item")
local get_col = vim.lsp.util._get_line_byte_from_position

---@type trouble.Source
---@diagnostic disable-next-line: missing-fields
local M = {}

---@diagnostic disable-next-line: missing-fields
M.config = {
  views = {
    lsp_document_symbols = {
      title = "{hl:Title}Document Symbols{hl} {count}",
      events = { "BufEnter", "BufWritePost", "BufReadPost" },
      -- events = { "CursorHold", "CursorMoved" },
      source = "lsp.document_symbols",
      flatten = false,
      groups = {
        { "filename", format = "{file_icon} {filename} {count}" },
      },
      sort = { { buf = 0 }, "filename", "pos", "text" },
      -- sort = { { buf = 0 }, { kind = "Function" }, "filename", "pos", "text" },
      format = "{kind_icon} {symbol.name} {text:Comment} {pos}",
    },
  },
  modes = {
    lsp = {
      sections = {
        "lsp_definitions",
        "lsp_references",
        "lsp_implementations",
        "lsp_type_definitions",
        "lsp_declarations",
      },
    },
  },
}

for _, mode in ipairs({ "definitions", "references", "implementations", "type_definitions", "declarations" }) do
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
---@param params? table
---@param cb fun(results: table<lsp.Client, any>)
function M.request(method, params, cb)
  local buf = vim.api.nvim_get_current_buf()
  local clients = vim.lsp.get_clients({ method = method, bufnr = buf })
  local results = {} ---@type table<lsp.Client, any>
  local done = 0
  if #clients == 0 then
    return cb(results)
  end
  for _, client in ipairs(clients) do
    vim.lsp.buf_request(buf, method, params, function(_, result)
      done = done + 1
      if result then
        results[client] = result
      end
      if done == #clients then
        cb(results)
      end
    end)
  end
end

---@param method string
---@param cb trouble.Source.Callback
---@param context? any lsp params context
function M.get_locations(method, cb, context)
  local win = vim.api.nvim_get_current_win()
  ---@type lsp.TextDocumentPositionParams
  local params = vim.lsp.util.make_position_params(win)
  ---@diagnostic disable-next-line: inject-field
  params.context = context

  M.request(method, params, function(results)
    local items = {} ---@type trouble.Item[]
    for client, result in pairs(results) do
      vim.list_extend(items, M.get_items(client, result))
    end
    cb(items)
  end)
end

M.get = {}
---@param cb trouble.Source.Callback
function M.get.document_symbols(cb)
  ---@type lsp.DocumentSymbolParams
  local params = { textDocument = vim.lsp.util.make_text_document_params() }

  M.request(methods.textDocument_documentSymbol, params, function(results)
    ---@cast results table<lsp.Client,lsp.SymbolInformation[]|lsp.DocumentSymbol[]>
    local items = {} ---@type trouble.Item[]

    for client, result in pairs(results) do
      ---@param symbol lsp.SymbolInformation|lsp.DocumentSymbol
      local function add(symbol)
        ---@type lsp.Location
        local loc = symbol.location or { range = symbol.selectionRange or symbol.range, uri = params.textDocument.uri }
        local item = M.location_to_item(client, loc)
        local id = { item.buf, item.pos[1], item.pos[2], item.end_pos[1], item.end_pos[2], item.kind }
        item.id = table.concat(id, "|")
        item.item.kind = vim.lsp.protocol.SymbolKind[symbol.kind] or tostring(symbol.kind)
        item.item.symbol = symbol
        items[#items + 1] = item
        for _, child in ipairs(symbol.children or {}) do
          item:add_child(add(child))
        end
        symbol.children = nil
        return item
      end

      for _, symbol in ipairs(result) do
        add(symbol)
      end
    end
    Item.add_text(items, { mode = "after" })
    cb(items)
  end)
end

---@param client lsp.Client
---@param locations? lsp.Location[]|lsp.LocationLink[]|lsp.Location
function M.get_items(client, locations)
  locations = locations or {}
  locations = vim.tbl_islist(locations) and locations or { locations }
  ---@cast locations (lsp.Location|lsp.LocationLink)[]
  local items = {} ---@type trouble.Item[]

  for _, loc in ipairs(locations) do
    items[#items + 1] = M.location_to_item(client, loc)
  end

  Item.add_text(items, { mode = "full" })
  return items
end

---@param client lsp.Client
---@param loc lsp.Location|lsp.LocationLink
function M.location_to_item(client, loc)
  local range = loc.range or loc.targetSelectionRange
  local uri = loc.uri or loc.targetUri
  local buf = vim.uri_to_bufnr(uri)
  local pos = { range.start.line + 1, get_col(buf, range.start, client.offset_encoding) }
  local end_pos = { range["end"].line + 1, get_col(buf, range["end"], client.offset_encoding) }
  return Item.new({
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

-- Declaration
---@param cb trouble.Source.Callback
function M.get.declarations(cb)
  M.get_locations(methods.textDocument_declaration, cb)
end

return M
