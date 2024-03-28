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
---@param sep? string
function M.camel(str, sep)
  local parts = vim.split(str, "[%.%-%_]")
  ---@diagnostic disable-next-line: no-unknown
  return table.concat(
    vim.tbl_map(function(part)
      return part:sub(1, 1):upper() .. part:sub(2)
    end, parts),
    sep or ""
  )
end

---@alias ThrottleOpts {ms:number, debounce?:boolean, is_running?:fun():boolean}

---@param opts? {ms?: number, debounce?: boolean}|number
---@param default ThrottleOpts
---@return ThrottleOpts
function M.throttle_opts(opts, default)
  opts = opts or {}
  if type(opts) == "number" then
    opts = { ms = opts }
  end
  return vim.tbl_deep_extend("force", default, opts)
end

-- throttle with trailing execution
---@generic T: fun()
---@param fn T
---@param opts? ThrottleOpts
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
        local _args = vim.F.unpack_len(args)
        -- FIXME:
        if not trailing and not timer:is_active() then
          args = {} -- clear args so they can be gc'd
        end
        fn(_args)
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
    if opts.debounce then
      delay = opts.ms
    end
    timer:start(math.max(0, delay), 0, throttle.run)
  end

  return function(...)
    args = vim.F.pack_len(...)
    if timer:is_active() and not opts.debounce then
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
  return M.split(s, "\n")
end

---@param s string
---@param c? string
function M.split(s, c)
  c = c or "\n"
  local pos = 1
  local l = 0
  return function()
    if pos == -1 then
      return
    end
    l = l + 1

    local nl = s:find(c, pos, true)
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

--- Gets lines from a file or buffer
---@param opts {path?:string, buf?: number, rows?: number[]}
---@return table<number, string>
function M.get_lines(opts)
  if opts.buf then
    local uri = vim.uri_from_bufnr(opts.buf)

    if uri:sub(1, 4) ~= "file" then
      vim.fn.bufload(opts.buf)
    end

    if vim.api.nvim_buf_is_loaded(opts.buf) then
      local lines = {} ---@type table<number, string>
      if not opts.rows then
        return vim.api.nvim_buf_get_lines(opts.buf, 0, -1, false)
      end
      for _, row in ipairs(opts.rows) do
        lines[row] = vim.api.nvim_buf_get_lines(opts.buf, row - 1, row, false)[1]
      end
      return lines
    end
    opts.path = vim.uri_to_fname(uri)
  elseif not opts.path then
    error("buf or filename is required")
  end

  local fd = uv.fs_open(opts.path, "r", 438)
  if not fd then
    return {}
  end
  local stat = assert(uv.fs_fstat(fd))
  local data = assert(uv.fs_read(fd, stat.size, 0)) --[[@as string]]
  assert(uv.fs_close(fd))
  local todo = opts.rows and #opts.rows or -1

  local ret = {} ---@type table<number, string>
  for row, line in M.lines(data) do
    if not opts.rows or vim.tbl_contains(opts.rows, row) then
      todo = todo - 1
      ret[row] = line
      if todo == 0 then
        break
      end
    end
  end
  return ret
end

--- Creates a weak reference to an object.
--- Calling the returned function will return the object if it has not been garbage collected.
---@generic T: table
---@param obj T
---@return T|fun():T?
function M.weak(obj)
  local weak = { _obj = obj }
  ---@return table<any, any>
  local function get()
    local ret = rawget(weak, "_obj")
    return ret == nil and error("Object has been garbage collected", 2) or ret
  end
  local mt = {
    __mode = "v",
    __call = function(t)
      return rawget(t, "_obj")
    end,
    __index = function(_, k)
      return get()[k]
    end,
    __newindex = function(_, k, v)
      get()[k] = v
    end,
    __pairs = function()
      return pairs(get())
    end,
  }
  return setmetatable(weak, mt)
end

return M
