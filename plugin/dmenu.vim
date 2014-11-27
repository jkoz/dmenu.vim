" =============================================================================
" File:          autoload/dmenu.vim
" Description:   Fuzzy file, buffer, mru, tag, etc finder.
" Author:        Tai Tran
" Version:       1.0
" =============================================================================

if exists('loaded_dmenu') | finish | en

comm! DmenuDebug cal dmenu#startdebug()

comm! -nargs=* -complete=dir -bang  Dmenu cal dmenu#run({'sink': 'e', 'backend': 'dmenu --reverse --smart  find'})
comm! -nargs=* -complete=dir -bang DmenuFM cal dmenu#run({'sink': 'e', 'backend': 'dmenu --reverse --smart  recursive'})
comm! DmenuMRU     cal dmenu#run({'source': dmenu#mrulist(), 'sink' : 'e','options' : '-p MRU:'})
comm! DmenuBufTag  cal dmenu#run({'sink': function('dmenu#buftagopen'), 'backend': 'dmenu --reverse --smart tags ' . expand("%")})
comm! DmenuHistory cal dmenu#run({'source': dmenu#historylist(), 'sink': function('dmenu#historyopen'),'options' : '-p History:'})
comm! DmenuBuffer cal dmenu#run({'source': dmenu#buflist(),'sink': function('dmenu#bufopen')})

nn <silent> <c-p> :Dmenu<CR>
nn <silent> <leader>f :DmenuFM<CR>
nn <silent> <Leader>z :DmenuBuffer<CR>
nn <silent> <Leader>m :DmenuMRU<CR>
nn <silent> <Leader>o :DmenuBufTag<CR>
nn <silent> <Leader>q :DmenuHistory<CR>
