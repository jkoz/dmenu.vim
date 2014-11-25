" =============================================================================
" File:          autoload/dmenu.vim
" Description:   Fuzzy file, buffer, mru, tag, etc finder.
" Author:        Tai Tran
" Version:       1.0
" =============================================================================

if exists('loaded_dmenu') | finish | en

let loaded_dmenu=1

let s:cpo_save = &cpo
se cpo&vim

let s:dmenu_default_backend = 'dmenu --smart'

" Main {{{
" shellesc {{{
fu! s:shellesc(arg) 
  retu '"'.substitute(a:arg, '"', '\\"', 'g').'"'
endf " }}}

fu! s:escape(path)
  retu substitute(a:path, ' ', '\\ ', 'g')
endf

fu! dmenu#run(...) abort
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

  cal substitute(system(prefix.texec.' '.optstr.' > '.ret.result), '\n$', '', '')

  if !filereadable(ret.result)
    let lines = []
  el
    let lines = readfile(ret.result)
    if has_key(dict, 'sink')
      for line in lines
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
endf
" }}}
" Extensions {{{
" Dmenu {{{
comm! -nargs=* -complete=dir -bang  Dmenu cal dmenu#run({'sink': 'e', 'backend': 'dmenu --smart  find'})
nn <silent> <c-p> :Dmenu<CR>
"}}}
" DmenuFM {{{
comm! -nargs=* -complete=dir -bang DmenuFM cal dmenu#run({'sink': 'e', 'backend': 'dmenu --smart  recursive'})
nn <silent> <leader>f :DmenuFM<CR>
"}}}
"DmenuBuffer {{{
fu! s:buflist()
  redir => ls
  sil ls
  redir END
  retu split(ls, '\n')
endf
fu! s:bufopen(line)
  exe 'buffer '.matchstr(a:line, '^[ 0-9]*')
endf

comm! DmenuBuffer cal dmenu#run({'source':s:buflist(),'sink': function('s:bufopen')})
nn <silent> <Leader>z :DmenuBuffer<CR>
"}}}
" DmenuMRU {{{
fu! s:mrulist()
  sil exe ":rviminfo!"
  let retl = copy(v:oldfiles)
  let regrexes = substitute(&wig, "*", "\.*", "g")
  let reglist = split(regrexes, ',') + map(split(&rtp, ','), 'v:val . "\.*"')
  for regrex in reglist | cal filter(retl, 'v:val !~# regrex') | endfo
  retu retl
endf
comm! DmenuMRU cal dmenu#run({'source': s:mrulist(), 'sink' : 'e','options' : '-p MRU:'})
nn <silent> <Leader>m :DmenuMRU<CR>
" }}}
" DmenuBufTag {{{
fu! s:buftagopen(line)
  cal cursor(system("echo '".a:line."' | awk -F ':' '{print $NF}'"), 1)
endf

comm! DmenuBufTag cal dmenu#run({'sink' :function('s:buftagopen'), 'backend': 'dmenu --smart  tags ' . expand("%")})
nn <silent> <Leader>o :DmenuBufTag<CR>
" }}}
" DmenuHistory {{{
fu! s:historylist()
  let l:num = histnr('cmd')
  let l:line = histget('cmd', l:num)
  let l:lines = []
  while l:num >= 1
    if l:line != ''
      cal add(l:lines, l:line)
    en
    let l:num = l:num-1
    let l:line = histget('cmd', l:num)
  endwhile
  retu l:lines
endf
fu! s:historyopen(line)
  cal histadd('cmd', a:line)
  sil exe ':' . a:line
endf
comm! DmenuHistory cal dmenu#run({'source':s:historylist(), 'sink' :function('s:historyopen'),'options' : '-p History:',})
nn <silent> <Leader>q :DmenuHistory<CR>
" }}}
"}}}

let &cpo = s:cpo_save
unlet s:cpo_save

