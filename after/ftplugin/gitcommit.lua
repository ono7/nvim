-- NOTE(jlima): Buffer-local save-and-close mapping for COMMIT_EDITMSG
local opts = { buffer = true, silent = true, desc = "Save and close git commit message" }
vim.keymap.set("n", "<C-x>", "<Cmd>x<CR>", opts)
vim.keymap.set("i", "<C-x>", "<Esc><Cmd>x<CR>", opts)

vim.opt_local.spell = true

-- NOTE(jlima): Evaluated lazily at snippet expansion time via v:lua.git_commit_scope()
-- to avoid race conditions where `filetype=gitcommit` fires before the buffer path
-- `%` is finalized.
function _G.git_commit_scope()
	local work_tree = vim.fn.expand("%:p:h:h")
	local res = vim.system({ "git", "-C", work_tree, "diff", "--cached", "--name-only" }, { text = true }):wait()

	if res.code ~= 0 or not res.stdout or res.stdout == "" then
		return ""
	end

	local files = vim.split(vim.trim(res.stdout), "\n", { trimempty = true })
	if #files == 1 then
		return "(" .. vim.fn.fnamemodify(files[1], ":t") .. ")"
	end

	local first_dir = vim.fn.fnamemodify(files[1], ":h:t")
	if first_dir == "." then
		return ""
	end
	for i = 2, #files do
		if vim.fn.fnamemodify(files[i], ":h:t") ~= first_dir then
			return ""
		end
	end
	return "(" .. first_dir .. ")"
end
