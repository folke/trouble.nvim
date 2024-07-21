local Format = require("trouble.format")
local Main = require("trouble.view.main")
local Preview = require("trouble.view.preview")
local Promise = require("trouble.promise")
local Render = require("trouble.view.render")
local Section = require("trouble.view.section")
local Spec = require("trouble.spec")
local Text = require("trouble.view.text")
local Util = require("trouble.util")
local Window = require("trouble.view.window")

---@class trouble.View
---@field win trouble.Window
---@field preview_win? trouble.Window
---@field opts trouble.Mode
---@field sections trouble.Section[]
---@field renderer trouble.Render
---@field first_render trouble.Promise
---@field first_update trouble.Promise
---@field moving uv_timer_t
---@field clicked uv_timer_t
---@field state table<string,any>
---@field _filters table<string, trouble.ViewFilter>
---@field private _main? trouble.Main
local M = {}
M.__index = M
local _idx = 0
---@type table<trouble.View, number>
M._views = setmetatable({}, { __mode = "k" })

---@type trouble.View[]
M._auto = {}

---@type table<string, trouble.Render.Location>
M._last = {}

M.MOVING_DELAY = 4000

local uv = vim.loop or vim.uv

---@param opts trouble.Mode
function M.new(opts)
  local self = setmetatable({}, M)
  _idx = _idx + 1
  M._views[self] = _idx
  self.state = {}
  self.opts = opts or {}
  self._filters = {}
  self.first_render = Promise.new(function() end)
  self.first_update = Promise.new(function() end)
  self.opts.win = vim.tbl_deep_extend("force", self.opts.win or {}, Window.FOLDS)
  self.opts.win.on_mount = function()
    self:on_mount()
  end
  self.opts.win.on_close = function()
    if not self.opts.auto_open then
      for _, section in ipairs(self.sections) do
        section:stop()
      end
    end
  end

  self.sections = {}
  for _, s in ipairs(Spec.sections(self.opts)) do
    local section = Section.new(s, self.opts)
    section.on_update = function()
      self:update()
    end
    table.insert(self.sections, section)
  end

  self.win = Window.new(self.opts.win)
  self.opts.win = self.win.opts

  self.preview_win = Window.new(self.opts.preview) or nil

  self.renderer = Render.new(self.opts, {
    padding = vim.tbl_get(self.opts.win, "padding", "left") or 0,
    multiline = self.opts.multiline,
  })
  self.update = Util.throttle(M.update, Util.throttle_opts(self.opts.throttle.update, { ms = 10 }))
  self.render = Util.throttle(M.render, Util.throttle_opts(self.opts.throttle.render, { ms = 10 }))
  self.follow = Util.throttle(M.follow, Util.throttle_opts(self.opts.throttle.follow, { ms = 100 }))

  if self.opts.auto_open then
    -- add to a table, so that the view doesn't gc
    table.insert(M._auto, self)
    self:listen()
    self:refresh()
  end
  self.moving = uv.new_timer()
  self.clicked = uv.new_timer()
  return self
end

---@alias trouble.View.filter {debug?: boolean, open?:boolean, mode?: string}

---@param filter? trouble.View.filter
function M.get(filter)
  filter = filter or {}
  ---@type {idx:number, mode?: string, view: trouble.View, is_open: boolean}[]
  local ret = {}
  for view, idx in pairs(M._views) do
    local is_open = view.win:valid()
    local opening = view.first_update:is_pending()
    local ok = is_open or view.opts.auto_open or opening
    ok = ok and (not filter.mode or filter.mode == view.opts.mode)
    ok = ok and (not filter.open or is_open or opening)
    if ok then
      ret[#ret + 1] = {
        idx = idx,
        mode = view.opts.mode,
        view = not filter.debug and view or {},
        is_open = is_open,
      }
    end
  end
  table.sort(ret, function(a, b)
    return a.idx < b.idx
  end)
  return ret
end

function M:on_mount()
  vim.w[self.win.win].trouble = {
    mode = self.opts.mode,
    type = self.opts.win.type,
    relative = self.opts.win.relative,
    position = self.opts.win.position,
  }

  self:listen()
  self.win:on("WinLeave", function()
    if self.opts.preview.type == "main" and self.clicked:is_active() and Preview.is_open() then
      local main = self.preview_win.opts.win
      local preview = self.preview_win.win
      if main and preview and vim.api.nvim_win_is_valid(main) and vim.api.nvim_win_is_valid(preview) then
        local view = vim.api.nvim_win_call(preview, vim.fn.winsaveview)
        vim.api.nvim_win_call(main, function()
          vim.fn.winrestview(view)
        end)
        vim.api.nvim_set_current_win(main)
      end
    end
    Preview.close()
  end)

  local _self = Util.weak(self)

  local preview = Util.throttle(
    M.preview,
    Util.throttle_opts(self.opts.throttle.preview, {
      ms = 100,
      debounce = true,
    })
  )

  self.win:on("CursorMoved", function()
    local this = _self()
    if not this then
      return true
    end
    M._last[self.opts.mode or ""] = self:at()
    if this.opts.auto_preview then
      local loc = this:at()
      if loc and loc.item then
        preview(this, loc.item)
      end
    end
  end)

  if self.opts.follow then
    -- tracking of the current item
    self.win:on("CursorMoved", function()
      local this = _self()
      if not this then
        return true
      end
      if this.win:valid() then
        this:follow()
      end
    end, { buffer = false })
  end

  self.win:on("OptionSet", function()
    local this = _self()
    if not this then
      return true
    end
    if this.win:valid() then
      local foldlevel = vim.wo[this.win.win].foldlevel
      if foldlevel ~= this.renderer.foldlevel then
        this:fold_level({ level = foldlevel })
      end
    end
  end, { pattern = "foldlevel", buffer = false })

  for k, v in pairs(self.opts.keys) do
    if v ~= false then
      self:map(k, v)
    end
  end

  self.win:map("<leftmouse>", function()
    self.clicked:start(100, 0, function() end)
    return "<leftmouse>"
  end, { remap = false, expr = true })
end

---@param node? trouble.Node
function M:delete(node)
  local selection = node and { node } or self:selection()
  if #selection == 0 then
    return
  end
  for _, n in ipairs(selection) do
    n:delete()
  end
  self.opts.auto_refresh = false
  self:render()
end

---@param node? trouble.Node
---@param opts? trouble.Render.fold_opts
function M:fold(node, opts)
  node = node or self:at().node
  if node then
    self.renderer:fold(node, opts)
    self:render()
  end
end

---@param opts {level?:number, add?:number}
function M:fold_level(opts)
  self.renderer:fold_level(opts)
  self:render()
end

---@param item? trouble.Item
---@param opts? {split?: boolean, vsplit?:boolean}
function M:jump(item, opts)
  opts = opts or {}
  item = item or self:at().item
  vim.schedule(function()
    Preview.close()
  end)
  if not item then
    return Util.warn("No item to jump to")
  end

  if not (item.buf or item.filename) then
    Util.warn("No buffer or filename for item")
    return
  end

  item.buf = item.buf or vim.fn.bufadd(item.filename)

  if not vim.api.nvim_buf_is_loaded(item.buf) then
    vim.fn.bufload(item.buf)
  end
  if not vim.bo[item.buf].buflisted then
    vim.bo[item.buf].buflisted = true
  end
  local main = self:main()
  local win = main and main.win or 0

  vim.api.nvim_win_call(win, function()
    -- save position in jump list
    vim.cmd("normal! m'")
  end)

  if opts.split then
    vim.api.nvim_win_call(win, function()
      vim.cmd("split")
      win = vim.api.nvim_get_current_win()
    end)
  elseif opts.vsplit then
    vim.api.nvim_win_call(win, function()
      vim.cmd("vsplit")
      win = vim.api.nvim_get_current_win()
    end)
  end

  vim.api.nvim_win_set_buf(win, item.buf)
  -- order of the below seems important with splitkeep=screen
  vim.api.nvim_set_current_win(win)
  vim.api.nvim_win_set_cursor(win, item.pos)
  vim.api.nvim_win_call(win, function()
    vim.cmd("norm! zzzv")
  end)
  return item
end

function M:wait(fn)
  self.first_render:next(fn)
end

---@param item? trouble.Item
function M:preview(item)
  item = item or self:at().item
  if not item then
    return Util.warn("No item to preview")
  end

  return Preview.open(self, item, { scratch = self.opts.preview.scratch })
end

function M:main()
  self._main = Main.get(self.opts.pinned and self._main or nil)
  return self._main
end

function M:goto_main()
  local main = self:main()
  if main then
    vim.api.nvim_set_current_win(main.win)
  end
end

function M:listen()
  self:main()

  for _, section in ipairs(self.sections) do
    section:listen()
  end
end

---@param cursor? number[]
function M:at(cursor)
  if not vim.api.nvim_buf_is_valid(self.win.buf) then
    return {}
  end
  cursor = cursor or vim.api.nvim_win_get_cursor(self.win.win)
  return self.renderer:at(cursor[1])
end

function M:selection()
  if not vim.fn.mode():lower():find("v") then
    local ret = self:at()
    return ret.node and { ret.node } or {}
  end
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<esc>", true, false, true), "x", false)

  local from = vim.api.nvim_buf_get_mark(self.win.buf, "<")[1]
  local to = vim.api.nvim_buf_get_mark(self.win.buf, ">")[1]
  ---@type trouble.Node[]
  local ret = {}
  for row = from, to do
    local node = self.renderer:at(row).node
    if not vim.tbl_contains(ret, node) then
      ret[#ret + 1] = node
    end
  end
  return ret
end

---@param key string
---@param action trouble.Action.spec
function M:map(key, action)
  action = Spec.action(action)
  local _self = Util.weak(self)
  self.win:map(key, function()
    local this = _self()
    if this then
      this:action(action)
    end
  end, { desc = action.desc, mode = action.mode })
end

---@param opts? {idx?: number, up?:number, down?:number, jump?:boolean}
function M:move(opts)
  -- start the moving timer. Will stop any previous timers,
  -- so this acts as a debounce.
  -- This is needed to prevent `follow` from being called
  self.moving:start(M.MOVING_DELAY, 0, function() end)

  opts = opts or {}
  local cursor = vim.api.nvim_win_get_cursor(self.win.win)
  local from = 1
  local to = vim.api.nvim_buf_line_count(self.win.buf)
  local todo = opts.idx or opts.up or opts.down or 0

  if opts.idx and opts.idx < 0 then
    from, to = to, 1
    todo = math.abs(todo)
  elseif opts.down then
    from = cursor[1] + 1
  elseif opts.up then
    from = cursor[1] - 1
    to = 1
  end

  for row = from, to, from > to and -1 or 1 do
    local info = self.renderer:at(row)
    if info.item and info.first_line then
      todo = todo - 1
      if todo == 0 then
        vim.api.nvim_win_set_cursor(self.win.win, { row, cursor[2] })
        if opts.jump then
          self:jump(info.item)
        end
        break
      end
    end
  end
end

---@param action trouble.Action.spec
---@param opts? table
function M:action(action, opts)
  action = Spec.action(action)
  self:wait(function()
    local at = self:at() or {}
    action.action(self, {
      item = at.item,
      node = at.node,
      opts = type(opts) == "table" and opts or {},
    })
  end)
end

---@param opts? {update?: boolean, opening?: boolean}
function M:refresh(opts)
  opts = opts or {}
  if not (opts.opening or self.win:valid() or self.opts.auto_open) then
    return
  end
  ---@param section trouble.Section
  return Promise.all(vim.tbl_map(function(section)
    return section:refresh(opts)
  end, self.sections))
end

function M:help()
  local text = Text.new({ padding = 1 })

  text:nl():append("# Help ", "Title"):nl()
  text:append("Press ", "Comment"):append("<q>", "Special"):append(" to close", "Comment"):nl():nl()
  text:append("# Keymaps ", "Title"):nl():nl()
  ---@type string[]
  local keys = vim.tbl_keys(self.win.keys)
  table.sort(keys, function(a, b)
    local lowa = string.lower(a)
    local lowb = string.lower(b)
    if lowa == lowb then
      return a > b -- Preserve original order for equal strings
    else
      return lowa < lowb
    end
  end)
  for _, key in ipairs(keys) do
    local desc = self.win.keys[key]
    text:append("  - ", "@punctuation.special.markdown")
    text:append(key, "Special"):append(" "):append(desc):nl()
  end
  text:trim()

  local win = Window.new({
    type = "float",
    size = { width = text:width(), height = text:height() },
    border = "rounded",
    wo = { cursorline = false },
  })
  win:open():focus()
  text:render(win.buf)
  vim.bo[win.buf].modifiable = false

  win:map("<esc>", win.close)
  win:map("q", win.close)
end

function M:is_open()
  return self.win:valid()
end

function M:open()
  if self.win:valid() then
    return self
  end
  self
    :refresh({ update = false, opening = true })
    :next(function()
      local count = self:count()
      if count == 0 then
        if not self.opts.open_no_results then
          if self.opts.warn_no_results then
            Util.warn({
              "No results for **" .. self.opts.mode .. "**",
              "Buffer: " .. vim.api.nvim_buf_get_name(self:main().buf),
            })
          end
          return
        end
      elseif count == 1 and self.opts.auto_jump then
        self:jump(self:flatten()[1])
        return self:close()
      end
      self.win:open()
      self:update()
    end)
    :next(self.first_update.resolve)
  return self
end

function M:close()
  if vim.api.nvim_get_current_win() == self.win.win then
    self:goto_main()
  end
  Preview.close()
  self.win:close()
  return self
end

function M:count()
  local count = 0
  for _, section in ipairs(self.sections) do
    if section.node then
      count = count + section.node:count()
    end
  end
  return count
end

function M:flatten()
  local ret = {}
  for _, section in ipairs(self.sections) do
    section.node:flatten(ret)
  end
  return ret
end

-- called when results are updated
function M:update()
  local is_open = self.win:valid()
  local count = self:count()

  if count == 0 and is_open and self.opts.auto_close then
    return self:close()
  end

  if self.opts.auto_open and not is_open and count > 0 then
    self.win:open()
    is_open = true
  end

  if not is_open then
    return
  end

  self:render()
end

---@param filter trouble.Filter
---@param opts? trouble.ViewFilter.opts
function M:filter(filter, opts)
  opts = opts or {}

  ---@type trouble.ViewFilter
  local view_filter = vim.tbl_deep_extend("force", {
    id = vim.inspect(filter),
    filter = filter,
    data = opts.data,
    template = opts.template,
  }, opts)

  if opts.del or (opts.toggle and self._filters[view_filter.id]) then
    self._filters[view_filter.id] = nil
  else
    self._filters[view_filter.id] = view_filter
  end

  local filters = vim.tbl_count(self._filters) > 0
      and vim.tbl_map(function(f)
        return f.filter
      end, vim.tbl_values(self._filters))
    or nil

  for _, section in ipairs(self.sections) do
    section.filter = filters
  end
  self:refresh()
end

function M:header()
  local ret = {} ---@type trouble.Format[][]
  for _, filter in pairs(self._filters) do
    local data = vim.tbl_deep_extend("force", {
      filter = filter.filter,
    }, type(filter.filter) == "table" and filter.filter or {}, filter.data or {})
    local template = filter.template or "{hl:Title}Filter:{hl} {filter}"
    ret[#ret + 1] = self:format(template, data)
  end
  return ret
end

---@param id string
function M:get_filter(id)
  return self._filters[id]
end

---@param template string
---@param data table<string,any>
function M:format(template, data)
  data.source = "view"
  assert(self.opts, "opts is nil")
  return Format.format(template, { item = data, opts = self.opts })
end

-- render the results
function M:render()
  if not self.win:valid() then
    return
  end

  local loc = self:at()
  local restore_loc = self.opts.restore and self.first_render:is_pending() and M._last[self.opts.mode or ""]
  if restore_loc then
    loc = restore_loc
  end

  -- render sections
  self.renderer:clear()
  self.renderer:nl()
  for _ = 1, vim.tbl_get(self.opts.win, "padding", "top") or 0 do
    self.renderer:nl()
  end

  local header = self:header()
  for _, h in ipairs(header) do
    for _, ff in ipairs(h) do
      self.renderer:append(ff.text, ff)
    end
    self.renderer:nl()
  end

  self.renderer:sections(self.sections)
  self.renderer:trim()

  -- calculate initial folds
  if self.renderer.foldlevel == nil then
    local level = vim.wo[self.win.win].foldlevel
    if level < self.renderer.max_depth then
      self.renderer:fold_level({ level = level })
      -- render again to apply folds
      return self:render()
    end
  end

  vim.schedule(function()
    self.first_render.resolve()
  end)

  -- render extmarks and restore window view
  local view = vim.api.nvim_win_call(self.win.win, vim.fn.winsaveview)
  self.renderer:render(self.win.buf)
  vim.api.nvim_win_call(self.win.win, function()
    vim.fn.winrestview(view)
  end)

  if self.opts.follow and self:follow() then
    return
  end

  -- when window is at top, dont move cursor
  if not restore_loc and view.topline == 1 then
    return
  end

  -- fast exit when cursor is already on the right item
  local new_loc = self:at()
  if new_loc.node and loc.node and new_loc.node.id == loc.node.id then
    return
  end

  -- Move cursor to the same item
  local cursor = vim.api.nvim_win_get_cursor(self.win.win)
  local item_row ---@type number?
  if loc.node then
    for row, l in pairs(self.renderer._locations) do
      if loc.node:is(l.node) then
        item_row = row
        break
      end
    end
  end

  -- Move cursor to the actual item when found
  if item_row and item_row ~= cursor[1] then
    vim.api.nvim_win_set_cursor(self.win.win, { item_row, cursor[2] })
    return
  end
end

-- When not in the trouble window, try to show the range
function M:follow()
  if not self.win:valid() then -- trouble is closed
    return
  end
  if self.moving:is_active() then -- dont follow when moving
    return
  end
  local current_win = vim.api.nvim_get_current_win()
  if current_win == self.win.win then -- inside the trouble window
    return
  end
  local Filter = require("trouble.filter")
  local ctx = { opts = self.opts, main = self:main() }
  local fname = vim.api.nvim_buf_get_name(ctx.main.buf or 0)
  local loc = self:at()

  -- check if we're already in the file group
  local in_group = loc.node and loc.node.item and loc.node.item.filename == fname

  ---@type number[]|nil
  local cursor_item = nil
  local cursor_group = cursor_item

  for row, l in pairs(self.renderer._locations) do
    -- only return the group if we're not yet in the group
    -- and the group's filename matches the current file
    local is_group = not in_group and l.node and l.node.group and l.node.item and l.node.item.filename == fname
    if is_group then
      cursor_group = { row, 1 }
    end

    -- prefer a full match
    local is_current = l.item and Filter.is(l.item, { range = true }, ctx)
    if is_current then
      cursor_item = { row, 1 }
    end
  end

  local cursor = cursor_item or cursor_group
  if cursor then
    -- make sure the cursorline is visible
    vim.wo[self.win.win].cursorline = true
    vim.api.nvim_win_set_cursor(self.win.win, cursor)
    return true
  end
end

return M
