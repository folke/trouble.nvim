
augroup LspTrouble
  autocmd!
  au User LspDiagnosticsChanged lua require'trouble'.refresh({auto = true, provider = "diagnostics"})
  autocmd BufWinEnter,BufEnter * lua require("trouble").action("on_win_enter")
augroup end

command! -nargs=* LspTrouble lua require'trouble'.open(<f-args>)
command! -nargs=* LspTroubleToggle lua require'trouble'.toggle(<f-args>)
command! LspTroubleClose lua require'trouble'.close()
command! LspTroubleRefresh lua require'trouble'.refresh()

" deprecated commands
command! -nargs=* LspTroubleOpen lua require'trouble'.open(<f-args>)
command! LspTroubleWorkspaceOpen lua require'trouble'.open({mode = "lsp_workspace_diagnostics"})
command! LspTroubleDocumentOpen lua require'trouble'.open({mode = "lsp_document_diagnostics"})
command! LspTroubleWorkspaceToggle lua require'trouble'.toggle({mode = "lsp_workspace_diagnostics"})
command! LspTroubleDocumentToggle lua require'trouble'.toggle({mode = "lsp_document_diagnostics"})

