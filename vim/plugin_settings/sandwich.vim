UsePlugin 'vim-sandwich'
let g:sandwich_no_default_key_mappings = 1
silent! nmap <unique><silent> cd <Plug>(operator-sandwich-delete)<Plug>(operator-sandwich-release-count)<Plug>(textobj-sandwich-query-a)
silent! nmap <unique><silent> cr <Plug>(operator-sandwich-replace)<Plug>(operator-sandwich-release-count)<Plug>(textobj-sandwich-query-a)
silent! nmap <unique><silent> cdb <Plug>(operator-sandwich-delete)<Plug>(operator-sandwich-release-count)<Plug>(textobj-sandwich-auto-a)
silent! nmap <unique><silent> crb <Plug>(operator-sandwich-replace)<Plug>(operator-sandwich-release-count)<Plug>(textobj-sandwich-auto-a)
let g:operator_sandwich_no_default_key_mappings = 1
silent! map <unique> ca <Plug>(operator-sandwich-add)
silent! xmap <unique> cd <Plug>(operator-sandwich-delete)
silent! xmap <unique> cr <Plug>(operator-sandwich-replace)
