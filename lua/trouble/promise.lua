local Util = require("trouble.util")

---@alias trouble.Promise.state "pending" | "fulfilled" | "rejected"

---@class trouble.Promise
---@field state trouble.Promise.state
---@field value any?
---@field queue (fun())[]
---@field resolve fun(value)
---@field reject fun(reason)
---@field has_next boolean
local P = {}
P.__index = P

--- Creates a new promise
---@param executor fun(resolve: fun(value), reject: fun(reason))
---@return trouble.Promise
function P.new(executor)
  local self = setmetatable({}, P)
  self.state = "pending"
  self.value = nil
  self.queue = {}
  self.has_next = false

  ---@param state trouble.Promise.state
  local function transition(state, result)
    if self.state == "pending" then
      self.state = state
      self.value = result
      for _, cb in ipairs(self.queue) do
        cb()
      end
      if state == "rejected" and not self.has_next then
        local bt = debug.traceback()
        vim.schedule(function()
          if not self.has_next then
            Util.error("Unhandled promise rejection:\n```lua\n" .. tostring(result) .. "\n\n" .. bt .. "```")
          end
        end)
      end
    end
  end

  self.resolve = function(value)
    transition("fulfilled", value)
  end
  self.reject = function(reason)
    transition("rejected", reason)
  end

  xpcall(function()
    executor(self.resolve, self.reject)
  end, function(err)
    self.reject(err)
  end)

  return self
end

--- Adds fulfillment and rejection handlers to the promise
---@param on_fulfilled? fun(value):any
---@param on_rejected? fun(reason):any
---@return trouble.Promise
function P:next(on_fulfilled, on_rejected)
  local next = P.new(function() end)

  local function handle()
    local callback = on_fulfilled
    if self.state == "rejected" then
      callback = on_rejected
    end
    if callback then
      local ok, ret = pcall(callback, self.value)
      if ok then
        if ret and type(ret) == "table" and getmetatable(ret) == P then
          ret:next(next.resolve, next.reject)
        else
          next.resolve(ret)
        end
      else
        next.reject(ret) -- reject the next promise with the error
      end
    else
      if self.state == "fulfilled" then
        next.resolve(self.value)
      else
        next.reject(self.value)
      end
    end
  end

  if self.state ~= "pending" then
    vim.schedule(handle) -- ensure the callback is called in the next event loop tick
  else
    table.insert(self.queue, handle)
  end

  self.has_next = true -- self.has_rejection_handler or (on_rejected ~= nil)
  return next
end

function P:catch(on_rejected)
  return self:next(nil, on_rejected)
end

function P:finally(on_finally)
  return self:next(function(value)
    return P.new(function(resolve)
      on_finally()
      resolve(value)
    end)
  end, function(reason)
    return P.new(function(_, reject)
      on_finally()
      reject(reason)
    end)
  end)
end

function P:is_pending()
  return self.state == "pending"
end

function P:timeout(ms)
  return P.new(function(resolve, reject)
    local timer = (vim.uv or vim.loop).new_timer()
    timer:start(ms, 0, function()
      timer:close()
      vim.schedule(function()
        reject("timeout")
      end)
    end)
    self:next(resolve, reject)
  end)
end

local M = {}

function M.resolve(value)
  return P.new(function(resolve)
    resolve(value)
  end)
end

function M.reject(reason)
  return P.new(function(_, reject)
    reject(reason)
  end)
end

---@param promises trouble.Promise[]
function M.all(promises)
  return P.new(function(resolve, reject)
    local results = {}
    local pending = #promises
    if pending == 0 then
      return resolve(results)
    end
    for i, promise in ipairs(promises) do
      promise:next(function(value)
        results[i] = value
        pending = pending - 1
        if pending == 0 then
          resolve(results)
        end
      end, reject)
    end
  end)
end

---@param promises trouble.Promise[]
function M.all_settled(promises)
  return P.new(function(resolve)
    local results = {}
    local pending = #promises
    if pending == 0 then
      return resolve(results)
    end
    for i, promise in ipairs(promises) do
      promise:next(function(value)
        results[i] = { status = "fulfilled", value = value }
        pending = pending - 1
        if pending == 0 then
          resolve(results)
        end
      end, function(reason)
        results[i] = { status = "rejected", reason = reason }
        pending = pending - 1
        if pending == 0 then
          resolve(results)
        end
      end)
    end
  end)
end

M.new = P.new

-- M.new(function() end):timeout(1000)

return M
