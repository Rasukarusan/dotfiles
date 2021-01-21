let g:python_host_prog = $PYENV_ROOT.'/versions/neovim2/bin/python'
let g:python3_host_prog = $PYENV_ROOT.'/versions/neovim3/bin/python'

if &compatible
  set nocompatible
endif
set runtimepath+=$XDG_CONFIG_HOME/nvim/dein/repos/github.com/Shougo/dein.vim
let s:rc_dir    = expand($XDG_CONFIG_HOME.'/nvim')
let s:toml      = s:rc_dir . '/dein.toml'

if dein#load_state(expand($XDG_CONFIG_HOME.'/nvim/dein'))
    call dein#begin(expand($XDG_CONFIG_HOME.'/nvim/dein'))
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
    \ 'sh',
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
    \ 'html',
    \ 'yaml'
    \]

" ==============================
" vimでファイルを開いたときに、tmuxのwindow名にファイル名を表示
" ==============================
if exists('$TMUX') && !exists('$NORENAME')
  au BufEnter * if empty(&buftype) | call system('tmux rename-window "[vim]"'.expand('%:t:S')) | endif
  au VimLeave * call system('tmux set-window automatic-rename on')
endif

filetype plugin indent on
syntax enable
set t_Co=256
colorscheme jellybeans
" QuickFixで選択した行をわかりやすくするための設定
hi QuickFixLine ctermbg=242 guibg=#a2227d
" Cocのlistでカーソル行をわかりやすくするための設定
hi CursorLine guibg=#a2227d
hi Search cterm=underline ctermfg=0 ctermbg=11 gui=underline guifg=#f0a0c0 guibg=NONE
" 拡張子別インデント設定。echo &filetypeでFileTypeを取得可能。
augroup IndentSettings
    autocmd!
    autocmd FileType javascript      setlocal sw=2 sts=2 ts=2 et
    autocmd FileType typescript      setlocal sw=2 sts=2 ts=2 et
    autocmd FileType typescript.tsx  setlocal sw=2 sts=2 ts=2 et
    autocmd BufEnter *.tsx set filetype=typescript
    autocmd FileType php             setlocal sw=4 sts=0 ts=4 et
    autocmd FileType zsh             setlocal sw=2 sts=2 ts=2 et
    autocmd FileType sh              setlocal sw=2 sts=2 ts=2 et
    autocmd FileType vim             setlocal sw=2 sts=2 ts=2 et
    autocmd FileType markdown        setlocal sw=4 sts=4 ts=4 et
    autocmd FileType html            setlocal sw=4 sts=4 ts=4 et
    autocmd FileType json            setlocal sw=4 sts=4 ts=4 et
    autocmd FileType yaml            setlocal sw=2 sts=2 ts=2 et
augroup END

" ==============================
"       Floating Windows
" ==============================
if has('nvim')
    set termguicolors
    set winblend=10
    " colorscheme jellybeans よりもあとに書かないと反映されない(上書きされてしまう)ので注意
    hi NormalFloat guifg=#ffffff guibg=#000000
    tnoremap <Esc> <C-\><C-n>
    " tnoremap jj <C-\><C-n>
    tnoremap <silent>:q <C-\><C-n>:call nvim_win_close(win_id, v:true)<CR>
endif

" =============================================
" 先頭行にシェバンが存在しないとき、挿入する
" =============================================
function! s:insert_shebang()
    let head = getline(1)
    if head !~ "bin"
        :execute ':s/^/#!\/usr\/bin\/env bash\r/g'
    endif
endfunction
" 拡張子別のファイル設定
augroup vimrc
    autocmd!
    autocmd BufRead,BufNewFile *.sh :call s:insert_shebang() " shファイルを開いたときに自動でシェバン挿入
    autocmd InsertLeave * set nopaste
    autocmd FileType markdown colorscheme jellybeans " markdownを開くときはmolokaiテーマ
augroup END

set mouse=a
set updatetime=250
" 起動時の画面をスキップ(:introで表示可能)
set shortmess+=I
" 自動でインデントを挿入
set autoindent
" 全角記号がずれるのを回避
" set ambiwidth=double
" タブをスペースに変換
set expandtab
" rrでvimrcを再度読み込む際、augroupで設定した設定が上書きされてしまうためコメントアウト
" set tabstop=4
" set shiftwidth=4
" set softtabstop=0
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
" crontab: temp file must be edited in placeのエラー文が出るのでtmpではバックアップをしないよう設定
set backupskip=/tmp/*,/private/tmp/*
" 行末の1文字先までカーソル移動を可
set virtualedit=onemore

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
cnoremap <C-a> <Home>
" タブ移動のショートカット
nnoremap <C-l> <ESC>gt
nnoremap <C-h> <ESC>g<S-t>
" 画面分割時の移動のショートカット
nnoremap <C-k> <ESC><C-w>k
nnoremap <C-j> <ESC><C-w>j
" 現在のタブを右へ移動
nnoremap <Tab>n :tabmove +<CR>
" 現在のタブを左へ移動
nnoremap <Tab>p :tabmove -<CR>
" ESCを二回押すことでハイライトを消す
nmap <silent> <Esc><Esc> :nohlsearch<CR>
" Yで末尾までコピー
nnoremap <S-y> y$
" syで単語コピー
nnoremap sy byw
" インデントショートカット
nnoremap th <<
nnoremap tl >>
vnoremap th <
vnoremap tl >
" source ~/.vimrcを簡略化
nnoremap rr :source ~/.config/nvim/init.vim<CR>
" ファイル再読み込み
nnoremap re :e!<CR>
" 現在開いているスクリプトを読み込む
nnoremap S :source %<CR>
" InsertモードのときはFキーを無効化(MacBookProのキーボードがおかしいせいでF5が入力されしまう等があるため)
imap <F1> <nop>
imap <F2> <nop>
imap <F3> <nop>
imap <F4> <nop>
imap <F5> <nop>
imap <F6> <nop>
imap <F7> <nop>
imap <F8> <nop>
imap <F9> <nop>
imap <F10> <nop>
imap <F11> <nop>
imap <F12> <nop>
cmap <F1> <nop>
cmap <F2> <nop>
cmap <F3> <nop>
cmap <F4> <nop>
cmap <F5> <nop>
cmap <F6> <nop>
cmap <F7> <nop>
cmap <F8> <nop>
cmap <F9> <nop>
cmap <F10> <nop>
cmap <F11> <nop>
cmap <F12> <nop>
" ページタイトル\nページURL形式をマークダウン記法にする
nnoremap Mf ^i- [<ESC>A]<ESC>Js(<ESC>A)<ESC>^
" 直前のファイルを開く
nnoremap <S-x> :tabe #<CR>
" 検索時のfoo/hogeなどの/を自動でエスケープして挿入する
cnoremap <expr> / (getcmdtype() == '/') ? '\/' : '/'
" ペースト時にインデントを合わせる
" nnoremap p ]p
" nnoremap P ]P
" nnoremap ]p p
" nnoremap ]P P
"pで貼り付けたテキストの選択
nnoremap <expr> gp '`[' . strpart(getregtype(), 0, 1) . '`]'
" ctrl-pでコマンド履歴を入力中の文字で遡る
cnoremap <C-p> <Up>
" :messagesの短縮
cabbrev ms messages
