local lsp = require("vim.lsp")
local util = require("trouble.util")

---@class Lsp
local M = {}

---@param options TroubleOptions
---@return Item[]
function M.diagnostics(_win, buf, cb, options)
  if options.mode == "lsp_workspace_diagnostics" then
    buf = nil
  end
  local buffer_diags = buf and { [buf] = vim.lsp.diagnostic.get(buf, nil) } or vim.lsp.diagnostic.get_all()

  local items = util.locations_to_items(buffer_diags, 1)
  cb(items)
end

---@return Item[]
function M.references(win, buf, cb, _options)
  local method = "textDocument/references"
  local params = util.make_position_params(win, buf)
  params.context = { includeDeclaration = true }
  lsp.buf_request(buf, method, params, function(err, _method, result, _client_id, _bufnr, _config)
    if err then
      util.error("an error happened getting references: " .. err)
      return cb({})
    end
    if result == nil or #result == 0 then
      return cb({})
    end
    local ret = util.locations_to_items({ result }, 0)
    cb(ret)
  end)
end

---@return Item[]
function M.implementations(win, buf, cb, _options)
  local method = "textDocument/implementation"
  local params = util.make_position_params(win, buf)
  params.context = { includeDeclaration = true }
  lsp.buf_request(buf, method, params, function(err, _method, result, _client_id, _bufnr, _config)
    if err then
      util.error("an error happened getting implementation: " .. err)
      return cb({})
    end
    if result == nil or #result == 0 then
      return cb({})
    end
    local ret = util.locations_to_items({ result }, 0)
    cb(ret)
  end)
end

---@return Item[]
function M.definitions(win, buf, cb, _options)
  local method = "textDocument/definition"
  local params = util.make_position_params(win, buf)
  params.context = { includeDeclaration = true }
  lsp.buf_request(buf, method, params, function(err, _method, result, _client_id, _bufnr, _config)
    if err then
      util.error("an error happened getting definitions: " .. err)
      return cb({})
    end
    if result == nil or #result == 0 then
      return cb({})
    end
    for _, value in ipairs(result) do
      value.uri = value.targetUri or value.uri
      value.range = value.targetSelectionRange or value.range
    end
    local ret = util.locations_to_items({ result }, 0)
    cb(ret)
  end)
end

function M.get_signs()
  local signs = {}
  for _, v in pairs(util.severity) do
    -- pcall to catch entirely unbound or cleared out sign hl group
    local status, sign = pcall(function()
      return vim.trim(vim.fn.sign_getdefined("LspDiagnosticsSign" .. v)[1].text)
    end)
    if not status then
      sign = v:sub(1, 1)
    end
    signs[string.lower(v)] = sign
  end
  return signs
end

return M
