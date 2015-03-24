" =============================================================================
" File:          autoload/dmenu.vim
" Description:   Fuzzy file, buffer, mru, tag, etc finder.
" Author:        Tai Tran
" Version:       1.0
" =============================================================================

let loaded_dmenu=1
let s:cpo_save = &cpo
se cpo&vim

" Debug {{{
let s:debug = 1
let s:debug_file = '/tmp/dmenudebug.log'
" s:gettime {{{
if has('reltime')
    fu! s:gettime() abort
        let time = split(reltimestr(reltime()), '\.')
        return strftime('%Y-%m-%d %H:%M:%S.', time[0]) . time[1]
    endf
el
    fu! s:gettime() abort
        return strftime('%Y-%m-%d %H:%M:%S')
    endf
endif " }}}
fu! s:debug(msg) abort " {{{
  if s:debug
    exe 'redir >> ' . s:debug_file
    sil echon s:gettime() . ': ' . a:msg . "\n"
    redi END
  en
endf " }}}
fu! dmenu#startdebug() abort "{{{
  exe 'redir! > ' . s:debug_file
  redi END
  let s:debug = 1
endf " }}}
" }}}

" {{{ Run
fu! dmenu#run(...) abort
  let context   = exists('a:1') ? a:1 : {}
  let choice = { 'result': tempname() }
  let optstr = get(context, 'options', '--reverse')

  if has_key(context, 'source')
    let data = context.source
    let type = type(data)
    if type == 1 " string
      let prefix = data.'|'
    elsei type == 3 " list
      let choice.input = tempname()
      cal writefile(data, choice.input)
      let prefix = 'cat "'.substitute(choice.input, '"', '\\"', 'g').'" | '
    el
      throw 'Invalid source type'
    en
  el
    let prefix = ''
  en

  let cmd = prefix.get(context, 'backend', g:dmenu_backend).' '.optstr.' > '.choice.result
  if exists('g:dmenu_launcher') && !empty(g:dmenu_launcher)
    cal system(g:dmenu_launcher.' "'.cmd.'"')
  el
    cal system(cmd)
  en


  if !filereadable(choice.result)
    let lines = []
  el
    let lines = readfile(choice.result)
    if has_key(context, 'handler')
      for line in lines
        cal s:debug(line)
        if type(context.handler) == 2 "function
          cal context.handler(line)
        el
          exe context.handler.' '.substitute(line, ' ', '\\ ', 'g')
        en
      endfo
    en
  en

  for tmp in values(choice) | sil! cal delete(tmp) | endfo

  retu lines
endf

" }}}

" Dmenu {{{

fu! dmenu#Dmenu(...) abort
  cal dmenu#run({
  \ 'handler': 'e',
  \ 'backend': 'dm find '.(len(a:000) > 0 ? join(copy(a:000)) : '.')
  \ })
endf

" }}}

" DmenuFM {{{

fu! dmenu#DmenuFM(...) abort
  cal dmenu#run({
  \ 'handler': 'e',
  \ 'backend': 'dm recursive '.(len(a:000) > 0 ? join(copy(a:000)) : '.')
  \ })
endf

" }}}

" DmenuBufTag {{{

fu! dmenu#buftagopen(line)
  cal cursor(split(a:line, '  ')[0] + 1, 1)
endf

fu! dmenu#DmenuBufTag() "{{{
  cal tagbar#OpenWindow('fjc')
  cal tagbar#SetFoldLevel(99, 1)

  cal dmenu#run({
  \ 'handler': function('dmenu#buftagopen'),
  \ 'source': map(getbufline(bufname("__Tagbar__"), 1, "$"), 'v:key."  ".v:val')
  \ })

  cal feedkeys("\<CR>")
endf "}}}
"}}}

" DmenuLines {{{

fu! dmenu#lineopen(line)
  cal cursor(split(a:line, '  ')[0] + 1, 1)
endf

fu! dmenu#DmenuLines()
  cal dmenu#run({
  \ 'source': map(getbufline(bufname("%"), 1, "$"), 'v:key."  ".v:val'),
  \ 'handler': function('dmenu#lineopen')
  \ })
endf

"}}}

" DmenuMRU {{{

fu! dmenu#DmenuMRU()
  cal dmenu#run({
  \ 'source': filter(copy(v:oldfiles), '!empty(glob(v:val))'),
  \ 'handler' : 'e'
  \ })
endf

" }}}

" DmenuHistory {{{

fu! dmenu#historylist()
  redir => histstr | sil hist | redir END | retu reverse(map(split(histstr, '\n')[2:], 'substitute(v:val, ".*[0-9]*  ", "", "g")'))
endf

fu! dmenu#historyopen(line)
  cal histadd('cmd', a:line) | sil exe ':' . a:line
endf

fu! dmenu#DmenuHistory()
  cal dmenu#run({
  \ 'source': dmenu#historylist(),
  \ 'handler': function('dmenu#historyopen')
  \ })
endf

" }}}

" DmenuBuffer {{{

fu! dmenu#buflist()
  redir => bufstr | sil ls | redir END
  let lst = split(bufstr, '\n')
  let lst1 = filter(copy(lst), 'v:val !~ "^  [1-9+] [%#]"') " remove current buffer and last modified buffer
  let lst2 = filter(copy(lst), 'v:val =~ "^  [1-9+] #"') " remove all expect last modified buffer
  retu lst2 + lst1 " put last modified buffer at the begining of the list
endf

fu! dmenu#bufopen(line)
  exe 'buffer '.matchstr(a:line, '^[ 0-9]*')
endf

fu! dmenu#DmenuBuffer()
  cal dmenu#run({'source': dmenu#buflist(),'handler': function('dmenu#bufopen')})
endf

" }}}

let &cpo = s:cpo_save
unlet s:cpo_save

