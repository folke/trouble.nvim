local M = {}

function M.document_symbols()
  local bufnr = vim.api.nvim_get_current_buf()
  local params = { textDocument = vim.lsp.util.make_text_document_params(bufnr) }
  vim.lsp.buf_request(bufnr, "textDocument/documentSymbol", params, function(_, result, ctx)
    local symbols = vim.lsp.util.symbols_to_items(result, bufnr)
    dd(symbols)
  end)
end
err()

function M._get_symbol_kind_name(symbol_kind)
  return vim.lsp.protocol.SymbolKind[symbol_kind] or "Unknown"
end

--- Converts symbols to quickfix list items.
---
---@param symbols table DocumentSymbol[] or SymbolInformation[]
function M.symbols_to_items(symbols, bufnr)
  local function _symbols_to_items(_symbols, _items, _bufnr)
    for _, symbol in ipairs(_symbols) do
      if symbol.location then -- SymbolInformation type
        local range = symbol.location.range
        local kind = M._get_symbol_kind_name(symbol.kind)
        table.insert(_items, {
          filename = vim.uri_to_fname(symbol.location.uri),
          lnum = range.start.line + 1,
          col = range.start.character + 1,
          kind = kind,
          text = "[" .. kind .. "] " .. symbol.name,
        })
      elseif symbol.selectionRange then -- DocumentSymbole type
        local kind = M._get_symbol_kind_name(symbol.kind)
        table.insert(_items, {
          -- bufnr = _bufnr,
          filename = api.nvim_buf_get_name(_bufnr),
          lnum = symbol.selectionRange.start.line + 1,
          col = symbol.selectionRange.start.character + 1,
          kind = kind,
          text = "[" .. kind .. "] " .. symbol.name,
        })
        if symbol.children then
          for _, v in ipairs(_symbols_to_items(symbol.children, _items, _bufnr)) do
            for _, s in ipairs(v) do
              table.insert(_items, s)
            end
          end
        end
      end
    end
    return _items
  end
  return _symbols_to_items(symbols, {}, bufnr or 0)
end

M.document_symbols()

return M
