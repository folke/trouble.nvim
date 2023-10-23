---@class trouble.Config.mod: trouble.Config
local M = {}

---@class trouble.Mode: trouble.Config
---@field sections? trouble.spec.section[]|trouble.spec.section

---@class trouble.Config
---@field mode? string
---@field config? fun(opts:trouble.Config)
local defaults = {
  debug = false,
  indent_lines = true, -- add an indent guide below the fold icons
  max_items = 200, -- limit number of items that can be displayed
  events = { "BufEnter" }, -- events that trigger refresh. Also used by auto_open and auto_close
  ---@type trouble.Window.opts
  win = {},
  throttle = 100,
  auto_open = false,
  auto_close = false,
  auto_preview = true,
  ---@type trouble.Render.opts
  render = {
    multiline = true, -- render multi-line messages
    -- stylua: ignore
    ---@type trouble.Indent.symbols
    indent = {
      top         = "│ ",
      middle      = "├╴",
      last        = "└╴",
      -- last     = "╰╴", -- rounded
      fold_open   = " ",
      fold_closed = " ",
      ws          = "  ",
    },
    ---@type table<string, trouble.Formatter>
    formatters = {}, -- custom formatters
  },
  ---@type table<string, trouble.FilterFn>
  filters = {}, -- custom filters
  ---@type table<string, trouble.Sorter>
  sorters = {}, -- custom sorters
  ---@type table<string, string|trouble.Action>
  keys = {
    ["?"] = "help",
    r = "refresh",
    q = "close",
    o = "jump_close",
    ["<esc>"] = "cancel",
    ["<cr>"] = "jump",
    ["<2-leftmouse>"] = "jump",
    ["<c-s>"] = "jump_split",
    ["<c-v>"] = "jump_vsplit",
    p = "preview",
    P = "toggle_auto_preview",
    zo = "fold_open",
    zO = "fold_open_recursive",
    zc = "fold_close",
    zC = "fold_close_recursive",
    za = "fold_toggle",
    zA = "fold_toggle_recursive",
    zm = "fold_more",
    zM = "fold_close_all",
    zr = "fold_reduce",
    zR = "fold_open_all",
  },
  ---@type table<string, trouble.Mode>
  modes = {
    diagnostics_buffer = {
      mode = "diagnostics",
      sections = {
        filter = { buf = 0 },
      },
    },
  },
}

---@type trouble.Config
local options

---@param opts? trouble.Config
function M.setup(opts)
  opts = opts or {}
  opts.mode = nil
  options = {}
  options = M.get(opts)
  require("trouble.config.highlights").setup()
  vim.api.nvim_create_user_command("Trouble", function(input)
    require("trouble.command").execute(input)
  end, {
    nargs = "+",
    complete = function(...)
      return require("trouble.command").complete(...)
    end,
    desc = "Trouble",
  })
  return options
end

---@param modes table<string, trouble.Mode>
function M.register(modes)
  for name, mode in pairs(modes) do
    if defaults.modes[name] then
      error("mode already registered: " .. name)
    end
    defaults.modes[name] = mode
  end
end

function M.modes()
  require("trouble.source").load()
  return vim.tbl_keys(options.modes)
end

---@param ...? trouble.Config|string
---@return trouble.Config
function M.get(...)
  options = options or M.setup()

  ---@type trouble.Config[]
  local all = { {}, defaults, options or {} }

  ---@type table<string, boolean>
  local modes = {}

  for i = 1, select("#", ...) do
    ---@type trouble.Config?
    local opts = select(i, ...)
    if type(opts) == "string" then
      opts = { mode = opts }
    end
    if opts then
      if opts.mode then
        M.modes() -- trigger loading of sources
      end
      table.insert(all, opts)
      local idx = #all
      while opts.mode and not modes[opts.mode] do
        modes[opts.mode or ""] = true
        opts = options.modes[opts.mode] or {}
        table.insert(all, idx, opts)
      end
    end
  end

  local ret = vim.tbl_deep_extend("force", unpack(all))

  if type(ret.config) == "function" then
    ret.config(ret)
  end

  if ret.mode then
    ret.modes = {}
  end

  return ret
end

return setmetatable(M, {
  __index = function(_, key)
    options = options or M.setup()
    assert(options, "should be setup")
    return options[key]
  end,
})
