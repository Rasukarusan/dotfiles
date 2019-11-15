if &compatible
  set nocompatible
endif

set runtimepath+=$HOME/.config/nvim/dein/repos/github.com/Shougo/dein.vim
let s:rc_dir    = expand('~/.config/nvim')
let s:toml      = s:rc_dir . '/dein.toml'

if dein#load_state(expand($HOME.'/.config/nvim/dein'))
    call dein#begin(expand($HOME.'/.config/nvim/dein'))
    call dein#load_toml(s:toml)
    call dein#end()
    call dein#save_state()
endif

if dein#check_install()
    call dein#install()
endif


" ===============グローバル設定関連===================== "
" 別ファイルのvimの設定を読み込む
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

" ==============================
"           Goの設定
" ==============================
exe "set rtp+=".globpath($GOPATH, "src/github.com/nsf/gocode/vim")
set completeopt=menu,preview


" ==============================
"    markdown内のコードシンタックスハイライト
" ==============================
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


filetype plugin indent on
syntax enable
set t_Co=256
colorscheme jellybeans
" 起動時の画面をスキップ(:introで表示可能)
set shortmess+=I
" 自動でインデントを挿入
set autoindent
" 全角記号がずれるのを回避
set ambiwidth=double
" タブをスペースに変換
set expandtab
set tabstop=4
set shiftwidth=4
set softtabstop=0
" 履歴件数
set history=1000
" jsonやmarkdownでダブルクォート、*が消えるのを回避
set conceallevel=0
" 検索語句のハイライト
set hlsearch
set number
" 自動で検索を開始しない
set noincsearch
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
nnoremap H 10h
nnoremap L 10l
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
" pasteモード(,iでもペーストモードへ)
nnoremap ,i :<C-u>set paste<Return>i
" 補完候補が表示されている場合は確定。そうでない場合は改行
" inoremap <expr><CR>  pumvisible() ? neocomplcache#close_popup() : "<CR>"
" ESCを二回押すことでハイライトを消す
nmap <silent> <Esc><Esc> :nohlsearch<CR>
" Yで末尾までコピー
nnoremap <S-y> v$hy
" syで単語コピー
nnoremap sy byw
" インデントショートカット
nnoremap th <<
nnoremap tl >>

" source ~/.vimrcを簡略化(zshのコマンドと同じに)
command! Svim :source ~/.config/nvim/init.vim
nnoremap rr :Svim<CR>

" 現在開いているスクリプトを読み込む
nnoremap S :source %<CR>

" =============================================
" clog($param)とclog("param")の相互変換関数(範囲指定も可)
" =============================================
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

" =============================================
" Gtabeditを簡単に実行できるようにした関数
" :Co [branch_name] でそのブランチのソースをタブ表示
" =============================================
function! s:alias_Gtabedit(...)
    if a:0 == 0
        let branch_name = 'master'
    else
        let branch_name = a:1
    endif
    execute ':Gtabedit '.branch_name.':%'
endfunction

function! s:fzf_alias_Gtabedit()
  call fzf#run({
    \ 'source': 'git branch -a',
    \ 'sink': function('s:alias_Gtabedit'),
    \ 'down': '40%'
    \ })
endfunction
command! Co call s:fzf_alias_Gtabedit()

" =============================================
" カーソル下の単語をPHPManualで開く
" =============================================
function! s:open_php_manual(cursor_word)
  echo a:cursor_word
  let search_word = substitute(a:cursor_word,'_','-','g')
  let url = 'http://php.net/manual/ja/function.' . search_word  . '.php'
  execute 'r! open ' . url
endfunction
command! PhpManual call s:open_php_manual(expand('<cword>'))
" nmap <S-k> :PhpManual<CR>


" =============================================
" ファイル内検索
" fzfの標準関数BLinesでエラーが出るので自作
" =============================================
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

" =============================================
" ファイル内関数検索
" gtags_filesでエラーが出るので自作
" =============================================
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

" =============================================
" grepの結果からvimで開く
" スプレッドシートからコピーした場合を想定
" =============================================
function! s:jump_by_grep(...)
    let args = split(@*, ':')
    let filePath = args[0]
    let extension = fnamemodify(filePath, ":e")
    if len(args) == 1 && extension == "php"
        execute ':e ' . filePath
        return
    endif
    let line = args[1]
    execute ':e ' . filePath
    execute ':' . line
endfunction
command! -nargs=? OpenByGrep call s:jump_by_grep(<f-args>)
nmap <S-r> :OpenByGrep<CR>

" =============================================
" 選択領域をHTML化→rtf(リッチテキスト)化してクリップボードにコピーする
" Keynoteなどに貼りたい場合に便利
" =============================================
command! -nargs=0 -range=% CopyHtml call s:copy_html()
function! s:copy_html() abort
    '<,'>TOhtml
    w !textutil -format html -convert rtf -stdin -stdout | pbcopy
    bdelete!
endfunction

" =============================================
" 行頭と行末に文字列を挿入
" ex.) InTH <div> <\/div>
" =============================================
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

" =============================================
" filetype設定
" 開くファイルによって適用させる設定
" =============================================
augroup vimrc
    autocmd!
    autocmd BufRead,BufNewFile *.sh :call s:insert_shebang() " shファイルを開いたときに自動でシェバン挿入
    autocmd InsertLeave * set nopaste
    autocmd FileType markdown colorscheme jellybeans " markdownを開くときはmolokaiテーマ
augroup END

" =============================================
" 先頭行にシェバンが存在しないとき、挿入する
" =============================================
function! s:insert_shebang()
    let head = getline(1)
    if head !~ "bin"
        :execute ':s/^/#!\/usr\/bin\/env bash\r/g'
    endif
endfunction

" =============================================
" カーソル下の単語をGoogleで検索する
" =============================================
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

" =============================================
" カーソル下コードのカラー名を出力
" vimでテーマを作る際に便利
" =============================================
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

" =============================================
" 本日の日付を曜日込みで挿入する 
" ex.) # 2019/05/07(火)
" =============================================
function! s:insert_today()
    let today = system("date '+%Y/%m/%d(%a)'")
    " markdown用なのでシャープを先頭につける
    execute ':normal i# ' . today
endfunction
command! Today call s:insert_today()

" =============================================
" テスト用のtest.phpを新規タブで開く
" =============================================
function! s:open_test_php()
    execute ':tabnew ~/test.php'
endfunction
command! Testphp call s:open_test_php()

" =============================================
" テスト用のshellを新規タブで開く
" =============================================
function! s:open_test_shell()
    execute ':tabnew ~/test.sh'
endfunction
command! Testshell call s:open_test_shell()

" =============================================
" Terminalを開く
" =============================================
function! s:open_terminal_by_floating_window() 
    " 空のバッファを作る
    let buf = nvim_create_buf(v:false, v:true)
    " そのバッファを使って floating windows を開く
    let height = float2nr(&lines * 0.5)
    let width = float2nr(&columns * 1.0)
    let horizontal = float2nr((&columns - width) / 2)
    let vertical = float2nr((&columns - height) / 2)
    let opts = {
        \ 'relative': 'editor',
        \ 'row': vertical,
        \ 'col': horizontal,
        \ 'width': width,
        \ 'height': height,
        \ 'anchor': 'NE',
    \}
    let g:win_id = nvim_open_win(buf, v:true, opts) 
    set winblend=40
    terminal
    startinsert 
endfunction
nnoremap T :call <SID>open_terminal_by_floating_window()<CR>

" =============================================
" READMEテンプレートを挿入
" =============================================
function! s:insert_template_github_readme()
    let template = "Name \r====\r\rOverview\r\r## Description\r\r## Demo\r\r## Requirement\r\r## Install\r\r## Usage"
    execute ':normal i' . template
endfunction
command! Readme call s:insert_template_github_readme()

" ===============Floating Windows===================== "
set termguicolors
set winblend=5
hi NormalFloat guifg=#ffffff guibg=#383838
tnoremap <Esc> <C-\><C-n>
tnoremap jj <C-\><C-n>
tnoremap <silent>:q <C-\><C-n>:call nvim_win_close(win_id, v:true)<CR>

