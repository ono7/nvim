-- Native Package Management

local gh = function(x)
	return "https://github.com/" .. x
end

-- installs pluins in parallel
vim.pack.add({
	{ src = gh("tpope/vim-fugitive") },
	{ src = gh("stevearc/oil.nvim") },
	{ src = gh("echasnovski/mini.pick") },
	{ src = gh("stevearc/conform.nvim") },
	{ src = gh("dcampos/nvim-snippy") },
	{ src = gh("stevearc/quicker.nvim") },
	{ src = gh("stevearc/dressing.nvim") },
	{ src = gh("norcalli/nvim-colorizer.lua") },
	{
		src = gh("nvim-treesitter/nvim-treesitter"),
		version = "main",
	},
	{ src = gh("mason-org/mason.nvim") },
	{ src = gh("mason-org/mason-lspconfig.nvim") },
	{ src = gh("WhoIsSethDaniel/mason-tool-installer.nvim") },
}, { confirm = false })

-- NOTE(jlima): Initialize core registry before dependent bridges.
require("mason").setup()

-- NOTE(jlima): Initialize lspconfig bridge without duplicate ensure_installed list; tool-installer manages state.
require("mason-lspconfig").setup()

-- NOTE(jlima): Single declarative source of truth for all LSPs, linters, and formatters (deduplicated).
require("mason-tool-installer").setup({
	ensure_installed = {
		-- Language Servers (via mason-lspconfig name resolution)
		"ansiblels",
		"dockerls",
		"gopls",
		"jsonls",
		"lua_ls",
		"pyright",
		"ts_ls",
		"vimls",
		"yamlls",
		-- Linters, Formatters & Binaries
		"gofumpt",
		"goimports",
		"golangci-lint",
		"golines",
		"gomodifytags",
		"gotests",
		"jq",
		"json-to-struct",
		"shellcheck",
		"shfmt",
		"sqlfmt",
		"staticcheck",
		"stylua",
		"yamlfmt",
		"yamllint",
	},
	auto_update = false,
	run_on_start = false,
})

require("colorizer").setup({
	"lua",
	"css",
	"html",
}, {
	RGB = true,
	RRGGBB = true,
	names = false,
	mode = "background",
})

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
		timeout_ms = 800,
		lsp_fallback = false,
	},
})

-- Buffer-based File Explorer
local has_oil, oil = pcall(require, "oil")
if has_oil then
	oil.setup({
		skip_confirm_for_simple_edits = true,
		view_options = {
			show_hidden = true,
		},
	})
	vim.keymap.set("n", "<c-\\>", "<CMD>Oil<CR>")
end

-- Fuzzy Picker
local has_pick, pick = pcall(require, "mini.pick")
if not has_pick then
	return
end

-- NOTE(jlima): preserve standard bottom dock layout and single border
pick.setup({
	window = {
		config = {
			border = "single",
		},
	},
})

-- NOTE(jlima): truncate overflowing paths from the left so the filename remains fully visible
local function show_truncate_left(buf_id, items_to_show, query)
	local win_id = vim.fn.bufwinid(buf_id)
	local max_w = (win_id ~= -1) and vim.api.nvim_win_get_width(win_id) or 80
	-- NOTE(jlima): account for gutter padding and right-side margin
	local limit = math.max(max_w - 6, 20)

	local truncated_items = {}
	for _, item in ipairs(items_to_show) do
		local str = type(item) == "table" and item.text or item
		if vim.fn.strdisplaywidth(str) > limit then
			-- NOTE(jlima): retain the trailing segment and prefix with ellipsis
			local tail = "..." .. string.sub(str, -(limit - 3))
			if type(item) == "table" then
				local clone = vim.deepcopy(item)
				clone.text = tail
				table.insert(truncated_items, clone)
			else
				table.insert(truncated_items, tail)
			end
		else
			table.insert(truncated_items, item)
		end
	end

	pick.default_show(buf_id, truncated_items, query)
end

-- NOTE(jlima): fast fd files picker; excludes build artifacts to restore rg-level throughput
pick.registry.files = function(local_opts)
	local_opts = local_opts or {}
	local cli_opts = {
		command = {
			"fd",
			"--type",
			"f",
			"--hidden",
			"--exclude",
			".git",
			"--exclude",
			"pkg/mod",
			"--exclude",
			".cache",
			"--strip-cwd-prefix",
		},
	}
	local default_opts = {
		source = {
			name = "Files (fd)",
			show = show_truncate_left,
		},
	}
	return pick.builtin.cli(cli_opts, vim.tbl_deep_extend("force", default_opts, local_opts))
end

-- NOTE(jlima): deterministic rg live-grep
pick.registry.grep_live = function(local_opts)
	local_opts = local_opts or {}
	local default_opts = {
		source = {
			name = "Grep Live (rg)",
		},
	}
	local rg_opts = {
		command = {
			"rg",
			"--column",
			"--line-number",
			"--no-heading",
			"--color=never",
			"--smart-case",
			"--hidden",
			"-g",
			"!.git",
		},
	}
	return pick.builtin.grep_live(rg_opts, vim.tbl_deep_extend("force", default_opts, local_opts))
end

local function pick_oldfiles()
	local old = vim.tbl_filter(function(path)
		return path ~= "" and vim.uv.fs_stat(path) ~= nil
	end, vim.v.oldfiles)

	local items = {}
	for i = 1, math.min(#old, 50) do
		table.insert(items, old[i])
	end

	pick.start({
		source = {
			items = items,
			name = "Recent",
			show = show_truncate_left,
			choose = pick.default_choose,
		},
	})
end

-- NOTE(jlima): scoped directory picker using fd streaming with left truncation
local function pick_dir(target_dir, display_name)
	return function()
		local resolved_dir = vim.fn.expand(target_dir)
		if vim.fn.isdirectory(resolved_dir) == 0 then
			vim.notify("Directory does not exist: " .. resolved_dir, vim.log.levels.WARN)
			return
		end

		if vim.fn.executable("fd") == 1 then
			local cli_opts = {
				command = {
					"fd",
					"--type",
					"f",
					"--hidden",
					"--exclude",
					".git",
					"--absolute-path",
					".",
					resolved_dir,
				},
			}
			local start_opts = {
				source = {
					name = display_name or resolved_dir,
					show = show_truncate_left,
					choose = pick.default_choose,
				},
			}
			pick.builtin.cli(cli_opts, start_opts)
		else
			local items = vim.fs.find(function()
				return true
			end, { path = resolved_dir, type = "file", limit = math.huge })

			pick.start({
				source = {
					items = items,
					name = display_name or resolved_dir,
					show = show_truncate_left,
					choose = pick.default_choose,
				},
			})
		end
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

--- tree-sitter configuration
require("nvim-treesitter").setup({
	install_dir = vim.fn.stdpath("data") .. "/site",
})

vim.filetype.add({
	extension = {
		csproj = "xml",
		esproj = "xml",
		keymap = "c",
		["yaml.ansible"] = "yaml",
		mdx = "markdown",
		uproject = "json",
		wsdl = "xml",
	},
})

local wanted_parsers = {
	"asm",
	"bash",
	"c",
	"comment",
	"cpp",
	"c_sharp",
	"css",
	"csv",
	"diff",
	"disassembly",
	"dockerfile",
	"editorconfig",
	"gitcommit",
	"git_config",
	"git_rebase",
	"go",
	"gomod",
	"gosum",
	"gotmpl",
	"http",
	"ini",
	"javascript",
	"jinja",
	"jq",
	"json",
	"lua",
	"make",
	"markdown",
	"markdown_inline",
	"mermaid",
	"passwd",
	"pem",
	"powershell",
	"printf",
	"python",
	"regex",
	"ssh_config",
	"typescript",
	"yaml",
	"zsh",
}

-- NOTE(jlima): Lookup set for O(1) buffer attachment validation in FileType events
local target_langs = {}
for _, lang in ipairs(wanted_parsers) do
	target_langs[lang] = true
end

-- NOTE(jlima): On-demand command to trigger idempotent parser installation without blocking startup
vim.api.nvim_create_user_command("TSInstallMyParsers", function()
	if vim.fn.executable("tree-sitter") == 0 then
		vim.notify("tree-sitter CLI executable not found in PATH", vim.log.levels.ERROR)
		return
	end
	vim.notify("Calling nvim-treesitter for setup...", vim.log.levels.ERROR)
	require("nvim-treesitter").install(wanted_parsers):wait(300000)
	vim.notify("Done..", vim.log.levels.ERROR)
end, { desc = "Install wanted treesitter parsers" })

vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("TreesitterNativeSetup", { clear = true }),
	pattern = "*",
	callback = function(args)
		local lang = vim.treesitter.language.get_lang(args.match) or args.match
		if not target_langs[lang] then
			return
		end

		if vim.b[args.buf].large_file or vim.api.nvim_buf_line_count(args.buf) > 10000 then
			vim.bo[args.buf].syntax = ""
			vim.bo[args.buf].indentexpr = ""
			vim.wo.foldmethod = "manual"
			vim.wo.foldexpr = ""
			return
		end

		-- NOTE(jlima): Enforce manual fold evaluation to prevent CursorMoved syntax tree recalculation
		vim.wo.foldmethod = "manual"
		vim.wo.foldexpr = ""

		-- NOTE(jlima): pcall isolates startup crashes if a parser .so is missing or currently compiling
		local ok = pcall(vim.treesitter.start, args.buf, lang)
		if ok then
			vim.bo[args.buf].syntax = ""
			-- NOTE(jlima): Delegate indentation to treesitter only upon verified parser attachment
			vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
		end
	end,
})
