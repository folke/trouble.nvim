---@class trouble.Config.mod: trouble.Config
local M = {}

---@class trouble.Mode: trouble.Config,trouble.Section.spec
---@field sections? string[]

---@class trouble.Config
---@field mode? string
---@field config? fun(opts:trouble.Config)
---@field formatters? table<string,trouble.Formatter> custom formatters
---@field filters? table<string, trouble.FilterFn> custom filters
---@field sorters? table<string, trouble.SorterFn> custom sorters
local defaults = {
  debug = false,
  throttle = 100,
  auto_open = false,
  auto_close = false,
  auto_preview = true,
  auto_refresh = true,
  pinned = false,
  results = {
    ---@type trouble.Window.opts
    win = {},
    indent_guides = true, -- show indent guides
    multiline = true, -- render multi-line messages
    max_items = 200, -- limit number of items that can be displayed per section
  },
  ---@type table<string, string|trouble.Action>
  keys = {
    ["?"] = "help",
    r = "refresh",
    R = "toggle_auto_refresh",
    q = "close",
    o = "jump_close",
    ["<esc>"] = "cancel",
    ["<cr>"] = "jump",
    ["<2-leftmouse>"] = "jump",
    ["<c-s>"] = "jump_split",
    ["<c-v>"] = "jump_vsplit",
    -- go down to next item (accepts count)
    -- j = "next",
    ["}"] = "next",
    ["]]"] = "next",
    -- go up to prev item (accepts count)
    -- k = "prev",
    ["{"] = "prev",
    ["[["] = "prev",
    i = "inspect",
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
    zx = "fold_update",
    zX = "fold_update_all",
    zn = "fold_disable",
    zN = "fold_enable",
    zi = "fold_toggle_enable",
  },
  ---@type table<string, trouble.Mode>
  modes = {
    diagnostics_buffer = {
      mode = "diagnostics",
      filter = { buf = 0 },
    },
    symbols = {
      mode = "lsp_document_symbols",
      results = {
        win = { position = "right" },
      },
      filter = {
        kind = {
          "Class",
          "Constructor",
          "Enum",
          "Field",
          "Function",
          "Interface",
          "Method",
          "Module",
          "Namespace",
          "Package", -- remove package since luals uses it for control flow structures
          "Property",
          "Struct",
          "Trait",
        },
      },
    },
  },
  -- stylua: ignore
  icons = {
    ---@type trouble.Indent.symbols
    indent = {
      top           = "│ ",
      middle        = "├╴",
      last          = "└╴",
      -- last          = "-╴",
      -- last       = "╰╴", -- rounded
      fold_open     = " ",
      fold_closed   = " ",
      ws            = "  ",
    },
    folder_closed   = " ",
    folder_open     = " ",
    kinds = {
      Array         = " ",
      Boolean       = "󰨙 ",
      Class         = " ",
      Constant      = "󰏿 ",
      Constructor   = " ",
      Enum          = " ",
      EnumMember    = " ",
      Event         = " ",
      Field         = " ",
      File          = " ",
      Function      = "󰊕 ",
      Interface     = " ",
      Key           = " ",
      Method        = "󰊕 ",
      Module        = " ",
      Namespace     = "󰦮 ",
      Null          = " ",
      Number        = "󰎠 ",
      Object        = " ",
      Operator      = " ",
      Package       = " ",
      Property      = " ",
      String        = " ",
      Struct        = "󰆼 ",
      TypeParameter = " ",
      Variable      = "󰀫 ",
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
    nargs = "*",
    complete = function(...)
      return require("trouble.command").complete(...)
    end,
    desc = "Trouble",
  })
  return options
end

--- Update the default config.
--- Should only be used by source to extend the default config.
---@param config trouble.Config
function M.defaults(config)
  options = vim.tbl_deep_extend("force", config, options)
end

function M.modes()
  require("trouble.source").load()
  local ret = {} ---@type string[]
  for k, v in pairs(options.modes) do
    if v.source or v.mode or v.sections then
      ret[#ret + 1] = k
    end
  end
  table.sort(ret)
  return ret
end

---@param ...? trouble.Config|string
---@return trouble.Config
function M.get(...)
  options = options or M.setup()

  -- check if we need to load sources
  for i = 1, select("#", ...) do
    ---@type trouble.Config?
    local opts = select(i, ...)
    if type(opts) == "string" or (type(opts) == "table" and opts.mode) then
      M.modes() -- trigger loading of sources
      break
    end
  end

  ---@type trouble.Config[]
  local all = { {}, defaults, options or {} }

  ---@type table<string, boolean>
  local modes = {}
  local first_mode ---@type string?

  for i = 1, select("#", ...) do
    ---@type trouble.Config?
    local opts = select(i, ...)
    if type(opts) == "string" then
      opts = { mode = opts }
    end
    if opts then
      table.insert(all, opts)
      local idx = #all
      while opts.mode and not modes[opts.mode] do
        first_mode = first_mode or opts.mode
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
  ret.mode = first_mode

  return ret
end

return setmetatable(M, {
  __index = function(_, key)
    options = options or M.setup()
    assert(options, "should be setup")
    return options[key]
  end,
})
