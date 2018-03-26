function! python_hl_lvar#invoke_initialization()
  let g:python_hl_lvar_verbose = get(g:, 'python_hl_lvar_verbose', 0)
endfunction



" TODO: rewrite
function! python_hl_lvar#findfirstline()
    " Start at a nonblank line
    let l:cur_pos = getpos('.')
    let l:cur_line = getline('.')
    if l:cur_line =~# '^\s*$'
        call cursor(prevnonblank(l:cur_pos[1]), 0)
    endif
endfunction


function! python_hl_lvar#find_definitionline(kwd)
    " Find the defn line
    let l:cur_pos = getpos('.')
    let l:cur_line = getline('.')
    if l:cur_line =~# '^\s*'.a:kwd.' '
        let l:defn_pos = l:cur_pos
    else
        let l:cur_indent = indent(l:cur_pos[1])
        while 1
            if search('^\s*'.a:kwd.' ', 'bW')
                let l:defn_pos = getpos('.')
                let l:defn_indent = indent(l:defn_pos[1])
                if l:defn_indent >= l:cur_indent
                    " This is a defn at the same level or deeper, keep searching
                    continue
                else
                    " Found a defn, make sure there aren't any statements at a
                    " shallower indent level in between
                    for l:l in range(l:defn_pos[1] + 1, l:cur_pos[1])
                        if getline(l:l) !~# '^\s*$' && indent(l:l) < l:defn_indent
                            throw "defn-not-found"
                        endif
                    endfor
                    break
                endif
            else
                throw "defn-not-found"
            endif
        endwhile
    endif
    call cursor(l:cur_pos[1], l:cur_pos[2])
    return l:defn_pos
endfunction


function! python_hl_lvar#find_lastline(kwd, defn_pos, indent_level)
    " Find the last line of the block at given indent level
    let l:cur_pos = getpos('.')
    let l:end_pos = l:cur_pos
    while 1
        " Is this a one-liner?
        if getline('.') =~# '^\s*'.a:kwd.'\[^:\]\+:\s*\[^#\]'
            return a:defn_pos
        endif
        " This isn't a one-liner, so skip the def line
        if line('.') == a:defn_pos[1]
            normal! j
            continue
        endif
        if getline('.') !~# '^\s*$'
            if indent('.') > a:indent_level
                let l:end_pos = getpos('.')
            else
                break
            endif
        endif
        if line('.') == line('$')
            break
        else
            normal! j
        endif
    endwhile
    call cursor(l:cur_pos[1], l:cur_pos[2])
    return l:end_pos
endfunction


function! python_hl_lvar#funcpos()
    call python_hl_lvar#findfirstline()

    try
        let l:defn_pos = python_hl_lvar#find_definitionline('def')
        let l:defn_indent_level = indent(l:defn_pos[1])
    catch /defn-not-found/
        return 0
    endtry

    let l:end_pos = python_hl_lvar#find_lastline('def', l:defn_pos, l:defn_indent_level)

    return ['V', l:defn_pos, l:end_pos]
endfunction


function! python_hl_lvar#redraw(result) abort
  if exists('w:python_hl_lvar_match_id')
    call s:delete_highlight(w:python_hl_lvar_match_id)
  endif
  if a:result.variables != []
    call s:add_highlight(a:result)
  endif
endfunction


function! s:delete_highlight(match_id) abort
  " must be greater than -1
  if a:match_id < 0
    return
  endif
  try
    call matchdelete(a:match_id)
  catch /E803:/
  endtry
endfunction


function! s:add_highlight(result) abort
  if get(b:, 'assignments', []) == a:result.variables
    return
  endif
  let b:assignments = a:result.variables

  let pat = "'\\%>" . (a:result['start_of_line'] - 1) . "l.\\%<" . (a:result['end_of_line'] + 1) . "l[[:blank:]([{,=]\\zs\\<'.v:val.'\\ze\\>'"
  let vv = map(b:assignments, pat)
  let pat = join(vv, '\|')
  "python print vim.eval('pat')
  " matchadd() priority -1 means 'hlsearch' will override the match.
  let w:python_hl_lvar_match_id = matchadd(g:python_hl_lvar_hl_group, pat, -1)
endfunction


"let g:enable_python_hl_lvar

function! python_hl_lvar#hl_lvar() abort
  if !g:enable_python_hl_lvar
    return
  endif
  let l:l = line('.')
  let l:c = col('.')
  let range_pos = python_hl_lvar#funcpos()
  call cursor(l, c)
  let start_of_line = range_pos[1][1]
  let end_of_line = range_pos[2][1]
  if start_of_line == '' || end_of_line == ''
    return
  endif

  if exists('s:result')
    unlet s:result
  endif
  " returns b:result
  python << EOF
from sys import path
curd = vim.eval("g:python_hl_lvar_current_dir")
if curd not in path: path.insert(0, curd)
from python_hl_lvar import interface_for_vim
interface_for_vim(vim.eval("start_of_line"), vim.eval("end_of_line"))
EOF

  call python_hl_lvar#redraw({
        \ 'variables': s:result,
        \ 'start_of_line': start_of_line,
        \ 'end_of_line': end_of_line,
        \ })
endfunction


