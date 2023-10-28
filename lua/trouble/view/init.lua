local Filter = require("trouble.filter")
local Preview = require("trouble.view.preview")
local Render = require("trouble.view.render")
local Sort = require("trouble.sort")
local Source = require("trouble.source")
local Spec = require("trouble.spec")
local Text = require("trouble.view.text")
local Tree = require("trouble.tree")
local Util = require("trouble.util")
local Window = require("trouble.view.window")

---@class trouble.View
---@field win trouble.Window
---@field preview_win? trouble.Window
---@field opts trouble.Mode
---@field sections trouble.Section[]
---@field items trouble.Item[][]
---@field nodes trouble.Node[]
---@field renderer trouble.Render
---@field private _main? trouble.Window.info
---@field fetching number
local M = {}
M.__index = M
local _idx = 0
---@type table<trouble.View, number>
M._views = setmetatable({}, { __mode = "k" })

---@param opts trouble.Mode
function M.new(opts)
  local self = setmetatable({}, M)
  _idx = _idx + 1
  M._views[self] = _idx
  self.opts = opts or {}
  self.opts.results.win = self.opts.results.win or {}
  self.opts.results.win.on_mount = function()
    self:on_mount()
  end
  self.items = {}
  self.fetching = 0
  self.nodes = {}
  self.sections = Spec.sections(self.opts)
  self.win = Window.new(self.opts.results.win)
  self.opts.results.win = self.win.opts

  ---@diagnostic disable-next-line: param-type-mismatch
  self.preview_win = self.opts.preview.win ~= "main" and Window.new(self.opts.preview.win) or nil

  self.renderer = Render.new(self, {
    padding = vim.tbl_get(self.opts.results.win, "padding", "left") or 0,
    multiline = self.opts.results.multiline,
  })
  local _self = Util.weak(self)
  self.refresh = Util.throttle(M.refresh, {
    ms = 200,
    is_running = function()
      local this = _self()
      return this and this.fetching > 0
    end,
  })
  self.update = Util.throttle(M.update, { ms = 10 })
  self.render = Util.throttle(M.render, { ms = 10 })

  if self.opts.results.auto_open then
    self:listen()
    self:refresh()
  end
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
    local ok = is_open or view.opts.results.auto_open
    ok = ok and (not filter.mode or filter.mode == view.opts.mode)
    ok = ok and (not filter.open or is_open)
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
  self:listen()
  self.win:on("WinLeave", function()
    Preview.close()
  end)

  local _self = Util.weak(self)

  local preview = Util.throttle(M.preview, { ms = 100, debounce = true })
  self.win:on("CursorMoved", function()
    local this = _self()
    if not this then
      return true
    end
    if this.opts.preview.auto_open then
      local loc = this:at()
      if loc and loc.item then
        preview(this, loc.item)
      end
    end
  end)

  self.win:on("OptionSet", function()
    local this = _self()
    if not this then
      return true
    end
    local foldlevel = vim.wo[this.win.win].foldlevel
    if foldlevel ~= this.renderer.foldlevel then
      this:fold_level({ level = foldlevel })
    end
  end, { pattern = "foldlevel", buffer = false })

  for k, v in pairs(self.opts.keys) do
    self:map(k, v)
  end
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
  Preview.close()
  if not item then
    return vim.notify("No item to jump to", vim.log.levels.WARN, { title = "Trouble" })
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
  return item
end

---@param item? trouble.Item
function M:preview(item)
  item = item or self:at().item
  if not item then
    return vim.notify("No item to preview", vim.log.levels.WARN, { title = "Trouble" })
  end

  return Preview.open(self, item)
end

function M:main()
  local valid = self._main
    and self._main.win
    and vim.api.nvim_win_is_valid(self._main.win)
    and self._main.buf
    and vim.api.nvim_buf_is_valid(self._main.buf)
  if not valid then
    self._main = self.win:find_main()
  end
  -- update the cursor, unless the preview is showing in the main window
  if self._main and not Preview.is_win(self._main.win) then
    self._main.cursor = vim.api.nvim_win_get_cursor(self._main.win)
  end
  return self._main
end

function M:goto_main()
  local main = self:main()
  if main then
    vim.api.nvim_set_current_win(main.win)
  end
end

function M:listen()
  local _self = Util.weak(self)
  self:main()

  -- track main window
  self.win:on("BufEnter", function()
    local this = _self()
    if not this then
      return true
    end
    -- don't update the main window when
    -- preview is open or when the window is pinned
    if this.opts.pinned then
      return
    end
    local buf = vim.api.nvim_get_current_buf()
    local win = vim.api.nvim_get_current_win()
    if vim.bo[buf].buftype == "" then
      ---@diagnostic disable-next-line: invisible
      this._main = Window.win_info(win)
    end
  end, { buffer = false })

  self.win:on("WinEnter", function()
    local this = _self()
    if not this then
      return true
    end
    ---@diagnostic disable-next-line: invisible
    if this._main and vim.api.nvim_win_is_valid(this._main.win) then
      ---@diagnostic disable-next-line: invisible
      this._main = Window.win_info(this._main.win)
    end
  end, { win = true })

  for _, section in ipairs(self.sections) do
    for _, event in ipairs(section.events or {}) do
      vim.api.nvim_create_autocmd(event.event, {
        group = self.win:augroup(),
        pattern = event.pattern,
        callback = function(e)
          local this = _self()
          if not this then
            return true
          end
          if not this.opts.results.auto_refresh then
            return
          end
          if event.main then
            local main = this:main()
            if main and main.buf ~= e.buf then
              return
            end
          end
          if e.event == "BufEnter" and vim.bo[e.buf].buftype ~= "" then
            return
          end
          this:refresh()
        end,
      })
    end
  end
end

---@param cursor? number[]
function M:at(cursor)
  cursor = cursor or vim.api.nvim_win_get_cursor(self.win.win)
  return self.renderer:at(cursor[1])
end

---@param key string
---@param action trouble.Action|string
function M:map(key, action)
  local desc ---@type string?
  if type(action) == "string" then
    desc = action:gsub("_", " ")
    action = require("trouble.config.actions")[action]
  end
  ---@type trouble.ActionFn
  local fn
  if type(action) == "function" then
    fn = action
  else
    fn = action.action
    desc = action.desc or desc
  end
  local _self = Util.weak(self)
  self.win:map(key, function()
    local this = _self()
    if this then
      this:action(fn)
    end
  end, desc)
end

---@param opts? {idx?: number, up?:number, down?:number, jump?:boolean}
function M:move(opts)
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

---@param action trouble.Action
---@param opts? table
function M:action(action, opts)
  local at = self:at() or {}
  action(self, {
    item = at.item,
    node = at.node,
    opts = type(opts) == "table" and opts or {},
  })
end

function M:refresh()
  local is_open = self.win:valid()
  if not is_open and not self.opts.results.auto_open then
    return
  end
  for s, section in ipairs(self.sections) do
    self.fetching = self.fetching + 1
    local done = false
    local complete = function()
      if done then
        return
      end
      done = true
      self.fetching = self.fetching - 1
    end
    -- mark as completed after 2 seconds to avoid
    -- errors staling the fetching count
    vim.defer_fn(complete, 1000)
    Source.get(section.source, function(items)
      items = Filter.filter(items, self.opts.filter, self)
      items = Filter.filter(items, section.filter, self)
      items = Sort.sort(items, section.sort, self)
      self.items[s] = items
      self.nodes[s] = Tree.build(items, section)
      complete()
      self:update()
    end, { filter = section.filter or self.opts.filter or nil, view = self })
  end
end

function M:help()
  local text = Text.new({ padding = 1 })

  text:nl():append("# Help ", "Title"):nl()
  text:append("Press ", "Comment"):append("<q>", "Special"):append(" to close", "Comment"):nl():nl()
  text:append("# Keymaps ", "Title"):nl():nl()
  local keys = vim.tbl_keys(self.win.keys)
  table.sort(keys)
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

function M:open()
  self.win:open()
  self:refresh()
  return self
end

function M:close()
  Preview.close()
  self.win:close()
  return self
end

function M:count()
  local count = 0
  for _, node in pairs(self.nodes) do
    count = count + node:count()
  end
  return count
end

function M:update()
  if self.opts.results.auto_close and self:count() == 0 then
    return self:close()
  end
  if self.opts.results.auto_open and not self.win:valid() then
    if self:count() == 0 then
      return
    end
    self:open()
  end
  self:render()
end

function M:render()
  if not self.win:valid() then
    return
  end
  local loc = self:at()

  -- render sections
  self.renderer:clear()
  self.renderer:nl()
  for _ = 1, vim.tbl_get(self.opts.results.win, "padding", "top") or 0 do
    self.renderer:nl()
  end
  for s, section in ipairs(self.sections) do
    local nodes = self.nodes[s] and self.nodes[s].children
    if nodes and #nodes > 0 then
      self.renderer:section(section, nodes)
    end
  end
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

  -- render extmarks and restore window view
  local view = vim.api.nvim_win_call(self.win.win, vim.fn.winsaveview)
  self.renderer:render(self.win.buf)
  vim.api.nvim_win_call(self.win.win, function()
    vim.fn.winrestview(view)
  end)

  -- when window is at top, dont move cursor
  if view.topline == 1 then
    return
  end

  local new_loc = self:at()
  if new_loc.node and loc.node and new_loc.node.id == loc.node.id then
    return
  end

  -- Move cursor to the same item
  local cursor = vim.api.nvim_win_get_cursor(self.win.win)
  local item_row ---@type number?
  for row, l in pairs(self.renderer._locations) do
    if loc.node and loc.item then
      if l.node and l.item and loc.node.id == l.node.id and l.item == loc.item then
        item_row = row
        break
      end
    elseif loc.node and l.node and loc.node.id == l.node.id then
      item_row = row
      break
    end
  end
  if item_row and item_row ~= cursor[1] then
    vim.api.nvim_win_set_cursor(self.win.win, { item_row, cursor[2] })
    return
  end
end

-- Tree.build = Util.track(Tree.build, "Tree.build")
-- Filter.filter = Util.track(Filter.filter, "Filter.filter")
-- Sort.sort = Util.track(Sort.sort, "Sort.sort")
-- Render.render = Util.track(Render.render, "Render.render")
-- Render.node = Util.track(Render.node, "Render.node")
-- Text.render = Util.track(Text.render, "Text.render")
-- Util.track(M, "View")
-- Util.report()

-- local view2 = M.new({
--   events = { "DiagnosticChanged", "BufEnter" },
--   win = {
--     type = "float",
--     position = { 3, -50 },
--     size = { width = 40, height = 5 },
--     border = "rounded",
--     focusable = false,
--   },
--   auto_open = true,
--   auto_close = true,
--   sections = {
--     {
--       -- Trouble classic for current buffer
--       source = "diagnostics",
--       groups = {
--         { "filename", format = "{file_icon} {filename} {count}" },
--       },
--       sort = { "severity", "filename", "pos" },
--       format = "{severity_icon} {message} {item.source} ({code}) {pos}",
--       filter = {
--         severity = vim.diagnostic.severity.ERROR,
--       },
--     },
--   },
-- })

return M
