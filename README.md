# python_hl_lvar.vim

Highlight local variables in function is under cursor.

## Version

prototype

## Requirements

python interface


## Settings

```vim

NeoBundleLazy 'hachibeeDI/python_hl_lvar.vim', {
\   'autoload' : {
\     'filetypes' : ['python'],
\   },
\ }
let g:enable_python_hl_lvar = 1
autocmd BufWinEnter  *.py PyHlLVar
autocmd BufWinLeave  *.py PyHlLVar
autocmd WinEnter     *.py PyHlLVar
autocmd BufWritePost *.py PyHlLVar
autocmd WinLeave     *.py PyHlLVar
autocmd TabEnter     *.py PyHlLVar
autocmd TabLeave     *.py PyHlLVar

```
