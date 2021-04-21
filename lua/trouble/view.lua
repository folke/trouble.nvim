local renderer = require("trouble.renderer")
local config = require("trouble.config")
local folds = require("trouble.folds")

local highlight = vim.api.nvim_buf_add_highlight

---@class View
---@field handle number
---@field win number
---@field items Diagnostics[]
---@field folded table<string, boolean>
local View = {}
View.__index = View

local function clear_hl(bufnr)
    vim.api.nvim_buf_clear_namespace(bufnr, config.namespace, 0, -1)
end

---Find a rogue LspTrouble buffer that might have been spawned by i.e. a session.
local function find_rogue_buffer()
    for _, v in ipairs(vim.api.nvim_list_bufs()) do
        if vim.fn.bufname(v) == "LspTrouble" then return v end
    end
    return nil
end

---Find pre-existing LspTrouble buffer, delete its windows then wipe it.
---@private
local function wipe_rogue_buffer()
    local bn = find_rogue_buffer()
    if bn then
        local win_ids = vim.fn.win_findbuf(bn)
        for _, id in ipairs(win_ids) do
            if vim.fn.win_gettype(id) ~= "autocmd" then
                vim.api.nvim_win_close(id, true)
            end
        end

        vim.api.nvim_buf_set_name(bn, "")
        vim.schedule(function() pcall(vim.api.nvim_buf_delete, bn, {}) end)
    end
end

function View:new()
    local this = {
        handle = vim.api.nvim_get_current_buf(),
        win = vim.api.nvim_get_current_win()
    }
    setmetatable(this, self)
    return this
end

function View:set_option(name, value, win)
    if win then
        return vim.api.nvim_win_set_option(self.win, name, value)
    else
        return vim.api.nvim_buf_set_option(self.handle, name, value)
    end
end

---@param text Text
function View:render(text)
    self:unlock()
    self:set_lines(text.lines)
    self:lock()
    clear_hl(self.handle)
    for _, data in ipairs(text.hl) do
        highlight(self.handle, config.namespace, data.group, data.line,
                  data.from, data.to)
    end
end

function View:clear()
    return vim.api.nvim_buf_set_lines(self.handle, 0, -1, false, {})
end

function View:unlock()
    self:set_option("readonly", false)
    self:set_option("modifiable", true)
end

function View:lock()
    self:set_option("readonly", true)
    self:set_option("modifiable", false)
end

function View:set_lines(lines, first, last, strict)
    first = first or 0
    last = last or -1
    strict = strict or false
    return vim.api.nvim_buf_set_lines(self.handle, first, last, strict, lines)
end

function View:is_valid()
    return vim.api.nvim_buf_is_valid(self.handle) and
               vim.api.nvim_buf_is_loaded(self.handle)
end

function View:update(opts) renderer.render(self, opts) end

function View:setup(opts)
    vim.cmd("setlocal nonu")
    vim.cmd("setlocal nornu")
    if not pcall(vim.api.nvim_buf_set_name, self.handle, 'LspTrouble') then
        wipe_rogue_buffer()
        vim.api.nvim_buf_set_name(self.handle, 'LspTrouble')
    end
    self:set_option("bufhidden", "wipe")
    self:set_option("filetype", "LspTrouble")
    self:set_option("buftype", "nofile")
    self:set_option("swapfile", false)
    self:set_option("buflisted", false)
    self:set_option("winfixwidth", true, true)
    self:set_option("spell", false, true)
    self:set_option("list", false, true)
    self:set_option("winfixheight", true, true)
    self:set_option("signcolumn", "no", true)
    self:set_option("foldmethod", "manual", true)
    self:set_option("foldcolumn", "0", true)
    self:set_option("foldlevel", 3, true)
    self:set_option("foldenable", false, true)
    self:set_option("winhl", "Normal:LspTroubleNormal", true)

    for key, action in pairs(config.options.actions) do
        vim.api.nvim_buf_set_keymap(self.handle, "n", key,
                                    [[<cmd>lua require("trouble").action("]] ..
                                        action .. [[")<cr>]],
                                    {silent = true, noremap = true})
    end

    vim.api.nvim_win_set_height(self.win, config.options.height)

    vim.api.nvim_exec([[
      augroup LspTroubleHighlights
        autocmd! * <buffer>
        autocmd CursorMoved <buffer> lua require("trouble").action("auto_preview")
      augroup END
    ]], false)

    self:lock()
    self:update(opts)
end

function View:focus()
    vim.api.nvim_set_current_win(self.win)
    vim.cmd(":buffer " .. self.handle)
end

function View:close() vim.api.nvim_buf_delete(self.handle, {}) end

function View.create(opts)
    vim.cmd("below new")
    vim.cmd("wincmd J")
    local buffer = View:new()
    buffer:setup(opts)

    if opts and opts.auto then vim.cmd("wincmd p") end
    return buffer
end

function View:current_item()
    local line = vim.fn.line(".")
    local item = self.items[line - 1]
    return item
end

function View:jump()
    local item = self:current_item()
    if not item then return end

    if item.is_file == true then
        folds.toggle(item.filename)
        self:update()
    else
        vim.cmd("wincmd p")
        vim.cmd("buffer " .. item.bufnr)
        vim.fn.cursor(item.lnum, item.col)
    end
end

function View:preview()
    local item = self:current_item()
    if not item then return end

    if item.is_file ~= true then
        self:jump()
        self:focus()
        clear_hl(item.bufnr)
        for row = item.start.line, item.finish.line, 1 do
            local col_start = 0
            local col_end = -1
            if row == item.start.line then
                col_start = item.start.character
            end
            if row == item.finish.line then
                col_end = item.finish.character
            end
            highlight(item.bufnr, config.namespace, "LspTroublePreview", row,
                      col_start, col_end)
        end
    end
end

return View
