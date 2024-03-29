# 🚦 Trouble v3 Beta

A pretty list for showing diagnostics, references, telescope results, quickfix and location lists to help you solve all the trouble your code is causing.

![image](https://github.com/folke/trouble.nvim/assets/292349/481bc1f7-cb93-432d-8ab6-f54044334b96)

## ✨ Features

- Diagnostics
- LSP references
- LSP implementations
- LSP definitions
- LSP type definitions
- LSP Document Symbols
- quickfix list
- location list
- [Telescope](https://github.com/nvim-telescope/telescope.nvim) search results

## 📰 What's new?

This is a full rewrite of the original **trouble.nvim**.

The new version is much more flexible and powerful,
with a lot of new features and improvements:

- multiple trouble windows at the same time
- LSP document symbols
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
  branch = "dev", -- IMPORTANT!
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
  focus = false, -- Focus the window when opened
  follow = true, -- Follow the current item
  indent_guides = true, -- show indent guides
  max_items = 200, -- limit number of items that can be displayed per section
  multiline = true, -- render multi-line messages
  pinned = false, -- When pinned, the opened trouble window will be bound to the current buffer
  ---@type trouble.Window.opts
  win = {}, -- window options for the results window. Can be a split or a floating window.
  -- Window options for the preview window. Can be a split, floating window,
  -- or `main` to show the preview in the main editor window.
  ---@type trouble.Window.opts
  preview = { type = "main" },
  -- Throttle/Debounce settings. Should usually not be changed.
  ---@type table<string, number|{ms:number, debounce?:boolean}>
  throttle = {
    refresh = 20, -- fetches new data when needed
    update = 10, -- updates the window
    render = 10, -- renders the window
    follow = 10, -- follows the current item
    preview = { ms = 100, debounce = true }, -- shows the preview for the current item
  },
  -- Key mappings can be set to the name of a builtin action,
  -- or you can define your own custom action.
  ---@type table<string, string|trouble.Action>
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
  },
  ---@type table<string, trouble.Mode>
  modes = {
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
  - `Trouble symbols toggle pinned=true results.win.relative=win results.win.position=right`
- You can use **lua** code in the options for the `Trouble` command.
  The examples below all do the same thing.
  - `Trouble diagnostics filter.severity=vim.diagnostic.severity.ERROR`
  - `Trouble diagnostics filter.severity = vim.diagnostic.severity.ERROR`
  - `Trouble diagnostics filter = { severity=vim.diagnostic.severity.ERROR }`
- Merging of nested options, with or without quoting strings:
  - `Trouble diagnostics results.win.type = split result.win.position=right`
  - `Trouble diagnostics results.win = { type = split, position=right}`
  - `Trouble diagnostics results.win = { type = "split", position='right'}`

Please refer to the API section for more information on the available actions and options.

Modes:

<!-- modes:start -->

- **diagnostics**: diagnostics
- **loclist**: Location List
- **lsp**: LSP definitions, references, implementations, type definitions, and declarations
- **lsp_declarations**: declarations
- **lsp_definitions**: definitions
- **lsp_document_symbols**: document symbols
- **lsp_implementations**: implementations
- **lsp_references**: references
- **lsp_type_definitions**: type definitions
- **qflist**: Quickfix List
- **quickfix**: Quickfix List
- **symbols**: document symbols
- **telescope**: Telescope results previously opened with `require('trouble.sources.telescope').open()`.

<!-- modes:end -->

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
---@param opts? trouble.Mode | { new?: boolean } | string
---@return trouble.View
require("trouble").open(opts)

-- Closes the last open view matching the filter.
---@param opts? trouble.Mode|string
---@return trouble.View?
require("trouble").close(opts)

-- Toggle the view with the given mode.
---@param opts? trouble.Mode|string
---@return trouble.View
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
---@param opts? trouble.Mode|string
---@return {get: (fun():string), has: (fun():boolean)}
require("trouble").statusline(opts)

-- Closes the preview and goes to the main window.
-- The Trouble window is not closed.
---@param opts? trouble.Mode | { new? : boolean } | string
---@return trouble.View
require("trouble").cancel(opts)

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

-- Open the item in a vsplit
---@param opts? trouble.Mode | { new? : boolean } | string
---@return trouble.View
require("trouble").jump_vsplit(opts)

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

| Highlight Group              | Default Group                 | Description |
| ---------------------------- | ----------------------------- | ----------- |
| **TroubleCount**             | **_TabLineSel_**              |             |
| **TroubleDirectory**         | **_Directory_**               |             |
| **TroubleFileName**          | **_Directory_**               |             |
| **TroubleIconArray**         | **_@punctuation.bracket_**    |             |
| **TroubleIconBoolean**       | **_@boolean_**                |             |
| **TroubleIconClass**         | **_@type_**                   |             |
| **TroubleIconConstant**      | **_@constant_**               |             |
| **TroubleIconConstructor**   | **_@constructor_**            |             |
| **TroubleIconDirectory**     | **_Special_**                 |             |
| **TroubleIconEnum**          | **_@lsp.type.enum_**          |             |
| **TroubleIconEnumMember**    | **_@lsp.type.enumMember_**    |             |
| **TroubleIconEvent**         | **_Special_**                 |             |
| **TroubleIconField**         | **_@variable.member_**        |             |
| **TroubleIconFile**          | **_Normal_**                  |             |
| **TroubleIconFunction**      | **_@function_**               |             |
| **TroubleIconInterface**     | **_@lsp.type.interface_**     |             |
| **TroubleIconKey**           | **_@lsp.type.keyword_**       |             |
| **TroubleIconMethod**        | **_@function.method_**        |             |
| **TroubleIconModule**        | **_@module_**                 |             |
| **TroubleIconNamespace**     | **_@module_**                 |             |
| **TroubleIconNull**          | **_@constant.builtin_**       |             |
| **TroubleIconNumber**        | **_@number_**                 |             |
| **TroubleIconObject**        | **_@constant_**               |             |
| **TroubleIconOperator**      | **_@operator_**               |             |
| **TroubleIconPackage**       | **_@module_**                 |             |
| **TroubleIconProperty**      | **_@property_**               |             |
| **TroubleIconString**        | **_@string_**                 |             |
| **TroubleIconStruct**        | **_@lsp.type.struct_**        |             |
| **TroubleIconTypeParameter** | **_@lsp.type.typeParameter_** |             |
| **TroubleIconVariable**      | **_@variable_**               |             |
| **TroubleIndent**            | **_LineNr_**                  |             |
| **TroubleIndentFoldClosed**  | **_CursorLineNr_**            |             |
| **TroubleIndentFoldOpen**    | **_TroubleIndent_**           |             |
| **TroubleIndentLast**        | **_TroubleIndent_**           |             |
| **TroubleIndentMiddle**      | **_TroubleIndent_**           |             |
| **TroubleIndentTop**         | **_TroubleIndent_**           |             |
| **TroubleIndentWs**          | **_TroubleIndent_**           |             |
| **TroubleNormal**            | **_NormalFloat_**             |             |
| **TroubleNormalNC**          | **_NormalFloat_**             |             |
| **TroublePos**               | **_LineNr_**                  |             |
| **TroublePreview**           | **_Visual_**                  |             |
| **TroubleSource**            | **_Comment_**                 |             |
| **TroubleText**              | **_Normal_**                  |             |

<!-- colors:end -->

</details>
