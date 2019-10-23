noremap [denite-gtags]  <Nop>
nmap <Space> [denite-gtags]
" 今のファイルの関数などの一覧
nnoremap [denite-gtags]f :Denite -buffer-name=gtags_file -prompt=> gtags_file<CR>
" カーソル下の単語の定義元を表示
nnorema [denite-gtags]d :<C-u>DeniteCursorWord -buffer-name=gtags_def -prompt=> gtags_def<CR>
" カーソル下の単語の参照先を表示
nnoremap [denite-gtags]r :<C-u>DeniteCursorWord -buffer-name=gtags_ref -prompt=> gtags_ref<CR>
