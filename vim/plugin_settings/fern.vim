UsePlugin 'fern.vim'
let g:fern#default_hidden=1
nnoremap <C-n> :Fern . -reveal=% -drawer -toggle -width=30<CR>
let g:fern#default_exclude = '.DS_Store'
augroup FernSettings
  autocmd!
  autocmd FileType fern set nonumber
  " この中で設定しないとデフォルトキーマップを上書きできない
  autocmd FileType fern nnoremap <buffer> R <Plug>(fern-action-reload:all)
augroup END
