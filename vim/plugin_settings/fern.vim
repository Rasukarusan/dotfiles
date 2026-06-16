UsePlugin 'fern.vim'
let g:fern#default_hidden=1
" 開いているファイルがcwd(git直下)配下なら全体表示、cwdの外ならそのファイルの階層を起点に開く
function! s:FernSmart() abort
  let l:file = expand('%:p')
  let l:cwd = getcwd()
  if l:file !=# '' && stridx(l:file, l:cwd . '/') != 0
    " cwdの外のファイル → ファイルの階層をルートにする
    execute 'Fern %:h -reveal=% -drawer -toggle -width=30'
  else
    " cwd配下 or 無名バッファ → git直下を起点に全体表示
    execute 'Fern . -reveal=% -drawer -toggle -width=30'
  endif
endfunction
nnoremap <C-n> :call <SID>FernSmart()<CR>
let g:fern#default_exclude = '.DS_Store'
augroup FernSettings
  autocmd!
  autocmd FileType fern set nonumber
  " この中で設定しないとデフォルトキーマップを上書きできない
  autocmd FileType fern nnoremap <buffer> R <Plug>(fern-action-reload:all)
  " - で一つ上の階層へ(ルートを親ディレクトリに移動)
  autocmd FileType fern nmap <buffer> - <Plug>(fern-action-leave)
augroup END
