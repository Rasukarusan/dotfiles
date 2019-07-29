" pythonのバージョンが3.7の時に出るエラーを表示しないようにする
" @See https://github.com/vim/vim/issues/3117
if has('python3')
  silent! python3 1
endif
if &compatible
  set nocompatible
endif
set runtimepath+=$HOME/.vim/dein/repos/github.com/Shougo/dein.vim

call dein#begin(expand($HOME.'/.vim/dein'))
    call dein#add('Shougo/dein.vim')
    call dein#add('roxma/vim-hug-neovim-rpc')
    call dein#add('roxma/nvim-yarp')
    call dein#add('Shougo/vimproc.vim', {'build': 'make'})
    call dein#add('Shougo/unite.vim')
    call dein#add('Shougo/neosnippet.vim')
    call dein#add('Shougo/neosnippet-snippets')
    call dein#add('Shougo/neocomplcache')
    call dein#add('scrooloose/nerdtree')
    call dein#add('jistr/vim-nerdtree-tabs')
    call dein#add('vim-scripts/PDV--phpdocumentor-for-vim')
    call dein#add('airblade/vim-gitgutter') " git管理下の場合行番号の横に差分記号を表示
    call dein#add('tomtom/tcomment_vim') " ctrl+-でコメントアウト
    call dein#add('tpope/vim-fugitive') " :Gstatusなどでvimにいながらgitコマンドが打てる
    call dein#add('vim-airline/vim-airline') " ステータスラインを表示
    call dein#add('rking/ag.vim')
    call dein#add('Shougo/vimproc')  " unite.vimで必要
    call dein#add('thinca/vim-quickrun') " shファイル等をその場で実行
    call dein#add('vim-jp/vimdoc-ja') " helpを:hで日本語で表示
    call dein#add('tpope/vim-surround') " シングルクオートとダブルクオートの入れ替え等
    call dein#add('junegunn/fzf.vim') "fzfでファイル検索
    call dein#add('jsfaint/gen_tags.vim') "gtags,ctagsを自動生成
    call dein#add('mattn/emmet-vim') " Emmnet
    call dein#add('Shougo/denite.nvim')
    call dein#add('ozelentok/denite-gtags')
    call dein#add('pocari/vim-denite-command-history') " コマンドの履歴を表示
    call dein#add('w0rp/ale') "リアルタイムLinter
    call dein#add('joonty/vdebug') " Vdebug
    call dein#add('kana/vim-submode') " 画面分割時の画面大きさ変更キーなど連続で打つコマンドを楽にする
    " call dein#add('mhinz/vim-startify') " vim起動時にバッファを表示する
    call dein#add('fatih/vim-go') "go開発環境
    call dein#add('Lokaltog/vim-easymotion') "vimnium
    call dein#add('junegunn/vim-easy-align') "好きな文字でインデントを揃える
call dein#end()
if dein#check_install()
  call dein#install()
endif

" ===============グローバル設定関連===================== "
" 別ファイルのviの設定を読み込む
runtime! myautoload/*.vim
" cmd+vでペーストしても勝手にインデントしない
if &term =~ "xterm"
    let &t_ti .= "\e[?2004h"
    let &t_te .= "\e[?2004l"
    let &pastetoggle = "\e[201~"
    function XTermPasteBegin(ret)
        set paste
        return a:ret
    endfunction
    noremap <special> <expr> <Esc>[200~ XTermPasteBegin("0i")
    inoremap <special> <expr> <Esc>[200~ XTermPasteBegin("")
    cnoremap <special> <Esc>[200~ <nop>
    cnoremap <special> <Esc>[201~ <nop>
endif
" マウスを有効に。クリックでカーソル移動もOK。
if has('mouse')
    set mouse=a
    if has('mouse_sgr')
        set ttymouse=sgr
    elseif v:version > 703 || v:version is 703 && has('patch632')
        set ttymouse=sgr
    else
        set ttymouse=xterm2
    endif
endif

" ============================== "
"           denite               "
" ============================== "
call denite#custom#option('default', 'prompt', '>')
" denite/insert モードのときは，C- で移動できるようにする
call denite#custom#map('insert', "<C-j>", '<denite:move_to_next_line>')
call denite#custom#map('insert', "<C-k>", '<denite:move_to_previous_line>')
" tabopen や vsplit のキーバインドを割り当て
call denite#custom#map('insert', "<C-t>", '<denite:do_action:tabopen>')
call denite#custom#map('insert', "<C-v>", '<denite:do_action:vsplit>')
call denite#custom#map('normal', "v", '<denite:do_action:vsplit>')
" jj で denite/insert を抜けるようにする
call denite#custom#map('insert', 'jj', '<denite:enter_mode:normal>')
" deniteでagを使う
if executable('ag')
  call denite#custom#var('file_rec', 'command',
        \ ['ag', '--files', '--glob', '!.git'])
  call denite#custom#var('grep', 'command', ['ag'])
endif

" ============================== "
"           unite                "
" ============================== "
" insert modeで開始しない
let g:unite_enable_start_insert = 0
" 大文字小文字を区別しない
let g:unite_enable_ignore_case = 1
let g:unite_enable_smart_case = 1
" unite grep に ag(The Silver Searcher) を使う
if executable('ag')
  let g:unite_source_grep_command = 'ag'
  let g:unite_source_grep_default_opts = '--nogroup --nocolor --column'
  let g:unite_source_grep_recursive_opt = ''
endif

" ============================== "
"           vim-easy-align       "
" ============================== "
xmap ga <Plug>(EasyAlign)
nmap ga <Plug>(EasyAlign)

" ============================== "
"           vim-airline          "
" ============================== "
" @See: https://original-game.com/vim-airline/
let g:airline#extensions#default#layout = [
    \ [ 'a', 'b', 'c'],
    \ [ 'x', 'y']
    \ ]

" ============================== "
"           emmet-vim            "
" ============================== "
" let g:user_emmet_leader_key = ','

" ============================== "
"           linter               "
" ============================== "
" @See :help ale-highlights
let g:ale_set_highlights = 0

" ============================== "
"           vim-submode          "
" ============================== "
call submode#enter_with('bufmove', 'n', '', 's>', '<C-w>>')
call submode#enter_with('bufmove', 'n', '', 's<', '<C-w><')
call submode#enter_with('bufmove', 'n', '', 's+', '<C-w>+')
call submode#enter_with('bufmove', 'n', '', 's-', '<C-w>-')
call submode#map('bufmove', 'n', '', '>', '<C-w>>')
call submode#map('bufmove', 'n', '', '<', '<C-w><')
call submode#map('bufmove', 'n', '', '+', '<C-w>+')
call submode#map('bufmove', 'n', '', '-', '<C-w>-')

" ============================== "
"           vim-go               "
" ============================== "
filetype plugin indent on " これがないと「エディタのコマンドではありません」と出る
let g:go_highlight_functions = 1
let g:go_highlight_methods = 1
let g:go_highlight_structs = 1
let g:go_gocode_unimported_packages = 1
let g:go_fmt_command = "goimports" " 保存時にimport
nnoremap gd :GoDef

" ============================== "
"          easy-motion           "
" ============================== "
let g:EasyMotion_do_mapping = 0 "Disable default mappings
nmap F <Plug>(easymotion-s2)


" ============================== "
"           quickrun             "
" ============================== "
" \rで保存して実行、画面分割を下に出す
nnoremap \r :cclose<CR>:write<CR>:QuickRun -mode n<CR>
xnoremap \r :<C-U>cclose<CR>:write<CR>gv:QuickRun -mode v<CR>
let g:quickrun_config={'*': {'split': ''}}
set splitbelow

" markdown内のコードシンタックスハイライト
let g:markdown_fenced_languages = [
    \ 'zsh',
    \ 'go',
    \ 'vim',
    \ 'php',
    \ 'javascript',
    \ 'js=javascript',
    \ 'json=javascript',
    \ 'c',
    \ 'php',
    \ 'xml',
    \ 'erb=eruby',
    \ 'ruby',
    \ 'sql',
    \ 'html'
    \]

" ============================== "
"           Vdebug               "
" ============================== "
let g:vdebug_options= {
\    "port" : 9001,
\    "timeout" : 20,
\    "on_close" : 'detach',
\    "break_on_open" : 0,
\    "remote_path" : "",
\    "local_path" : "",
\    "debug_window_level" : 0,
\    "debug_file_level" : 0,
\    "debug_file" : "",
\    "window_arrangement" : ["DebuggerWatch", "DebuggerStack"]
\}
let g:vdebug_keymap = {
\    "run" : "<F5>",
\    "run_to_cursor" : "<F9>",
\    "step_over" : "<F2>",
\    "step_into" : "<F3>",
\    "step_out" : "<F4>",
\    "close" : "<F6>",
\    "detach" : "<F7>",
\    "set_breakpoint" : "<F10>",
\    "get_context" : "<F11>",
\    "eval_under_cursor" : "<F12>",
\    "eval_visual" : "<Leader>e"
\}

" 起動時の画面をスキップ(:introで表示可能)
set shortmess+=I
" シンタックスハイライト
syntax on
set t_Co=256
colorscheme jellybeans
" 自動でインデントを挿入
set autoindent
" 全角記号がずれるのを回避
set ambiwidth=double
" タブをスペースに変換
set expandtab
set tabstop=4
set shiftwidth=4
set softtabstop=0
" goのタブ設定
" au BufNewFile,BufRead *.go set noexpandtab tabstop=4 shiftwidth=4
" 履歴件数
set history=1000
" jsonやmarkdownでダブルクォート、*が消えるのを回避
set conceallevel=0
" 検索語句のハイライト
set hlsearch
" カーソル行をハイライト。これをONにするとvimが重くなるのでコメントアウトした。
" set cursorline
set number
" 括弧の後に自動でインデントを挿入
set cindent
" 検索時に大文字小文字無視
set ignorecase
" 検索語句を全て英小文字で入力した場合のみ区別を無視
set smartcase
" バックアップを作成しない
set nobackup
" swpファイルを作成しない
set noswapfile
" swpファイルのパス
set directory=~/.vim/swp
" クリップボード共有(vim --version | grep clipboard で+clipboardとなっていないと使えない。-clipbordになってると無理)
set clipboard=unnamed
" 不可視文字表示
set list
" Gitで何も変更がないのにdiffが出てしまうのを回避。(No newline at end of file対策。set binary noeol だと改行時のインデントがタブになってしまうためnofixeolにした)
set nofixeol
" タブを >--- 半スペを . で表示する
set listchars=tab:»-,trail:･
" 保存時に行末の空白を削除(空行のdiffが出てしまうのでコメントアウト)
" autocmd BufWritePre * :%s/\s\+$//ge
" vimでバックスペースを有効に
set backspace=indent,eol,start
" 折りたたみ機能をOFFにする
set nofoldenable
" ビープ音をOFFにする
set belloff=all
" タブ自体の移動
function! MyTabMove(c)
  let current = tabpagenr()
  let max = tabpagenr('$')
  let target = a:c > 1       ? current + a:c - line('.') :
             \ a:c == 1      ? current :
             \ a:c == -1     ? current - 2 :
             \ a:c < -1      ? current + a:c + line('.') - 2 : 0
  let target = target >= max ? target % max :
             \ target < 0    ? target + max :
             \ target
  execute ':tabmove ' . target
endfunction
command! -count=1 MyTabMoveRight call MyTabMove(<count>)
command! -count=1 MyTabMoveLeft  call MyTabMove(-<count>)
" crontab: temp file must be edited in placeのエラー文が出るのでtmpではバックアップをしないよう設定
set backupskip=/tmp/*,/private/tmp/*
" ctags,gtagsの自動生成
let g:gen_tags#ctags_auto_gen = 1
let g:gen_tags#gtags_auto_gen = 1

" golをfzf形式で開く
" @see https://qiita.com/gorilla0513/items/4ea13f7b370482f68ea5
nnoremap <silent> <Space>l :belowright term ++close gol -f<cr>
" 現在行の末尾のスペースを削除
nnoremap <silent> rs :s/\s\+$//ge <CR> :noh <CR>
" 行末スペースを全て削除
command! RemoveSpace :%s/\s\+$//ge

" ===============キーマップ関連===================== "
" 入力モードでのカーソル移動
inoremap <C-j> <Down>
inoremap <C-k> <Up>
inoremap <C-h> <Left>
inoremap <C-l> <Right>
nnoremap <C-e> <Esc>$a
inoremap <C-e> <Esc>$a
nnoremap H 4h
nnoremap L 4l
nnoremap sa ^
nnoremap se $
vnoremap sa ^
vnoremap se $
nnoremap sl <C-w>l
nnoremap sh <C-w>h
nnoremap sj <C-w>j
nnoremap sk <C-w>k
"表示行単位で移動(snippet展開対策済み)
nnoremap j gj
onoremap j gj
xnoremap j gj
nnoremap k gk
onoremap k gk
xnoremap k gk
nnoremap <down> gj
nnoremap <up> gk
" jjでエスケープ
inoremap <silent> jj <ESC>
" 日本語入力で”っj”と入力してもEnterキーで確定させればインサートモードを抜ける
inoremap <silent> っj <ESC>
" 入力モード中:wqと打つとノーマルモードに戻って:wqになる
inoremap :wq <ESC>:wq
inoremap ：wq <ESC>:wq
inoremap :w <ESC>:w
inoremap :q <ESC>:q
" 閉じかっこをENTERと同時に挿入
inoremap {<Enter> {}<Left><CR><ESC><S-o>
inoremap [<Enter> []<Left><CR><ESC><S-o>
inoremap (<Enter> ()<Left><CR><ESC><S-o>
" NerdTree表示
nnoremap <C-n> :NERDTreeTabsToggle<CR>
" 削除した際ヤンクしないように
nnoremap x "_x
nnoremap _ci "_ci
nnoremap _cw "_cw
nnoremap _D "_D
nnoremap _dd "_dd
vnoremap _d "_d
" 現在ヤンクしているもので置き換える
nnoremap ri" di""0P
nnoremap ri' di'"0P
nnoremap ri( di("0P
nnoremap ri[ di["0P
nnoremap rit dit"0P
" Exモードの際単語移動をVimライクにする
cnoremap <C-h> <Left>
cnoremap <C-l> <Right>
" タブ移動のショートカット
nnoremap <C-l> <ESC>gt
nnoremap <C-h> <ESC>g<S-t>
" 画面分割時の移動のショートカット
nnoremap <C-k> <ESC><C-w>k
nnoremap <C-j> <ESC><C-w>j
" 現在のタブを右へ移動
nnoremap <Tab>n :MyTabMoveRight<CR>
" 現在のタブを左へ移動
nnoremap <Tab>p :MyTabMoveLeft<CR>
" Docコメントを挿入
nnoremap <C-P> :call PhpDocSingle()<CR><C-v><S-]>=
inoremap <C-P> <Esc>:call PhpDocSingle()<CR><S-v>}=
vnoremap <C-P> :call PhpDocSingle()<CR>
" pasteモード(,iでもペーストモードへ)
nnoremap ,i :<C-u>set paste<Return>i
" 補完候補が表示されている場合は確定。そうでない場合は改行
inoremap <expr><CR>  pumvisible() ? neocomplcache#close_popup() : "<CR>"
" ESCを二回押すことでハイライトを消す
nmap <silent> <Esc><Esc> :nohlsearch<CR>
" Yで末尾までコピー
nnoremap <S-y> <C-v>$y
" syで単語コピー
nnoremap sy byw
" インデントショートカット
nnoremap th <<
nnoremap tl >>

" =========neosnippet========= "
let g:neosnippet#snippets_directory=$HOME.'/.vim/dein/repos/github.com/Shougo/neosnippet-snippets/neosnippets,'.$HOME.'/.vim/mySnippets/'
imap <TAB>     <Plug>(neosnippet_expand_or_jump)
smap <TAB>     <Plug>(neosnippet_expand_or_jump)

" =========fzf========= "
" fzfの参照先(brew install fzfした先となる)
set rtp+=/usr/local/opt/fzf
" ファイル検索
nmap <C-p> :Files<CR>
nmap <C-g> :Rg<Space>
" コマンド履歴
" nmap <C-h> :History:<CR>
" 検索単語履歴
" nmap <C-h>w :History/<CR>
" Rgでプレビュー表示
command! -bang -nargs=* Rg
  \ call fzf#vim#grep(
  \   'rg --column --line-number --no-heading --color=always --smart-case '.shellescape(<q-args>), 1,
  \   <bang>0 ? fzf#vim#with_preview('up:60%')
  \           : fzf#vim#with_preview('right:50%:hidden', '?'),
  \   <bang>0)

" ========unite======== "
" grep検索
nnoremap <silent> ,g  :<C-u>Unite grep:. -buffer-name=search-buffer<CR>
" カーソル位置の単語をgrep検索
nnoremap <silent> ,cg :<C-u>Unite grep:. -buffer-name=search-buffer<CR><C-R><C-W>
" grep検索結果の再呼出
nnoremap <silent> ,r  :<C-u>UniteResume search-buffer<CR>
" バッファ一覧を表示
nnoremap <silent> ,b :<C-u>Unite buffer<CR>
" レジスタ一覧を表示
nnoremap <silent> ,y :<C-u>Unite -buffer-name=register register<CR>
" 現在開いているタブを表示
nnoremap <silent> ,t :<C-u>Unite tab<CR>

" ========Gtags======== "
" Quickfixで選択時tでタブで開く
" autocmd FileType qf nnoremap <buffer> t <C-W><Enter><C-W>T
" " 今のファイルの関数などの一覧
" nnoremap <silent> <Space>f :Gtags -f %<CR>
" " カーソル下の単語が含まれるタグの表示
" nnoremap <silent> <Space>j :GtagsCursor<CR>
" " カーソル下の単語の定義元を表示
" nnoremap <silent> <Space>d :<C-u>exe('Gtags '.expand('<cword>'))<CR>
" " カーソル下の単語の参照先を表示
" nnoremap <silent> <Space>r :<C-u>exe('Gtags -r '.expand('<cword>'))<CR>

" ========denite======== "
noremap <Space>h :Denite command_history<CR>
" ========denite-gtags======== "
noremap [denite-gtags]  <Nop>
nmap <Space> [denite-gtags]
" 今のファイルの関数などの一覧
nnoremap [denite-gtags]f :Denite -buffer-name=gtags_file -mode=normal -prompt=> gtags_file<CR>
" カーソル下の単語の定義元を表示
nnorema [denite-gtags]d :<C-u>DeniteCursorWord -buffer-name=gtags_def -mode=normal -prompt=> gtags_def<CR>
" カーソル下の単語の参照先を表示
nnoremap [denite-gtags]r :<C-u>DeniteCursorWord -buffer-name=gtags_ref -mode=normal -prompt=> gtags_ref<CR>

" clog($param)とclog("param")の相互変換関数(範囲指定も可)
function! s:clog_convert() range
    for currentLineNo in range(a:firstline, a:lastline)
        " 指定した行を取得
        let currentLine = getline(currentLineNo)
        let isDoller = stridx(currentLine, '$')
        if isDoller != -1
            execute ':'.currentLineNo.'s/(\$/("/g | s/)/")/g'
        else
            execute ':'.currentLineNo.'s/("/($/g | s/"//g'
        endif
    endfor
endfunction
command! -range Clog <line1>,<line2> call s:clog_convert()

" Gtabeditを簡単に実行できるようにした関数
" :Co ブランチ名 でそのブランチのソースをタブ表示
function! s:alias_Gtabedit(...)
    if a:0 == 0
        let branch_name = 'master'
    else
        let branch_name = a:1
    endif
    execute ':Gtabedit '.branch_name.':%'
endfunction
" command! -nargs=? Co call s:AliasGtabedit(<f-args>)

"fzfで選択したものをAliasGtabeditに渡す
function! s:fzf_alias_Gtabedit()
  call fzf#run({
    \ 'source': 'git branch -a',
    \ 'sink': function('s:alias_Gtabedit'),
    \ 'down': '40%'
    \ })
endfunction
command! Co call s:fzf_alias_Gtabedit()

" 現在タブで開いているファイルのパスを取得する
function! s:get_tab_page()
  let list = range(1, tabpagenr('$'))
  let paths = ''
    for i in list
        let bufnr = tabpagebuflist(i)[tabpagewinnr(i) - 1]
        let bufname = unite#util#substitute_path_separator(
            \ (i == tabpagenr() ?
            \       bufname('#') : bufname(bufnr)))
        echo bufname
        let paths = paths . ' ' . bufname
        if bufname == ''
            let bufname = '[No Name]'
        endif
    endfor
    let @* = paths
endfunction
command! Tab call s:get_tab_page()

" カーソル下の単語をPHPManualで開く
function! s:open_php_manual(cursor_word)
  echo a:cursor_word
  let search_word = substitute(a:cursor_word,'_','-','g')
  let url = 'http://php.net/manual/ja/function.' . search_word  . '.php'
  execute 'r! open ' . url
endfunction
command! PhpManual call s:open_php_manual(expand('<cword>'))
nmap <S-k> :PhpManual<CR>

" source ~/.vimrcを簡略化(zshのコマンドと同じに)
command! Svim :source ~/.vimrc

" fzfの標準関数BLinesでエラーが出るので自作
" ファイル内検索
function! s:fzf_BLines(file_path)
  call fzf#run({
    \ 'source': 'cat -n '.a:file_path,
    \ 'sink': function('s:jump_to_line'),
    \ 'down': '40%'
    \ })
endfunction
function! s:jump_to_line(value)
    let lines = split(a:value, '\t')
    let line  = substitute(lines[0], ' ','','g')
    execute ':' . line
endfunction
command! BLines call s:fzf_BLines(expand('%:p'))
nmap <C-f> :BLines<CR>

" gtags_filesでエラーが出るので自作
" ファイル内関数検索
function! s:fzf_ShowFunction(file_path)
  call fzf#run({
    \ 'source': 'global -f '.a:file_path. ' | awk '. "'{print $1." . '"\t"$2}' . "'",
    \ 'sink': function('s:jump_to_function'),
    \ 'down': '40%'
    \ })
endfunction
function! s:jump_to_function(value)
    let lines = split(a:value, '\t')
    execute ':' . lines[1]
endfunction
command! ShowFunction call s:fzf_ShowFunction(expand('%:p'))
nmap <Space>f :ShowFunction<CR>

" grepの結果からvimで開く
function! s:jump_by_grep(...)
    let args = split(@*, ':')
    let filePath = args[0]
    let line = args[1]
    execute ':e ' . filePath
    execute ':' . line
endfunction
command! -nargs=? Vl call s:jump_by_grep(<f-args>)
nmap <S-r> :Vl<CR>

" 選択領域をHTML化→rtf(リッチテキスト)化してクリップボードにコピーする
" Keynoteなどに貼りたい場合に便利
command! -nargs=0 -range=% CopyHtml call s:copy_html()
function! s:copy_html() abort
    '<,'>TOhtml
    w !textutil -format html -convert rtf -stdin -stdout | pbcopy
    bdelete!
endfunction

" 行頭と行末に文字列を挿入
" ex.) InTH <div> <\/div>
function! s:insert_head_and_tail(...) range
    let head = a:1 " 行頭に入れたい文字列
    let tail = a:2 " 行末に入れたい文字列
    " 範囲選択中かで実行するコマンドが違うので分岐
    if a:firstline == a:lastline
        execute ':%s/^/'.head.'/g | %s/$/'.tail.'/g'
    else 
        execute ':'.a:firstline.','.a:lastline.'s/^/'.head.'/g | '.a:firstline.','.a:lastline."s/$/".tail.'/g'
    endif
endfunction
command! -nargs=+ -range InTH <line1>,<line2> call s:insert_head_and_tail(<f-args>)

augroup vimrc
    autocmd!
    autocmd BufRead,BufNewFile *.sh :call s:insert_shebang() " shファイルを開いたときに自動でシェバン挿入
    autocmd InsertLeave * set nopaste
    autocmd FileType markdown colorscheme molokai " markdownを開くときはmolokaiテーマ 
augroup END

" 先頭行にシェバンが存在しないとき、挿入する
function! s:insert_shebang() 
    let head = getline(1)
    if head !~ "bin"
        :execute ':s/^/#!\/bin\/sh\r/g' 
    endif
endfunction

" カーソル下の単語をGoogleで検索する
function! s:search_by_google() 
    let line = line(".")
    let col  = col(".")
    let searchWord = expand("<cword>")
    if searchWord  != ''
        execute 'read !open https://www.google.co.jp/search\?q\=' . searchWord
        execute 'call cursor(' . line . ',' . col . ')'
    endif
endfunction
command! SearchByGoogle call s:search_by_google()
nnoremap <silent> <Space>g :SearchByGoogle<CR>

function! s:mode_on_vimnium()
    execute 'read !osascript ~/ch.sh'
    while 1
        let char = getchar()
        let nr2char = nr2char(char)
        " execute 'read !osascript ~/ch.sh ' . nr2char 
        execute 'read !echo ' . nr2char . ' > ~/vim_vimnium.txt'
    endwhile
endfunction
command! V call s:mode_on_vimnium()

" カーソル下コードのハイライト名を出力
function! s:get_syn_id(transparent)
  let synid = synID(line("."), col("."), 1)
  if a:transparent
    return synIDtrans(synid)
  else
    return synid
  endif
endfunction
function! s:get_syn_attr(synid)
  let name = synIDattr(a:synid, "name")
  let ctermfg = synIDattr(a:synid, "fg", "cterm")
  let ctermbg = synIDattr(a:synid, "bg", "cterm")
  let guifg = synIDattr(a:synid, "fg", "gui")
  let guibg = synIDattr(a:synid, "bg", "gui")
  return {
        \ "name": name,
        \ "ctermfg": ctermfg,
        \ "ctermbg": ctermbg,
        \ "guifg": guifg,
        \ "guibg": guibg}
endfunction
function! s:get_syn_info()
  let baseSyn = s:get_syn_attr(s:get_syn_id(0))
  echo "name: " . baseSyn.name .
        \ " ctermfg: " . baseSyn.ctermfg .
        \ " ctermbg: " . baseSyn.ctermbg .
        \ " guifg: " . baseSyn.guifg .
        \ " guibg: " . baseSyn.guibg
  let linkedSyn = s:get_syn_attr(s:get_syn_id(1))
  echo "link to"
  echo "name: " . linkedSyn.name .
        \ " ctermfg: " . linkedSyn.ctermfg .
        \ " ctermbg: " . linkedSyn.ctermbg .
        \ " guifg: " . linkedSyn.guifg .
        \ " guibg: " . linkedSyn.guibg
endfunction
command! SyntaxInfo call s:get_syn_info()

" 本日の日付を曜日込みで挿入する ex.) # 2019/05/07(火)
function! s:insert_today()
    let today = system("date '+%Y/%m/%d(%a)'")
    " markdown用なのでシャープを先頭につける
    execute ':normal i# ' . today
endfunction
command! Today call s:insert_today()

" テスト用のtest.phpを新規タブで開く
function! s:open_test_php() 
    execute ':tabnew ~/test.php'
endfunction
command! Testphp call s:open_test_php()

" テスト用のshellを新規タブで開く
function! s:open_test_shell() 
    execute ':tabnew ~/test.sh'
endfunction
command! Testshell call s:open_test_shell()

" 現在開いているmarkdownをブラウザで開く
function! s:open_markdown_browser(file_path)
    execute 'r !open -a Google\ Chrome '.a:file_path
endfunction
command! Opr call s:open_markdown_browser(expand('%:p'))
