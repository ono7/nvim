-- Native Package Management

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
}, { confirm = false })

-- quickfix editor
require("quicker").setup({
	keys = {
		{
			">",
			function()
				require("quicker").expand({ before = 2, after = 2, add_to_existing = true })
			end,
			desc = "Expand quickfix context",
		},
		{
			"<",
			function()
				require("quicker").collapse()
			end,
			desc = "Collapse quickfix context",
		},
		{
			"<c-/>",
			"<cmd>cclose<CR>",
			desc = "Close quickfix window",
		},
	},
})

-- Snippets Engine
local has_snippy, snippy = pcall(require, "snippy")
if has_snippy then
	snippy.setup({
		snippet_dirs = "~/.config/nvim/snippets",
		mappings = {
			is = {
				["<Tab>"] = "expand_or_advance",
				-- ["<S-Tab>"] = "previous",
			},
			x = {
				["<leader>d"] = "cut_text",
			},
		},
	})
end

-- Code Formatting
require("conform").setup({
	formatters_by_ft = {
		c = { "clang-format" },
		cpp = { "clang-format" },
		lua = { "stylua" },
		yaml = { "prettier" },
		json = { "prettier" },
		markdown = { "prettier" },
		go = { "goimports", "goimports-reviser" },
		python = function(bufnr)
			if require("conform").get_formatter_info("ruff_format", bufnr).available then
				return { "isort", "ruff_fix", "ruff_format" }
			else
				return { "isort", "ruff_fix", "black" }
			end
		end,
	},
	format_on_save = {
		timeout_ms = 500,
		lsp_fallback = false,
	},
})

-- Buffer-based File Explorer
local has_oil, oil = pcall(require, "oil")
if has_oil then
	oil.setup()
	vim.keymap.set("n", "<c-\\>", "<CMD>Oil<CR>")
end

-- Fuzzy Picker
local has_pick, pick = pcall(require, "mini.pick")
if has_pick then
	pick.setup({
		window = {
			config = {
				border = "single",
			},
		},
	})

	local function pick_oldfiles()
		local old = vim.tbl_filter(function(path)
			return path ~= "" and vim.uv.fs_stat(path) ~= nil
		end, vim.v.oldfiles)

		local items = {}
		for i = 1, math.min(#old, 25) do
			table.insert(items, old[i])
		end

		pick.start({
			source = {
				items = items,
				name = "Oldfiles",
				choose = pick.default_choose,
			},
		})
	end

	-- NOTE(jlima): Use pick.start directly to yield absolute paths without hitting mini.pick builtin tool validation errors
	local function pick_dotfiles()
		local dotfiles_dir = vim.fn.expand("~/.config/nvim")
		if vim.fn.isdirectory(dotfiles_dir) == 0 then
			vim.notify("Directory does not exist: " .. dotfiles_dir, vim.log.levels.WARN)
			return
		end

		local items
		if vim.fn.executable("fd") == 1 then
			local cmd = string.format(
				"fd --type f --hidden --exclude .git --absolute-path . %s",
				vim.fn.shellescape(dotfiles_dir)
			)
			items = vim.fn.systemlist(cmd)
		else
			items = vim.fs.find(function()
				return true
			end, { path = dotfiles_dir, type = "file", limit = math.huge })
		end

		pick.start({
			source = {
				items = items,
				name = "Dotfiles (~/.config/nvim)",
				choose = pick.default_choose,
			},
		})
	end

	pick.registry.oldfiles = pick_oldfiles
	pick.registry.dotfiles = pick_dotfiles

	local silent = { noremap = true, silent = true }
	vim.keymap.set("n", "<M-f>", "<cmd>Pick files<CR>", silent)
	vim.keymap.set("n", "<M-g>", "<cmd>Pick grep_live<CR>", silent)
	vim.keymap.set("n", "<M-r>", pick_oldfiles, silent)
	vim.keymap.set("n", "<leader>vs", pick_dotfiles, vim.tbl_extend("force", silent, { desc = "Find dotfiles" }))
end
