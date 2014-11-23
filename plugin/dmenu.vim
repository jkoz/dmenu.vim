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
    exe 'chdir '.s:escape(a:dict.dir)
  endif
endf

fu! s:popd(dict)
  if has_key(a:dict, 'prev_dir')
    exe 'chdir '.s:escape(remove(a:dict, 'prev_dir'))
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
    let texec = s:getexec()
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
  let command = prefix.texec.' '.optstr.' > '.temps.result
  "call system("echo '".command."' > /tmp/vim-test")

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
          exe a:dict.sink.' '.s:escape(line)
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
" Dmenu {{{
fu! s:findlist()
  return split(system("find * ! -path \"*/\.*\" -type f "), '\n')
endf
comm! -nargs=* -complete=dir -bang  Dmenu call dmenu#run({'source':s:findlist(), 'sink': 'e'})
nn <silent> <c-p> :Dmenu<CR>
"}}}
" DmenuFM {{{
fu! s:dirlist()
  return split(system("find * ! -path \"*/\.*\" -type f "), '\n')
endf
comm! -nargs=* -complete=dir -bang DmenuFM call dmenu#run({'source':s:dirlist(), 'sink': 'e'})
nn <silent> <leader>f :DmenuFM<CR>
"}}}
"DmenuBuffer {{{
fu! s:buflist()
  redir => ls
  silent ls
  redir END
  return split(ls, '\n')
endf

fu! s:bufopen(line)
  exe 'buffer '.matchstr(a:line, '^[ 0-9]*')
endf

comm! DmenuBuffer call dmenu#run({'source':reverse(s:buflist()),'sink':function('s:bufopen')})
nn <silent> <Leader>z :DmenuBuffer<CR>
"}}}
" DmenuMRU {{{
comm! DmenuMRU call dmenu#run({'source':v:oldfiles, 'sink' : 'e ','options' : '-p MRU:'})
nn <silent> <Leader>m :DmenuMRU<CR>
" }}}
" DmenuBufTag {{{
fu! s:buftaglist()
  let ret= system("ctags -f - --sort=no --excmd=pattern --fields=nKs '" . expand("%")."' | awk 'sub(/line/,\"\") {print $1  $NF}'")
  retu split(ret, '\n')
endf

fu! s:buftagopen(line)
  cal cursor(system("echo '".a:line."' | awk -F ':' '{print $NF}'"), 1)
endf

comm! DmenuBufTag call dmenu#run({'source':s:buftaglist(), 'sink' :function('s:buftagopen'),'options' : '-p Ctags:',})
nn <silent> <Leader>o :DmenuBufTag<CR>
" }}}
" DmenuHistory {{{
fu! s:historylist()
  let l:num = histnr('cmd')
  let l:line = histget('cmd', l:num)
  let l:lines = []
  while l:num >= 1
    if l:line != ''
      call add(l:lines, l:line)
    endif
    let l:num = l:num-1
    let l:line = histget('cmd', l:num)
  endwhile
  return l:lines
endf
fu! s:historyopen(line)
  call histadd('cmd', a:line)
  silent exe ':' . a:line
endf
comm! DmenuHistory call dmenu#run({'source':s:historylist(), 'sink' :function('s:historyopen'),'options' : '-p History:',})
nn <silent> <Leader>q :DmenuHistory<CR>
" }}}

let &cpo = s:cpo_save
unlet s:cpo_save

