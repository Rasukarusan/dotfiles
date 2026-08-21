UsePlugin 'coc.nvim'
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
  \, 'coc-rust-analyzer'
  \, 'coc-eslint'
  \, 'coc-oxc'
  \, 'coc-diagnostic'
  \, 'coc-prettier'
\]
" 診断ジャンプ(旧ALEの<C-a><C-n>/<C-p>を踏襲)
nmap <silent> <C-a><C-n> <Plug>(coc-diagnostic-next)
nmap <silent> <C-a><C-p> <Plug>(coc-diagnostic-prev)

" フロート(診断全文)表示中はカーソル行のvirtualtextを隠す(重複して見づらいため)。
" カーソル移動でフロートが閉じたらdiagnosticRefreshで復元する。
function! s:hide_cursor_virtualtext() abort
  let l:ns = get(nvim_get_namespaces(), 'coc-diagnostic-virtualText', -1)
  if l:ns == -1 | return | endif
  let s:vt_hidden = 1
  call nvim_buf_clear_namespace(0, l:ns, line('.') - 1, line('.'))
endfunction
function! s:restore_cursor_virtualtext() abort
  if !get(s:, 'vt_hidden', 0) | return | endif
  let s:vt_hidden = 0
  if get(g:, 'coc_service_initialized', 0)
    call CocActionAsync('diagnosticRefresh')
  endif
endfunction
augroup coc_virtualtext_toggle
  autocmd!
  autocmd User CocOpenFloat call s:hide_cursor_virtualtext()
  autocmd CursorMoved,CursorMovedI * call s:restore_cursor_virtualtext()
augroup END

" 補完メニューの色
hi CocFloating guifg=#ffffff guibg=#001622
