nnoremap <silent> K :call <SID>show_documentation()<CR>
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gr <Plug>(coc-references)
nmap <silent> gf <Plug>(coc-format)
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
      \ pumvisible() ? coc#_select_confirm() :
      \ coc#expandableOrJumpable() ? "\<C-r>=coc#rpc#request('doKeymap', ['snippets-expand-jump',''])\<CR>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()

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
  \, 'coc-ultisnips'
  \, 'coc-word'
  \, 'coc-tailwindcss'
\]
" CocConfigのdiagnostic.enableが効かなくなってしまったのでこちらで対応
let b:coc_diagnostic_disable=1
