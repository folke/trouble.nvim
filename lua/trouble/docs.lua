local Config = require("trouble.config")
local Docs = require("lazy.docs")

local M = {}

function M.update()
  local config = Docs.extract("lua/trouble/config/init.lua", "\n(--@class trouble%.Config.-\n})")
  config = config:gsub("%s*debug = false.\n", "\n")
  Docs.save({
    config = config,
    colors = Docs.colors({
      modname = "trouble.config.highlights",
      path = "lua/trouble/config/highlights.lua",
      name = "Trouble",
    }),
    modes = M.modes(),
  })
end

---@return ReadmeBlock
function M.modes()
  ---@type string[]
  local lines = {}

  local modes = Config.modes()
  for _, mode in ipairs(modes) do
    local m = Config.get(mode)
    lines[#lines + 1] = ("- **%s**: %s"):format(mode, m.desc or "")
  end

  return { content = table.concat(lines, "\n") }
end

M.update()

return M
