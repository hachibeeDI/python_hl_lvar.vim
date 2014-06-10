# python_hl_lvar.vim

Highlight local variables in function is under cursor.

## Version

prototype

## Requirements

python interface


## Settings

```vim

" example
NeoBundleLazy 'hachibeeDI/python_hl_lvar.vim', {
\   'autoload' : {
\     'filetypes' : ['python'],
\   },
\ }
let g:enable_python_hl_lvar = 1
" default is 'guifg=palegreen3 gui=NONE ctermfg=114 cterm=NONE'
let g:python_hl_lvar_highlight_color = 'guifg=lightgoldenrod2 gui=NONE ctermfg=186 cterm=NONE'

autocmd BufWinEnter  *.py PyHlLVar
autocmd BufWinLeave  *.py PyHlLVar
autocmd WinEnter     *.py PyHlLVar
autocmd BufWritePost *.py PyHlLVar
autocmd WinLeave     *.py PyHlLVar
autocmd TabEnter     *.py PyHlLVar
autocmd TabLeave     *.py PyHlLVar

```
