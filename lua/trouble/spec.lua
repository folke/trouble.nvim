---@alias trouble.Sorter fun(item: trouble.Item): any?

---@alias trouble.spec.sort string|trouble.Sorter|(string|trouble.Sorter|trouble.spec.filter)[]
---@alias trouble.spec.filter table<string, any>|fun(item: trouble.Item): boolean
---@alias trouble.spec.group string|string[]|{format?:string}
---@alias trouble.spec.section {source: string, groups: trouble.spec.group[]|trouble.spec.group, sort?: trouble.spec.sort, filter?: trouble.spec.filter, format?:string}
---

---@alias trouble.Sort ({field:string, desc?:boolean}|trouble.Sorter|trouble.Filter)[]
---@alias trouble.Filter table<string, any>|fun(item: trouble.Item): boolean
---@alias trouble.Group {fields: string[], format: string}
---@alias trouble.Section {source: string, groups: trouble.Group[], sort?: trouble.Sort, filter?: trouble.Filter, format?:string, max_items?:number}

local M = {}

---@param spec trouble.spec.section
---@return trouble.Section
function M.section(spec)
  local groups = type(spec.groups) == "string" and { spec.groups } or spec.groups
  ---@cast groups trouble.spec.group[]
  return {
    source = spec.source,
    groups = vim.tbl_map(M.group, groups),
    sort = spec.sort and M.sort(spec.sort) or nil,
    filter = spec.filter,
    format = spec.format or "{filename} {pos}",
  }
end

---@param spec trouble.spec.section|trouble.spec.section[]
---@return trouble.Section[]
function M.sections(spec)
  spec = vim.tbl_islist(spec) and spec or { spec }
  return vim.tbl_map(M.section, spec)
end

---@param spec trouble.spec.sort
---@return trouble.Sort
function M.sort(spec)
  spec = type(spec) == "table" and spec or { spec }
  ---@cast spec (trouble.Sort|string)[]
  ---@param s trouble.Sort|string
  return vim.tbl_map(function(s)
    if type(s) == "string" then
      local desc = s:sub(1, 1) == "-"
      return {
        field = desc and s:sub(2) or s,
        desc = desc and true or nil,
      }
    end
    return s
  end, spec)
end

---@param spec trouble.spec.group
---@return trouble.Group
function M.group(spec)
  spec = type(spec) == "string" and { spec } or spec
  ---@cast spec string[]|{sort?:trouble.spec.sort}
  ---@type trouble.Group
  local ret = { fields = {} }
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
  -- ret.sort = ret.sort or M.sort(ret.fields)
  ret.fields = vim.tbl_map(function(s)
    return s:gsub("^%-", "")
  end, ret.fields)
  ret.format = ret.format
    or table.concat(
      vim.tbl_map(function(f)
        return "{" .. f .. "}"
      end, ret.fields),
      " "
    )
  return ret
end

return M
