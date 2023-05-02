-- severity filters

local DiagnosticSeverity = vim.lsp.protocol.DiagnosticSeverity

--@class Severity
local M = {}

----------------------------------
-- config validation --
----------------------------------

-- this is a bit overboard to validate these settings, but fun
local to_severity = function(severity)
  if not severity then return nil end
  return type(severity) == 'string' and DiagnosticSeverity[severity] or severity
end
local severity_keys = vim.tbl_keys(DiagnosticSeverity)
local severity_names = vim.tbl_filter(function(a) return type(a) == "string" end, severity_keys)
table.sort(severity_names, function (a, b) return to_severity(a) < to_severity(b) end)
local severity_names_joined = table.concat(severity_names, ", ")
local severity_expected = "nil, number in range 1..=4, or {"..severity_names_joined .. "}"
local function sev_validate(s)
  -- Diagnostics
  return vim.tbl_contains(severity_keys, s)
end
local function opt_sev_validate(s)
  if s == nil then return true end
  if type(s) == 'number' then return s end
  return sev_validate(s)
end

-- @param options TroubleOptions
function M.fix_config(options)
  vim.validate {
    min_severity = { options.min_severity, opt_sev_validate, severity_expected },
    cascading_severity = { options.cascading_severity, opt_sev_validate, severity_expected },
  }
  -- make them 1..=4 or nil
  options.min_severity = to_severity(options.min_severity)
  -- min_severity being Hint just runs a no-op filter, so ignore it
  if options.min_severity == 4 then
    options.min_severity = nil
  end
  options.cascading_severity = to_severity(options.cascading_severity)
end

----------------------------------
-- handling keybindings/actions --
----------------------------------

-- counter-intuitive. LSP severities are backwards.
-- nil is least severe (no filter), 4 is next smallest (Hint), 1 is most severe (Error)
-- however, 4/Hint is meaningless for min_severity.
-- min and max are not counter intuitive. They represent the min and max of the range of acceptable values.
local function incr_sev(min, max)
  return function(s)
    if s == nil then return max
    elseif s <= min then return min -- can't get more severe than {min}
    elseif s >= max then return max - 1
    else return s - 1
    end
  end
end

local function decr_sev(min, max)
  return function(s)
    if s == nil then return nil -- can't get less severe than nil
    elseif s >= max then return nil
    elseif s <= min then return min+1
    else return s + 1
    end
  end
end

-- not the greatest lua test harness ever, but it works
-- :lua require'trouble.severity'.__run_tests()
function M.__run_tests()
  local function testit(start, fn, to_eq)
    local x = start
    for i, v in ipairs(to_eq) do
      x = fn(x)
      assert((x or "nil") == v, "x ("..(x or "nil")..") should = to_eq["..i.."] = "..(v or "nil").."; "..vim.inspect(to_eq))
    end
  end

  testit(nil, incr_sev(1, 3), { 3, 2, 1, 1, 1 })
  testit(1, decr_sev(1, 3), { 2, 3, "nil", "nil" })
  testit(nil, incr_sev(1, 4), { 4, 3, 2, 1, 1 })
  testit(1, decr_sev(1, 4), { 2, 3, 4, "nil", "nil" })

  assert(incr_sev(1, 4)(500) == 3, 'incr on 500 should be 3')
  assert(incr_sev(1, 4)(0) == 1, 'incr on 0 should be 1')
  assert(decr_sev(1, 4)(0) == 2, 'decr on zero should be 2')
  assert(decr_sev(1, 4)(500) == nil, 'decr on 500 should be nil')
  print("trouble.severity tests passed")
end

-- for Trouble.action
local severity_actions = {
  "incr_min_severity",
  "decr_min_severity",
  "incr_cascading_severity",
  "decr_cascading_severity",
}
function M.handles_action(action)
  return vim.tbl_contains(severity_actions, action)
end

-- for Trouble.action
function M.apply_action(action, config)
  local fn = nil
  local key = nil
  if     action == "incr_min_severity"       then fn = incr_sev(1, 3); key = "min_severity"
  elseif action == "decr_min_severity"       then fn = decr_sev(1, 3); key = "min_severity"
  elseif action == "incr_cascading_severity" then fn = incr_sev(1, 4); key = "cascading_severity_threshold"
  elseif action == "decr_cascading_severity" then fn = decr_sev(1, 4); key = "cascading_severity_threshold"
  else error("trouble.severity.apply_action called on unknown action '" .. action .. "'") end
  -- print("trouble.severity: applying action " .. action .. " to key " .. key)
  local prev_sev = config.options[key]
  config.options[key] = fn(prev_sev)
end

--------------------------
-- filtering severities --
--------------------------

-- Note that LSP severities are backwards in the sense that "Error"=1, "Warning"=2, "Info"=3, "Hint"=4.
-- So "Hint" is the highest number but not the most severe.
-- When we say min_severity in the code, it means we are filtering by <= the LSP severity number.

-- must pass an integer severity to these
local function eq_severity_fn(severity)
  return function(t) return t.severity == severity end
end
local function min_severity_fn(severity)
  -- recall LSP DiagnosticSeverity being backwards
  return function(t) return t.severity <= severity end
end

--- Filters using a function. Returns a new table, and the number of diagnostics left out
---
--- @param items Item[]
--- @return Item[], number
local function filter_diags(items, filter_fn)
  local filtered = vim.tbl_filter(filter_fn, items)
  local hidden = #items - #filtered
  return filtered, hidden
end

local function mk_msg(m, t, o)
 if m == nil and t == nil and o == nil then return "" end
 return "(" .. table.concat(vim.tbl_filter(function(x) return x ~= nil end, { m, t, o }), ", ") .. ")"
end

-- @param options TroubleOptions
-- @param items Item[]
-- @return Item[], string
function M.filter_severities(options, items)
  -- these are 1..=4 integers or nil, because of M.fix_config above
  local min_sev = options.min_severity
  local cascading_sev = options.cascading_severity_threshold

  -- min_sev applies even when cascading_sev is enabled.
  -- so treat it as a pre-filter.
  local min_hidden = 0
  if min_sev ~= nil then
    items, min_hidden = filter_diags(items, min_severity_fn(min_sev))
  end

  local eq_hidden = 0
  local eq_chosen = nil
  if cascading_sev ~= nil then
    if min_sev ~= nil and min_sev < cascading_sev then
      -- just save a few useless loop iterations
      cascading_sev = min_sev
    end
    -- comments here show what happens if cascading_severity_threshold is set to "Information"
    -- =>> if we have no errors, show warnings; if we have no warnings, show the rest
    local try = items
    for sev=1,cascading_sev do
      if sev == cascading_sev then
        -- we got to the Information level, so that means we couldn't find any Warning/Error diags
        -- therefore, show everything means show Info + Hint.
        -- We have already filtered away anything less than min_sev.
        try = items
        break
      end
      local h
      try, h = filter_diags(items, eq_severity_fn(sev))
      -- if we get any results at all, stop and display them
      if not vim.tbl_isempty(try) then
        eq_chosen = DiagnosticSeverity[sev]
        eq_hidden = h
        break
      end
    end
    items = try
  end
  local msg = nil
  local total_hidden = min_hidden + eq_hidden
  local some_hidden = total_hidden .. " diagnostic".. (total_hidden > 1 and "s" or "") .." hidden "
  local min_is = min_sev ~= nil and ("min = "..DiagnosticSeverity[min_sev]) or nil
  local cascade_threshold = options.cascading_severity_threshold
  cascade_threshold = (cascade_threshold == 4 and "cascade enabled")
    or (cascade_threshold ~= nil and "cascade <= " .. DiagnosticSeverity[cascade_threshold])
    or nil
  local eq_chosen_is = eq_hidden > 0 and ("only showing "..eq_chosen) or nil
  if total_hidden > 0 then
    msg = some_hidden .. mk_msg(min_is, cascade_threshold, eq_chosen_is)
  else
    msg = mk_msg(min_is, cascade_threshold, nil)
  end
  return items, msg
end


return M

