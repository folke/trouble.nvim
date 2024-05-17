local Cache = require("trouble.cache")
local Item = require("trouble.item")
local Util = require("trouble.util")

local function get_col(bufnr, position, offset_encoding)
  local ok, ret = pcall(vim.lsp.util._get_line_byte_from_position, bufnr, position, offset_encoding)
  return ok and ret or position.character
end

---@class trouble.Source.lsp: trouble.Source
---@diagnostic disable-next-line: missing-fields
local M = {}

function M.setup()
  vim.api.nvim_create_autocmd("LspAttach", {
    callback = function()
      Cache.symbols:clear()
    end,
  })
end

M.config = {
  modes = {
    lsp_document_symbols = {
      title = "{hl:Title}Document Symbols{hl} {count}",
      desc = "document symbols",
      events = {
        "BufEnter",
        -- symbols are cached on changedtick,
        -- so it's ok to refresh often
        { event = "TextChanged", main = true },
        { event = "CursorMoved", main = true },
        { event = "LspAttach", main = true },
      },
      source = "lsp.document_symbols",
      groups = {
        { "filename", format = "{file_icon} {filename} {count}" },
      },
      sort = { { buf = 0 }, "filename", "pos", "text" },
      -- sort = { { buf = 0 }, { kind = "Function" }, "filename", "pos", "text" },
      format = "{kind_icon} {symbol.name} {text:Comment} {pos}",
    },
    lsp_base = {
      events = { { event = "CursorHold", main = true } },
      groups = {
        { "filename", format = "{file_icon} {filename} {count}" },
      },
      sort = { { buf = 0 }, "filename", "pos", "text" },
      format = "{text:ts} ({item.client}) {pos}",
    },
    lsp = {
      desc = "LSP definitions, references, implementations, type definitions, and declarations",
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
  M.config.modes["lsp_" .. mode] = {
    auto_jump = true,
    mode = "lsp_base",
    title = "{hl:Title}" .. Util.camel(mode, " ") .. "{hl} {count}",
    source = "lsp." .. mode,
    desc = Util.camel(mode, " "):lower(),
  }
end

---@param method string
---@param params? table
---@param cb fun(results: table<vim.lsp.Client, any>)
function M.request(method, params, cb)
  local buf = vim.api.nvim_get_current_buf()
  ---@type vim.lsp.Client[]
  local clients = {}

  if vim.lsp.get_clients then
    clients = vim.lsp.get_clients({ method = method, bufnr = buf })
  else
    ---@diagnostic disable-next-line: deprecated
    clients = vim.lsp.get_active_clients({ bufnr = buf })
    ---@param client vim.lsp.Client
    clients = vim.tbl_filter(function(client)
      return client.supports_method(method)
    end, clients)
  end
  local results = {} ---@type table<vim.lsp.Client, any>
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
  local buf = vim.api.nvim_get_current_buf()
  ---@type {changedtick:number, symbols:trouble.Item[]}
  local ret = Cache.symbols[buf]

  if ret and ret.changedtick == vim.b[buf].changedtick then
    return cb(ret.symbols)
  end

  ---@type lsp.DocumentSymbolParams
  local params = { textDocument = vim.lsp.util.make_text_document_params() }

  M.request("textDocument/documentSymbol", params, function(results)
    ---@cast results table<vim.lsp.Client,lsp.SymbolInformation[]|lsp.DocumentSymbol[]>
    local items = {} ---@type trouble.Item[]

    for client, result in pairs(results) do
      ---@param symbol lsp.SymbolInformation|lsp.DocumentSymbol
      local function add(symbol)
        ---@type lsp.Location
        local loc = symbol.location or { range = symbol.selectionRange or symbol.range, uri = params.textDocument.uri }
        local item = M.location_to_item(client, loc)
        local id = { item.buf, item.pos[1], item.pos[2], item.end_pos[1], item.end_pos[2], item.kind }
        item.id = table.concat(id, "|")
        -- the range enclosing this symbol. Useful to get the symbol of the current cursor position
        item.range = symbol.range and M.location(client, { range = symbol.range, uri = params.textDocument.uri }) or nil
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
    ---@diagnostic disable-next-line: no-unknown
    Cache.symbols[buf] = { changedtick = vim.b[buf].changedtick, symbols = items }
    cb(items)
  end)
end

---@param client vim.lsp.Client
---@param locations? lsp.Location[]|lsp.LocationLink[]|lsp.Location
function M.get_items(client, locations)
  locations = locations or {}
  locations = Util.islist(locations) and locations or { locations }
  ---@cast locations (lsp.Location|lsp.LocationLink)[]
  local items = {} ---@type trouble.Item[]

  for _, loc in ipairs(locations) do
    items[#items + 1] = M.location_to_item(client, loc)
  end

  Item.add_text(items, { mode = "full" })
  return items
end

---@param client vim.lsp.Client
---@param loc lsp.Location|lsp.LocationLink
function M.location_to_item(client, loc)
  local info = M.location(client, loc)
  info.source = "lsp"
  info.item = {
    client_id = client.id,
    client = client.name,
    location = loc,
  }
  return Item.new(info)
end

---@param client vim.lsp.Client
---@param loc lsp.Location|lsp.LocationLink
---@return {buf:number, filename:string, pos:trouble.Pos, end_pos:trouble.Pos}
function M.location(client, loc)
  local range = loc.range or loc.targetSelectionRange
  local uri = loc.uri or loc.targetUri
  local buf = vim.uri_to_bufnr(uri)
  local pos = { range.start.line + 1, get_col(buf, range.start, client.offset_encoding) }
  local end_pos = { range["end"].line + 1, get_col(buf, range["end"], client.offset_encoding) }
  return {
    buf = buf,
    filename = vim.uri_to_fname(uri),
    pos = pos,
    end_pos = end_pos,
  }
end

---@param cb trouble.Source.Callback
function M.get.references(cb)
  M.get_locations("textDocument/references", cb, { includeDeclaration = true })
end

---@param cb trouble.Source.Callback
function M.get.definitions(cb)
  M.get_locations("textDocument/definition", cb)
end

---@param cb trouble.Source.Callback
function M.get.implementations(cb)
  M.get_locations("textDocument/implementation", cb)
end

-- Type Definitions
---@param cb trouble.Source.Callback
function M.get.type_definitions(cb)
  M.get_locations("textDocument/typeDefinition", cb)
end

-- Declaration
---@param cb trouble.Source.Callback
function M.get.declarations(cb)
  M.get_locations("textDocument/declaration", cb)
end

return M
