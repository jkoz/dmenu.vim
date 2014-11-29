" =============================================================================
" File:          autoload/dmenu.vim
" Description:   Fuzzy file, buffer, mru, tag, etc finder.
" Author:        Tai Tran
" Version:       1.0
" =============================================================================

if exists('loaded_dmenu') | finish | en

comm! DmenuDebug cal dmenu#startdebug()


comm! -nargs=* -complete=dir Dmenu   cal dmenu#Dmenu(<f-args>)
comm! -nargs=* -complete=dir DmenuFM cal dmenu#DmenuFM(<f-args>)

comm! DmenuBufTag  cal dmenu#DmenuBufTag()
comm! DmenuMRU     cal dmenu#DmenuMRU()
comm! DmenuHistory cal dmenu#DmenuHistory()
comm! DmenuBuffer  cal dmenu#DmenuBuffer()

nn <silent> <c-p>     :Dmenu<CR>
nn <silent> <leader>f :DmenuFM<CR>
nn <silent> <Leader>z :DmenuBuffer<CR>
nn <silent> <Leader>m :DmenuMRU<CR>
nn <silent> <Leader>o :DmenuBufTag<CR>
nn <silent> <Leader>q :DmenuHistory<CR>
