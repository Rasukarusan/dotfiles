function UsePlugin(name)
  if vim.fn.FindPlugin(name) == 0 then
    return false
  end
  return true
end

-- グローバルに設定
_G.UsePlugin = UsePlugin
