vim.lsp.config("*", {
	root_markers = { ".git" },
	float = {
		border = "rounded",
	},
})

local lsp_notify_group = vim.api.nvim_create_augroup("LspManualNotify", { clear = true })
--- Manual LSP File Change Notification ---
vim.api.nvim_create_autocmd("BufWritePost", {
	group = lsp_notify_group,
	callback = function(args)
		local clients = vim.lsp.get_clients({ bufnr = args.buf })
		for _, client in ipairs(clients) do
			client:notify("workspace/didChangeWatchedFiles", {
				changes = {
					{
						uri = vim.uri_from_bufnr(args.buf),
						type = 2, -- LSP Protocol: 1 = Created, 2 = Changed, 3 = Deleted
					},
				},
			})
		end
	end,
})

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("UserLspAttach", { clear = true }),
	callback = function(args)
		-- NOTE(jlima): Set omnifunc natively on attach; Navic redraw loops removed.
		vim.bo[args.buf].omnifunc = "v:lua.vim.lsp.omnifunc"

		-- NOTE(jlima): Bind K strictly to the buffer ID provided by LspAttach (args.buf).
		vim.keymap.set("n", "K", function()
			vim.lsp.buf.hover({ border = "rounded" })
		end, { buffer = args.buf, desc = "LSP Hover Documentation" })

		-- NOTE(jlima): Filter strictly for clients supporting textDocument/completion before triggering omnifunc.
		-- vim.keymap.set("i", "<C-l>", function()
		-- 	if vim.fn.pumvisible() == 1 then
		-- 		return "<C-y>"
		-- 	end
		-- 	local clients = vim.lsp.get_clients({
		-- 		bufnr = args.buf,
		-- 		method = "textDocument/completion",
		-- 	})
		-- 	return #clients > 0 and "<C-x><C-o>" or "<C-x><C-n>"
		-- end, { expr = true, replace_keycodes = true, buffer = args.buf, desc = "Smart Completion" })
	end,
})

vim.diagnostic.config({
	update_in_insert = false,
	virtual_text = false,
	severity_sort = true,
	float = { border = "rounded", source = true },
	jump = {
		float = true,
	},
})

local diagnostic_group = vim.api.nvim_create_augroup("DiagnosticToggle", { clear = true })
vim.api.nvim_create_autocmd("InsertEnter", {
	group = diagnostic_group,
	callback = function()
		vim.diagnostic.enable(false)
	end,
})

vim.api.nvim_create_autocmd({ "InsertLeave", "BufWritePost" }, {
	group = diagnostic_group,
	callback = function()
		vim.diagnostic.enable(true)
	end,
})

-- NOTE(jlima): Load Lua module tables from lua/lsp/*.lua and register them with vim.lsp.config.
vim.lsp.config("pyright", require("lsp.pyright"))
vim.lsp.config("lua_ls", require("lsp.lua_ls"))
vim.lsp.config("ansiblels", require("lsp.ansiblels"))
-- vim.lsp.config("ruff", require("lsp.ruff"))

vim.lsp.enable({
	"pyright",
	"lua_ls",
})
