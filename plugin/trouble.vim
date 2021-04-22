
augroup LspTrouble
  autocmd!
  au User LspDiagnosticsChanged lua require'trouble'.refresh({auto = true})
  autocmd BufWinEnter,BufEnter * lua require("trouble").action("on_win_enter")
augroup end

command! LspTroubleOpen lua require'trouble'.open()
command! LspTroubleWorkspaceOpen lua require'trouble'.open({mode = "workspace"})
command! LspTroubleDocumentOpen lua require'trouble'.open({mode = "document"})
command! LspTroubleClose lua require'trouble'.close()
command! LspTroubleToggle lua require'trouble'.toggle()
command! LspTroubleWorkspaceToggle lua require'trouble'.toggle({mode = "workspace"})
command! LspTroubleDocumentToggle lua require'trouble'.toggle({mode = "document"})

command! LspTroubleRefresh lua require'trouble'.refresh()