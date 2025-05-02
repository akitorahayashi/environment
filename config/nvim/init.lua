-- オプション設定やキーマップを読み込む (推奨)
-- require("core.options") -- まだファイルがないのでコメントアウト
-- require("core.keymaps") -- まだファイルがないのでコメントアウト

-- lazy.nvim のセットアップ
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  -- lazy.nvimリポジトリが存在しない場合、クローンする
  print("Installing lazy.nvim...")
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
  print("lazy.nvim installed.")
end
-- lazy.nvim をランタイムパスに追加
vim.opt.rtp:prepend(lazypath)

-- プラグイン設定を読み込んで lazy.nvim をセットアップ
-- "plugins" は lua/plugins/ ディレクトリを指す
require("lazy").setup("plugins")

print("Neovim config loaded!") 