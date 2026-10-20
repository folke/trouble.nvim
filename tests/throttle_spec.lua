local Util = require("trouble.util")
local uv = vim.uv or vim.loop

local function active_checks()
  local count = 0
  uv.walk(function(handle)
    if tostring(handle):match("^uv_check_t:") and handle:is_active() then
      count = count + 1
    end
  end)
  return count
end

describe("throttle lifecycle", function()
  it("does not retain active checks when views are closed", function()
    local before = active_checks()
    local Trouble = require("trouble")
    for _ = 1, 20 do
      Trouble.open({ mode = "diagnostics", open_no_results = true, warn_no_results = false })
      vim.wait(20)
      Trouble.close({ mode = "diagnostics" })
    end
    vim.wait(30)
    assert.same(before, active_checks())
  end)

  it("keeps the latest arguments when throttled or debounced", function()
    local calls = {}
    local throttle = Util.throttle(function(value)
      calls[#calls + 1] = value
    end, { ms = 20 })
    throttle("first")
    throttle("second")
    vim.wait(40)
    assert.same({ "second" }, calls)

    local debounce = Util.throttle(function(value)
      calls[#calls + 1] = value
    end, { ms = 30, debounce = true })
    debounce("first")
    vim.wait(10)
    debounce("last")
    vim.wait(50)
    assert.same({ "second", "last" }, calls)
  end)

  it("waits for asynchronous work before running the trailing call", function()
    local busy = false
    local calls = {}
    local throttle = Util.throttle(function(value)
      calls[#calls + 1] = value
      busy = true
      vim.defer_fn(function()
        busy = false
      end, 40)
    end, { ms = 10, is_running = function() return busy end })
    throttle("first")
    vim.wait(20)
    throttle("second")
    vim.wait(120)
    assert.same({ "first", "second" }, calls)
  end)

  it("follows a returned promise without polling a stale running flag", function()
    local Promise = require("trouble.promise")
    local calls = {}
    local checks = 0
    local throttle = Util.throttle(function(value)
      calls[#calls + 1] = value
      return Promise.new(function(resolve, reject)
        vim.defer_fn(value == "first" and function() reject("expected failure") end or resolve, 40)
      end)
    end, {
      ms = 10,
      is_running = function()
        checks = checks + 1
        return true
      end,
    })
    throttle("first")
    vim.wait(20)
    throttle("second")
    vim.wait(120)
    assert.same({ "first", "second" }, calls)
    assert(checks <= 2, "a returned promise should not require periodic polling")
  end)
end)
