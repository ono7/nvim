local M = {}

function M.run_fd_filtered(input, max_results)
	local parts = vim.split(input, "!", { plain = true })
	local pattern = parts[1] ~= "" and parts[1] or ".*"
	local limit_flag = max_results and string.format("--max-results %d", max_results) or ""
	local cmd = string.format("fd --type f --hidden --exclude .git -p %s %s", limit_flag, vim.fn.shellescape(pattern))
	local results = vim.fn.systemlist(cmd)

	for i = 2, #parts do
		local exclude = parts[i]
		if exclude ~= "" then
			results = vim.tbl_filter(function(item)
				return not item:find(exclude, 1, true) and not item:match(exclude)
			end, results)
		end
	end
	return results
end

vim.api.nvim_create_user_command("F", function(opts_cmd)
	local is_empty = vim.api.nvim_buf_get_name(0) == "" and not vim.bo.modified and vim.bo.buftype == ""
	if is_empty then
		vim.cmd.edit(vim.fn.fnameescape(opts_cmd.args))
	else
		vim.cmd.tabedit(vim.fn.fnameescape(opts_cmd.args))
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
		local is_empty = i == 1 and vim.api.nvim_buf_get_name(0) == "" and not vim.bo.modified and vim.bo.buftype == ""
		if is_empty then
			vim.cmd.edit(vim.fn.fnameescape(file))
		else
			vim.cmd.tabedit(vim.fn.fnameescape(file))
		end
	end
end, {
	nargs = 1,
	complete = function(lead)
		return M.run_fd_filtered(lead, 50)
	end,
	desc = "Open all regex matches in separate tabs: :FT <pattern>!<exclude>",
})

return M
