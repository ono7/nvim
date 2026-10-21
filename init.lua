vim.loader.enable()

-- disable deprication warnings
vim.deprecate = function() end

require("options")
require("keymaps")
require("autocmds")
require("tools")
require("plugins")
require("colorscheme")

local neovide_path = vim.fn.expand("~/.config/nvim/lua/neovide.lua")
if vim.g.neovide and vim.fn.filereadable(neovide_path) == 1 then
	dofile(neovide_path)
end
