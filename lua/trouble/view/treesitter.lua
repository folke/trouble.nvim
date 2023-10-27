local M = {}

---@param buf number
---@param lang? string
function M.highlight(buf, lang, regions)
  local Render = require("trouble.view.render")
  lang = lang or "markdown"
  lang = lang == "markdown" and "markdown_inline" or lang
  -- lang = "markdown_inline"
  local parser = vim.treesitter.get_parser(buf, lang)

  ---@diagnostic disable-next-line: invisible
  parser:set_included_regions(regions)
  parser:parse(true)
  local ret = {} ---@type Extmark[]

  parser:for_each_tree(function(tstree, tree)
    if not tstree then
      return
    end
    local query = vim.treesitter.query.get(tree:lang(), "highlights")

    -- Some injected languages may not have highlight queries.
    if not query then
      return
    end

    ---@diagnostic disable-next-line: missing-parameter
    local iter = query:iter_captures(tstree:root(), buf)

    for capture, node, metadata in iter do
      ---@type number, number, number, number
      local start_row, start_col, end_row, end_col = node:range()

      ---@type string
      local name = query.captures[capture]
      local hl = 0
      if not vim.startswith(name, "_") then
        hl = vim.api.nvim_get_hl_id_by_name("@" .. name .. "." .. lang)
      end

      if hl and name ~= "spell" then
        pcall(vim.api.nvim_buf_set_extmark, buf, Render.ns, start_row, start_col, {
          end_line = end_row,
          end_col = end_col,
          hl_group = hl,
          priority = (tonumber(metadata.priority) or 100) + 10, -- add 10, so it will be higher than the standard highlighter of the buffer
          conceal = metadata.conceal,
        })
      end
    end
  end)
  return ret
end

return M
