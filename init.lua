--- 🐇 Follow the white Rabbit...
-- TODO(jlima): neovim 0.13 release https://dotfiles.substack.com/p/whats-new-in-neovim-013?r=bkrs6&utm_campaign=post&utm_medium=web
vim.loader.enable()

-- core settings
require("options")
require("keymaps")
require("autocmds")
require("tools")
require("plugins")
require("themes.colorscheme")
require("compilers")
require("lsp")

local neovide_path = vim.fn.expand("~/.config/nvim/lua/neovide.lua")
if vim.g.neovide and vim.fn.filereadable(neovide_path) == 1 then
	dofile(neovide_path)
end

-- :lua vim.pack.update(nil, {force = true})
local gh = function(x)
	return "https://github.com/" .. x
end

vim.pack.add({
	{ src = gh("tpope/vim-fugitive") },
	{ src = gh("stevearc/oil.nvim") },
	{ src = gh("echasnovski/mini.pick") },
	{ src = gh("stevearc/conform.nvim") },
	{ src = gh("dcampos/nvim-snippy") },
	{ src = gh("stevearc/quicker.nvim") },
	{ src = gh("stevearc/dressing.nvim") },
	{ src = gh("sindrets/diffview.nvim") },
	{ src = gh("nvim-lua/plenary.nvim") },
	{
		src = gh("nvim-treesitter/nvim-treesitter"),
		version = "main",
	},
	{ src = gh("mason-org/mason.nvim") },
	{ src = gh("mason-org/mason-lspconfig.nvim") },
	{ src = gh("WhoIsSethDaniel/mason-tool-installer.nvim") },
}, { confirm = false })

local configs = {
	"plugin_config.quicker",
	"plugin_config.snippy",
	"plugin_config.conform",
	"plugin_config.oil",
	"plugin_config.mini_pick",
	"plugin_config.mason",
	"plugin_config.treesitter",
	"plugin_config.diffview",
	"tools.terminal",
	"tools.runner",
	"tools.finder",
	"tools.text_helpers",
	"tools.buffers",
	"tools.git_tags",
	"tools.pack_helpers",
}

for _, mod in ipairs(configs) do
	local ok, err = pcall(require, mod)
	if not ok then
		vim.notify(string.format("Failed loading %s: %s", mod, err), vim.log.levels.ERROR)
	end
end
