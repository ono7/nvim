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

-- add configs under ~/.config/nvim/lsp/
-- file name must match the language server to enable
vim.lsp.enable({
	"pyright",
	"lua_ls",
	"ansiblels",
	"gopls",
	"clangd",
})
