# 🚦 Trouble

A pretty list for showing diagnostics, references, telescope results, quickfix and location lists to help you solve all the trouble your code is causing.

![LSP Trouble Screenshot](./media/shot.png)

## ✨ Features

- pretty list of:
  - Diagnostics
  - LSP references
  - LSP implementations
  - LSP definitions
  - LSP type definitions
  - quickfix list
  - location list
  - [Telescope](https://github.com/nvim-telescope/telescope.nvim) search results
- automatically updates on new diagnostics
- toggle **diagnostics** mode between **workspace** or **document**
- **interactive preview** in your last accessed window
- _cancel_ preview or _jump_ to the location
- configurable actions, signs, highlights,...

## ⚡️ Requirements

- Neovim >= 0.7.2
- Properly configured Neovim LSP client
- [nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons) is optional to enable file icons
- a theme with properly configured highlight groups for Neovim Diagnostics
- or install 🌈 [lsp-colors](https://github.com/folke/lsp-colors.nvim) to automatically create the missing highlight groups
- a [patched font](https://www.nerdfonts.com/) for the default severity and fold icons

## 📦 Installation

Install the plugin with your preferred package manager:

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "folke/trouble.nvim",
  branch = "dev",
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
  throttle = 100,
  pinned = false,
  results = {
    ---@type trouble.Window.opts
    win = {},
    indent_guides = true, -- show indent guides
    multiline = true, -- render multi-line messages
    max_items = 200, -- limit number of items that can be displayed per section
    auto_open = false,
    auto_close = false,
    auto_refresh = true,
  },
  preview = {
    -- preview window, or "main", to show the preview in
    -- the main editor window
    ---@type trouble.Window.opts
    win = { type = "main" },
    auto_open = true, -- automatically open preview when on an item
  },
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
    diagnostics_buffer = {
      desc = "buffer diagnostics",
      mode = "diagnostics",
      filter = { buf = 0 },
    },
    symbols = {
      desc = "document symbols",
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
    preview_float = {
      mode = "diagnostics",
      preview = {
        win = {
          type = "float",
          -- position = "right",
          relative = "editor",
          border = "rounded",
          title = "Preview",
          title_pos = "center",
          position = { 0, -2 },
          size = { width = 0.3, height = 0.3 },
          zindex = 200,
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

## 🚀 Usage

### Commands

The **Trouble** command is a wrapper around the **Trouble** API.

- `Trouble [mode] [action] [options]`

Some examples:

- Toggle diagnostics for the current buffer and stay in the current window:
  - `Trouble diagnostics toggle focus=false filter.buf=0`
- Show document symbols on the right of the current window.
  Keep the document symbols in sync with the buffer you started the command in.
  - `Trouble symbols toggle pinned=true results.win.relative=win position=right`

Please refer to the API section for more information on the available actions and options.

Modes:

<!-- modes:start -->

- **diagnostics**: diagnostics
- **diagnostics_buffer**: buffer diagnostics
- **fs**:
- **loclist**: Location List
- **lsp**: LSP definitions, references, implementations, type definitions, and declarations
- **lsp_declarations**: declarations
- **lsp_definitions**: definitions
- **lsp_document_symbols**: document symbols
- **lsp_implementations**: implementations
- **lsp_references**: references
- **lsp_type_definitions**: type definitions
- **preview_float**: diagnostics
- **qflist**: Quickfix List
- **quickfix**: Quickfix List
- **symbols**: document symbols
- **telescope**: Telescope results previously opened with `require('trouble.sources.telescope').open()`.
- **todo**:

<!-- modes:end -->

### API

You can use the following functions in your keybindings:

<details><summary>API</summary>

<!-- api:start -->

```lua
---@alias trouble.Open trouble.Mode|{focus?:boolean, new?:boolean}

--- Finds all open views matching the filter.
---@param opts? trouble.Config|string
---@param filter? trouble.View.filter
---@return trouble.View[], trouble.Config
require("trouble").find(opts, filter)

--- Finds the last open view matching the filter.
---@param opts? trouble.Open|string
---@param filter? trouble.View.filter
---@return trouble.View?, trouble.Open
require("trouble").find_last(opts, filter)

--- Gets the last open view matching the filter or creates a new one.
---@param opts? trouble.Config|string
---@param filter? trouble.View.filter
---@return trouble.View, trouble.Open
require("trouble").get(opts, filter)

---@param opts? trouble.Open|string
require("trouble").open(opts)

--- Returns true if there is an open view matching the filter.
---@param opts? trouble.Config|string
require("trouble").is_open(opts)

---@param opts? trouble.Config|string
require("trouble").close(opts)

---@param opts? trouble.Open|string
require("trouble").toggle(opts)

--- Special case for refresh. Refresh all open views.
---@param opts? trouble.Config|string
require("trouble").refresh(opts)

--- Proxy to last view's action.
---@param action trouble.Action|string
require("trouble").action(action)

---@param opts? trouble.Config|string
require("trouble").get_items(opts)

---@param opts? trouble.Config|string
---@return {get: fun():string, cond: fun():boolean}
require("trouble").statusline(opts)

-- cancel
require("trouble").cancel()

-- close
require("trouble").close()

-- first
require("trouble").first()

-- focus
require("trouble").focus()

-- Fold close
require("trouble").fold_close()

-- fold close all
require("trouble").fold_close_all()

-- Fold close recursive
require("trouble").fold_close_recursive()

-- fold disable
require("trouble").fold_disable()

-- fold enable
require("trouble").fold_enable()

-- fold more
require("trouble").fold_more()

-- Fold open
require("trouble").fold_open()

-- fold open all
require("trouble").fold_open_all()

-- Fold open recursive
require("trouble").fold_open_recursive()

-- fold reduce
require("trouble").fold_reduce()

-- Fold toggle
require("trouble").fold_toggle()

-- fold toggle enable
require("trouble").fold_toggle_enable()

-- Fold toggle recursive
require("trouble").fold_toggle_recursive()

-- fold update
require("trouble").fold_update()

-- fold update all
require("trouble").fold_update_all()

-- help
require("trouble").help()

-- inspect
require("trouble").inspect()

-- jump
require("trouble").jump()

-- jump close
require("trouble").jump_close()

-- jump only
require("trouble").jump_only()

-- jump split
require("trouble").jump_split()

-- jump vsplit
require("trouble").jump_vsplit()

-- last
require("trouble").last()

-- next
require("trouble").next()

-- prev
require("trouble").prev()

-- preview
require("trouble").preview()

-- previous
require("trouble").previous()

-- refresh
require("trouble").refresh()

-- toggle preview
require("trouble").toggle_preview()

-- toggle refresh
require("trouble").toggle_refresh()
```

<!-- api:end -->

</details>

### Telescope

You can easily open any search results in **Trouble**, by defining a custom action:

```lua
local actions = require("telescope.actions")
local trouble = require("trouble.source.telescope")

local telescope = require("telescope")

telescope.setup({
  defaults = {
    mappings = {
      i = { ["<c-t>"] = trouble.open },
      n = { ["<c-t>"] = trouble.open },
    },
  },
})
```

When you open telescope, you can now hit `<c-t>` to open the results in **Trouble**

## 🎨 Colors

The table below shows all the highlight groups defined for Trouble.

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
| **TroubleIconField**         | **_@field_**                  |             |
| **TroubleIconFile**          | **_Normal_**                  |             |
| **TroubleIconFunction**      | **_@function_**               |             |
| **TroubleIconInterface**     | **_@lsp.type.interface_**     |             |
| **TroubleIconKey**           | **_@lsp.type.keyword_**       |             |
| **TroubleIconMethod**        | **_@method_**                 |             |
| **TroubleIconModule**        | **_@namespace_**              |             |
| **TroubleIconNamespace**     | **_@namespace_**              |             |
| **TroubleIconNull**          | **_@constant.builtin_**       |             |
| **TroubleIconNumber**        | **_@number_**                 |             |
| **TroubleIconObject**        | **_@constant_**               |             |
| **TroubleIconOperator**      | **_@operator_**               |             |
| **TroubleIconPackage**       | **_@namespace_**              |             |
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
| **TroublePos**               | **_LineNr_**                  |             |
| **TroublePreview**           | **_Visual_**                  |             |
| **TroubleSource**            | **_Comment_**                 |             |
| **TroubleText**              | **_Normal_**                  |             |

<!-- colors:end -->
