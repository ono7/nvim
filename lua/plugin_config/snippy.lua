local has_snippy, snippy = pcall(require, "snippy")
if not has_snippy then
	return
end

-- NOTE(jlima): Tab-driven snippet expansion targeting custom local snippet library.
snippy.setup({
	snippet_dirs = "~/.config/nvim/snippets",
	mappings = {
		is = {
			["<Tab>"] = "expand_or_advance",
			["<S-Tab>"] = "previous",
		},
		x = {
			["<leader>d"] = "cut_text",
		},
	},
})
