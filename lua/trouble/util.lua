local Config = require("trouble.config")
local uv = vim.loop or vim.uv

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

---@alias NotifyOpts {level?: number, title?: string, once?: boolean}

---@param msg string|string[]
---@param opts? NotifyOpts
function M.notify(msg, opts)
  opts = opts or {}
  msg = type(msg) == "table" and table.concat(msg, "\n") or msg
  ---@cast msg string
  msg = vim.trim(msg)
  return vim[opts.once and "notify_once" or "notify"](msg, opts.level, {
    title = opts.title or "Trouble",
    on_open = function(win)
      vim.wo.conceallevel = 3
      vim.wo.concealcursor = "n"
      vim.wo.spell = false
      vim.treesitter.start(vim.api.nvim_win_get_buf(win), "markdown")
    end,
  })
end

---@param msg string|string[]
---@param opts? NotifyOpts
function M.warn(msg, opts)
  M.notify(msg, vim.tbl_extend("keep", { level = vim.log.levels.WARN }, opts or {}))
end

---@param msg string|string[]
---@param opts? NotifyOpts
function M.error(msg, opts)
  M.notify(msg, vim.tbl_extend("keep", { level = vim.log.levels.ERROR }, opts or {}))
end

---@param msg string
function M.debug(msg, ...)
  if Config.debug then
    if select("#", ...) > 0 then
      local obj = select("#", ...) == 1 and ... or { ... }
      msg = msg .. "\n" .. vim.inspect(obj)
    end
    M.notify(msg, { title = "Trouble (debug)" })
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

---@param opts? {ms?: number, debounce?: boolean}|number
---@param default Throttle.opts
---@return Throttle.opts
function M.throttle_opts(opts, default)
  opts = opts or {}
  if type(opts) == "number" then
    opts = { ms = opts }
  end
  return vim.tbl_deep_extend("force", default, opts)
end

---@alias Throttle.opts {ms:number, debounce?:boolean, is_running?:fun():boolean}

-- throttle with trailing execution
---@generic T: fun()
---@param fn T
---@param opts? Throttle.opts
---@return T
function M.throttle(fn, opts)
  opts = opts or {}
  opts.ms = opts.ms or 20
  local last = 0
  local args = nil ---@type {n?:number}?
  local timer = assert(uv.new_timer())
  local pending = false -- from run() till end of fn
  local running = false -- from run() till end of fn with is_running()

  local t = {}

  function t.run()
    pending = true
    running = true
    timer:stop()
    last = uv.now()
    vim.schedule(function()
      xpcall(function()
        if not args then
          return M.debug("Empty args. This should not happen.")
        end
        fn(vim.F.unpack_len(args))
        args = nil
      end, function(err)
        vim.schedule(function()
          M.error(err)
        end)
      end)
      pending = false
      t.check()
    end)
  end

  function t.schedule()
    local now = uv.now()
    local delay = opts.debounce and opts.ms or (opts.ms - (now - last))
    timer:stop()
    timer:start(math.max(0, delay), 0, t.run)
  end

  function t.check()
    if running and not pending and not (opts.is_running and opts.is_running()) then
      running = false
      if args then -- schedule if there are pending args
        t.schedule()
      end
    end
  end

  local check = assert(uv.new_check())
  check:start(t.check)

  return function(...)
    args = vim.F.pack_len(...)

    if timer:is_active() and not opts.debounce then
      return
    elseif not running then
      t.schedule()
    end
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
