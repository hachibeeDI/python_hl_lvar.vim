
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
  if !exists("g:enable_python_hl_lvar")
    return
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
  vim.command('let result = "{0}"'.format(' '.join(assignments)))
except Exception as e:
  # TODO: debug part
  print e
EOF

  if result != ''
    call s:add_highlight(result)
  endif
endfunction


function! s:add_highlight(vars)
  "echo a:vars
  try
    syn clear pythonLocalVariables
  catch /E28/
    "E28: No such highlight group name: pythonLocalVariables
  endtry
  exe 'syn keyword pythonLocalVariables '.a:vars
  hi link pythonLocalVariables Special
endfunction
