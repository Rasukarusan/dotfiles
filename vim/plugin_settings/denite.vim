autocmd FileType denite call s:denite_my_settings()
function! s:denite_my_settings() abort
    nnoremap <silent><buffer><expr> <CR>
    \ denite#do_map('do_action')
    nnoremap <silent><buffer><expr> p
    \ denite#do_map('do_action', 'preview')
    nnoremap <silent><buffer><expr> <C-t>
    \ denite#do_map('do_action','tabopen')
    nnoremap <silent><buffer><expr> q
    \ denite#do_map('quit')
    nnoremap <silent><buffer><expr> i
    \ denite#do_map('open_filter_buffer')
endfunction

" キーマップ
" noremap <Space>h :Denite command_history<CR>

" 候補表示の設定。Floating Window
" let s:denite_win_width_percent = 1.0
" let s:denite_win_height_percent = 0.5
" if has('nvim')
"     call denite#custom#option('default', {
"         \ 'split': 'floating',
"         \ 'winwidth': float2nr(&columns * s:denite_win_width_percent),
"         \ 'wincol': float2nr((&columns - (&columns * s:denite_win_width_percent))),
"         \ 'winheight': float2nr(&lines * s:denite_win_height_percent),
"         \ 'winrow': float2nr((&lines - (&lines * s:denite_win_height_percent)) * 2),
"         \ })
" endif
