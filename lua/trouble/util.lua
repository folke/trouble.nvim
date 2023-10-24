local Config = require("trouble.config")
local uv = vim.loop

local M = {}

---@param fn function
function M.noautocmd(fn)
  local ei = vim.o.eventignore
  vim.o.eventignore = "all"
  fn()
  vim.o.eventignore = ei
end

---@param opts? {msg?: string}
function M.try(fn, opts)
  local ok, err = pcall(fn)
  if not ok then
    local msg = opts and opts.msg or "Something went wrong:"
    msg = msg .. "\n" .. err
    M.error(msg)
  end
end

M.stats = {} ---@type table<string, {count: number, total: number}>
local tracked = {} ---@type table<table|function, boolean>
local nested = {}

---@param fn function|table
---@param name string
function M.track(fn, name)
  if tracked[fn] then
    return fn
  end
  tracked[fn] = true
  if type(fn) == "table" then
    for k, v in pairs(fn) do
      if type(v) == "table" or type(v) == "function" then
        fn[k] = M.track(v, name .. "." .. k)
      end
    end
    return fn
  elseif type(fn) ~= "function" then
    bt(name)
    error("Expected a function or table")
  end
  local ret = function(...)
    if nested[name] then
      return fn(...)
    end
    nested[name] = true
    local start = vim.loop.hrtime()
    local res = { fn(...) }
    local stop = vim.loop.hrtime()
    local ms = (stop - start) / 1000000
    nested[name] = false
    M.stats[name] = M.stats[name] or { count = 0, total = 0 }
    M.stats[name].count = M.stats[name].count + 1
    M.stats[name].total = M.stats[name].total + ms
    return unpack(res)
  end
  tracked[ret] = true
  return ret
end

function M.report()
  local timer = vim.loop.new_timer()
  timer:start(3000, 3000, function()
    vim.schedule(function()
      local entries = {} ---@type {name: string, count: number, total: number, avg: number}[]
      for k, v in pairs(M.stats) do
        entries[#entries + 1] = { name = k, count = v.count, total = v.total, avg = v.total / v.count }
      end
      table.sort(entries, function(a, b)
        return a.total > b.total
      end)
      dd(entries)
    end)
  end)
end

function M.warn(msg)
  vim.notify(msg, vim.log.levels.WARN, { title = "Trouble" })
end

function M.error(msg)
  vim.notify(msg, vim.log.levels.ERROR, { title = "Trouble" })
end

function M.debug(msg, ...)
  if Config.debug then
    if select("#", ...) > 0 then
      local obj = select("#", ...) == 1 and ... or { ... }
      msg = msg .. "\n" .. vim.inspect(obj)
    end
    vim.notify(msg, vim.log.levels.INFO, { title = "Trouble (debug)" })
  end
end

---@param str string
function M.camel(str)
  local parts = vim.split(str, "[%.%-%_]")
  ---@diagnostic disable-next-line: no-unknown
  return table.concat(vim.tbl_map(function(part)
    return part:sub(1, 1):upper() .. part:sub(2)
  end, parts))
end

-- throttle with trailing execution
---@generic T: fun()
---@param fn T
---@param opts? {ms:number, is_running?:fun():boolean}
---@return T
function M.throttle(fn, opts)
  opts = opts or {}
  opts.ms = opts.ms or 20
  local timer = assert(vim.loop.new_timer())
  local check = assert(vim.loop.new_check())
  local last = 0
  local args = {} ---@type any[]
  local executing = false
  local trailing = false

  local throttle = {}

  check:start(function()
    if not throttle.is_running() and not timer:is_active() and trailing then
      trailing = false
      throttle.schedule()
    end
  end)

  function throttle.is_running()
    return executing or (opts.is_running and opts.is_running())
  end

  function throttle.run()
    executing = true
    last = vim.loop.now()
    vim.schedule(function()
      xpcall(function()
        fn(vim.F.unpack_len(args))
      end, function(err)
        vim.schedule(function()
          M.error(err)
        end)
      end)
      executing = false
    end)
  end

  function throttle.schedule()
    local now = vim.loop.now()
    local delay = opts.ms - (now - last)
    timer:start(math.max(0, delay), 0, throttle.run)
  end

  return function(...)
    args = vim.F.pack_len(...)
    if timer:is_active() then
      return
    elseif throttle.is_running() then
      trailing = true
      return
    end
    throttle.schedule()
  end
end

---@param s string
function M.lines(s)
  local pos = 1
  local l = 0
  return function()
    if pos == -1 then
      return
    end
    l = l + 1

    local nl = s:find("\n", pos, true)
    if not nl then
      local lastLine = s:sub(pos)
      pos = -1
      return l, lastLine
    end

    local line = s:sub(pos, nl - 1)
    pos = nl + 1
    return l, line
  end
end

return M
