UsePlugin 'fzf'
UsePlugin 'fzf.vim'
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

" ファイル検索中にctrl-eで、テスト系ファイルを除外するクエリを付け外しする。
" 既存のクエリの前に足すだけなので絞り込みの途中でも押せる。今の状態はヘッダに出す。
" 除外する語と文言はbin/fzf-exclude-toggleが持つ(シェルのvif/vip/vima系と共用)。
" fzfデフォルトのctrl-e(end-of-line)は上書きされる(行末移動はEndで可能)。
let s:fzf_file_options = [
    \ '--preview', 'bat --color always {}',
    \ '--bind', 'start:transform-header(fzf-exclude-toggle header ctrl-e)',
    \ '--bind', 'ctrl-e:transform-query(fzf-exclude-toggle query)'
    \           . '+transform-header(fzf-exclude-toggle header ctrl-e)',
    \ ]

command! -bang -nargs=? -complete=dir Files
    \ call fzf#vim#files(<q-args>, {'options': s:fzf_file_options}, <bang>0)
command! -bang -nargs=? -complete=dir GFiles
    \ call fzf#vim#gitfiles(<q-args>, {'options': s:fzf_file_options}, <bang>0)
command! -bang Colors
  \ call fzf#vim#colors({'left': '15%', 'options': '--reverse --margin 30%,0'}, <bang>0)

" Agコマンドをカスタマイズ（複数選択時にタブで開く）
function! s:ag_to_qf(lines)
  " 最初の行はキーバインド情報なのでスキップ
  let key = remove(a:lines, 0)
  " 開いたファイルを記録する辞書（重複防止用）
  let opened_files = {}
  " 各行をタブで開く（ファイル名:行番号の形式でパース）
  for line in a:lines
    let parts = matchlist(line, '^\([^:]*\):\(\d\+\):\(\d\+\):')
    if !empty(parts)
      let file = parts[1]
      let lnum = parts[2]
      let col = parts[3]
      " 同じファイルを複数回開かないようにチェック
      if !has_key(opened_files, file)
        execute 'tabedit +' . lnum . ' ' . fnameescape(file)
        let opened_files[file] = 1
      endif
    endif
  endfor
endfunction

" ctrl-eの除外トグルはFiles/GFilesと共用。ただしAgは1行が file:行:列:本文 で、
" fzfのクエリは行全体に効くため、本文に test/spec/medium を含む行も一緒に隠れる。
command! -bang -nargs=* Ag
  \ call fzf#vim#ag(<q-args>,
  \   fzf#vim#with_preview({
  \     'sink*': function('s:ag_to_qf'),
  \     'options': ['--multi', '--bind', 'ctrl-a:select-all',
  \                 '--bind', 'start:transform-header(fzf-exclude-toggle header ctrl-e)',
  \                 '--bind', 'ctrl-e:transform-query(fzf-exclude-toggle query)'
  \                           . '+transform-header(fzf-exclude-toggle header ctrl-e)']
  \   }), <bang>0)

" Git管理下ファイル検索
nmap <C-p> :GFiles<CR>
" 全ファイル検索
nmap <C-f> :Files<CR>
" ファイル内検索
nmap <Space>f :BLines<CR>
" コマンド履歴
nmap <SPACE>c :History:<CR>
" 検索単語履歴
nmap <SPACE>/ :History/<CR>
" Window移動
nmap <SPACE>w :Windows<CR>
" バッファ全体から行を選択して挿入
imap <C-x><C-l> <Plug>(fzf-complete-line)
