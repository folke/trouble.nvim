local util = require("trouble.util")

local M = {}

local severities = { E = 1, W = 2, I = 3, H = 4 }

function M.get_list(winid)
  local list = winid == nil and vim.fn.getqflist({ all = true }) or vim.fn.getloclist(winid, { all = true })

  local ret = {}
  for _, item in pairs(list.items) do
    local row = (item.lnum == 0 and 1 or item.lnum) - 1
    local col = (item.col == 0 and 1 or item.col) - 1

    if item.valid == 1 then
      ret[#ret + 1] = {
        row = row,
        col = col,
        message = item.text,
        severity = severities[item.type] or 0,
        bufnr = item.bufnr,
        range = {
          start = { line = row, character = col },
          ["end"] = { line = row, character = -1 },
        },
      }
    elseif #ret > 0 then
      ret[#ret].message = ret[#ret].message .. "\n" .. item.text
    end
  end

  for i, item in ipairs(ret) do
    ret[i] = util.process_item(item)
  end

  return ret
end

function M.loclist(win, _buf, cb, _options)
  return cb(M.get_list(win))
end

function M.qflist(_win, _buf, cb, _options)
  return cb(M.get_list())
end

return M
