UsePlugin 'git-messenger.vim'
nnoremap <silent>gm :GitMessenger<CR>
let g:git_messenger_close_on_cursor_moved = v:true
let g:git_messenger_include_diff = "none" " none, current, all
let g:git_messenger_always_into_popup = v:true
