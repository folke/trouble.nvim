---@alias trouble.Action.ctx {item?: trouble.Item, node?: trouble.Node}
---@alias trouble.ActionFn fun(view:trouble.View, ctx:trouble.Action.ctx)
---@alias trouble.Action trouble.ActionFn|{action:trouble.ActionFn, desc?:string}

---@type table<string, trouble.Action>
local M = {
  refresh = function(self)
    self:refresh()
  end,
  close = function(self)
    self:close()
  end,
  cancel = function(self)
    self:goto_main()
  end,
  preview = function(self, ctx)
    self:preview(ctx.item)
  end,
  toggle_auto_preview = function(self)
    self.opts.auto_preview = not self.opts.auto_preview
    local Preview = require("trouble.view.preview")
    if self.opts.auto_preview then
      self:preview()
    else
      Preview.close()
    end
  end,
  help = function(self)
    self:help()
  end,
  jump_only = function(self, ctx)
    if ctx.item then
      self:jump(ctx.item)
    end
  end,
  jump = function(self, ctx)
    if ctx.item then
      self:jump(ctx.item)
    elseif ctx.node then
      self:fold(ctx.node)
    end
  end,
  jump_close = function(self, ctx)
    if ctx.item then
      self:jump(ctx.item)
      self:close()
    end
  end,
  jump_split = function(self, ctx)
    if ctx.item then
      self:jump(ctx.item, { split = true })
    end
  end,
  jump_vsplit = function(self, ctx)
    if ctx.item then
      self:jump(ctx.item, { vsplit = true })
    end
  end,
  inspect = function(_, ctx)
    vim.print(ctx.item)
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

return M
