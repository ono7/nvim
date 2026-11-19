local M = {}

--- Runs Universal Ctags asynchronously from the current buffer's Git root.
---@param extra_args string[]|nil Optional CLI flags forwarded to ctags
function M.generate_tags(extra_args)
	if vim.fn.executable("ctags") ~= 1 then
		vim.notify("ctags binary not found in PATH.", vim.log.levels.ERROR)
		return
	end

	local root = vim.fs.root(0, ".git")
	if not root then
		vim.notify("Not a git repository: cannot generate tags", vim.log.levels.WARN)
		return
	end

	-- NOTE(jlima): Base flags enforcing disambiguation and defaults; user args override or append.
	local args = {
		"ctags",
		"-R",
		"--sort=yes",
		"--tag-relative=yes",
		"--fields=+iaS",
		"--extras=+q",
		"--extras=+f",
		"--exclude=.git",
		"--exclude=.venv",
		"--exclude=__pycache__",
		"--exclude=build",
		"--exclude=dist",
		"--exclude=*.json",
		"--exclude=*.lock",
	}

	-- NOTE(jlima): extra_args forwards user CLI tokens parsed identically to native shell arguments.
	if extra_args and #extra_args > 0 then
		vim.list_extend(args, extra_args)
	else
		vim.list_extend(args, { "-f", "tags", "." })
	end

	vim.notify("Generating tags for " .. root .. "...", vim.log.levels.INFO)

	-- NOTE(jlima): Spawns ctags directly with forward-passed args; runs asynchronously in repo root.
	vim.system(args, { cwd = root }, function(obj)
		vim.schedule(function()
			if obj.code == 0 then
				vim.notify("Tags updated successfully in: " .. root, vim.log.levels.INFO)
			else
				vim.notify("Ctags failed (exit code " .. obj.code .. "): " .. (obj.stderr or ""), vim.log.levels.ERROR)
			end
		end)
	end)
end

--- Flushes, stages, and commits only the current buffer file asynchronously.
function M.quick_commit_current_file()
	local bufnr = vim.api.nvim_get_current_buf()
	local file_path = vim.api.nvim_buf_get_name(bufnr)

	if vim.bo[bufnr].buftype ~= "" or file_path == "" then
		vim.notify("Cannot commit: buffer is not a file on disk.", vim.log.levels.WARN)
		return
	end

	-- NOTE(jlima): Flush unwritten changes before staging so HEAD matches buffer state.
	if vim.bo[bufnr].modified then
		vim.cmd("silent write")
	end

	local root = vim.fs.root(bufnr, ".git")
	if not root then
		vim.notify("Not inside a git repository.", vim.log.levels.WARN)
		return
	end

	local filename = vim.fn.fnamemodify(file_path, ":t")
	local default_text = string.format("(%s): ", filename)

	-- NOTE(jlima): Pre-load <Home> into typeahead buffer; vim.fn.input() consumes it
	-- immediately after rendering default_text, placing cursor before '('.
	local home_key = vim.api.nvim_replace_termcodes("<Home>", true, false, true)
	vim.api.nvim_feedkeys(home_key, "n", false)

	local ok, input = pcall(vim.fn.input, {
		prompt = "Commit: ",
		default = default_text,
		cancelreturn = "",
	})

	if not ok or vim.trim(input) == "" then
		return
	end

	local msg = vim.trim(input):gsub("%%", filename)

	vim.system({ "git", "add", "--", file_path }, { cwd = root }, function(add_res)
		if add_res.code ~= 0 then
			vim.schedule(function()
				vim.notify("git add failed: " .. (add_res.stderr or ""), vim.log.levels.ERROR)
			end)
			return
		end

		vim.system({ "git", "commit", "-m", msg }, { cwd = root }, function(commit_res)
			vim.schedule(function()
				if commit_res.code == 0 then
					vim.notify("Committed: " .. msg, vim.log.levels.INFO)
				else
					vim.notify(
						"git commit failed: " .. (commit_res.stderr or commit_res.stdout or ""),
						vim.log.levels.ERROR
					)
				end
			end)
		end)
	end)
end

vim.api.nvim_create_user_command("Mktags", function(opts)
	M.generate_tags(opts.fargs)
end, {
	nargs = "*",
	complete = "file",
	desc = "Run ctags in git root with optional custom arguments",
})

vim.keymap.set(
	"n",
	"gm",
	M.quick_commit_current_file,
	{ noremap = true, silent = true, desc = "Stage and commit current file" }
)

return M
