" ========================================
"         有効化するサイトの設定
" ========================================
let g:firenvim_config = {
    \ 'localSettings': {
        \ '.*': {
            \ 'selector': '',
            \ 'priority': 0,
        \ },
        \ 'github\.com': {
            \ 'selector': 'textarea',
            \ 'priority': 1,
        \ },
        \ 'kcw\.kddi\.ne\.jp': {
            \ 'selector': 'textarea',
            \ 'priority': 0,
        \ },
    \ }
\ }

" ========================================
"        フォントの設定
" ========================================
let g:firenvim_font = 'Ricty-Regular'
function! Set_Font(font) abort
  execute 'set guifont=' . a:font . ':h8'
endfunction

" ========================================
"        サイト毎のfiletype指定
" ========================================
augroup Firenvim
  au BufEnter github.com_*.txt set filetype=markdown | call Set_Font(g:firenvim_font)
augroup END
