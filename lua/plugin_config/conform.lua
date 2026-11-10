local has_conform, conform = pcall(require, "conform")
if not has_conform then
	return
end

-- NOTE(jlima): Explicit formatter resolution per filetype with non-blocking fallback.
conform.setup({
	formatters_by_ft = {
		c = { "clang-format" },
		cpp = { "clang-format" },
		lua = { "stylua" },
		yaml = { "prettier" },
		json = { "prettier" },
		markdown = { "prettier" },
		go = { "goimports", "goimports-reviser" },
		python = function(bufnr)
			if conform.get_formatter_info("ruff_format", bufnr).available then
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
