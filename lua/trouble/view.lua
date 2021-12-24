local providers = require("trouble.providers")
local renderer = require("trouble.renderer")
local config = require("trouble.config")
local util = require("trouble.util")
local Split = require("nui.split")
local Tree = require("nui.tree")
local Line = require("nui.line")

local highlight = vim.api.nvim_buf_add_highlight

---@class TroubleView
---@field split table
---@field tree table
---@field group boolean
---@field parent number
local View = {}
View.__index = View

-- keep track of buffers with added highlights
-- highlights are cleared on BufLeave of Trouble
local hl_bufs = {}

local function clear_hl(bufnr)
  if vim.api.nvim_buf_is_valid(bufnr) then
    vim.api.nvim_buf_clear_namespace(bufnr, config.namespace, 0, -1)
  end
end

---Find a rogue Trouble buffer that might have been spawned by i.e. a session.
local function find_rogue_buffer()
  for _, v in ipairs(vim.api.nvim_list_bufs()) do
    if vim.fn.bufname(v) == "Trouble" then
      return v
    end
  end
  return nil
end

---Find pre-existing Trouble buffer, delete its windows then wipe it.
---@private
local function wipe_rogue_buffer()
  local bn = find_rogue_buffer()
  if bn then
    local win_ids = vim.fn.win_findbuf(bn)
    for _, id in ipairs(win_ids) do
      if vim.fn.win_gettype(id) ~= "autocmd" and vim.api.nvim_win_is_valid(id) then
        vim.api.nvim_win_close(id, true)
      end
    end

    vim.api.nvim_buf_set_name(bn, "")
    vim.schedule(function()
      pcall(vim.api.nvim_buf_delete, bn, {})
    end)
  end
end

function View:new(opts)
  opts = opts or {}

  local group
  if opts.group ~= nil then
    group = opts.group
  else
    group = config.options.group
  end

  local size
  if config.options.position == "top" or config.options.position == "bottom" then
    size = config.options.height
  else
    size = config.options.width
  end

  local split = Split({
    relative = "editor",
    position = config.options.position or "top",
    size = size,
  })

  split:mount()

  local tree = Tree({
    winid = split.winid,
    ns_id = config.namespace,
    buf_options = {
      bufhidden = "wipe",
      buflisted = false,
      buftype = "nofile",
      filetype = "Trouble",
      modifiable = false,
      readonly = true,
      swapfile = false,
    },
    win_options = {
      fcs = "eob: ",
      foldcolumn = "0",
      foldenable = false,
      foldlevel = 3,
      foldmethod = "manual",
      list = false,
      number = false,
      relativenumber = false,
      signcolumn = "no",
      spell = false,
      winfixheight = true,
      winfixwidth = true,
      winhighlight = "Normal:TroubleNormal,EndOfBuffer:TroubleNormal,SignColumn:TroubleNormal",
      wrap = false,
    },
    prepare_node = function(node)
      local line = Line()

      if node.type == "padding" then
        line:append("")
      elseif node.type == "file" then
        line:append(" ")

        if node:is_expanded() then
          line:append(config.options.fold_open, "TroubleFoldIcon")
        else
          line:append(config.options.fold_closed, "TroubleFoldIcon")
        end
        line:append(" ")

        local filename = node.data.filename

        local count = #(node.data.items or {})

        if config.options.icons then
          local icon, icon_hl = renderer.get_icon(filename)
          line:append(icon, icon_hl)
          line:append(" ")
        end

        line:append(vim.fn.fnamemodify(filename, ":p:."), "TroubleFile")
        line:append(" ")
        line:append(" " .. count .. " ", "TroubleCount")
      elseif node.type == "diagnostic" then
        local diag = node.data

        local sign = diag.sign or renderer.signs[string.lower(diag.type)]
        if not sign then
          sign = diag.type
        end

        local indent = "     "
        if config.options.indent_lines then
          indent = " │   "
        end

        local sign_hl = diag.sign_hl or ("TroubleSign" .. diag.type)

        line:append(indent, "TroubleIndent")
        line:append(sign .. "  ", sign_hl)
        line:append(diag.text, "TroubleText" .. diag.type)
        line:append(" ")

        if diag.source then
          line:append(diag.source, "TroubleSource")
        end
        if diag.code and diag.code ~= vim.NIL then
          line:append(" (" .. diag.code .. ")", "TroubleCode")
        end

        line:append(" ")

        line:append("[" .. diag.lnum .. ", " .. diag.col .. "]", "TroubleLocation")
      end

      return line
    end,
  })

  local view = setmetatable({
    split = split,
    tree = tree,
    parent = opts.parent,
    group = group,
  }, self)

  return view
end

function View:set_option(name, value, win)
  if win then
    return vim.api.nvim_win_set_option(self.split.winid, name, value)
  else
    return vim.api.nvim_buf_set_option(self.split.bufnr, name, value)
  end
end

function View:clear()
  return vim.api.nvim_buf_set_lines(self.split.bufnr, 0, -1, false, {})
end

function View:unlock()
  self:set_option("modifiable", true)
  self:set_option("readonly", false)
end

function View:lock()
  self:set_option("readonly", true)
  self:set_option("modifiable", false)
end

function View:is_valid()
  return self.split and vim.api.nvim_buf_is_valid(self.split.bufnr) and vim.api.nvim_buf_is_loaded(self.split.bufnr)
end

function View:update(opts)
  util.debug("update")
  opts = opts or {}
  local buf = vim.api.nvim_win_get_buf(self.parent)
  providers.get(self.parent, buf, function(items)
    local grouped = providers.group(items)
    local count = util.count(grouped)

    -- check for auto close
    if opts.auto and config.options.auto_close then
      if count == 0 then
        self:close()
        return
      end
    end

    if #items == 0 then
      util.warn("no results")
    end

    -- Update lsp signs
    renderer.update_signs()

    local nodes = {}

    if config.options.padding then
      table.insert(nodes, Tree.Node({ type = "padding" }))
    end

    for _, group in ipairs(grouped) do
      local diagnostic_nodes = vim.tbl_map(function(diag)
        return Tree.Node({ type = "diagnostic", data = diag })
      end, group.items)

      if self.group then
        local node = Tree.Node({ type = "file", data = group }, diagnostic_nodes)
        opts.open_folds = true
        if opts.open_folds then
          node:expand()
        end
        if opts.close_folds then
          node:collapse()
        end
        table.insert(nodes, node)
      else
        for _, node in ipairs(diagnostic_nodes) do
          table.insert(nodes, node)
        end
      end
    end

    self.tree:set_nodes(nodes)

    self.tree:render()

    if opts.focus then
      self:focus()
    end
  end, config.options)
end

function View:setup(opts)
  util.debug("setup")
  opts = opts or {}
  if not pcall(vim.api.nvim_buf_set_name, self.split.bufnr, "Trouble") then
    wipe_rogue_buffer()
    vim.api.nvim_buf_set_name(self.split.bufnr, "Trouble")
  end

  for action, keys in pairs(config.options.action_keys) do
    if type(keys) == "string" then
      keys = { keys }
    end
    for _, key in pairs(keys) do
      vim.api.nvim_buf_set_keymap(
        self.split.bufnr,
        "n",
        key,
        [[<cmd>lua require("trouble").action("]] .. action .. [[")<cr>]],
        { silent = true, noremap = true, nowait = true }
      )
    end
  end

  vim.api.nvim_exec(
    [[
      augroup TroubleHighlights
        autocmd! * <buffer>
        autocmd BufEnter <buffer> lua require("trouble").action("on_enter")
        autocmd CursorMoved <buffer> lua require("trouble").action("auto_preview")
        autocmd BufLeave <buffer> lua require("trouble").action("on_leave")
      augroup END
    ]],
    false
  )

  if not opts.parent then
    self:on_enter()
  end
  self:lock()
  self:update(opts)
end

function View:on_enter()
  util.debug("on_enter")

  self.parent = self.parent or vim.fn.win_getid(vim.fn.winnr("#"))

  if (not self:is_valid_parent(self.parent)) or self.parent == self.split.winid then
    util.debug("not valid parent")
    for _, win in pairs(vim.api.nvim_list_wins()) do
      if self:is_valid_parent(win) and win ~= self.split.winid then
        self.parent = win
        break
      end
    end
  end

  if not vim.api.nvim_win_is_valid(self.parent) then
    return self:close()
  end

  self.parent_state = {
    buf = vim.api.nvim_win_get_buf(self.parent),
    cursor = vim.api.nvim_win_get_cursor(self.parent),
  }
end

function View:on_leave()
  util.debug("on_leave")
  self:close_preview()
end

function View:close_preview()
  -- Clear preview highlights
  for buf, _ in pairs(hl_bufs) do
    clear_hl(buf)
  end
  hl_bufs = {}

  -- Reset parent state
  local valid_win = vim.api.nvim_win_is_valid(self.parent)
  local valid_buf = self.parent_state and vim.api.nvim_buf_is_valid(self.parent_state.buf)

  if self.parent_state and valid_buf and valid_win then
    vim.api.nvim_win_set_buf(self.parent, self.parent_state.buf)
    vim.api.nvim_win_set_cursor(self.parent, self.parent_state.cursor)
  end

  self.parent_state = nil
end

function View:is_float(win)
  local opts = vim.api.nvim_win_get_config(win)
  return opts and opts.relative and opts.relative ~= ""
end

function View:is_valid_parent(win)
  if not vim.api.nvim_win_is_valid(win) then
    return false
  end
  -- dont do anything for floating windows
  if View:is_float(win) then
    return false
  end
  local buf = vim.api.nvim_win_get_buf(win)
  -- Skip special buffers
  if vim.api.nvim_buf_get_option(buf, "buftype") ~= "" then
    return false
  end

  return true
end

function View:on_win_enter()
  util.debug("on_win_enter")

  local current_win = vim.api.nvim_get_current_win()

  if vim.fn.winnr("$") == 1 and current_win == self.split.winid then
    vim.cmd([[q]])
    return
  end

  if not self:is_valid_parent(current_win) then
    return
  end

  local current_buf = vim.api.nvim_get_current_buf()

  -- update parent when needed
  if current_win ~= self.parent and current_win ~= self.split.winid then
    self.parent = current_win
    -- update diagnostics to match the window we are viewing
    if self:is_valid() then
      vim.defer_fn(function()
        util.debug("update_on_win_enter")
        self:update()
      end, 100)
    end
  end

  -- check if another buffer took over our window
  local parent = self.parent
  if current_win == self.split.winid and current_buf ~= self.split.bufnr then
    -- open the buffer in the parent
    vim.api.nvim_win_set_buf(parent, current_buf)
    -- HACK: some window local settings need to be reset
    vim.api.nvim_win_set_option(parent, "winhl", "")
    -- close the current trouble window
    vim.api.nvim_win_close(self.split.winid, false)
    -- open a new trouble window
    require("trouble").open()
    -- switch back to the opened window / buffer
    View.switch_to(parent, current_buf)
    -- util.warn("win_enter pro")
  end
end

function View:focus()
  View.switch_to(self.split.winid, self.split.bufnr)
  local line = self:get_line()
  if line == 1 then
    self:next_item()
  end
end

function View.switch_to(win, buf)
  if win then
    vim.api.nvim_set_current_win(win)
    if buf then
      vim.api.nvim_win_set_buf(win, buf)
    end
  end
end

function View:switch_to_parent()
  -- vim.cmd("wincmd p")
  View.switch_to(self.parent)
end

function View:close()
  util.debug("close")
  self.split:hide()
end

function View.create(opts)
  opts = opts or {}

  local view = View:new(opts)
  view:setup(opts)

  if opts and opts.auto then
    view:switch_to_parent()
  end
  return view
end

function View:get_cursor()
  return vim.api.nvim_win_get_cursor(self.split.winid)
end
function View:get_line()
  return self:get_cursor()[1]
end
function View:get_col()
  return self:get_cursor()[2]
end

function View:current_item()
  return self.tree:get_node()
end

local function focus_item(view, opts, direction, current_linenr)
  opts = opts or { skip_groups = false }

  local curr_linenr = current_linenr or view:get_line()
  local next_linenr = nil

  if direction == "next" then
    if curr_linenr == vim.api.nvim_buf_line_count(view.split.bufnr) then
      return
    end
    next_linenr = curr_linenr + 1
  elseif direction == "prev" then
    if curr_linenr == 1 then
      return
    end
    next_linenr = curr_linenr - 1
  end

  local next_node = view.tree:get_node(next_linenr)

  if next_node and (next_node.type == "padding" or (opts.skip_groups and next_node.type == "file")) then
    return focus_item(view, opts, direction, next_linenr)
  end

  if next_linenr then
    vim.api.nvim_win_set_cursor(view.split.winid, { next_linenr, view:get_col() })
    if opts.jump then
      view:jump()
    end
  end
end

function View:next_item(opts)
  focus_item(self, opts, "next")
end

function View:previous_item(opts)
  focus_item(self, opts, "prev")
end

function View:hover(opts)
  opts = opts or {}
  local node = opts.item or self:current_item()
  if not (node and node.data and node.data.full_text) then
    return
  end

  local lines = {}
  for line in node.data.full_text:gmatch("([^\n]*)\n?") do
    table.insert(lines, line)
  end

  vim.lsp.util.open_floating_preview(lines, "plaintext", { border = "single" })
end

local function toggle(node)
  return node:is_expanded() and node:collapse() or node:expand()
end

function View:jump(opts)
  opts = opts or {}
  local node = opts.item or self:current_item()
  if not node then
    return
  end

  if node.type == "file" then
    toggle(node)
    self.tree:render()
  elseif node.type == "diagnostic" then
    local diag = node.data
    util.jump_to_item(opts.win or self.parent, opts.precmd, diag)
  end
end

function View:toggle_fold()
  toggle(self.tree:get_node())
  self.tree:render()
end

function View:_preview()
  if not vim.api.nvim_win_is_valid(self.parent) then
    return
  end

  local node = self:current_item()
  if not node then
    return
  end
  util.debug("preview")

  if node.type == "diagnostic" then
    local diag = node.data
    vim.api.nvim_win_set_buf(self.parent, diag.bufnr)
    vim.api.nvim_win_set_cursor(self.parent, { diag.start.line + 1, diag.start.character })

    vim.api.nvim_buf_call(diag.bufnr, function()
      -- Center preview line on screen and open enough folds to show it
      vim.cmd("norm! zz zv")
      if vim.api.nvim_buf_get_option(diag.bufnr, "filetype") == "" then
        vim.cmd("do BufRead")
      end
    end)

    clear_hl(diag.bufnr)
    hl_bufs[diag.bufnr] = true
    for row = diag.start.line, diag.finish.line, 1 do
      local col_start = 0
      local col_end = -1
      if row == diag.start.line then
        col_start = diag.start.character
      end
      if row == diag.finish.line then
        col_end = diag.finish.character
      end
      highlight(diag.bufnr, config.namespace, "TroublePreview", row, col_start, col_end)
    end
  end
end

View.preview = util.throttle(50, View._preview)

return View
