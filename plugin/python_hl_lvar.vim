if !has('python')
  echoerr "python_hl_lvar: This plugin does not work without has('python')"
  finish
endif

" ============= variable initialization ==========

let g:enable_python_hl_lvar = get(g:, 'enable_python_hl_lvar', 0)
let g:python_hl_lvar_hl_group = get(g:, 'python_hl_lvar_hl_group', 'pythonLocalVariables')
let g:python_hl_lvar_highlight_color = get(
      \ g:,
      \ 'python_hl_lvar_highlight_color',
      \ 'guifg=palegreen3 gui=NONE ctermfg=114 cterm=NONE'
      \ )

exe "highlight " . g:python_hl_lvar_hl_group . " " . g:python_hl_lvar_highlight_color
" ================================================


command! PyHlLVar call python_hl_lvar#hl_lvar()
