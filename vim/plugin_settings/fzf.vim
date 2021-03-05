set rtp+=/usr/local/opt/fzf

" fzf実行時はステータスバーを非表示に
autocmd! FileType fzf set laststatus=0 noshowmode noruler
  \| autocmd BufLeave <buffer> set laststatus=2 showmode ruler

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

command! -bang -nargs=? -complete=dir Files
    \ call fzf#vim#files(<q-args>, {'options': [ '--preview', 'bat --color always {}']}, <bang>0)
command! -bang -nargs=? -complete=dir GFiles
    \ call fzf#vim#gitfiles(<q-args>, {'options': [ '--preview', 'bat --color always {}']}, <bang>0)
command! -bang Colors
  \ call fzf#vim#colors({'left': '15%', 'options': '--reverse --margin 30%,0'}, <bang>0)

" Git管理下ファイル検索
nmap <C-p> :GFiles<CR>
" カレントディレクトリ配下のファイル検索
nmap <Space>f :Files<CR>
" 以前開いたことのあるファイルを開く
nmap <SPACE>o :History<CR>
" コマンド履歴
nmap <SPACE>c :History:<CR>
" 検索単語履歴
nmap <SPACE>/ :History/<CR>
" Window移動
nmap <SPACE>w :Windows<CR>
" Map系(leaderがspaceだと普段の入力で待ち時間が発生してしまうため却下)
" nmap <SPACE><TAB> <plug>(fzf-maps-n)
" xmap <SPACE><TAB> <plug>(fzf-maps-x)
" imap <SPACE><TAB> <plug>(fzf-maps-i)
