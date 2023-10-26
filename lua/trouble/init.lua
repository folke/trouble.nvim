---@class trouble: trouble.api
local M = {}

---@param opts? trouble.Config
function M.setup(opts)
  require("trouble.config").setup(opts)
end

return setmetatable(M, {
  __index = function(_, k)
    return require("trouble.api")[k]
  end,
})
