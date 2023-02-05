local util = require("trouble.util")

---@class Lsp
local M = {}

---@param options TroubleOptions
function M.tsc(_, buf, cb, options)
  local items = {}

  local tsConfigPath = vim.fn.findfile("tsconfig.json", ".;")

  if tsConfigPath == "" then
    print("No tsconfig.json found, Treeouble cannot run")
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

  -- "(.*)\(\d+,\d+\):(.+?(?=\n)(?:\s\s+.+?(?=\n))*)"
  local errors = vim.json.decode(result)

  for _, error in ipairs(errors) do
    local item = {
	  bufnr = vim.fn.bufnr(error.value.path.value),
	  -- filename = error.value.path.value,
	  -- filepath = error.value.path.value,
      lnum = error.value.cursor.value.line,
      end_lnum = error.value.cursor.value.line,
      col = error.value.cursor.value.col,
      end_col = error.value.cursor.value.col,
      severity = 1,
      message = error.value.message.value,
      code = error.value.tsError.value.errorString,
    }

    table.insert(items, util.process_item(item))
  end

  cb(items)
end

return M
