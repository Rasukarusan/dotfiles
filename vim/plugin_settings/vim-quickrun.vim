UsePlugin 'vim-quickrun'
let g:quickrun_config={
  \'_': {
  \  'split': ''
  \},
\}
set splitbelow
" \rで保存して実行、画面分割を下に出す
nnoremap \r :cclose<CR>:write<CR>:QuickRun -mode n<CR>
xnoremap \r :<C-U>cclose<CR>:write<CR>gv:QuickRun -mode v<CR>
