-- severity filters

local DiagnosticSeverity = vim.lsp.protocol.DiagnosticSeverity

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
function sev_validate(s)
  -- Diagnostics
  return vim.tbl_contains(severity_keys, s)
end
function opt_sev_validate(s)
  if s == nil then return true end
  if type(s) == 'number' then return s end
  return sev_validate(s)
end

function M.fix_config(opts)
  vim.validate {
    min_severity = { opts.min_severity, opt_sev_validate, severity_expected },
    cascading_severity = { opts.cascading_severity, opt_sev_validate, severity_expected },
  }
  -- make them 1..=4 or nil
  opts.min_severity = to_severity(opts.min_severity)
  -- min_severity being Hint just runs a no-op filter, so ignore it
  if opts.min_severity == 4 then
    opts.min_severity = nil
  end
  opts.cascading_severity = to_severity(opts.cascading_severity)
end

----------------------------------
-- handling keybindings/actions --
----------------------------------

-- counter-intuitive. LSP severities are backwards.
-- nil is least severe (no filter), 4 is next smallest (Hint), 1 is most severe (Error)
-- however, 4/Hint is meaningless for min_severity.
-- min and max are not counter intuitive. They represent the min and max of the range of acceptable values.
function incr_sev(min, max)
  return function(s)
    if s == nil then return max
    elseif s <= min then return min -- can't get more severe than {min}
    elseif s >= max then return max - 1
    else return s - 1
    end
  end
end

function decr_sev(min, max)
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
  function testit(start, fn, to_eq)
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
function eq_severity_fn(severity)
  return function(t) return t.severity == severity end
end
function min_severity_fn(severity)
  -- recall LSP DiagnosticSeverity being backwards
  return function(t) return t.severity <= severity end
end

--- Filters using a function. Returns a new table, and the number of diagnostics left out
---
--- @param items Diagnostic[]
--- @return Diagnostic[], number
function filter_diags(items, filter_fn)
  local filtered = vim.tbl_filter(filter_fn, items)
  local hidden = #items - #filtered
  return filtered, hidden
end

return M

