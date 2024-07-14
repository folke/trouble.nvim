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

function M.is_win()
  return uv.os_uname().sysname:find("Windows") ~= nil
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

M.islist = vim.islist or vim.tbl_islist

---@alias NotifyOpts {level?: number, title?: string, once?: boolean, id?:string}

---@type table<string, any>
local notif_ids = {}

---@param msg string|string[]
---@param opts? NotifyOpts
function M.notify(msg, opts)
  opts = opts or {}
  msg = type(msg) == "table" and table.concat(msg, "\n") or msg
  ---@cast msg string
  msg = vim.trim(msg)
  local ret = vim[opts.once and "notify_once" or "notify"](msg, opts.level, {
    replace = opts.id and notif_ids[opts.id] or nil,
    title = opts.title or "Trouble",
    on_open = function(win)
      vim.wo[win].conceallevel = 3
      vim.wo[win].concealcursor = "n"
      vim.wo[win].spell = false
      vim.treesitter.start(vim.api.nvim_win_get_buf(win), "markdown")
    end,
  })
  if opts.id then
    notif_ids[opts.id] = ret
  end
  return ret
end

---@param msg string|string[]
---@param opts? NotifyOpts
function M.warn(msg, opts)
  M.notify(msg, vim.tbl_extend("keep", { level = vim.log.levels.WARN }, opts or {}))
end

---@param msg string|string[]
---@param opts? NotifyOpts
function M.info(msg, opts)
  M.notify(msg, vim.tbl_extend("keep", { level = vim.log.levels.INFO }, opts or {}))
end

---@param msg string|string[]
---@param opts? NotifyOpts
function M.error(msg, opts)
  M.notify(msg, vim.tbl_extend("keep", { level = vim.log.levels.ERROR }, opts or {}))
end

---@param msg string|string[]
function M.debug(msg, ...)
  if Config.debug then
    if select("#", ...) > 0 then
      local obj = select("#", ...) == 1 and ... or { ... }
      msg = msg .. "\n```lua\n" .. vim.inspect(obj) .. "\n```"
    end
    M.notify(msg, { title = "Trouble (debug)" })
  end
end

---@param buf number
---@param row number
---@param ns number
---@param col number
---@param opts vim.api.keyset.set_extmark
---@param debug_info? any
function M.set_extmark(buf, ns, row, col, opts, debug_info)
  local ok, err = pcall(vim.api.nvim_buf_set_extmark, buf, ns, row, col, opts)
  if not ok and Config.debug then
    M.debug("Failed to set extmark for preview", { info = debug_info, row = row, col = col, opts = opts, error = err })
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
---@return table<number, string>?
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
    return
  end
  local stat = assert(uv.fs_fstat(fd))
  if not (stat.type == "file" or stat.type == "link") then
    return
  end
  local data = assert(uv.fs_read(fd, stat.size, 0)) --[[@as string]]
  assert(uv.fs_close(fd))

  local todo = 0
  local ret = {} ---@type table<number, string|boolean>
  for _, r in ipairs(opts.rows or {}) do
    if not ret[r] then
      todo = todo + 1
      ret[r] = true
    end
  end

  for row, line in M.lines(data) do
    if not opts.rows or ret[row] then
      if line:sub(-1) == "\r" then
        line = line:sub(1, -2)
      end
      todo = todo - 1
      ret[row] = line
      if todo == 0 then
        break
      end
    end
  end
  for i, r in pairs(ret) do
    if r == true then
      ret[i] = ""
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
