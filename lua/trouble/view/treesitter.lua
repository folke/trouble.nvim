---@alias trouble.LangRegions table<string, number[][][]>

local M = {}

M.cache = {} ---@type table<number, table<string,{parser: vim.treesitter.LanguageTree, highlighter:vim.treesitter.highlighter, enabled:boolean}>>
local ns = vim.api.nvim_create_namespace("trouble.treesitter")

local TSHighlighter = vim.treesitter.highlighter

local function wrap(name)
  return function(_, win, buf, ...)
    if not M.cache[buf] then
      return false
    end
    for _, hl in pairs(M.cache[buf] or {}) do
      if hl.enabled then
        TSHighlighter.active[buf] = hl.highlighter
        TSHighlighter[name](_, win, buf, ...)
      end
    end
    TSHighlighter.active[buf] = nil
  end
end

M.did_setup = false
function M.setup()
  if M.did_setup then
    return
  end
  M.did_setup = true

  vim.api.nvim_set_decoration_provider(ns, {
    on_win = wrap("_on_win"),
    on_line = wrap("_on_line"),
  })

  vim.api.nvim_create_autocmd("BufWipeout", {
    group = vim.api.nvim_create_augroup("trouble.treesitter.hl", { clear = true }),
    callback = function(ev)
      M.cache[ev.buf] = nil
    end,
  })
end

---@param buf number
---@param regions trouble.LangRegions
function M.attach(buf, regions)
  M.setup()
  M.cache[buf] = M.cache[buf] or {}
  for lang in pairs(M.cache[buf]) do
    M.cache[buf][lang].enabled = regions[lang] ~= nil
  end

  for lang in pairs(regions) do
    M._attach_lang(buf, lang, regions[lang])
  end
end

---@param buf number
---@param lang? string
function M._attach_lang(buf, lang, regions)
  lang = lang or "markdown"
  lang = lang == "markdown" and "markdown_inline" or lang

  M.cache[buf] = M.cache[buf] or {}

  if not M.cache[buf][lang] then
    local ok, parser = pcall(vim.treesitter.languagetree.new, buf, lang)
    if not ok then
      local msg = "nvim-treesitter parser missing `" .. lang .. "`"
      vim.notify_once(msg, vim.log.levels.WARN, { title = "trouble.nvim" })
      return
    end

    parser:set_included_regions(vim.deepcopy(regions))
    M.cache[buf][lang] = {
      parser = parser,
      highlighter = TSHighlighter.new(parser),
    }
  end
  M.cache[buf][lang].enabled = true
  local parser = M.cache[buf][lang].parser

  parser:set_included_regions(vim.deepcopy(regions))
end

return M
