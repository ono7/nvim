-- NOTE(jlima): Automatically write modified buffers before invoking :make
vim.opt.autowrite = true

vim.api.nvim_create_autocmd("FileType", {
	pattern = "c",
	callback = function()
		-- NOTE(jlima): Load standard GCC errorformat rules into quickfix parser
		vim.cmd("compiler gcc")

		-- NOTE(jlima): Fall back to direct gcc invocation with $* for extra flags when no Makefile exists
		if vim.fn.filereadable("Makefile") == 0 and vim.fn.filereadable("makefile") == 0 then
			vim.opt_local.makeprg = "gcc -Wall -Wextra -std=c11 -g $* -o %:p:r:S %:p:S"
		end
	end,
})
