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
    \ 'html'
    \]

" ==============================
"       Floating Windows
" ==============================
if has('nvim')
    set termguicolors
    set winblend=5
    hi NormalFloat guifg=#ffffff guibg=#383838
    tnoremap <Esc> <C-\><C-n>
    " tnoremap jj <C-\><C-n>
    tnoremap <silent>:q <C-\><C-n>:call nvim_win_close(win_id, v:true)<CR>
endif

filetype plugin indent on
syntax enable
set t_Co=256
colorscheme jellybeans
set mouse=a
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
cnoremap <C-a> <Home>
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
" ESCを二回押すことでハイライトを消す
nmap <silent> <Esc><Esc> :nohlsearch<CR>
" Yで末尾までコピー
nnoremap <S-y> v$hy
" syで単語コピー
nnoremap sy byw
" インデントショートカット
nnoremap th <<
nnoremap tl >>
vnoremap th <<
vnoremap tl >>
" source ~/.vimrcを簡略化
nnoremap rr :source ~/.config/nvim/init.vim<CR>
" 現在開いているスクリプトを読み込む
nnoremap S :source %<CR>

" vimでファイルを開いたときに、tmuxのwindow名にファイル名を表示
if exists('$TMUX') && !exists('$NORENAME')
  au BufEnter * if empty(&buftype) | call system('tmux rename-window "[vim]"'.expand('%:t:S')) | endif
  au VimLeave * call system('tmux set-window automatic-rename on')
endif
