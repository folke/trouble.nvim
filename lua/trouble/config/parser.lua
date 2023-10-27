local M = {}

---@param t table<any, any>
---@param dotted_key string
---@param value any
function M.dotset(t, dotted_key, value)
  local keys = vim.split(dotted_key, ".", { plain = true })
  for i = 1, #keys - 1 do
    local key = keys[i]
    t[key] = t[key] or {}
    if type(t[key]) ~= "table" then
      t[key] = {}
    end
    t = t[key]
  end
  ---@diagnostic disable-next-line: no-unknown
  t[keys[#keys]] = value
end

---@return {args: string[], opts: table<string, any>, errors: string[]}
function M.parse(input)
  ---@type string?, string?
  local positional, options = input:match("^%s*(.-)%s*([a-z%._]+%s*=.*)$")
  positional = positional or input
  positional = vim.trim(positional)
  local ret = {
    args = positional == "" and {} or vim.split(positional, "%s+"),
    opts = {},
    errors = {},
  }
  if not options then
    return ret
  end
  input = options
  local parser = vim.treesitter.get_string_parser(input, "lua")
  parser:parse()
  local query = vim.treesitter.query.parse(
    "lua",
    [[
      (ERROR) @error
      (assignment_statement (variable_list name: (_)) @name)
      (assignment_statement (expression_list value: (_)) @value)
      (_ value: (identifier) @global (#has-ancestor? @global expression_list))
    ]]
  )
  ---@type table<string, any>
  local env = {
    dotset = M.dotset,
    opts = ret.opts,
  }
  local lines = {} ---@type string[]
  local name = ""
  ---@diagnostic disable-next-line: missing-parameter
  for id, node in query:iter_captures(parser:trees()[1]:root(), input) do
    local capture = query.captures[id]
    local text = vim.treesitter.get_node_text(node, input)
    if capture == "name" then
      name = text
    elseif capture == "value" then
      table.insert(lines, ("dotset(opts, %q, %s)"):format(name, text))
    elseif capture == "global" then
      env[text] = text
    elseif capture == "error" then
      table.insert(ret.errors, text)
    end
  end
  local ok, err = pcall(function()
    local code = table.concat(lines, "\n")
    env.vim = vim
    -- selene: allow(incorrect_standard_library_use)
    local chunk = load(code, "trouble", "t", env)
    chunk()
  end)
  if not ok then
    table.insert(ret.errors, err)
  end
  return ret
end

return M
