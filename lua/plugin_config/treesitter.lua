local has_ts, ts = pcall(require, "nvim-treesitter")
if not has_ts then
	return
end

ts.setup({
	install_dir = vim.fn.stdpath("data") .. "/site",
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
	vim.notify("Calling nvim-treesitter for setup...", vim.log.INFO)
	require("nvim-treesitter").install(wanted_parsers):wait(300000)
	vim.notify("Done.", vim.log.INFO)
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
