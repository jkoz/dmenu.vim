" =============================================================================
" File:          autoload/dmenu.vim
" Description:   Fuzzy file, buffer, mru, tag, etc finder.
" Author:        Tai Tran
" Version:       1.0
" =============================================================================

let loaded_dmenu=1
let s:cpo_save = &cpo
se cpo&vim

" Script variables {{{
let s:dmenu_default_backend = 'dmenu'
let s:debug = 1
let s:debug_file = '/tmp/dmenudebug.log'
let s:dmenu_default_launcher = 'st -c Fzf -e sh -c'
" }}}

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
fu! s:shellesc(arg) " {{{
  retu '"'.substitute(a:arg, '"', '\\"', 'g').'"'
endf " }}}
fu! s:escape(path) " {{{
  retu substitute(a:path, ' ', '\\ ', 'g')
endf "}}}
fu! dmenu#startdebug() abort "{{{
  exe 'redir! > ' . s:debug_file
  redi END
  let s:debug = 1
endf " }}}
fu! dmenu#run(...) abort " {{{
  let dict   = exists('a:1') ? a:1 : {}
  let ret = { 'result': tempname() }
  let optstr = get(dict, 'options', '')

  if has_key(dict, 'handler')
    cal dict.handler(line)
  en

  if has_key(dict, 'source')
    let data = dict.source
    let type = type(data)

    if type == 1 " string
      let prefix = data.'|'
    elsei type == 3 " list
      let ret.input = tempname()
      cal writefile(data, ret.input)
      let prefix = 'cat '.s:shellesc(ret.input).'|'
    el
      throw 'Invalid source type'
    en
  el
    let prefix = ''
  en

  " backend
  if has_key(dict, 'backend')
    let texec = dict.backend
  el
    let texec = get(g:, 'dmenu_backend', s:dmenu_default_backend)
  en

  let launcher = get(g:,'dmenu_launcher', s:dmenu_default_launcher)
  cal substitute(system(launcher.' '.prefix.texec.' '.optstr.' > '.ret.result.''), '\n$', '', '')

  if !filereadable(ret.result)
    let lines = []
  el
    let lines = readfile(ret.result)
    if has_key(dict, 'sink')
      for line in lines
        cal s:debug(line)
        if type(dict.sink) == 2 "function
          cal dict.sink(line)
        el
          exe dict.sink.' '.s:escape(line)
        en
      endfo
    en
  en

  for tmp in values(ret) | sil! cal delete(tmp) | endfo

  retu lines
endf " }}}

" Dmenu {{{
fu! dmenu#Dmenu(...) abort " {{{
  let f = len(a:000) > 0 ? join(copy(a:000)) : '.'
  cal dmenu#run({'sink': 'e', 'backend': 'dm find ' . f })
endf " }}}
" }}}
" DmenuFM {{{
fu! dmenu#DmenuFM(...) abort " {{{
  let f = len(a:000) > 0 ? join(copy(a:000)) : '.'
  cal dmenu#run({'sink': 'e', 'backend': 'dm recursive ' . f})
endf " }}}
" }}}
" DmenuBufTag {{{
fu! dmenu#buftagopen(line) "{{{
  cal cursor(split(a:line, '  ')[0] + 1, 1)
endf "}}}
fu! dmenu#buftaglist() " {{{
  retu map(getbufline(bufname("__Tagbar__"), 1, "$"), 'v:key."  ".v:val')
endf "}}}
fu! dmenu#DmenuBufTag() "{{{
  cal tagbar#OpenWindow('fjc')
  cal tagbar#SetFoldLevel(99, 1)
  cal dmenu#run({'sink': function('dmenu#buftagopen'), 'source': dmenu#buftaglist()})
  cal feedkeys("\<CR>")
endf "}}}
"}}}
" DmenuLines {{{
fu! dmenu#lineopen(line) "{{{
  cal cursor(split(a:line, '  ')[0] + 1, 1)
endf "}}}
fu! dmenu#linelist() " {{{
  retu map(getbufline(bufname("%"), 1, "$"), 'v:key."  ".v:val')
endf "}}}
fu! dmenu#DmenuLines() "{{{
  cal dmenu#run({'source': dmenu#linelist(), 'sink': function('dmenu#lineopen')})
endf "}}}
"}}}
" DmenuMRU {{{
fu! dmenu#mrulist() " {{{
  sil exe ":rviminfo"
  retu filter(copy(v:oldfiles), '!empty(glob(v:val))')
endf " }}}
fu! dmenu#DmenuMRU() "{{{
  cal dmenu#run({'source': dmenu#mrulist(), 'sink' : 'e'})
endf "}}}
" }}}
" DmenuHistory {{{
fu! dmenu#historylist() " {{{
  redir => histstr | sil hist | redir END | retu reverse(map(split(histstr, '\n')[2:], 'substitute(v:val, ".*[0-9]*  ", "", "g")'))
endf "}}}
fu! dmenu#historyopen(line) " {{{
  cal histadd('cmd', a:line) | sil exe ':' . a:line
endf " }}}
fu! dmenu#DmenuHistory() " {{{
  cal dmenu#run({'source': dmenu#historylist(), 'sink': function('dmenu#historyopen')})
endf " }}}
" }}}
" DmenuBuffer {{{
fu! dmenu#buflist() "{{{
  redir => bufstr | sil ls | redir END
  let lst = split(bufstr, '\n')
  let lst1 = filter(copy(lst), 'v:val !~ "^  [1-9+] [%#]"') " remove current buffer and last modified buffer
  let lst2 = filter(copy(lst), 'v:val =~ "^  [1-9+] #"') " remove all expect last modified buffer
  retu lst2 + lst1 " put last modified buffer at the begining of the list
endf "}}}
fu! dmenu#bufopen(line) " {{{
  exe 'buffer '.matchstr(a:line, '^[ 0-9]*')
endf " }}}
fu! dmenu#DmenuBuffer() "{{{
  cal dmenu#run({'source': dmenu#buflist(),'sink': function('dmenu#bufopen')})
endf "}}}
" }}}

let &cpo = s:cpo_save
unlet s:cpo_save

