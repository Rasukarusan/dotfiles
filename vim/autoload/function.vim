" =============================================
" clog($param)とclog("param")の相互変換関数(範囲指定も可)
" =============================================
function! s:clog_convert() range
    for currentLineNo in range(a:firstline, a:lastline)
        " 指定した行を取得
        let currentLine = getline(currentLineNo)
        let isDoller = stridx(currentLine, '$')
        if isDoller != -1
            execute ':'.currentLineNo.'s/(\$/("/g | s/)/")/g'
        else
            execute ':'.currentLineNo.'s/("/($/g | s/"//g'
        endif
    endfor
endfunction
command! -range Clog <line1>,<line2> call s:clog_convert()

" =============================================
" 現在開いているファイルを指定のブランチで開く
" =============================================
function! s:open_file_on_branch(...)
    let branch_name = get(a:, 1, 'master')
    let file_path = get(a:, 2, '%')
    execute ':Gvsplit '.branch_name.':'.file_path
    " スクロール同期
    execute 'windo :set scb'
    " windowを右に入れ替える
    call feedkeys("\<C-w>\<S-l>") 
endfunction

" =============================================
" fzfでブランチを指定してファイルを開く
" 引数: ブランチ名もしくはブランチ名+ファイルパス
"   :Co [branch_name]
"   :Co [branch_name] [filepath]
" =============================================
function! s:fzf_open_file_on_branch(...)
  let branch_name = get(a:, 1, '')
  let file_path = get(a:, 2, '')
  if branch_name != '' && file_path != ''
    call s:open_file_on_branch(branch_name, file_path)
    return
  endif
  if branch_name != ''
    call s:open_file_on_branch(branch_name)
    return
  endif
  call fzf#run(fzf#wrap({
    \ 'source': 'git branch -a | tr -d " "',
    \ 'sink': function('s:open_file_on_branch'),
    \ 'options': '--preview "git show {}:' . expand('%') .' | bat --color always -l '. &filetype .'"'
    \ }))
endfunction
command! -nargs=* Co call s:fzf_open_file_on_branch(<f-args>)

" =============================================
" カーソル下の単語をPHPManualで開く
" =============================================
function! s:open_php_manual(cursor_word)
  let search_word = substitute(a:cursor_word,'_','-','g')
  let url = 'http://php.net/manual/ja/function.' . search_word  . '.php'
  execute 'r! open ' . url
endfunction
command! PhpManual call s:open_php_manual(expand('<cword>'))
nmap <Space>k :PhpManual<CR>

" =============================================
" grepの結果からvimで開く
" スプレッドシートからコピーした場合を想定
" =============================================
function! s:jump_by_grep(...)
    let args = split(@*, ':')
    let filePath = args[0]
    let extension = fnamemodify(filePath, ":e")
    if len(args) == 1 && extension == "php"
        execute ':e ' . filePath
        return
    endif
    let line = args[1]
    execute ':e ' . filePath
    execute ':' . line
endfunction
command! -nargs=? OpenByGrep call s:jump_by_grep(<f-args>)
nmap <S-r> :OpenByGrep<CR>

" =============================================
" 選択領域をHTML化→rtf(リッチテキスト)化してクリップボードにコピーする
" Keynoteなどに貼りたい場合に便利
" =============================================
command! -nargs=0 -range=% CopyHtml call s:copy_html()
function! s:copy_html() abort
    '<,'>TOhtml
    w !textutil -format html -convert rtf -stdin -stdout | pbcopy
    bdelete!
endfunction

" =============================================
" カーソル下の単語をGoogleで検索する
" =============================================
function! s:search_by_google(...)
  let searchWord = expand("<cword>")
  if a:1 == 'v' " visualモード時
    " 選択した文字列を取得
    let tmp = @@
    silent normal gvy
    let searchWord = @@
    let @@ = tmp
  endif

  if searchWord  != ''
    " /usr/local/bin/search_by_googleがある前提
    call system('search_by_google "' . searchWord . '"')
  endif
endfunction
command! -nargs=1 -range Goo <line1>,<line2> call s:search_by_google(<f-args>)
nnoremap <silent> <Space>g :Goo n<CR>
vnoremap <silent> <Space>g :Goo v<CR>

" =============================================
" :messagesの最後の行をGoogleで検索する
" =============================================
nnoremap <silent> MG :call system('search_by_google "' . <SID>get_last_message() . '"')<CR>

" =============================================
" カーソル下コードのカラー名を出力
" vimでテーマを作る際に便利
" =============================================
function! s:get_syn_id(transparent)
  let synid = synID(line("."), col("."), 1)
  if a:transparent
    return synIDtrans(synid)
  else
    return synid
  endif
endfunction
function! s:get_syn_attr(synid)
  let name = synIDattr(a:synid, "name")
  let ctermfg = synIDattr(a:synid, "fg", "cterm")
  let ctermbg = synIDattr(a:synid, "bg", "cterm")
  let guifg = synIDattr(a:synid, "fg", "gui")
  let guibg = synIDattr(a:synid, "bg", "gui")
  return {
        \ "name": name,
        \ "ctermfg": ctermfg,
        \ "ctermbg": ctermbg,
        \ "guifg": guifg,
        \ "guibg": guibg}
endfunction
function! s:get_syn_info()
  let baseSyn = s:get_syn_attr(s:get_syn_id(0))
  echo "name: " . baseSyn.name .
        \ " ctermfg: " . baseSyn.ctermfg .
        \ " ctermbg: " . baseSyn.ctermbg .
        \ " guifg: " . baseSyn.guifg .
        \ " guibg: " . baseSyn.guibg
  let linkedSyn = s:get_syn_attr(s:get_syn_id(1))
  echo "link to"
  echo "name: " . linkedSyn.name .
        \ " ctermfg: " . linkedSyn.ctermfg .
        \ " ctermbg: " . linkedSyn.ctermbg .
        \ " guifg: " . linkedSyn.guifg .
        \ " guibg: " . linkedSyn.guibg
endfunction
command! SyntaxInfo call s:get_syn_info()

" =============================================
" 本日の日付を曜日込みで挿入する
" ex.) # 2019/05/07(火)
" =============================================
function! s:insert_today()
    let today = system("date '+%Y/%m/%d(%a)'")
    " markdown用なのでシャープを先頭につける
    execute ':normal i# ' . today
endfunction
command! Today call s:insert_today()

" =============================================
" テスト用のtest.phpを新規タブで開く
" =============================================
function! s:open_test_php()
    execute ':tabnew ~/test.php'
endfunction
command! Testphp call s:open_test_php()

" =============================================
" テスト用のshellを新規タブで開く
" =============================================
function! s:open_test_shell()
    execute ':tabnew ~/test.sh'
endfunction
command! Testshell call s:open_test_shell()

" =============================================
" テスト用のvimを新規タブで開く
" =============================================
function! s:open_test_vim()
    execute ':tabnew ~/test.vim'
endfunction
command! Testvim call s:open_test_vim()

" =============================================
" Terminalを開く
" =============================================
function! s:open_terminal_by_floating_window()
    " 空のバッファを作る
    let buf = nvim_create_buf(v:false, v:true)
    " そのバッファを使って floating windows を開く
    let height = float2nr(&lines * 0.5)
    let width = float2nr(&columns * 1.0)
    let horizontal = float2nr((&columns - width) / 2)
    let vertical = float2nr((&columns - height) / 2)
    let opts = {
        \ 'relative': 'editor',
        \ 'row': vertical,
        \ 'col': horizontal,
        \ 'width': width,
        \ 'height': height,
        \ 'anchor': 'NE',
    \}
    let g:win_id = nvim_open_win(buf, v:true, opts)
    set winblend=40
    terminal
    startinsert
endfunction
nnoremap T :call <SID>open_terminal_by_floating_window()<CR>

" =============================================
" READMEテンプレートを挿入
" =============================================
function! s:insert_template_github_readme()
    let template = "Name \r====\r\rOverview\r\r## Description\r\r## Requirement\r\r## Install\r\r## Usage"
    execute ':normal i' . template
endfunction
command! Readme call s:insert_template_github_readme()

" =============================================
" 選択範囲内の空行を削除
" =============================================
function! s:remove_empty_line() range
    execute ':' . a:firstline . ',' . a:lastline . 'g/^$/d'
endfunction
command! -range RemoveEmptyLine <line1>,<line2>call s:remove_empty_line()

" =============================================
" 選択範囲内の空白を削除
" =============================================
function! s:remove_space() range
    execute ':' . a:firstline . ',' . a:lastline . 's/\s\+$//ge'
    execute ':noh'
endfunction
command! -range RemoveSpace <line1>,<line2>call s:remove_space()

" =============================================
" 指定のデータをレジスタに登録する
" =============================================
function! s:Clip(data)
    let @*=substitute(a:data, $HOME.'/', '',  'g')
    echo "clipped: " . @*
endfunction
" 現在開いているファイルのパスをレジスタへ
command! -nargs=0 ClipPath call s:Clip(expand('%:p'))
" 現在開いているファイルのファイル名をレジスタへ
command! -nargs=0 ClipFile call s:Clip(expand('%:t'))
" memoを新しいタブで開く
command! Memo :tabe ~/memo.md

" =============================================
" Exコマンドの結果を別タブで開いて表示
" nmapやmessageなどを出力するときに便利
" =============================================
function! s:show_ex_result(cmd)
  redir => message
  silent execute a:cmd
  redir END
  if empty(message)
    echoerr "no output"
  else
    tabnew
    setlocal buftype=nofile bufhidden=wipe noswapfile nobuflisted nomodified
    silent put=message
    normal gg
  endif
endfunction
command! -nargs=+ -complete=command ShowExResult call s:show_ex_result(<q-args>)

" =============================================
" vimrcに関わるファイルをfzfで表示する
" `vimrc`コマンドをvim上で実現するもの
" =============================================
function! s:fzf_vimrc()
  call fzf#run({
    \ 'source': "find ~/dotfiles ${XDG_CONFIG_HOME}/nvim/myautoload -follow -name '*.vim' -o -name 'dein.toml' -o -name 'xvimrc' -o -name '*.lua' | awk '{ print length, $0 }' | sort -n -s | cut -d' ' -f2- ",
    \ 'sink': 'tabe',
    \ 'options': '--preview "bat --color always {} --style=plain | head -n 100"',
    \ 'tmux': '-p80%,80%',
    \ })
endfunction
command! Vimrc call s:fzf_vimrc()

" =============================================
" zshrcに関わるファイルをfzfで表示する
" `zshrc`コマンドをvim上で実現するもの
" =============================================
function! s:fzf_zshrc()
  call fzf#run({
    \ 'source': "find ~/dotfiles/zsh -type f | awk '{ print length, $0 }' | sort -n -s | cut -d' ' -f2- ",
    \ 'sink': 'tabe',
    \ 'options': '--preview "bat --color always {} --style=plain | head -n 100"',
    \ 'tmux': '-p80%,80%',
    \ })
endfunction
command! Zshrc call s:fzf_zshrc()

" =============================================
" コマンドの結果を取得する
" @see http://koturn.hatenablog.com/entry/2015/07/31/001507
" =============================================
function! s:get_command_result(cmd) abort
  let [verbose, verbosefile] = [&verbose, &verbosefile]
  set verbose=0 verbosefile=
  redir => str
    execute 'silent!' a:cmd
  redir END
  let [&verbose, &verbosefile] = [verbose, verbosefile]
  return str
endfunction

" =============================================
" :messagesの最後の行を取得する
" =============================================
function! s:get_last_message() abort
  let lines = filter(split(s:get_command_result('messages'), "\n"), 'v:val !=# ""')
  if len(lines) <= 0
      return ''
  end
  return lines[len(lines) - 1 :][0]
endfunction
command! MessageLast echo s:get_last_message()

" Rasukarusan/popup_message.nvimの関数
nnoremap <silent> MM :call popup_message#open(<SID>get_last_message())<CR>

" =============================================
" :messagesの最後の行をコピーする
" =============================================
function! s:copy_last_message()
    let lastMessage = s:get_last_message()
    if strlen(lastMessage) <= 0
        echo 'メッセージがありません'
        return
    end
    let @*=lastMessage
    echo 'clipped: ' . @*[:20] . '...'
endfunction
command! CopyLastMessage call s:copy_last_message()

" =============================================
" jsxでコメントアウト開始/終了を差し込む
" =============================================
function! s:comment_out_jsx() range
    " 下記2行でも実現可能だが、置換した旨がechoされてしまい邪魔なのでfor文でしている。silentでも消えない。
    " execute ':'.a:firstline.','.a:lastline.' s/\(\S\)/{\/* \1/'
    " execute ':'.a:firstline.','.a:lastline.' s/$/ *\/}/'
    for currentLineNo in range(a:firstline, a:lastline)
        " 指定した行を取得
        let currentLine = getline(currentLineNo)
        let isComment = stridx(currentLine, '{/*')
        if isComment != -1
            execute ':'.currentLineNo.' s/{\/\* //'
            execute ':'.currentLineNo.' s/ \*\/}//'
        else
            execute ':'.currentLineNo.' s/\(\S\)/{\/* \1/'
            execute ':'.currentLineNo.' s/$/ *\/}/'
        endif
    endfor
endfunction
command! -range CommentOut <line1>,<line2>call s:comment_out_jsx()
nnoremap Com :CommentOut<CR>
vnoremap Com :CommentOut<CR>

" =============================================
" shellコマンドを実行
" @See https://vim.fandom.com/wiki/Display_output_of_shell_commands_in_new_window
" =============================================
function! s:exec_shell_command(cmdline)
  let expanded_cmdline = a:cmdline
  for part in split(a:cmdline, ' ')
     if part[0] =~ '\v[%#<]'
        let expanded_part = fnameescape(expand(part))
        let expanded_cmdline = substitute(expanded_cmdline, part, expanded_part, '')
     endif
  endfor
  botright new
  setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile nowrap
  execute '0read !'. expanded_cmdline
  setlocal nomodifiable
  1 " カーソルを先頭へ移動
endfunction
command! -complete=shellcmd -nargs=+ Shell call s:exec_shell_command(<q-args>)

" =============================================
" Exコマンドの補完をfzfでする
" =============================================
function! CompletionExCmdWithFzf()
    let currentCmdLine = getcmdline()
    let isVisualMode = stridx(currentCmdLine, "'<,'>") != -1
    let isCall = stridx(currentCmdLine, 'call ') != -1
    let type = 'command'
    let prefix = ''

    if isCall == 1
      let cmdLines = split(currentCmdLine, ' ')
      let currentCmdLine = len(cmdLines) > 1 ? cmdLines[1] : ''
      let type = 'function'
      let prefix = 'call '
    elseif isVisualMode == 1
      let cmdLines = split(currentCmdLine, '>')
      let currentCmdLine = len(cmdLines) > 1 ? cmdLines[1] : ''
      let type = 'command'
      let prefix = "'<,'>"
    endif

    let result = fzf#run({
      \'source': getcompletion(currentCmdLine, type),
      \ 'tmux': '-p60%,60%',
      \ 'options': '--no-multi --bind tab:down'
      \}
    \)
    if len(result) == 0
      return ''
    endif

    " fzf#runの結果はlist型で返されるので、そのままコマンドラインに返すと^@が末尾に付与される
    " ^@を削除するためjoin()している
    return prefix . join(result, '')
endfunction
" cnoremap <TAB> <C-\>eCompletionExCmdWithFzf()<CR>

" =============================================
" 別ブランチのファイルを開く
" =============================================
function! s:open_file_of_branch(branch, file)
  execute ':Gtabedit '.a:branch.':'.a:file
endfunction

" =============================================
" 別ブランチのファイル一覧をfzfで表示して開く
" =============================================
function! s:fzf_show_git_files(branch)
  call fzf#run({
    \ 'source': 'git ls-tree -r --name-only ' . a:branch,
    \ 'sink': function('s:open_file_of_branch', [a:branch]),
    \ 'tmux': '-p60%,60%',
    \ })
endfunction

" =============================================
" ブランチ一覧を表示しファイルを選択して表示する
" =============================================
function! s:fzf_show_branch(...)
  if a:0 == 1
    call <SID>fzf_show_git_files(a:1)
  else
    call fzf#run({
      \ 'source': 'git branch -a',
      \ 'sink': function('s:fzf_show_git_files'),
      \ 'tmux': '-p60%,60%',
      \ })
  endif
endfunction
command! -nargs=? Cof call s:fzf_show_branch(<f-args>)

" =============================================
" カレントディレクトリをfzfで変更
" =============================================
function! s:fzf_cd()
  let excludeDirs = ['node_modules', '.git']
  let excludeCmd = ''
  for excludeDir in excludeDirs
    let excludeCmd = excludeCmd . ' -type d -name ' . excludeDir . ' -prune -o'
  endfor
  call fzf#run({
    \ 'source': 'find . $(git rev-parse --show-cdup) ' . excludeCmd . ' -type d',
    \ 'sink': 'cd',
    \ 'tmux': '-p60%,60%',
    \ })
endfunction
command! Cdd call s:fzf_cd()

" =============================================
" カレントバッファより後ろのバッファを全て削除
" =============================================
function! s:delete_all_buffers()
  let buffer_count = bufnr('$')
  if buffer_count > 1
    execute ':.+,$bwipeout'
  endif
endfunction
nnoremap <silent> BB :call <SID>delete_all_buffers()<CR>

" =============================================
" はてなブログ用 - キャプション付きの画像
" =============================================
function! s:hatena_make_figure()
  let current_line = getline('.')
  let text = '<figure class="figure-image figure-image-fotolife" title="説明"><img src="' . current_line .'"><figcaption>説明</figcaption></figure>'
  call setline('.', text)
endfunction
command! HatenaFigure call s:hatena_make_figure()

" =============================================
" はてなブログ用 - サイト埋込み
" =============================================
function! s:hatena_embed_cite()
  let current_line = getline('.')
  let text = '[' . current_line . ':embed:cite]'
  call setline('.', text)
endfunction
command! HatenaEmbedCite call s:hatena_embed_cite()

" =============================================
" 背景色を黒に変更
" =============================================
function! s:change_background_black()
  :highlight Normal  guibg=#000000
  :highlight NonText guibg=#000000
  :highlight LineNr  guibg=#000000
  :highlight SignColumn guibg=#000000
endfunction

command! Black call s:change_background_black()

" =============================================
" はてぶに下書き投稿
" =============================================
function! s:hatena_post_entry() abort
  let title = substitute(getline(1), '^# ', '', '')
  let content = join(getline(3, '$'), "\n")
  " '&'を一番最初に変換する必要がある。後の変換と競合してしまうため。
  let content = substitute(content, "\&", "\&amp;", 'g')
  let content = substitute(content, '`', '\\`', 'g')
  let content = substitute(content, '"', '\\"', 'g')
  let content = substitute(content, '<', '\&lt;', 'g')
  let content = substitute(content, '>', '\&gt;', 'g')
  let content = substitute(content, '\$', '\\$', 'g')
  call system('sh -x ~/Documents/github/hatena-scripts/post_entry.sh "' . title .'" "' . content . '"')
  echo 'posted!'
endfunction
command! HatenaPostEntry call s:hatena_post_entry()

" =============================================
" 選択した行をキャメルケースに変換
" 区切りもいい感じに判定してくれる
" @see https://vim-jp.org/vim-users-jp/2010/08/08/Hack-166.html
" =============================================
function! s:convert_camel_case() abort
    :'<,'>s/\w\+/\u\0/g"
endfunction
command! -nargs=0 -range=% ToCamelCase call s:convert_camel_case()

" =============================================
" 現在開いているファイルのディレクトリをtmuxのpaneで開く
" =============================================
function! s:open_current_dir_pane() abort
  let current = expand("%:p:h")
  if current == '' | return | endif
  execute 'r !tmux popup -E -d ' . current
endfunction
command! OpenCurrentDirPane call s:open_current_dir_pane()
nnoremap <silent> <Space>o :OpenCurrentDirPane<CR>

" =============================================
" 分割ウインドウのスクロールを同期
" =============================================
function! s:sync_scroll() abort
  if &scb == 0
    windo set scb
    windo set scrollopt=ver,hor,jump
    echo 1
  else
    windo set noscb
    echo 0
  endif
endfunction
command! SyncScroll call s:sync_scroll()

" =============================================
" カーソル下の関数を実行
" 関数ブロック内で実行も可能
" =============================================
function! s:exec_this_method() abort
  let allowFileType = ['sh', 'bash', 'zsh']
  if match(allowFileType, &ft) == -1 | return | endif

  let targetScript = expand('%:p')
  " スクリプト内の関数を全て取得
  let methods = split(system('grep -P "\(\) {" ' . targetScript . ' | tr -d "() {"'), '\n')

  " 引数ありの場合に対応するため、<cword>ではなく現在行を取得して対象の関数を抽出する
  let currentLine = split(getline('.'), ' ')
  let targetMethod = len(currentLine) > 0 ? currentLine[0] : ''

  " カーソル下の文字列が関数であるかを判定
  let index = match(methods, targetMethod)
  if index == -1 " 関数ではない場合(関数ブロック内で実行した場合)
    let line = line('.')
    while line > 0
      let line -= 1
      let matchLine = matchstr(getline(line), '.*() {')
      if matchLine != ''
        let targetMethod = substitute(matchLine, '() {', '', 'g')
        let index = match(methods, targetMethod)
        break
      endif
    endwhile
  endif
  " 探索しても見つからなかった場合、終了
  if targetMethod == ''
    echo 'target not found'
    return
  endif

  " 対象メソッドの実行のみを残したスクリプト文字列を生成
  call remove(methods, index)
  " 対象メソッド以外を除外するためのsed文を作成 ex) sed -e '/^main$/d' -e '/^main /d'
  let sed = 'sed'
  for method in methods
    let sed = sed . ' -e "/^' . method . '$/d"' . ' -e "/^' . method . ' /d"'
  endfor

  " 生成した文字列をスクリプトとして実行できるよう一時ファイルに保存
  let tempfile = tempname()
  call system(sed . ' ' . targetScript . ' > ' . tempfile)

  " 一時ファイルを実行
  execute ':QuickRun ' . &ft . ' -srcfile ' . tempfile
  echo 'exec ' . targetMethod
  call system('rm ' . tempfile)
endfunction
nnoremap <silent><nowait><C-j> :call <sid>exec_this_method()<CR>
