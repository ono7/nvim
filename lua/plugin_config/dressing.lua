local has_dressing, dressing = pcall(require, "dressing")
if not has_dressing then
	return
end

-- NOTE(jlima): Native vim.ui.select and vim.ui.input hooks for terminal consistency.
dressing.setup({
	input = {
		border = "single",
		win_options = {
			winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
		},
	},
	select = {
		backend = { "builtin" },
		builtin = {
			border = "single",
		},
	},
})
