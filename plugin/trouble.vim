
augroup Trouble
  autocmd!
  au User LspDiagnosticsChanged lua require'trouble'.refresh({auto = true, provider = "diagnostics"})
  autocmd BufWinEnter,BufEnter * lua require("trouble").action("on_win_enter")
augroup end

function! s:complete(arg,line,pos) abort
  return join(sort(luaeval('vim.tbl_keys(require("trouble.providers").providers)')), "\n")
endfunction

command! -nargs=* -complete=custom,s:complete Trouble lua require'trouble'.open(<f-args>)
command! -nargs=* -complete=custom,s:complete TroubleToggle lua require'trouble'.toggle(<f-args>)
command! TroubleClose lua require'trouble'.close()
command! TroubleRefresh lua require'trouble'.refresh()

" deprecated commands
command! -nargs=* -complete=custom,s:complete LspTrouble lua require'trouble'.open(<f-args>)
command! -nargs=* -complete=custom,s:complete LspTroubleToggle lua require'trouble'.toggle(<f-args>)
command! LspTroubleClose lua require'trouble'.close()
command! LspTroubleRefresh lua require'trouble'.refresh()
command! -nargs=* -complete=custom,s:complete LspTroubleOpen lua require'trouble'.open(<f-args>)
command! LspTroubleWorkspaceOpen lua require'trouble'.open({mode = "lsp_workspace_diagnostics"})
command! LspTroubleDocumentOpen lua require'trouble'.open({mode = "lsp_document_diagnostics"})
command! LspTroubleWorkspaceToggle lua require'trouble'.toggle({mode = "lsp_workspace_diagnostics"})
command! LspTroubleDocumentToggle lua require'trouble'.toggle({mode = "lsp_document_diagnostics"})

