local Cache = require("trouble.cache")
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
---@field opts trouble.Mode
---@field sections trouble.Section[]
---@field items trouble.Item[][]
---@field nodes trouble.Node[]
---@field renderer trouble.Render
---@field private _main? {buf:number, win:number}
---@field fetching number
---@field cache trouble.Cache
local M = {}
M.__index = M

---@param opts trouble.Mode
function M.new(opts)
  local self = setmetatable({}, M)
  self.opts = opts or {}
  self.opts.win = self.opts.win or {}
  self.opts.win.on_mount = function()
    self:on_mount()
  end
  self.sections = self.opts.sections and Spec.sections(self.opts.sections) or {}
  for _, s in ipairs(self.sections) do
    s.max_items = s.max_items or self.opts.max_items
  end
  self.win = Window.new(opts.win)
  self.opts.win = self.win.opts
  self.items = {}
  self.fetching = 0
  self.nodes = {}
  self._main = {}
  self.cache = Cache.new("view")

  self.opts.render.padding = self.opts.render.padding or vim.tbl_get(self.opts.win, "padding", "left")

  self.renderer = Render.new(self.opts.render)
  self.refresh = Util.throttle(self.refresh, {
    ms = 200,
    is_running = function()
      return self.fetching > 0
    end,
  })
  self.update = Util.throttle(self.update, { ms = 10 })
  self.render = Util.throttle(self.render, { ms = 10 })

  if self.opts.auto_open then
    self:listen()
    self:refresh()
  end
  return self
end

function M:on_mount()
  self:listen()
  self.win:on("WinLeave", function()
    Preview.close()
  end)

  local preview = Util.throttle(self.preview, { ms = 100 })
  self.win:on("CursorMoved", function()
    if self.opts.auto_preview then
      local loc = self:at()
      if loc and loc.item then
        preview(self, loc.item)
      end
    end
  end)

  self.win:on("OptionSet", function()
    local foldlevel = vim.wo[self.win.win].foldlevel
    if foldlevel ~= self.renderer.foldlevel then
      self:fold_level({ level = foldlevel })
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
  if not item then
    return vim.notify("No item to jump to", vim.log.levels.WARN, { title = "Trouble" })
  end

  if not vim.bo[item.buf].buflisted then
    vim.bo[item.buf].buflisted = true
  end
  if not vim.api.nvim_buf_is_loaded(item.buf) then
    vim.fn.bufload(item.buf)
  end
  Preview.close()
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
  if vim.b[item.buf].trouble_preview then
    vim.cmd.edit()
  end
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

---@return {buf:number, win:number}?
function M:main()
  local valid = self._main
    and self._main.win
    and vim.api.nvim_win_is_valid(self._main.win)
    and self._main.buf
    and vim.api.nvim_buf_is_valid(self._main.buf)
  if not valid then
    self._main = self.win:find_main()
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
  self:main()
  self.win:on("BufEnter", function()
    if Preview.preview then
      return
    end
    local buf = vim.api.nvim_get_current_buf()
    local win = vim.api.nvim_get_current_win()
    if vim.bo[buf].buftype == "" then
      self._main = { buf = buf, win = win }
    end
  end, { buffer = false })

  local events = self.opts.events or {}
  events = type(events) == "string" and { events } or events
  ---@cast events string[]
  for _, spec in ipairs(events) do
    local event, pattern = spec:match("^(%w+)%s+(.*)$")
    event = event or spec
    vim.api.nvim_create_autocmd(event, {
      group = self.win:augroup(),
      pattern = pattern,
      callback = function()
        self:refresh()
      end,
    })
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
  self.win:map(key, function()
    fn(self, self:at())
  end, desc)
end

function M:refresh()
  local is_open = self.win:valid()
  if not is_open and not self.opts.auto_open then
    return
  end
  self.cache:clear()
  for s, section in ipairs(self.sections) do
    self.fetching = self.fetching + 1
    Source.get(section.source, function(items)
      self.items[s] = Filter.filter(items, section.filter, self)
      self.items[s] = Sort.sort(self.items[s], section.sort, self)
      for i, item in ipairs(self.items[s]) do
        item.idx = i
      end
      -- self.items[s] = vim.list_slice(self.items[s], 1, 10)
      self.nodes[s] = Tree.build(self.items[s], section)
      self.fetching = self.fetching - 1
      self:update()
    end, { filter = section.filter, view = self })
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
end

function M:close()
  Preview.close()
  self.win:close()
end

function M:count()
  local count = 0
  for _, node in ipairs(self.nodes) do
    count = count + #node.items
  end
  return count
end

function M:update()
  if self.opts.auto_close and self:count() == 0 then
    return self:close()
  end
  if self.opts.auto_open and not self.win:valid() and self:count() > 0 then
    return self:open()
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
  for _ = 1, vim.tbl_get(self.opts.win, "padding", "top") or 0 do
    self.renderer:nl()
  end
  for s, section in ipairs(self.sections) do
    local nodes = self.nodes[s].nodes
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

  -- Move cursor to the same item
  local cursor = vim.api.nvim_win_get_cursor(self.win.win)
  for row, l in pairs(self.renderer._locations) do
    if loc.node and loc.item then
      if l.node and l.item and loc.node.id == l.node.id and l.item == loc.item then
        cursor[1] = row
        vim.api.nvim_win_set_cursor(self.win.win, cursor)
        break
      end
    elseif loc.node and l.node and loc.node.id == l.node.id then
      cursor[1] = row
      vim.api.nvim_win_set_cursor(self.win.win, cursor)
      break
    end
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
