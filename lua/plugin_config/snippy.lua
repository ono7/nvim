local has_snippy, snippy = pcall(require, "snippy")
if not has_snippy then
	return
end

-- NOTE(jlima): Tab-driven snippet expansion targeting custom local snippet library.
snippy.setup({
	snippet_dirs = "~/.config/nvim/snippets",
	mappings = {
		ix = {
			["<Tab>"] = "expand_or_advance",
		},
		x = {
			["<leader>d"] = "cut_text",
		},
	},
})
