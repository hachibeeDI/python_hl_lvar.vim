if !has('python')
  echoerr "python_hl_lvar: This plugin does not work without has('python')"
  finish
endif

command! PyHlLVar call python_hl_lvar#hl_lvar()
