-- NOTE(jlima): Package manifest managing remote repositories via vim.pack.
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
	{
		src = gh("nvim-treesitter/nvim-treesitter"),
		version = "main",
	},
	{ src = gh("mason-org/mason.nvim") },
	{ src = gh("mason-org/mason-lspconfig.nvim") },
	{ src = gh("WhoIsSethDaniel/mason-tool-installer.nvim") },
}, { confirm = false })

-- NOTE(jlima): Ordered module loader with isolated failure domains.
local configs = {
	"plugin_config.quicker",
	"plugin_config.snippy",
	"plugin_config.conform",
	"plugin_config.oil",
	"plugin_config.mini_pick",
	"plugin_config.mason",
	"plugin_config.treesitter",
}

for _, mod in ipairs(configs) do
	local ok, err = pcall(require, mod)
	if not ok then
		vim.notify(string.format("Failed loading %s: %s", mod, err), vim.log.levels.ERROR)
	end
end
