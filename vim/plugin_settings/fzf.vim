set rtp+=/usr/local/opt/fzf

" 候補表示のwindow設定
if has('nvim')
    let g:fzf_layout = { 'window': 'call FloatingFZF()' }
endif
function! FloatingFZF()
    let buf = nvim_create_buf(v:false, v:true)
    let height = float2nr(&lines * 0.5)
    let width = float2nr(&columns * 1.0)
    let horizontal = float2nr((&columns - width) / 2)
    let vertical = float2nr((&columns - height) / 2)
    let opts = {
        \ 'relative': 'editor',
        \ 'row': vertical,
        \ 'col': horizontal,
        \ 'width': width,
        \ 'height': height
        \ }
    call nvim_open_win(buf, v:true, opts)
endfunction

" ファイル検索
nmap <C-p> :Files<CR>
" コマンド履歴
" nmap <C-h> :History:<CR>
" 検索単語履歴
" nmap <C-h>w :History/<CR>
