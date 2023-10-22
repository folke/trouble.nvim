---@class trouble.Split
---@field type "split"
---@field relative "editor" | "win" cursor is only valid for float
---@field win? number
---@field size number
---@field position "top" | "bottom" | "left" | "right"

---@class trouble.Float
---@field type "float"
---@field relative "editor" | "win" | "cursor" cursor is only valid for float
---@field size {width: number, height: number}
---@field position {[1]: number, [2]: number}

---@class trouble.Window.opts: trouble.Split,trouble.Float
---@field padding? {top?:number, left?:number}
---@field enter? boolean
---@field wo? vim.wo
---@field bo? vim.bo
---@field on_mount? fun(self: trouble.Window)

---@class trouble.Window
---@field opts trouble.Window.opts
---@field win? number
---@field buf number
---@field id number
local M = {}
M.__index = M

local _id = 0
local function next_id()
  _id = _id + 1
  return _id
end

local split_commands = {
  editor = {
    top = "topleft",
    right = "vertical botright",
    bottom = "botright",
    left = "vertical topleft",
  },
  win = {
    top = "aboveleft",
    right = "vertical rightbelow",
    bottom = "belowright",
    left = "vertical leftabove",
  },
}

local float_options = {
  "anchor",
  "border",
  "bufpos",
  "col",
  "external",
  "fixed",
  "focusable",
  "footer",
  "footer_pos",
  "height",
  "hide",
  "noautocmd",
  "relative",
  "row",
  "style",
  "title",
  "title_pos",
  "width",
  "win",
  "zindex",
}

---@type trouble.Window.opts
local defaults = {
  enter = false,
  padding = { top = 0, left = 1 },
  bo = {
    bufhidden = "wipe",
    filetype = "trouble",
  },
  wo = {
    cursorcolumn = false,
    cursorline = true,
    fillchars = "eob: ",
    foldcolumn = "0",
    foldenable = false,
    foldlevel = 99,
    foldmethod = "manual",
    list = false,
    number = false,
    relativenumber = false,
    signcolumn = "no",
    spell = false,
    statuscolumn = "",
    winfixheight = true,
    winfixwidth = true,
    winhighlight = "Normal:TroubleNormal,EndOfBuffer:TroubleNormal",
    wrap = false,
  },
}

---@param opts? trouble.Window.opts
function M.new(opts)
  local self = setmetatable({}, M)
  self.id = next_id()
  opts = vim.tbl_deep_extend("force", defaults, opts or {})
  opts.type = opts.type or "split"
  if opts.type == "split" then
    opts.relative = opts.relative or "editor"
    opts.position = opts.position or "bottom"
    opts.size = opts.size or (opts.position == "bottom" or opts.position == "top") and 10 or 50
    opts.win = opts.win or vim.api.nvim_get_current_win()
  elseif opts.type == "float" then
    opts.relative = opts.relative or "editor"
    opts.size = opts.size or { width = 0.8, height = 0.8 }
    opts.position = opts.position or { 0.5, 0.5 }
  end
  self.opts = opts
  return self
end

---@param clear? boolean
function M:augroup(clear)
  return vim.api.nvim_create_augroup("trouble.window." .. self.id, { clear = clear == true })
end

function M:parent_size()
  if self.opts.relative == "editor" or self.opts.relative == "cursor" then
    return { width = vim.o.columns, height = vim.o.lines }
  end
  return { width = vim.api.nvim_win_get_width(self.opts.win), height = vim.api.nvim_win_get_height(self.opts.win) }
end

---@param type "win" | "buf"
function M:set_options(type)
  local opts = type == "win" and self.opts.wo or self.opts.bo
  ---@diagnostic disable-next-line: no-unknown
  for k, v in pairs(opts or {}) do
    ---@diagnostic disable-next-line: no-unknown
    local ok, err = pcall(vim.api.nvim_set_option_value, k, v, type == "win" and {
      scope = "local",
      win = self.win,
    } or { buf = self.buf })
    if not ok then
      vim.notify("Error setting option " .. k .. ": " .. err, vim.log.levels.ERROR, { title = "Trouble" })
    end
  end
end

function M:mount()
  self.buf = vim.api.nvim_create_buf(false, true)
  self:set_options("buf")
  if self.opts.type == "split" then
    self:mount_split(self.opts)
  else
    self:mount_float(self.opts)
  end
  self:set_options("win")

  self:on({ "BufWinLeave" }, vim.schedule_wrap(self.check_alien))

  self:on("WinClosed", function()
    self:augroup(true)
  end, { buffer = false, pattern = self.win .. "" })

  if self.opts.on_mount then
    self.opts.on_mount(self)
  end
end

---@return {win:number,buf:number}?
function M:find_main()
  local wins = vim.api.nvim_list_wins()
  table.insert(wins, 1, vim.api.nvim_get_current_win())
  for _, win in ipairs(wins) do
    if win ~= self.win then
      local b = vim.api.nvim_win_get_buf(win)
      if vim.bo[b].buftype == "" then
        return { win = win, buf = b }
      end
    end
  end
end

function M:check_alien()
  if self.win and vim.api.nvim_win_is_valid(self.win) then
    local buf = vim.api.nvim_win_get_buf(self.win)
    if buf ~= self.buf then
      -- move the alien buffer to another window
      local main = self:find_main()
      if main then
        vim.api.nvim_win_set_buf(main.win, buf)
      end
      -- restore the trouble window
      self:close()
      self:open()
    end
  end
end

function M:close()
  self:augroup(true)
  pcall(vim.api.nvim_win_close, self.win, true)
  self.win = nil
  pcall(vim.api.nvim_buf_delete, self.buf, { force = true })
  self.buf = nil
end

function M:open()
  if self:valid() then
    return
  end
  self:close()
  self:mount()
end

function M:valid()
  return self.win
    and vim.api.nvim_win_is_valid(self.win)
    and self.buf
    and vim.api.nvim_buf_is_valid(self.buf)
    and vim.api.nvim_win_get_buf(self.win) == self.buf
end

---@param opts trouble.Split
function M:mount_split(opts)
  if self.opts.win and not vim.api.nvim_win_is_valid(self.opts.win) then
    self.opts.win = 0
  end
  local parent_size = self:parent_size()
  local size = opts.size
  if size <= 1 then
    local vertical = opts.position == "left" or opts.position == "right"
    size = math.floor(parent_size[vertical and "height" or "width"] * size)
  end
  local cmd = split_commands[opts.relative][opts.position]
  vim.api.nvim_win_call(opts.win, function()
    vim.cmd("silent noswapfile " .. cmd .. " " .. size .. "split")
    vim.api.nvim_win_set_buf(0, self.buf)
    self.win = vim.api.nvim_get_current_win()
  end)
end

---@param opts trouble.Float
function M:mount_float(opts)
  local parent_size = self:parent_size()
  ---@type vim.api.keyset.float_config
  local config = {}
  for _, v in ipairs(float_options) do
    ---@diagnostic disable-next-line: no-unknown
    config[v] = opts[v]
  end
  config.focusable = true
  config.height = opts.size.height <= 1 and math.floor(parent_size.height * opts.size.height) or opts.size.height
  config.width = opts.size.width <= 1 and math.floor(parent_size.width * opts.size.width) or opts.size.width

  config.row = math.abs(opts.position[1]) <= 1 and math.floor((parent_size.height - config.height) * opts.position[1])
    or opts.position[1]
  config.row = config.row < 0 and (parent_size.height + config.row) or config.row

  config.col = math.abs(opts.position[2]) <= 1 and math.floor((parent_size.width - config.width) * opts.position[2])
    or opts.position[2]
  config.col = config.col < 0 and (parent_size.width + config.col) or config.col

  self.win = vim.api.nvim_open_win(self.buf, false, config)
end

---@param events string|string[]
---@param fn fun(self:trouble.Window):boolean?
---@param opts? vim.api.keyset.create_autocmd | {buffer: false}
function M:on(events, fn, opts)
  opts = opts or {}
  if opts.buffer == nil then
    opts.buffer = self.buf
  elseif opts.buffer == false then
    opts.buffer = nil
  end
  opts.callback = function()
    return fn(self)
  end
  opts.group = self:augroup()
  vim.api.nvim_create_autocmd(events, opts)
end

---@param key string
---@param fn fun(self: trouble.Window)
---@param desc? string
function M:map(key, fn, desc)
  if not self:valid() then
    error("Cannot create a keymap for an invalid window")
  end
  vim.keymap.set("n", key, function()
    fn(self)
  end, {
    nowait = true,
    buffer = self.buf,
    desc = desc,
  })
end

return M
