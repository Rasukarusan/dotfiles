let g:ale_set_highlights = 0
if executable('eslint_d')
  let g:ale_javascript_eslint_use_global = 1
  let g:ale_javascript_eslint_executable = 'eslint_d'
endif
let b:ale_fixers = ['prettier', 'eslint']
let g:ale_fixers = {
\   '*': ['remove_trailing_lines', 'trim_whitespace'],
\   'javascript': ['eslint'],
\   'markdown': ['textlint'],
\}
let g:ale_fix_on_save = 1

" エラー箇所に飛ぶ
nmap <silent> <C-a><C-n> <Plug>(ale_next_wrap)
nmap <silent> <C-a><C-p> <Plug>(ale_previous_wrap)
let g:ale_virtualtext_cursor = 1
