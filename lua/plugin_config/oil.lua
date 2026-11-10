local has_oil, oil = pcall(require, "oil")
if not has_oil then
	return
end

-- NOTE(jlima): Buffer-based directory editor with immediate edits and hidden file visibility.
oil.setup({
	skip_confirm_for_simple_edits = true,
	view_options = {
		show_hidden = true,
	},
})

vim.keymap.set("n", "<c-\\>", "<CMD>Oil<CR>", { noremap = true, silent = true, desc = "Open Oil file browser" })
