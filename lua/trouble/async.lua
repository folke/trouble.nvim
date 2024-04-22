local M = {}
local uv = vim.loop or vim.uv

M.budget = 1
local Scheduler = {}
Scheduler._queue = {}
Scheduler._executor = assert(uv.new_check())

function Scheduler.step()
  local budget = M.budget * 1e6
  local start = uv.hrtime()
  while #Scheduler._queue > 0 and uv.hrtime() - start < budget do
    local a = table.remove(Scheduler._queue, 1)
    a:_step()
    if a.running then
      table.insert(Scheduler._queue, a)
    end
  end
  if #Scheduler._queue == 0 then
    return Scheduler._executor:stop()
  end
end

---@param a Async
function Scheduler.add(a)
  table.insert(Scheduler._queue, a)
  if not Scheduler._executor:is_active() then
    Scheduler._executor:start(vim.schedule_wrap(Scheduler.step))
  end
end

--- @alias AsyncCallback fun(result?:any, error?:string)

--- @class Async
--- @field running boolean
--- @field result? any
--- @field error? string
--- @field callbacks AsyncCallback[]
--- @field thread thread
local Async = {}
Async.__index = Async

function Async.new(fn)
  local self = setmetatable({}, Async)
  self.callbacks = {}
  self.running = true
  self.thread = coroutine.create(fn)
  Scheduler.add(self)
  return self
end

---@param result? any
---@param error? string
function Async:_done(result, error)
  if self.running then
    self.running = false
    self.result = result
    self.error = error
  end
  for _, callback in ipairs(self.callbacks) do
    callback(result, error)
  end
  -- only run each callback once.
  -- _done can possibly be called multiple times.
  -- so we need to clear callbacks after executing them.
  self.callbacks = {}
end

function Async:_step()
  local ok, res = coroutine.resume(self.thread)
  if not ok then
    return self:_done(nil, res)
  elseif res == "abort" then
    return self:_done(nil, "abort")
  elseif coroutine.status(self.thread) == "dead" then
    return self:_done(res)
  end
end

function Async:cancel()
  self:_done(nil, "abort")
end

---@param cb AsyncCallback
function Async:await(cb)
  if not cb then
    error("callback is required")
  end
  if self.running then
    table.insert(self.callbacks, cb)
  else
    cb(self.result, self.error)
  end
end

function Async:sync()
  while self.running do
    vim.wait(10)
  end
  return self.error and error(self.error) or self.result
end

--- @return boolean
function M.is_async(obj)
  return obj and type(obj) == "table" and getmetatable(obj) == Async
end

---@generic F
---@param fn F
---@return F|fun(...): Async
function M.wrap(fn)
  return function(...)
    local args = { ... }
    return Async.new(function()
      return fn(unpack(args))
    end)
  end
end

-- This will yield when called from a coroutine
---@async
function M.yield(...)
  if coroutine.running() == nil then
    error("Trying to yield from a non-yieldable context")
    return ...
  end
  return coroutine.yield(...)
end

---@async
function M.abort()
  return M.yield("abort")
end

return M
