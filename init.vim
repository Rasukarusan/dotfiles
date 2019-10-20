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

filetype plugin indent on
syntax enable
colorscheme jellybeans



nnoremap <C-n> :NERDTreeTabsToggle<CR>

" If you want to install not installed plugins on startup.
"if dein#check_install()
"  call dein#install()
"endif


" if &compatible
"   set nocompatible
" endif
"
" let s:dein_dir = expand('~/.config/nvim/dein')
" let s:dein_repo_dir = s:dein_dir . '/repos/github.com/Shougo/dein.vim'
"
" set runtimepath+=s:dein_repo_dir
"
"
" call dein#begin(s:dein_dir)
"
" let s:toml = $HOME/.config/nvim/dein.toml
" call dein#load_toml(s:toml, {'lazy': 0})
"
" call dein#end()
" call dein#save_state()
"
" if dein#check_install()
"   call dein#install()
" endif
"
