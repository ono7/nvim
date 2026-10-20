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
	{
		src = gh("nvim-treesitter/nvim-treesitter"),
		version = "main",
	},
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
				name = "Recent",
				choose = pick.default_choose,
			},
		})
	end

	-- NOTE(jlima): Direct pick.start execution enforces absolute paths and bypasses tool validation mismatches
	local function pick_dir(target_dir, display_name)
		return function()
			local resolved_dir = vim.fn.expand(target_dir)
			if vim.fn.isdirectory(resolved_dir) == 0 then
				vim.notify("Directory does not exist: " .. resolved_dir, vim.log.levels.WARN)
				return
			end

			local items
			if vim.fn.executable("fd") == 1 then
				local cmd = string.format(
					"fd --type f --hidden --exclude .git --absolute-path . %s",
					vim.fn.shellescape(resolved_dir)
				)
				items = vim.fn.systemlist(cmd)
			else
				items = vim.fs.find(function()
					return true
				end, { path = resolved_dir, type = "file", limit = math.huge })
			end

			pick.start({
				source = {
					items = items,
					name = display_name or resolved_dir,
					choose = pick.default_choose,
				},
			})
		end
	end

	pick.registry.oldfiles = pick_oldfiles

	local silent = { noremap = true, silent = true }
	vim.keymap.set("n", "<M-f>", "<cmd>Pick files<CR>", silent)
	vim.keymap.set("n", "<M-g>", "<cmd>Pick grep_live<CR>", silent)
	vim.keymap.set("n", "<M-r>", pick_oldfiles, silent)

	local dir_pickers = {
		{ key = "<M-v>", dir = "~/.config/nvim", desc = "Neovim Config" },
		{ key = "<M-i>", dir = "~/.dotfiles", desc = "Dotfiles" },
	}

	for _, target in ipairs(dir_pickers) do
		vim.keymap.set(
			"n",
			target.key,
			pick_dir(target.dir, target.desc),
			vim.tbl_extend("force", silent, { desc = target.desc })
		)
	end
end

-- treesitter
local install = require("nvim-treesitter.install")
install.prefer_git = false
install.compilers = { "gcc", "clang", "cc" }

-- NOTE(jlima): Register explicit custom extension mappings at configuration time
vim.filetype.add({
	extension = {
		csproj = "xml",
		esproj = "xml",
		keymap = "c",
		-- ["yaml.ansible"] = "yaml",
		mdx = "markdown",
		uproject = "json",
		wsdl = "xml",
	},
})

-- NOTE(jlima): Single declarative source of truth for both installation and buffer attachment
local wanted_parsers = {
	"asm",
	"bash",
	"c",
	"cpp",
	"diff",
	"dockerfile",
	"gitcommit",
	"go",
	"gomod",
	"javascript",
	"jinja",
	"lua",
	"markdown",
	"markdown_inline",
	"python",
	"yaml",
	"make",
}

-- NOTE(jlima): Build lookup set and missing parser list in a single pass
local target_langs = {}
local missing_parsers = {}

for _, lang in ipairs(wanted_parsers) do
	target_langs[lang] = true
	if #vim.api.nvim_get_runtime_file("parser/" .. lang .. ".so", false) == 0 then
		table.insert(missing_parsers, lang)
	end
end

if #missing_parsers > 0 and vim.fn.executable("tree-sitter") == 1 then
	require("nvim-treesitter").install(missing_parsers)
end

vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("TreesitterNativeSetup", { clear = true }),
	pattern = "*",
	callback = function(args)
		-- NOTE(jlima): Resolve filetype alias to grammar name (e.g. sh -> bash)
		local lang = vim.treesitter.language.get_lang(args.match) or args.match
		if not target_langs[lang] then
			return
		end

		-- NOTE(jlima): Prevent main thread redraw stalls on minified or generated buffers exceeding 10k lines
		if vim.b[args.buf].large_file or vim.api.nvim_buf_line_count(args.buf) > 10000 then
			vim.bo[args.buf].syntax = ""
			vim.bo[args.buf].indentexpr = ""
			vim.wo.foldmethod = "manual"
			vim.wo.foldexpr = ""
			return
		end

		-- NOTE(jlima): Eliminate AST tree-walking on insert keystrokes by resetting legacy indent scripts
		vim.bo[args.buf].indentexpr = ""

		-- NOTE(jlima): Enforce manual fold evaluation to prevent CursorMoved syntax tree recalculation
		vim.wo.foldmethod = "manual"
		vim.wo.foldexpr = ""

		-- NOTE(jlima): pcall isolates startup crashes if a parser .so is missing or currently compiling
		local ok = pcall(vim.treesitter.start, args.buf, lang)
		if ok then
			vim.bo[args.buf].syntax = ""
			vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
		end
	end,
})
