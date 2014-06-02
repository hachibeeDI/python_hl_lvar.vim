if !has('python')
  echoerr "python_hl_lvar: This plugin does not work without has('python')"
  finish
endif

" ============= variable initialization ==========

let g:enable_python_hl_lvar = get(g:, 'enable_python_hl_lvar', 0)
let g:python_hl_lvar_hl_group = get(g:, 'python_hl_lvar_hl_group', 'pythonLocalVariables')

"highlight pythonLocalVariables ctermbg=green guibg=green
hi link pythonLocalVariables Special
" ================================================


command! PyHlLVar call python_hl_lvar#hl_lvar()
