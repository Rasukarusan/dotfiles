UsePlugin 'nvim-treesitter'
" mainブランチではvim.treesitter組み込みAPIを使用
" ハイライトは自動で有効、特定言語を無効化したい場合は下記で設定
lua <<EOF
-- php, vimのtreesitterハイライトを無効化
vim.api.nvim_create_autocmd("FileType", {
  pattern = {"php", "vim"},
  callback = function()
    vim.treesitter.stop()
  end,
})
EOF
":TSInstall <lang> パーサーインストール
":TSUpdate パーサー更新
