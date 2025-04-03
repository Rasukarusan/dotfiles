UsePlugin 'ale'
if executable('eslint_d')
  let g:ale_javascript_eslint_use_global = 1
  let g:ale_javascript_eslint_executable = 'eslint_d'
endif
let g:ale_fixers = {
\   '*': ['remove_trailing_lines', 'trim_whitespace'],
\   'javascript': ['eslint'],
\   'typescriptreact': ['eslint'],
\   'markdown': ['textlint'],
\}
let g:ale_fix_on_save = 1
" ローカルの.prettierrcを優先
let g:ale_javascript_prettier_use_local_config = 1

" vimrcを再読込みしないとfixersが未定義になってしまうため、autocmdで設定した
autocmd VimEnter,SourcePost * :let b:ale_fixers = ['biome', 'eslint']

let g:ale_pattern_options = {
\   '.*\.html$': {'ale_fix_on_save': 1},
\}

" エラー箇所に飛ぶ
nmap <silent> <C-a><C-n> <Plug>(ale_next_wrap)
nmap <silent> <C-a><C-p> <Plug>(ale_previous_wrap)

" ale_virtualtext関連とale_sign_errorを有効にするには0にする
" これを0にするとvirtual textの色が失われる
let g:ale_use_neovim_diagnostics_api = 0
let g:ale_virtualtext_cursor = 1
let g:ale_virtualtext_prefix = ' --> '
let g:ale_sign_error = '>>'
let g:ale_sign_warning = '--'

let g:ale_set_highlights = 0
" @See https://github.com/dense-analysis/ale/issues/249
" autocmd VimEnter,SourcePost * :highlight! ALEError guifg=#C30500 guibg=#151515
" autocmd VimEnter,SourcePost * :highlight! ALEWarning  guifg=#ffd300 guibg=#333333
