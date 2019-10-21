filetype plugin indent on " これがないと「エディタのコマンドではありません」と出る
let g:go_highlight_functions = 1
let g:go_highlight_methods = 1
let g:go_highlight_structs = 1
let g:go_gocode_unimported_packages = 1
let g:go_metalinter_autosave_enabled = ['vet']
let g:go_fmt_command = "goimports" " 保存時にimport
let g:go_list_type = "quickfix"
augroup GolangSettings
    autocmd!
    autocmd FileType go nmap \r <Plug>(go-run)
    autocmd FileType go nmap <Space>d <Plug>(go-def-tab)
    autocmd FileType go nmap <Space>r <Plug>(go-referrers)
    autocmd FileType go nmap <C-t> <Plug>(go-def-pop)
    autocmd FileType go nmap <Space>f :GoDecls<CR>
    autocmd FileType go nmap <Space>i <Plug>(go-info)
augroup END
