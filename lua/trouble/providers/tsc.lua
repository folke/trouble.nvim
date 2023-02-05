local util = require("trouble.util")

---@class Lsp
local M = {}

---@param options TroubleOptions
function M.tsc(_, buf, cb, options)
  local tsConfigPath = vim.fn.findfile("tsconfig.json", ".;")

  if tsConfigPath == "" then
    print("No tsconfig.json found, cannot type-check")
    return
  end

  local command = "tsc --noEmit --pretty false --project " .. tsConfigPath .. " | tsc-output-parser"

  local handle = io.popen(command)
  if handle == nil then
    print("Unable to start command: " .. command)
    return
  end

  local result = handle:read("*a")
  handle:close()

  local items = {}
  local rawItems = vim.json.decode(result)
  for _, error in ipairs(rawItems) do
    local item = {
      bufnr = vim.fn.bufnr(error.value.path.value, true),
      lnum = error.value.cursor.value.line - 1,
      end_lnum = error.value.cursor.value.line - 1,
      col = error.value.cursor.value.col - 1,
      end_col = error.value.cursor.value.col - 1,
      severity = 1,
      message = error.value.message.value,
      code = error.value.tsError.value.errorString,
    }

    table.insert(items, util.process_item(item))
  end

  cb(items)
end

function M.eslint(_, buf, cb, options)
  local eslintConfigPath = vim.fn.findfile(".eslintrc.cjs", ".;")

  if eslintConfigPath == "" then
    print("No .eslintrc.cjs found, cannot lint")
    return
  end

  local directory
  for dir in vim.fs.parents(eslintConfigPath) do
    directory = dir
  end

  local command = "yarn --silent eslint -f json " .. directory

  local handle = io.popen(command)
  if handle == nil then
    print("Unable to start command: " .. command)
    return
  end

  local result = handle:read("*a")
  handle:close()

  local items = {}
  local files = vim.json.decode(result)

  for _, file in ipairs(files) do
    for _, message in ipairs(file.messages) do
      local item = {
        bufnr = vim.fn.bufnr(file.filePath, true),
        lnum = message.line - 1,
        col = message.column - 1,
        end_lnum = message.endLine - 1,
        end_col = message.endColumn - 1,
        severity = message.severity,
        message = message.message,
        code = message.ruleId,
      }

      table.insert(items, util.process_item(item))
    end
  end

  cb(items)
end

return M
