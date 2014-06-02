
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


"let g:enable_python_hl_lvar

function! python_hl_lvar#hl_lvar()
  if !g:enable_python_hl_lvar
    return
  endif
  let range_pos = python_hl_lvar#funcpos()
  let funcdef = getline(range_pos[1][1], range_pos[2][1])
python << EOF
import sys
import ast
from itertools import takewhile

def extract_assignment(funcdef_lines):
    if not func_def_lines:
      return []
    tabspace = len(list(takewhile(lambda x: x == ' ', func_def_lines[0])))
    func_definition = '\n'.join([line[tabspace:] for line in func_def_lines])
    definition_node = ast.walk(ast.parse(func_definition, mode='single').body[0])
    next(definition_node)
    result = []
    result_add = result.extend
    for z in definition_node:
        if isinstance(z, ast.arguments):
            v = [getattr(a, 'id', None) for a in z.args]
            result_add(filter(bool, v))
        if isinstance(z, ast.Assign):
            v = [getattr(v, 'id', None) for v in z.targets]
            result_add(filter(bool, v))
    return result


try:
    func_def_lines = vim.eval('l:funcdef')
    assignments = extract_assignment(func_def_lines)
    cmd = 'let b:result = {0}'.format(repr(assignments))
    vim.command(cmd)
    #vim.command('let b:result = '.format(assignments))
except Exception as e:
    # TODO: debug part
    print e
    vim.command('let b:result = []')
EOF

  call python_hl_lvar#redraw(b:result)
endfunction


function! python_hl_lvar#redraw(variables) abort
  if exists('w:python_hl_lvar_match_id')
    call s:delete_highlight(w:python_hl_lvar_match_id)
  endif
  if a:variables != []
    call s:add_highlight(a:variables)
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


function! s:add_highlight(variables) abort
  if get(b:, 'assignments', []) == a:variables
    return
  endif
  let b:assignments = a:variables

  let vv = map(a:variables, "'[^.''\"]\\zs'.v:val.'\\ze[^''\"]'")
  let pat = join(vv, '\|')
  "python print vim.eval('pat')
  " lowest priority
  let w:python_hl_lvar_match_id = matchadd(g:python_hl_lvar_hl_group, pat, 0)
endfunction
