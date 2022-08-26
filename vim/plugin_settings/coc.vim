nnoremap <silent> K :call <SID>show_documentation()<CR>
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gr <Plug>(coc-references)
nmap <silent> gf <Plug>(coc-format)
nmap rn <Plug>(coc-rename)
function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction

" SnippetsのジャンプをTabでする。デフォルトは<C-j>、<C-k>。
" @See https://github.com/neoclide/coc-snippets
inoremap <silent><expr> <TAB>
      \ coc#pum#visible() ? coc#pum#confirm() :
      \ coc#expandableOrJumpable() ? "\<C-r>=coc#rpc#request('doKeymap', ['snippets-expand-jump',''])\<CR>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()

" 補完メニューの移動
inoremap <silent><expr> <C-j> coc#pum#visible() ? coc#pum#next(1) : "\<Down>"
inoremap <silent><expr> <C-k> coc#pum#visible() ? coc#pum#prev(1) : "\<Up>"
inoremap <silent><expr> <Enter> coc#pum#visible() ? coc#pum#confirm() : "\<Enter>"

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

let g:coc_snippet_next = '<tab>'
" 自動インストール
let g:coc_global_extensions = [
  \  'coc-css'
  \, 'coc-go'
  \, 'coc-html'
  \, 'coc-json'
  \, 'coc-phpls'
  \, 'coc-snippets'
  \, 'coc-tsserver'
  \, 'coc-word'
  \, 'coc-tailwindcss'
  \, 'coc-jedi'
  \, 'coc-webview'
  \, 'coc-markdown-preview-enhanced'
\]
" CocConfigのdiagnostic.enableが効かなくなってしまったのでこちらで対応
let b:coc_diagnostic_disable=1
