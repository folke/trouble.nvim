---@alias trouble.SorterFn fun(item: trouble.Item): any?

---@alias trouble.Sort.spec string|trouble.SorterFn|(string|trouble.SorterFn|trouble.Filter.spec)[]
---@alias trouble.Filter.spec table<string, any>|fun(items: trouble.Item[]): trouble.Item[]
---@alias trouble.Group.spec string|string[]|{format?:string}

---@alias trouble.Sections.spec (trouble.Section.spec|string)[]

---@class trouble.Section.spec
---@field source string
---@field title? string
---@field events? string[]
---@field groups? trouble.Group.spec[]|trouble.Group.spec
---@field sort? trouble.Sort.spec
---@field filter? trouble.Filter.spec
---@field format? string
---@field max_items? number

---@alias trouble.Filter table<string, any>|fun(items: trouble.Item[]): trouble.Item[]

---@class trouble.Sort
---@field field? string
---@field sorter? trouble.SorterFn
---@field filter? trouble.Filter
---@field desc? boolean

---@class trouble.Group
---@field fields string[]
---@field format string

---@class trouble.Section
---@field source string
---@field groups trouble.Group[]
---@field format string
---@field events? string[]
---@field sort? trouble.Sort[]
---@field filter? trouble.Filter
---@field max_items? number

local M = {}

---@param spec trouble.Section.spec|string
---@return trouble.Section
function M.section(spec)
  local groups = type(spec.groups) == "string" and { spec.groups } or spec.groups
  ---@cast groups trouble.Group.spec[]
  local ret = {
    source = spec.source,
    groups = vim.tbl_map(M.group, groups or {}),
    sort = spec.sort and M.sort(spec.sort) or nil,
    filter = spec.filter,
    format = spec.format or "{filename} {pos}",
    events = spec.events,
  }
  -- A title is just a group without fields
  if spec.title then
    table.insert(ret.groups, 1, { fields = {}, format = spec.title })
  end
  return ret
end

---@param spec trouble.Section.spec|trouble.Section.spec[]
---@return trouble.Section[]
function M.sections(spec)
  spec = vim.tbl_islist(spec) and spec or { spec }
  return vim.tbl_map(M.section, spec)
end

---@param spec trouble.Sort.spec
---@return trouble.Sort[]
function M.sort(spec)
  spec = type(spec) == "table" and vim.tbl_islist(spec) and spec or { spec }
  ---@cast spec (string|trouble.SorterFn|trouble.Filter.spec)[]
  local fields = {} ---@type trouble.Sort[]
  for f, field in ipairs(spec) do
    if type(field) == "function" then
      ---@cast field trouble.SorterFn
      fields[f] = { sorter = field }
    elseif type(field) == "table" and field.field then
      ---@cast field {field:string, desc?:boolean}
      fields[f] = field
    elseif type(field) == "table" then
      fields[f] = { filter = field }
    elseif type(field) == "string" then
      local desc = field:sub(1, 1) == "-"
      fields[f] = {
        field = desc and field:sub(2) or field,
        desc = desc and true or nil,
      }
    else
      error("invalid sort field: " .. vim.inspect(field))
    end
  end
  return fields
end

---@param spec trouble.Group.spec
---@return trouble.Group
function M.group(spec)
  spec = type(spec) == "string" and { spec } or spec
  ---@cast spec string[]|{format?:string}
  ---@type trouble.Group
  local ret = { fields = {}, format = "" }
  for k, v in pairs(spec) do
    if type(k) == "number" then
      ---@cast v string
      ret.fields[#ret.fields + 1] = v
    elseif k == "format" then
      ---@cast v string
      ret.format = v
    else
      error("invalid `group` key: " .. k)
    end
  end
  ret.format = ret.format and ret.format ~= "" and ret.format
    or table.concat(
      ---@param f string
      vim.tbl_map(function(f)
        return "{" .. f .. "}"
      end, ret.fields),
      " "
    )
  return ret
end

return M
