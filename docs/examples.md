# Examples

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
              return item.filename:find(vim.loop.cwd(), 1, true)
            end,
          },
        },
      },
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
