local util = require("trouble.util")
local M = {}

M.results = {}

function M.open_with_trouble(prompt_bufnr, _mode)
  local action_state = require("telescope.actions.state")
  local actions = require("telescope.actions")
  local picker = action_state.get_current_picker(prompt_bufnr)
  local manager = picker.manager

  M.results = {}
  for item in manager:iter() do
    local row = (item.lnum or 1) - 1
    local col = (item.col or 1) - 1

    if not item.bufnr then
      item.bufnr = vim.fn.bufnr(item.filename, true)
    end

    local pitem = {
      row = row,
      col = col,
      message = item.text,
      severity = 0,
      range = {
        start = { line = row, character = col },
        ["end"] = { line = row, character = -1 },
      },
    }

    table.insert(M.results, util.process_item(pitem, item.bufnr))
  end

  actions.close(prompt_bufnr)
  require("trouble").open({ mode = "telescope" })
end

function M.telescope(_win, _buf, cb, _options)
  if #M.results == 0 then
    util.warn("No Telescope results found. Open Telescopen and send results to Trouble first. Refer to the documentation for more info.")
  end
  cb(M.results)
end

return M
