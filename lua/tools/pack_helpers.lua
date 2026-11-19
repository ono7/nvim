-- NOTE(jlima): Wrapper for automated package updates with forced overwrite
vim.api.nvim_create_user_command("PackUpdate", function()
	vim.pack.update(nil, { force = true })
end, {
	desc = "Update packages forcing overwrite",
	nargs = 0,
})
