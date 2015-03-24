" =============================================================================
" File:          autoload/dmenu.vim
" Description:   Fuzzy file, buffer, mru, tag, etc finder.
" Author:        Tai Tran
" Version:       1.0
" =============================================================================

if exists('loaded_dmenu') | finish | en

com! DmenuDebug cal dmenu#startdebug()


com! -nargs=* -complete=dir Dmenu   cal dmenu#Dmenu(<f-args>)
com! -nargs=* -complete=dir DmenuFM cal dmenu#DmenuFM(<f-args>)

com! DmenuBufTag  cal dmenu#DmenuBufTag()
com! DmenuMRU     cal dmenu#DmenuMRU()
com! DmenuHistory cal dmenu#DmenuHistory()
com! DmenuBuffer  cal dmenu#DmenuBuffer()
com! DmenuLines cal dmenu#DmenuLines()
com! DmenuMarks cal dmenu#DmenuMarks()
