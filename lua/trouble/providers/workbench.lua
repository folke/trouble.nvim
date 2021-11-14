local util = require("trouble.util")
local todo_available, Search = pcall(require, "todo-comments.search")

local M = {}

function M.workbench(_win, buf, cb, _options)
  local diagnostics = vim.lsp.diagnostic.get_all()
  local all_items = util.locations_to_items(diagnostics, 0)

  if not todo_available then
    cb(all_items)
    return
  end

  local Config = require("todo-comments.config")

  if not Config.loaded then
    cb(all_items)
    return
  end

  Search.search(function(results)
    local ret = {}
    for _, item in pairs(results) do
      local row = (item.lnum == 0 and 1 or item.lnum) - 1
      local col = (item.col == 0 and 1 or item.col) - 1

      local pitem = {
        row = row,
        col = col,
        message = item.text,
        sign = Config.options.keywords[item.tag].icon,
        sign_hl = "TodoFg" .. item.tag,
        severity = 1,
        range = {
          start = { line = row, character = col },
          ["end"] = { line = row, character = -1 },
        },
      }

      table.insert(ret, util.process_item(pitem, vim.fn.bufnr(item.filename, true)))
    end
    if #ret > 0 then
      vim.list_extend(all_items, ret)
    end
    cb(all_items)
  end)
end

return M
