local M = {}

--- Runs `fd` and applies `!exclude` substring/Lua-pattern filters.
---@param input string Raw argument string in `<pattern>!<exclude1>!<exclude2>` format
---@param max_results integer|nil Optional cap on returned paths
---@return string[]
function M.run_fd_filtered(input, max_results)
	if vim.fn.executable("fd") ~= 1 then
		return {}
	end

	local parts = vim.split(input, "!", { plain = true })
	local pattern = parts[1] ~= "" and parts[1] or ".*"
	local limit_flag = max_results and string.format("--max-results %d", max_results) or ""
	local cmd = string.format("fd --type f --hidden --exclude .git -p %s %s", limit_flag, vim.fn.shellescape(pattern))
	local results = vim.fn.systemlist(cmd)

	if vim.v.shell_error ~= 0 then
		return {}
	end

	for i = 2, #parts do
		local exclude = parts[i]
		if exclude ~= "" then
			results = vim.tbl_filter(function(item)
				-- NOTE(jlima): Plain substring check first, falling back to Lua pattern match
				local ok_pat, pat_match = pcall(string.match, item, exclude)
				return not item:find(exclude, 1, true) and not (ok_pat and pat_match ~= nil)
			end, results)
		end
	end

	return results
end

local function is_reusable_empty_buf()
	return vim.api.nvim_buf_get_name(0) == "" and not vim.bo.modified and vim.bo.buftype == ""
end

vim.api.nvim_create_user_command("F", function(opts_cmd)
	local target = vim.fn.fnameescape(opts_cmd.args)
	if is_reusable_empty_buf() then
		vim.cmd.edit(target)
	else
		vim.cmd.tabedit(target)
	end
end, {
	nargs = 1,
	complete = function(lead)
		return M.run_fd_filtered(lead, 100)
	end,
	desc = "Fast regex find: :F <pattern>!<exclude>",
})

vim.api.nvim_create_user_command("FT", function(opts_cmd)
	local files = M.run_fd_filtered(opts_cmd.args, nil)
	if #files == 0 then
		vim.notify("No files matched: " .. opts_cmd.args, vim.log.levels.WARN)
		return
	end

	local max_tabs = vim.o.tabpagemax
	if #files > max_tabs then
		local confirm =
			vim.fn.confirm(string.format("Found %d matches. Open first %d in tabs?", #files, max_tabs), "&Yes\n&No", 2)
		if confirm ~= 1 then
			return
		end
	end

	for i, file in ipairs(files) do
		if i > max_tabs then
			break
		end
		local target = vim.fn.fnameescape(file)
		if i == 1 and is_reusable_empty_buf() then
			vim.cmd.edit(target)
		else
			vim.cmd.tabedit(target)
		end
	end
end, {
	nargs = 1,
	complete = function(lead)
		return M.run_fd_filtered(lead, 50)
	end,
	desc = "Open all regex matches in separate tabs: :FT <pattern>!<exclude>",
})

vim.api.nvim_create_user_command("Rg", function(opts_cmd)
	-- NOTE(jlima): Translate unescaped pipe alternation into Vim/ripgrep regex OR syntax
	local pattern = opts_cmd.args:gsub("|", "\\|")
	vim.cmd("silent! grep! " .. pattern)
	vim.cmd.copen()
end, {
	nargs = "+",
	complete = "file",
	desc = "Run ripgrep via grepprg and open results in quickfix",
})

return M
