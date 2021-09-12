-- severity filters

local M = {}

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

local severity_actions = {
  "incr_min_severity",
  "decr_min_severity",
  "incr_cascading_severity",
  "decr_cascading_severity",
}

function M.handles_action(action)
  return vim.tbl_contains(severity_actions, action)
end

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

return M
