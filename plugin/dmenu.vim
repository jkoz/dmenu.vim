" =============================================================================
" File:          autoload/dmenu.vim
" Description:   Fuzzy file, buffer, mru, tag, etc finder.
" Author:        Tai Tran
" Version:       1.0
" =============================================================================

let s:cpo_save = &cpo
set cpo&vim

" Utilities {{{
fu! s:shellesc(arg)
  retu '"'.substitute(a:arg, '"', '\\"', 'g').'"'
endf

fu! s:escape(path)
  retu substitute(a:path, ' ', '\\ ', 'g')
endf

fu! s:pushd(dict)
  if !empty(get(a:dict, 'dir', ''))
    let a:dict.prev_dir = getcwd()
    execute 'chdir '.s:escape(a:dict.dir)
  endif
endf

fu! s:popd(dict)
  if has_key(a:dict, 'prev_dir')
    execute 'chdir '.s:escape(remove(a:dict, 'prev_dir'))
  endif
endf
" }}}
" Execution {{{

fu! s:getexec()
  if !exists('s:exec')
    call system('type dmenu')
    if v:shell_error
      throw 'dmenu not found'
    else
      let s:exec = 'dmenu --smart'
    endif
    retu s:getexec()
  elseif empty(s:exec)
    unlet s:exec
    throw 'backend dmenu not found'
  else
    retu s:exec
  endif
endf

fu! dmenu#run(...) abort
  let dict   = exists('a:1') ? a:1 : {}
  let temps  = { 'result': tempname() }
  let optstr = get(dict, 'options', '')
  try
    let getexec = s:getexec()
  catch
    throw v:exception
  endtry

  if has_key(dict, 'source')
    let source = dict.source
    let type = type(source)
    if type == 1
      let prefix = source.'|'
    elseif type == 3
      let temps.input = tempname()
      call writefile(source, temps.input)
      let prefix = 'cat '.s:shellesc(temps.input).'|'
    else
      throw 'Invalid source type'
    endif
  else
    let prefix = ''
  endif
  let command = prefix.getexec.' '.optstr.' > '.temps.result

  retu s:execute(dict, command, temps)
endf


fu! s:execute(dict, command, temps)
  call s:pushd(a:dict)

  let command = a:command
  call substitute(system(command), '\n$', '', '')

  retu s:callback(a:dict, a:temps, 1)
endf


fu! s:callback(dict, temps, cd)
  if !filereadable(a:temps.result)
    let lines = []
  else
    if a:cd | call s:pushd(a:dict) | endif

    let lines = readfile(a:temps.result)
    if has_key(a:dict, 'sink')
      for line in lines
        if type(a:dict.sink) == 2
          call a:dict.sink(line)
        else
          execute a:dict.sink.' '.s:escape(line)
        endif
      endfor
    endif
  endif

  for tf in values(a:temps)
    silent! call delete(tf)
  endfor

  call s:popd(a:dict)

  retu lines
endf
" }}}

fu! s:cmd(bang, ...) abort
  let args = copy(a:000)
  let opts = {}
  if len(args) > 0 && isdirectory(expand(args[-1]))
    let opts.dir = remove(args, -1)
  endif
  if !a:bang
    let opts.tmux = get(g:, 'dmenu_tmux_height', s:default_tmux_height)
  endif
  call dmenu#run(extend({ 'sink': 'e', 'options': join(args) }, opts))
endf

command! -nargs=* -complete=dir -bang DMENU call s:cmd('<bang>' == '!', <f-args>)

let &cpo = s:cpo_save
unlet s:cpo_save

