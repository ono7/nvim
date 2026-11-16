--- 🐇 Follow the white Rabbit...
-- TODO(jlima): neovim 0.13 release https://dotfiles.substack.com/p/whats-new-in-neovim-013?r=bkrs6&utm_campaign=post&utm_medium=web
vim.loader.enable()

require("options")
require("keymaps")
require("autocmds")
require("tools")
require("plugins")
require("colorscheme")
require("compilers")
require("lsp")

local neovide_path = vim.fn.expand("~/.config/nvim/lua/neovide.lua")
if vim.g.neovide and vim.fn.filereadable(neovide_path) == 1 then
	dofile(neovide_path)
end
