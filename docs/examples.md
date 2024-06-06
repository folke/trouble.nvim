# Examples

## Window Options

### Preview in small float top right

![image](https://github.com/folke/trouble.nvim/assets/292349/f422b8fd-579e-427b-87d3-62daab85d2e0)

```lua
{
  modes = {
    preview_float = {
      mode = "diagnostics",
      preview = {
        type = "float",
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
}
```

### Preview in a split to the right of the trouble list

![image](https://github.com/folke/trouble.nvim/assets/292349/adfa02df-b3dd-4c90-af3c-41683c0b5356)

```lua
{
  modes = {
    test = {
      mode = "diagnostics",
      preview = {
        type = "split",
        relative = "win",
        position = "right",
        size = 0.3,
      },
    },
  },
}
```

### Make Trouble look like v2

```lua
{
  icons = {
    indent = {
      middle = " ",
      last = " ",
      top = " ",
      ws = "│  ",
    },
  },
  modes = {
    diagnostics = {
      groups = {
        { "filename", format = "{file_icon} {basename:Title} {count}" },
      },
    },
  },
}
```

## Filtering

### Diagnostics for the current buffer only

```lua
{
  modes = {
    diagnostics_buffer = {
      mode = "diagnostics", -- inherit from diagnostics mode
      filter = { buf = 0 }, -- filter diagnostics to the current buffer
    },
  }
}
```

### Diagnostics for the current buffer and errors from the current project

```lua
{
  modes = {
    mydiags = {
      mode = "diagnostics", -- inherit from diagnostics mode
      filter = {
        any = {
          buf = 0, -- current buffer
          {
            severity = vim.diagnostic.severity.ERROR, -- errors only
            -- limit to files in the current project
            function(item)
              return item.filename:find((vim.loop or vim.uv).cwd(), 1, true)
            end,
          },
        },
      },
    }
  }
}
```

### Diagnostics Cascade

The following example shows how to create a new mode that
shows only the most severe diagnostics.

Once those are resolved, less severe diagnostics will be shown.

```lua
{
  modes = {
    cascade = {
      mode = "diagnostics", -- inherit from diagnostics mode
      filter = function(items)
        local severity = vim.diagnostic.severity.HINT
        for _, item in ipairs(items) do
          severity = math.min(severity, item.severity)
        end
        return vim.tbl_filter(function(item)
          return item.severity == severity
        end, items)
      end,
    },
  },
}
```

## Other

### Automatically Open Trouble Quickfix

```lua
vim.api.nvim_create_autocmd("QuickFixCmdPost", {
  callback = function()
    vim.cmd([[Trouble qflist open]])
  end,
})
```

Test with something like `:silent grep vim %`

### Open Trouble Quickfix when the qf list opens

> This is **NOT** recommended, since you won't be able to use the quickfix list for other things.

```lua

vim.api.nvim_create_autocmd("BufRead", {
  callback = function(ev)
    if vim.bo[ev.buf].buftype == "quickfix" then
      vim.schedule(function()
        vim.cmd([[cclose]])
        vim.cmd([[Trouble qflist open]])
      end)
    end
  end,
})
```
