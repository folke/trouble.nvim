
augroup LspTrouble
  autocmd!
  au User LspDiagnosticsChanged lua require'trouble'.refresh({auto = true})
  autocmd BufWinEnter,BufEnter * lua require("trouble").action("on_win_enter")
augroup end

command! LspTroubleOpen lua require'trouble'.open()
command! LspTroubleClose lua require'trouble'.close()
command! LspTroubleToggle lua require'trouble'.toggle()
command! LspTroubleRefresh lua require'trouble'.refresh()