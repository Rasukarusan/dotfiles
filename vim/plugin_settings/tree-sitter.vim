lua <<EOF
require'nvim-treesitter.configs'.setup {
  ignore_install = { "norg" },
  highlight = {
    enable = true,
    disable = {}, -- :TSModuleInfo で言語一覧表示
  },
  indent = {
    enable = true
  },
}
EOF
"：TSBufEnable {module} "現在のバッファでモジュールを有効にする
"：TSBufDisable {module} "現在のバッファでモジュールを無効にする
"：TSEnableAll {module} [{ ft }] "すべてのバッファでモジュールを有効にする。filetypeが指定されている場合は、このファイルタイプに対してのみ有効にします。 
"：TSDisableAll {module} [{ ft }] "すべてのバッファでモジュールを無効にします。ファイルタイプが指定されている場合は、このファイルタイプに対してのみ無効にします。
"：TSModuleInfo [{module}] "各ファイルタイプのモジュール状態に関する情報を一覧表示します     
"
