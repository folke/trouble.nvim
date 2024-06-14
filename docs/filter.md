# Filter

## Examples

A simple filter is a table whose keys are item attributes.
The following filter keeps items with attribute `buf = 0` **and** `ft = 'lua'`,
i.e., diagnostics with severity error to the current buffer when its filetype is `lua`.

```lua
{
  modes = {
    my_diagnostics = {
      mode = 'diagnostics',
      filter = {
        buf = 0,
        ft = 'lua',
      },
    },
  },
}
```

A filter may be a function that takes `items` as parameter.
The following filter keeps items with severity `HINT`
```lua
{
  modes = {
    my_diagnostics = {
      mode = 'diagnostics',
      filter = function(items)
        return vim.tbl_filter(function(item)
          return item.severity == vim.diagnostic.severity.HINT
        end, items)
      end,
    },
  },
}
```

## Advanced examples

### The `not` filter

The `not` negates filter results.
The following filter **removes** diagnostics with severity `INFO`
```lua
{
  modes = {
    my_diagnostics = {
      mode = 'diagnostics',
      filter = {
        ['not'] = { severity = vim.diagnostic.severity.INFO },
      },
    },
  },
}
```

## Item attributes

Item attributes are documented in `lua/trouble/item.lua`

|     Name     |            Type            |                    Description                     |
| ------------ | -------------------------- | -------------------------------------------------- |
| **buf**      | `number`                   | Buffer id.                                         |
| **filename** | `string`                   | Absolute file path.                                |
| **ft**       | `string` or `string[]`     | File types.                                        |
| **kind**     | `string`                   | Symbol kind. See `:h symbol`.                      |
| **not**      | Loginal `not`              | Filter result negation.                            |
| **pos**      | `{[1]:number, [2]:number}` | Item position.                                     |
| **severity** | `number`                   | Diagnostic severity. See `:h diagnostic-severity`. |