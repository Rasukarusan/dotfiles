UsePlugin 'fern.vim'
let g:fern#default_hidden=1
nnoremap <C-n> :Fern . -reveal=% -drawer -toggle -width=30<CR>
augroup FernSettings
  autocmd!
  au FileType fern set nonumber
augroup END
