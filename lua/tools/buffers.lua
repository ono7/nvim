local M = {}

local function test_match(str, pat)
	if not str or str == "" then
		return false
	end
	local ok, match = pcall(string.find, str, pat)
	return (ok and match ~= nil) or str:lower():find(pat:lower(), 1, true) ~= nil
end

--- Force-closes listed buffers matching `|`-separated include/!exclude patterns.
---@param raw_arg string
---@param preserve_modified boolean
function M.delete_matching_buffers(raw_arg, preserve_modified)
	local arg = vim.trim(raw_arg or "")
	local raw_patterns = arg ~= "" and vim.split(arg, "|", { trimempty = true }) or {}
	local include_pats, exclude_pats = {}, {}

	for _, pat in ipairs(raw_patterns) do
		local trimmed = vim.trim(pat)
		if trimmed:sub(1, 1) == "!" then
			local stripped = vim.trim(trimmed:sub(2))
			if stripped ~= "" then
				table.insert(exclude_pats, stripped)
			end
		elseif trimmed ~= "" then
			table.insert(include_pats, trimmed)
		end
	end

	local bufs = vim.tbl_filter(function(b)
		if not vim.api.nvim_buf_is_valid(b) then
			return false
		end
		local ok, listed = pcall(vim.api.nvim_get_option_value, "buflisted", { buf = b })
		return ok and listed
	end, vim.api.nvim_list_bufs())

	local targets = {}
	for _, buf in ipairs(bufs) do
		local full_path = vim.api.nvim_buf_get_name(buf)
		local rel_path = full_path ~= "" and vim.fn.fnamemodify(full_path, ":.") or ""
		local buf_name = vim.fn.bufname(buf)

		local is_excluded = false
		for _, pat in ipairs(exclude_pats) do
			if test_match(rel_path, pat) or test_match(buf_name, pat) or test_match(full_path, pat) then
				is_excluded = true
				break
			end
		end

		if not is_excluded then
			if #include_pats == 0 then
				table.insert(targets, buf)
			else
				for _, pat in ipairs(include_pats) do
					if test_match(rel_path, pat) or test_match(buf_name, pat) or test_match(full_path, pat) then
						table.insert(targets, buf)
						break
					end
				end
			end
		end
	end

	if #targets == 0 then
		vim.notify("No buffers matched" .. (arg ~= "" and (": " .. arg) or ""), vim.log.levels.WARN)
		return
	end

	local force_delete = not preserve_modified
	local closed, skipped_modified = 0, 0

	for _, buf in ipairs(targets) do
		if vim.api.nvim_buf_is_valid(buf) then
			local ok_mod, is_modified = pcall(vim.api.nvim_get_option_value, "modified", { buf = buf })
			if not force_delete and ok_mod and is_modified then
				skipped_modified = skipped_modified + 1
			else
				if pcall(vim.api.nvim_buf_delete, buf, { force = force_delete }) then
					closed = closed + 1
				end
			end
		end
	end

	if skipped_modified > 0 then
		vim.notify(
			string.format(
				"Closed %d buffer(s). Skipped %d modified buffer(s) (run :Da without '!' to force).",
				closed,
				skipped_modified
			),
			vim.log.levels.WARN
		)
	else
		vim.notify(string.format("Closed %d buffer(s).", closed), vim.log.levels.INFO)
	end
end

vim.api.nvim_create_user_command("Da", function(opts_cmd)
	-- NOTE(jlima): Invert bang semantics so force-delete is the default; bang preserves unwritten changes.
	M.delete_matching_buffers(opts_cmd.args, opts_cmd.bang)
end, {
	bang = true,
	nargs = "?",
	desc = "Force close matching buffers by default; use '!' to preserve unsaved buffers",
})

vim.api.nvim_create_user_command("D", "bdelete!", {
	desc = "Force delete current buffer",
})

vim.api.nvim_create_user_command("Cd", function()
	local root = vim.fs.root(0, ".git")
	if root then
		vim.cmd.lcd(root)
	else
		vim.notify("Not a git repository", vim.log.levels.WARN)
	end
end, {
	desc = "Change local window directory to git root",
})

vim.api.nvim_create_user_command("Take", function(opts)
	local path = vim.fn.fnamemodify(opts.args:gsub("%s+", "-"), ":p")
	vim.fn.mkdir(path, "p")
	vim.cmd.lcd(vim.fn.fnameescape(path))
end, {
	nargs = "+",
	complete = "dir",
	desc = "Create directory (normalizing spaces to hyphens) and lcd into it",
})

return M
