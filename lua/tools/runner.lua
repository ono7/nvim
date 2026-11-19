-- NOTE(jlima): Ensure :T command is registered before :HRun can dispatch to it.
require("tools.terminal")

local M = {}

local HOOKS_PATH = vim.fn.stdpath("config") .. "/hooks.json"

local function load_hooks()
	local uv = vim.uv or vim.loop
	local fd = uv.fs_open(HOOKS_PATH, "r", 438)
	if not fd then
		return {}
	end

	local stat = uv.fs_fstat(fd)
	local data = stat and uv.fs_read(fd, stat.size, 0) or ""
	uv.fs_close(fd)

	if not data or data == "" then
		return {}
	end

	local ok, parsed = pcall(vim.json.decode, data)
	return (ok and type(parsed) == "table") and parsed or {}
end

local function save_hooks(hooks)
	local ok_encode, encoded = pcall(vim.json.encode, hooks)
	if not ok_encode then
		vim.notify("Failed to serialize hooks table to JSON.", vim.log.levels.ERROR)
		return false
	end

	local dir = vim.fs.dirname(HOOKS_PATH)
	if vim.fn.isdirectory(dir) == 0 then
		vim.fn.mkdir(dir, "p")
	end

	local uv = vim.uv or vim.loop
	-- NOTE(jlima): 438 decimal == 0666 octal permissions (masked by process umask).
	local fd, err = uv.fs_open(HOOKS_PATH, "w", 438)
	if not fd then
		vim.notify(string.format("Failed to open hooks file: %s", err), vim.log.levels.ERROR)
		return false
	end

	uv.fs_write(fd, encoded, 0)
	uv.fs_close(fd)
	return true
end

function M.execute(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	if not vim.api.nvim_buf_is_valid(bufnr) then
		return
	end

	local ft = vim.bo[bufnr].filetype
	local hooks = load_hooks()
	local raw_cmd = hooks[ft]
	if not raw_cmd or raw_cmd == "" then
		vim.notify(string.format("No hook configured for filetype '%s'.", ft), vim.log.levels.WARN)
		return
	end

	local buf_name = vim.api.nvim_buf_get_name(bufnr)
	local buf_dir = buf_name ~= "" and vim.fs.dirname(buf_name) or vim.fn.getcwd()

	local expanded_cmd
	vim.api.nvim_buf_call(bufnr, function()
		local saved_cwd = vim.fn.getcwd()
		vim.cmd.lcd(buf_dir)
		expanded_cmd = vim.fn.expandcmd(raw_cmd)
		vim.cmd.lcd(saved_cwd)
	end)

	if expanded_cmd and expanded_cmd ~= "" then
		-- NOTE(jlima): Dispatch expanded hook command without prepending cd
		vim.cmd(string.format("T! %s", expanded_cmd))
	end
end

function M.save_and_execute()
	local bufnr = vim.api.nvim_get_current_buf()
	if vim.bo[bufnr].buftype == "" and vim.bo[bufnr].modified then
		if vim.api.nvim_buf_get_name(bufnr) == "" then
			vim.notify("Cannot save and execute: buffer has no file name.", vim.log.levels.ERROR)
			return
		end
		vim.cmd("silent update")
	end
	M.execute(bufnr)
end

vim.api.nvim_create_user_command("H", function(args)
	local bufnr = vim.api.nvim_get_current_buf()
	local ft = vim.bo[bufnr].filetype

	if ft == "" then
		vim.notify("Cannot register hook: buffer has no filetype.", vim.log.levels.WARN)
		return
	end

	local hooks = load_hooks()
	local function apply_hook(input)
		if input == nil then
			return
		end
		local cleaned = vim.trim(input)
		if cleaned == "" then
			hooks[ft] = nil
			save_hooks(hooks)
			vim.notify(string.format("[%s] Compiler cleared.", ft), vim.log.levels.INFO)
			return
		end
		hooks[ft] = cleaned
		save_hooks(hooks)
		vim.notify(string.format("[%s] Compiler configured: %s", ft, cleaned), vim.log.levels.INFO)
	end

	if #args.args == 0 then
		vim.ui.input({
			prompt = string.format("[%s] Edit Hook (empty to clear): ", ft),
			default = hooks[ft] or "",
		}, function(input)
			apply_hook(input)
		end)
	else
		apply_hook(args.args)
	end
end, { nargs = "*", desc = "Configure or clear runner hook for current filetype" })

vim.api.nvim_create_user_command("HRun", M.save_and_execute, { desc = "Save and run filetype hook" })
vim.keymap.set(
	"n",
	"<leader>r",
	M.save_and_execute,
	{ noremap = true, silent = true, desc = "Save and run filetype hook" }
)

return M
