let g:ale_set_highlights = 0
if executable('eslint_d')
  let g:ale_javascript_eslint_use_global = 1
  let g:ale_javascript_eslint_executable = 'eslint_d'
endif
" Fix files with prettier, and then ESLint.
let b:ale_fixers = ['prettier', 'eslint']
let g:ale_fixers = {
\   '*': ['remove_trailing_lines', 'trim_whitespace'],
\   'javascript': ['eslint'],
\}
" Set this variable to 1 to fix files when you save them.
let g:ale_fix_on_save = 1

