local Util = require("trouble.util")

---@alias trouble.Action.ctx {item?: trouble.Item, node?: trouble.Node, opts?: table}
---@alias trouble.ActionFn fun(view:trouble.View, ctx:trouble.Action.ctx)
---@alias trouble.Action {action: trouble.ActionFn, desc?: string, mode?: string}
---@alias trouble.Action.spec string|trouble.ActionFn|trouble.Action|{action: string}

---@class trouble.actions: {[string]: trouble.ActionFn}
local M = {
  -- Refresh the trouble source
  refresh = function(self)
    self:refresh()
  end,
  -- Close the trouble window
  close = function(self)
    self:close()
  end,
  -- Closes the preview and goes to the main window.
  -- The Trouble window is not closed.
  cancel = function(self)
    self:goto_main()
  end,
  -- Focus the trouble window
  focus = function(self)
    self.win:focus()
  end,
  -- Open the preview
  preview = function(self, ctx)
    local Preview = require("trouble.view.preview")
    if Preview.is_open() then
      Preview.close()
    else
      self:preview(ctx.item)
    end
  end,
  -- Open the preview
  delete = function(self)
    local enabled = self.opts.auto_refresh
    self:delete()
    if enabled and not self.opts.auto_refresh then
      Util.warn("Auto refresh **disabled**", { id = "toggle_refresh" })
    end
  end,
  -- Toggle the preview
  toggle_preview = function(self, ctx)
    self.opts.auto_preview = not self.opts.auto_preview
    local enabled = self.opts.auto_preview and "enabled" or "disabled"
    local notify = (enabled == "enabled") and Util.info or Util.warn
    notify("Auto preview **" .. enabled .. "**", { id = "toggle_preview" })
    local Preview = require("trouble.view.preview")
    if self.opts.auto_preview then
      if ctx.item then
        self:preview()
      end
    else
      Preview.close()
    end
  end,
  -- Toggle the auto refresh
  toggle_refresh = function(self)
    self.opts.auto_refresh = not self.opts.auto_refresh
    local enabled = self.opts.auto_refresh and "enabled" or "disabled"
    local notify = (enabled == "enabled") and Util.info or Util.warn
    notify("Auto refresh **" .. enabled .. "**", { id = "toggle_refresh" })
  end,

  filter = function(self, ctx)
    self:filter(ctx.opts.filter)
  end,
  -- Show the help
  help = function(self)
    self:help()
  end,
  -- Go to the next item
  next = function(self, ctx)
    self:move({ down = vim.v.count1, jump = ctx.opts.jump })
  end,
  -- Go to the previous item
  prev = function(self, ctx)
    self:move({ up = vim.v.count1, jump = ctx.opts.jump })
  end,
  -- Go to the first item
  first = function(self, ctx)
    self:move({ idx = vim.v.count1, jump = ctx.opts.jump })
  end,
  -- Go to the last item
  last = function(self, ctx)
    self:move({ idx = -vim.v.count1, jump = ctx.opts.jump })
  end,
  -- Jump to the item if on an item, otherwise do nothing
  jump_only = function(self, ctx)
    if ctx.item then
      self:jump(ctx.item)
    end
  end,
  -- Jump to the item if on an item, otherwise fold the node
  jump = function(self, ctx)
    if ctx.item then
      self:jump(ctx.item)
    elseif ctx.node then
      self:fold(ctx.node)
    end
  end,
  -- Jump to the item and close the trouble window
  jump_close = function(self, ctx)
    if ctx.item then
      self:jump(ctx.item)
      self:close()
    end
  end,
  -- Open the item in a split
  jump_split = function(self, ctx)
    if ctx.item then
      self:jump(ctx.item, { split = true })
    end
  end,
  -- Open the item in a split and close the trouble window
  jump_split_close = function(self, ctx)
    if ctx.item then
      self:jump(ctx.item, { split = true })
      self:close()
    end
  end,
  -- Open the item in a vsplit
  jump_vsplit = function(self, ctx)
    if ctx.item then
      self:jump(ctx.item, { vsplit = true })
    end
  end,
  -- Open the item in a vsplit and close the trouble window
  jump_vsplit_close = function(self, ctx)
    if ctx.item then
      self:jump(ctx.item, { vsplit = true })
      self:close()
    end
  end,
  -- Dump the item to the console
  inspect = function(_, ctx)
    vim.print(ctx.item or (ctx.node and ctx.node.item))
  end,
  fold_reduce = function(self)
    self:fold_level({ add = vim.v.count1 })
  end,
  fold_open_all = function(self)
    self:fold_level({ level = 1000 })
  end,
  fold_more = function(self)
    self:fold_level({ add = -vim.v.count1 })
  end,
  fold_close_all = function(self)
    self:fold_level({ level = 0 })
  end,
  fold_update = function(self, ctx)
    self:fold_level({})
    self:fold(ctx.node, { action = "open" })
  end,
  fold_update_all = function(self)
    self:fold_level({})
  end,
  fold_disable = function(self)
    self.renderer.foldenable = false
    self:render()
  end,
  fold_enable = function(self)
    self.renderer.foldenable = true
    self:render()
  end,
  fold_toggle_enable = function(self)
    self.renderer.foldenable = not self.renderer.foldenable
    self:render()
  end,
}

for _, fold_action in ipairs({ "toggle", "open", "close" }) do
  for _, recursive in ipairs({ true, false }) do
    local desc = "Fold " .. fold_action .. " " .. (recursive and "recursive" or "")
    local name = "fold_" .. fold_action .. (recursive and "_recursive" or "")
    M[name] = {
      action = function(self, ctx)
        self:fold(ctx.node, { action = fold_action, recursive = recursive })
      end,
      desc = desc,
    }
  end
end

return setmetatable(M, {
  __index = function(_, k)
    if k == "previous" then
      Util.warn("`previous` is deprecated, use `prev` instead")
    else
      Util.error("Action not found: " .. k)
    end
  end,
})
