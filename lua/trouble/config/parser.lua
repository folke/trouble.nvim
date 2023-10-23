---@diagnostic disable: no-unknown
local lpeg = vim.lpeg
local P, S, R = lpeg.P, lpeg.S, lpeg.R
local C, Ct, Cs = lpeg.C, lpeg.Ct, lpeg.Cs

local M = {}

---@type vim.lpeg.Pattern|Capture
local pattern
do
  -- Basic Definitions
  local ws = S(" \t") ^ 0 -- Optional whitespace
  local eq = P("=") -- Equals sign
  local key_component = R("az", "AZ", "09", "__") ^ 1 -- Single component of a key
  local dot = P(".") -- Dot separator
  local full_key = C(key_component * (dot * key_component) ^ 0) -- Full dot-separated key
  ---@type vim.lpeg.Pattern|Capture
  local value = (P('"') * (P("\\") * P(1) + (1 - P('"'))) ^ 0 * P('"')) -- Values that are quoted strings
    + (1 - S(" \t\n\r")) ^ 1 -- Unquoted values
  local pair = full_key * ws * eq * ws * Cs(value) -- Capture the full key-value pair

  -- Main pattern
  pattern = Ct(ws * pair * (ws * pair) ^ 0 * ws)
end

---@return trouble.Config
function M.parse(input)
  ---@type string[]
  local t = pattern:match(input)
  if not t then
    error("Invalid input: " .. input)
  end

  -- Convert list to a table of key-value pairs
  local parts = {} ---@type string[]
  for i = 1, #t, 2 do
    local k = t[i]
    local v = t[i + 1]
    parts[#parts + 1] = string.format("{%q,%s}", k, v)
  end

  local chunk = loadstring("return {" .. table.concat(parts, ", ") .. "}")
  if not chunk then
    error("Failed to parse input: " .. input)
  end
  local ret = {}
  ---@diagnostic disable-next-line: no-unknown
  for _, pair in pairs(chunk()) do
    M.set(ret, pair[1], pair[2])
  end
  return ret
end

---@param t table
---@param dotted_key string
---@param value any
function M.set(t, dotted_key, value)
  local keys = vim.split(dotted_key, ".", { plain = true })
  for i = 1, #keys - 1 do
    local key = keys[i]
    t[key] = t[key] or {}
    if type(t[key]) ~= "table" then
      t[key] = {}
    end
    t = t[key]
  end
  t[keys[#keys]] = value
end

return M
