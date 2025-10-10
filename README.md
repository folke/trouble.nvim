# 🚦 Trouble

A pretty list for showing diagnostics, references, telescope results, quickfix and location lists to help you solve all the trouble your code is causing.

![image](https://github.com/folke/trouble.nvim/assets/292349/481bc1f7-cb93-432d-8ab6-f54044334b96)

## ✨ Features

- Diagnostics
- LSP references
- LSP implementations
- LSP definitions
- LSP type definitions
- LSP Document Symbols
- LSP Incoming/Outgoing calls
- quickfix list
- location list
- [Telescope](https://github.com/nvim-telescope/telescope.nvim) search results
- [fzf-lua](https://github.com/ibhagwan/fzf-lua) results

## 📰 What's new?

This is a full rewrite of the original **trouble.nvim**.

The new version is much more flexible and powerful,
with a lot of new features and improvements:

- multiple trouble windows at the same time
- LSP document symbols
- LSP incoming/outgoing calls
- lots of options to configure trouble windows (floats or splits)
- `focus` option to focus the trouble window when opened (or not)
- `follow` option to follow the item under the cursor
- `pinned` option to pin the buffer as the source for the opened trouble window
- full tree views of anything
- highly configurable views with custom formatters, filters, and sorters
- show multiple sections in the same view
- multi-line messages
- prettier and configurable indent guides
- tree view that follows the natural hierarchy of the items (like document symbols, or file structure)
- expansive API and `Trouble` command
- trouble `modes` to define custom views
- statusline component (useful with document symbols)

## ⚡️ Requirements

- Neovim >= 0.9.2
- Neovim >= 0.10.0 **OR** the `markdown` and `markdown_inline` [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) parsers
- Properly configured Neovim LSP client
- [nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons) is optional to enable file icons
- a theme with properly configured highlight groups for Neovim Diagnostics
- a [patched font](https://www.nerdfonts.com/) for the default severity and fold icons

## 📦 Installation

Install the plugin with your preferred package manager:

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "folke/trouble.nvim",
  opts = {}, -- for default options, refer to the configuration section for custom setup.
  cmd = "Trouble",
  keys = {
    {
      "<leader>xx",
      "<cmd>Trouble diagnostics toggle<cr>",
      desc = "Diagnostics (Trouble)",
    },
    {
      "<leader>xX",
      "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
      desc = "Buffer Diagnostics (Trouble)",
    },
    {
      "<leader>cs",
      "<cmd>Trouble symbols toggle focus=false<cr>",
      desc = "Symbols (Trouble)",
    },
    {
      "<leader>cl",
      "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
      desc = "LSP Definitions / references / ... (Trouble)",
    },
    {
      "<leader>xL",
      "<cmd>Trouble loclist toggle<cr>",
      desc = "Location List (Trouble)",
    },
    {
      "<leader>xQ",
      "<cmd>Trouble qflist toggle<cr>",
      desc = "Quickfix List (Trouble)",
    },
  },
}
```

## ⚙️ Configuration

### Setup

**Trouble** is highly configurable. Please refer to the default settings below.

<details><summary>Default Settings</summary>

<!-- config:start -->

```lua
---@class trouble.Mode: trouble.Config,trouble.Section.spec
---@field desc? string
---@field sections? string[]

---@class trouble.Config
---@field mode? string
---@field config? fun(opts:trouble.Config)
---@field formatters? table<string,trouble.Formatter> custom formatters
---@field filters? table<string, trouble.FilterFn> custom filters
---@field sorters? table<string, trouble.SorterFn> custom sorters
local defaults = {
  auto_close = false, -- auto close when there are no items
  auto_open = false, -- auto open when there are items
  auto_preview = true, -- automatically open preview when on an item
  auto_refresh = true, -- auto refresh when open
  auto_jump = false, -- auto jump to the item when there's only one
  focus = false, -- Focus the window when opened
  restore = true, -- restores the last location in the list when opening
  follow = true, -- Follow the current item
  indent_guides = true, -- show indent guides
  max_items = 200, -- limit number of items that can be displayed per section
  multiline = true, -- render multi-line messages
  pinned = false, -- When pinned, the opened trouble window will be bound to the current buffer
  warn_no_results = true, -- show a warning when there are no results
  open_no_results = false, -- open the trouble window when there are no results
  ---@type trouble.Window.opts
  win = {}, -- window options for the results window. Can be a split or a floating window.
  -- Window options for the preview window. Can be a split, floating window,
  -- or `main` to show the preview in the main editor window.
  ---@type trouble.Window.opts
  preview = {
    type = "main",
    -- when a buffer is not yet loaded, the preview window will be created
    -- in a scratch buffer with only syntax highlighting enabled.
    -- Set to false, if you want the preview to always be a real loaded buffer.
    scratch = true,
  },
  -- Throttle/Debounce settings. Should usually not be changed.
  ---@type table<string, number|{ms:number, debounce?:boolean}>
  throttle = {
    refresh = 20, -- fetches new data when needed
    update = 10, -- updates the window
    render = 10, -- renders the window
    follow = 100, -- follows the current item
    preview = { ms = 100, debounce = true }, -- shows the preview for the current item
  },
  -- Key mappings can be set to the name of a builtin action,
  -- or you can define your own custom action.
  ---@type table<string, trouble.Action.spec|false>
  keys = {
    ["?"] = "help",
    r = "refresh",
    R = "toggle_refresh",
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
    dd = "delete",
    d = { action = "delete", mode = "v" },
    i = "inspect",
    p = "preview",
    P = "toggle_preview",
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
    gb = { -- example of a custom action that toggles the active view filter
      action = function(view)
        view:filter({ buf = 0 }, { toggle = true })
      end,
      desc = "Toggle Current Buffer Filter",
    },
    s = { -- example of a custom action that toggles the severity
      action = function(view)
        local f = view:get_filter("severity")
        local severity = ((f and f.filter.severity or 0) + 1) % 5
        view:filter({ severity = severity }, {
          id = "severity",
          template = "{hl:Title}Filter:{hl} {severity}",
          del = severity == 0,
        })
      end,
      desc = "Toggle Severity Filter",
    },
  },
  ---@type table<string, trouble.Mode>
  modes = {
    -- sources define their own modes, which you can use directly,
    -- or override like in the example below
    lsp_references = {
      -- some modes are configurable, see the source code for more details
      params = {
        include_declaration = true,
      },
    },
    -- The LSP base mode for:
    -- * lsp_definitions, lsp_references, lsp_implementations
    -- * lsp_type_definitions, lsp_declarations, lsp_command
    lsp_base = {
      params = {
        -- don't include the current location in the results
        include_current = false,
      },
    },
    -- more advanced example that extends the lsp_document_symbols
    symbols = {
      desc = "document symbols",
      mode = "lsp_document_symbols",
      focus = false,
      win = { position = "right" },
      filter = {
        -- remove Package since luals uses it for control flow structures
        ["not"] = { ft = "lua", kind = "Package" },
        any = {
          -- all symbol kinds for help / markdown files
          ft = { "help", "markdown" },
          -- default set of symbol kinds
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
            "Package",
            "Property",
            "Struct",
            "Trait",
          },
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
```

<!-- config:end -->

</details>

Make sure to check the [Examples](/docs/examples.md)!

## 🚀 Usage

### Commands

The **Trouble** command is a wrapper around the **Trouble** API.
It can do anything the regular API can do.

- `Trouble [mode] [action] [options]`

Some examples:

- Toggle diagnostics for the current buffer and stay in the current window:
  - `Trouble diagnostics toggle focus=false filter.buf=0`
- Show document symbols on the right of the current window.
  Keep the document symbols in sync with the buffer you started the command in.
  - `Trouble symbols toggle pinned=true win.relative=win win.position=right`
- You can use **lua** code in the options for the `Trouble` command.
  The examples below all do the same thing.
  - `Trouble diagnostics filter.severity=vim.diagnostic.severity.ERROR`
  - `Trouble diagnostics filter.severity = vim.diagnostic.severity.ERROR`
  - `Trouble diagnostics filter = { severity=vim.diagnostic.severity.ERROR }`
- Merging of nested options, with or without quoting strings:
  - `Trouble diagnostics win.type = split win.position=right`
  - `Trouble diagnostics win = { type = split, position=right}`
  - `Trouble diagnostics win = { type = "split", position='right'}`

Please refer to the API section for more information on the available actions and options.

Modes:

<!-- modes:start -->

- **diagnostics**: diagnostics
- **fzf**: FzfLua results previously opened with `require('trouble.sources.fzf').open()`.
- **fzf_files**: FzfLua results previously opened with `require('trouble.sources.fzf').open()`.
- **loclist**: Location List
- **lsp**: LSP definitions, references, implementations, type definitions, and declarations
- **lsp_command**: command
- **lsp_declarations**: declarations
- **lsp_definitions**: definitions
- **lsp_document_symbols**: document symbols
- **lsp_implementations**: implementations
- **lsp_incoming_calls**: Incoming Calls
- **lsp_outgoing_calls**: Outgoing Calls
- **lsp_references**: references
- **lsp_type_definitions**: type definitions
- **qflist**: Quickfix List
- **quickfix**: Quickfix List
- **snacks**: Snacks results previously opened with `require('trouble.sources.snacks').open()`.
- **snacks_files**: Snacks results previously opened with `require('trouble.sources.snacks').open()`.
- **symbols**: document symbols
- **telescope**: Telescope results previously opened with `require('trouble.sources.telescope').open()`.
- **telescope_files**: Telescope results previously opened with `require('trouble.sources.telescope').open()`.

<!-- modes:end -->

### Filters

Please refer to the [filter docs](docs/filter.md) for more information examples on filters.

### API

You can use the following functions in your keybindings:

<details><summary>API</summary>

<!-- api:start -->

```lua
-- Opens trouble with the given mode.
-- If a view is already open with the same mode,
-- it will be focused unless `opts.focus = false`.
-- When a view is already open and `opts.new = true`,
-- a new view will be created.
---@param opts? trouble.Mode | { new?: boolean, refresh?: boolean } | string
---@return trouble.View?
require("trouble").open(opts)

-- Closes the last open view matching the filter.
---@param opts? trouble.Mode|string
---@return trouble.View?
require("trouble").close(opts)

-- Toggle the view with the given mode.
---@param opts? trouble.Mode|string
---@return trouble.View?
require("trouble").toggle(opts)

-- Returns true if there is an open view matching the mode.
---@param opts? trouble.Mode|string
require("trouble").is_open(opts)

-- Refresh all open views. Normally this is done automatically,
-- unless you disabled auto refresh.
---@param opts? trouble.Mode|string
require("trouble").refresh(opts)

-- Get all items from the active view for a given mode.
---@param opts? trouble.Mode|string
require("trouble").get_items(opts)

-- Renders a trouble list as a statusline component.
-- Check the docs for examples.
---@param opts? trouble.Mode|string|{hl_group?:string}
---@return {get: (fun():string), has: (fun():boolean)}
require("trouble").statusline(opts)

-- Closes the preview and goes to the main window.
-- The Trouble window is not closed.
---@param opts? trouble.Mode | { new? : boolean } | string
---@return trouble.View
require("trouble").cancel(opts)

-- Open the preview
---@param opts? trouble.Mode | { new? : boolean } | string
---@return trouble.View
require("trouble").delete(opts)

-- filter
---@param opts? trouble.Mode | { new? : boolean } | string
---@return trouble.View
require("trouble").filter(opts)

-- Go to the first item
---@param opts? trouble.Mode | { new? : boolean } | string
---@return trouble.View
require("trouble").first(opts)

-- Focus the trouble window
---@param opts? trouble.Mode | { new? : boolean } | string
---@return trouble.View
require("trouble").focus(opts)

-- Fold close 
---@param opts? trouble.Mode | { new? : boolean } | string
---@return trouble.View
require("trouble").fold_close(opts)

-- fold close all
---@param opts? trouble.Mode | { new? : boolean } | string
---@return trouble.View
require("trouble").fold_close_all(opts)

-- Fold close recursive
---@param opts? trouble.Mode | { new? : boolean } | string
---@return trouble.View
require("trouble").fold_close_recursive(opts)

-- fold disable
---@param opts? trouble.Mode | { new? : boolean } | string
---@return trouble.View
require("trouble").fold_disable(opts)

-- fold enable
---@param opts? trouble.Mode | { new? : boolean } | string
---@return trouble.View
require("trouble").fold_enable(opts)

-- fold more
---@param opts? trouble.Mode | { new? : boolean } | string
---@return trouble.View
require("trouble").fold_more(opts)

-- Fold open 
---@param opts? trouble.Mode | { new? : boolean } | string
---@return trouble.View
require("trouble").fold_open(opts)

-- fold open all
---@param opts? trouble.Mode | { new? : boolean } | string
---@return trouble.View
require("trouble").fold_open_all(opts)

-- Fold open recursive
---@param opts? trouble.Mode | { new? : boolean } | string
---@return trouble.View
require("trouble").fold_open_recursive(opts)

-- fold reduce
---@param opts? trouble.Mode | { new? : boolean } | string
---@return trouble.View
require("trouble").fold_reduce(opts)

-- Fold toggle 
---@param opts? trouble.Mode | { new? : boolean } | string
---@return trouble.View
require("trouble").fold_toggle(opts)

-- fold toggle enable
---@param opts? trouble.Mode | { new? : boolean } | string
---@return trouble.View
require("trouble").fold_toggle_enable(opts)

-- Fold toggle recursive
---@param opts? trouble.Mode | { new? : boolean } | string
---@return trouble.View
require("trouble").fold_toggle_recursive(opts)

-- fold update
---@param opts? trouble.Mode | { new? : boolean } | string
---@return trouble.View
require("trouble").fold_update(opts)

-- fold update all
---@param opts? trouble.Mode | { new? : boolean } | string
---@return trouble.View
require("trouble").fold_update_all(opts)

-- Show the help
---@param opts? trouble.Mode | { new? : boolean } | string
---@return trouble.View
require("trouble").help(opts)

-- Dump the item to the console
---@param opts? trouble.Mode | { new? : boolean } | string
---@return trouble.View
require("trouble").inspect(opts)

-- Jump to the item if on an item, otherwise fold the node
---@param opts? trouble.Mode | { new? : boolean } | string
---@return trouble.View
require("trouble").jump(opts)

-- Jump to the item and close the trouble window
---@param opts? trouble.Mode | { new? : boolean } | string
---@return trouble.View
require("trouble").jump_close(opts)

-- Jump to the item if on an item, otherwise do nothing
---@param opts? trouble.Mode | { new? : boolean } | string
---@return trouble.View
require("trouble").jump_only(opts)

-- Open the item in a split
---@param opts? trouble.Mode | { new? : boolean } | string
---@return trouble.View
require("trouble").jump_split(opts)

-- Open the item in a split and close the trouble window
---@param opts? trouble.Mode | { new? : boolean } | string
---@return trouble.View
require("trouble").jump_split_close(opts)

-- Open the item in a vsplit
---@param opts? trouble.Mode | { new? : boolean } | string
---@return trouble.View
require("trouble").jump_vsplit(opts)

-- Open the item in a vsplit and close the trouble window
---@param opts? trouble.Mode | { new? : boolean } | string
---@return trouble.View
require("trouble").jump_vsplit_close(opts)

-- Go to the last item
---@param opts? trouble.Mode | { new? : boolean } | string
---@return trouble.View
require("trouble").last(opts)

-- Go to the next item
---@param opts? trouble.Mode | { new? : boolean } | string
---@return trouble.View
require("trouble").next(opts)

-- Go to the previous item
---@param opts? trouble.Mode | { new? : boolean } | string
---@return trouble.View
require("trouble").prev(opts)

-- Open the preview
---@param opts? trouble.Mode | { new? : boolean } | string
---@return trouble.View
require("trouble").preview(opts)

-- Refresh the trouble source
---@param opts? trouble.Mode | { new? : boolean } | string
---@return trouble.View
require("trouble").refresh(opts)

-- Toggle the preview
---@param opts? trouble.Mode | { new? : boolean } | string
---@return trouble.View
require("trouble").toggle_preview(opts)

-- Toggle the auto refresh
---@param opts? trouble.Mode | { new? : boolean } | string
---@return trouble.View
require("trouble").toggle_refresh(opts)
```

<!-- api:end -->

</details>

### Telescope

You can easily open any search results in **Trouble**, by defining a custom action:

```lua
local actions = require("telescope.actions")
local open_with_trouble = require("trouble.sources.telescope").open

-- Use this to add more results without clearing the trouble list
local add_to_trouble = require("trouble.sources.telescope").add

local telescope = require("telescope")

telescope.setup({
  defaults = {
    mappings = {
      i = { ["<c-t>"] = open_with_trouble },
      n = { ["<c-t>"] = open_with_trouble },
    },
  },
})
```

When you open telescope, you can now hit `<c-t>` to open the results in **Trouble**

### fzf-lua

You can easily open any search results in **Trouble**, by defining a custom action:

```lua
local config = require("fzf-lua.config")
local actions = require("trouble.sources.fzf").actions
config.defaults.actions.files["ctrl-t"] = actions.open
```

When you open fzf-lua, you can now hit `<c-t>` to open the results in **Trouble**

### Statusline Component

Example for [lualine.nvim](https://github.com/nvim-lualine/lualine.nvim):

```lua
{
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    local trouble = require("trouble")
    local symbols = trouble.statusline({
      mode = "lsp_document_symbols",
      groups = {},
      title = false,
      filter = { range = true },
      format = "{kind_icon}{symbol.name:Normal}",
      -- The following line is needed to fix the background color
      -- Set it to the lualine section you want to use
      hl_group = "lualine_c_normal",
    })
    table.insert(opts.sections.lualine_c, {
      symbols.get,
      cond = symbols.has,
    })
  end,
}
```

## 🎨 Colors

The table below shows all the highlight groups defined for Trouble.

<details><summary>Highlight Groups</summary>

<!-- colors:start -->

| Highlight Group | Default Group | Description |
| --- | --- | --- |
| **TroubleBasename** | ***TroubleFilename*** |  |
| **TroubleCode** | ***Special*** |  |
| **TroubleCount** | ***TabLineSel*** |  |
| **TroubleCursorLine** | ***CursorLine*** |  |
| **TroubleDirectory** | ***Directory*** |  |
| **TroubleFilename** | ***Directory*** |  |
| **TroubleIconArray** | ***@punctuation.bracket*** |  |
| **TroubleIconBoolean** | ***@boolean*** |  |
| **TroubleIconClass** | ***@type*** |  |
| **TroubleIconConstant** | ***@constant*** |  |
| **TroubleIconConstructor** | ***@constructor*** |  |
| **TroubleIconDirectory** | ***Special*** |  |
| **TroubleIconEnum** | ***@lsp.type.enum*** |  |
| **TroubleIconEnumMember** | ***@lsp.type.enumMember*** |  |
| **TroubleIconEvent** | ***Special*** |  |
| **TroubleIconField** | ***@variable.member*** |  |
| **TroubleIconFile** | ***Normal*** |  |
| **TroubleIconFunction** | ***@function*** |  |
| **TroubleIconInterface** | ***@lsp.type.interface*** |  |
| **TroubleIconKey** | ***@lsp.type.keyword*** |  |
| **TroubleIconMethod** | ***@function.method*** |  |
| **TroubleIconModule** | ***@module*** |  |
| **TroubleIconNamespace** | ***@module*** |  |
| **TroubleIconNull** | ***@constant.builtin*** |  |
| **TroubleIconNumber** | ***@number*** |  |
| **TroubleIconObject** | ***@constant*** |  |
| **TroubleIconOperator** | ***@operator*** |  |
| **TroubleIconPackage** | ***@module*** |  |
| **TroubleIconProperty** | ***@property*** |  |
| **TroubleIconString** | ***@string*** |  |
| **TroubleIconStruct** | ***@lsp.type.struct*** |  |
| **TroubleIconTypeParameter** | ***@lsp.type.typeParameter*** |  |
| **TroubleIconVariable** | ***@variable*** |  |
| **TroubleIndent** | ***LineNr*** |  |
| **TroubleIndentFoldClosed** | ***CursorLineNr*** |  |
| **TroubleIndentFoldOpen** | ***TroubleIndent*** |  |
| **TroubleIndentLast** | ***TroubleIndent*** |  |
| **TroubleIndentMiddle** | ***TroubleIndent*** |  |
| **TroubleIndentTop** | ***TroubleIndent*** |  |
| **TroubleIndentWs** | ***TroubleIndent*** |  |
| **TroubleNormal** | ***NormalFloat*** |  |
| **TroubleNormalNC** | ***NormalFloat*** |  |
| **TroublePos** | ***LineNr*** |  |
| **TroublePreview** | ***Visual*** |  |
| **TroubleSource** | ***Comment*** |  |
| **TroubleText** | ***Normal*** |  |

<!-- colors:end -->

</details>
