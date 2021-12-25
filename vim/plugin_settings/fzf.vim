" 実行ファイルのfzfではなくfzfのディレクトリの場所を指定する。
" これを指定しないとVimのPluginとしてfzfをいれなければならない、
" かつ、:Windowsなど様々なfzf.vimのコマンドが使用不可能になる。
set rtp+=/usr/local/opt/fzf
set rtp+=/opt/homebrew/opt/fzf

if exists('$TMUX')
  let g:fzf_layout = { 'tmux': '-p80%,80%' }
else
  let g:fzf_layout = { 'window': { 'width': 0.8, 'height': 0.8 } }
endif

" fzf実行時はステータスバーを非表示に
autocmd! FileType fzf set laststatus=0 noshowmode noruler
  \| autocmd BufLeave <buffer> set laststatus=2 showmode ruler

command! -bang -nargs=? -complete=dir Files
    \ call fzf#vim#files(<q-args>, {'options': [ '--preview', 'bat --color always {}']}, <bang>0)
command! -bang -nargs=? -complete=dir GFiles
    \ call fzf#vim#gitfiles(<q-args>, {'options': [ '--preview', 'bat --color always {}']}, <bang>0)
command! -bang Colors
  \ call fzf#vim#colors({'left': '15%', 'options': '--reverse --margin 30%,0'}, <bang>0)

" Git管理下ファイル検索
nmap <C-p> :GFiles<CR>
" ファイル内検索
nmap <C-f> :BLines<CR>
" カレントディレクトリ配下のファイル検索
nmap <Space>f :Files<CR>
" コマンド履歴
nmap <SPACE>c :History:<CR>
" 検索単語履歴
nmap <SPACE>/ :History/<CR>
" Window移動
nmap <SPACE>w :Windows<CR>
" バッファ全体から行を選択して挿入
imap <C-x><C-l> <Plug>(fzf-complete-line)
