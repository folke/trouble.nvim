local T = require("trouble.sources.telescope")

return setmetatable({}, {
  __index = function(_, k)
    require("trouble.util").warn(
      ([[
`%s()` is deprecated
```lua
-- Use this:
require("trouble.sources.telescope").open()

-- Instead of:
require("trouble.providers.telescope").%s()
]]):format(k, k),
      { once = true }
    )
    return T.open
  end,
})
