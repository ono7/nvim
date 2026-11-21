local M = {}

local term_group = vim.api.nvim_create_augroup("TerminalDrawerAutoCmds", { clear = true })
local tab_state = {}
local term_size = 12

local function get_normal_wins()
	return vim.tbl_filter(function(win)
		return vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_config(win).relative == ""
	end, vim.api.nvim_tabpage_list_wins(0))
end

local function get_tab_state(tab)
	tab = tab or vim.api.nvim_get_current_tabpage()
	if not tab_state[tab] then
		tab_state[tab] = {
			buf = nil,
			win = nil,
			job = nil,
			last_win = nil,
			last_cursor = nil,
			height = term_size,
			cwd = nil,
		}
	end
	return tab_state[tab]
end

local function close_quickfix()
	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		if vim.fn.win_gettype(win) == "quickfix" then
			pcall(vim.api.nvim_win_close, win, true)
		end
	end
end

function M.toggle_maximize()
	-- NOTE(jlima): If already in a maximized zoom tab, close the zoom tab to return to the parent layout.
	if vim.t.maximized_win then
		if vim.api.nvim_tabpage_is_valid(vim.t.maximized_tab) and #vim.api.nvim_list_tabpages() > 1 then
			vim.cmd("tabclose")
		end
		return
	end

	local cur_win = vim.api.nvim_get_current_win()
	local parent_tab = vim.api.nvim_get_current_tabpage()
	vim.cmd("tab split")
	vim.t.maximized_win = cur_win
	vim.t.maximized_tab = vim.api.nvim_get_current_tabpage()
	vim.t.parent_tab = parent_tab
end

function M.hide_transients()
	-- NOTE(jlima): If hiding transients while zoomed into a maximized terminal tab, collapse the zoom tab first.
	if vim.t.maximized_win and vim.bo.buftype == "terminal" and #vim.api.nvim_list_tabpages() > 1 then
		vim.cmd("tabclose")
	end

	local state = get_tab_state()
	local closed_terminal = false

	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		if vim.api.nvim_win_is_valid(win) then
			local b = vim.api.nvim_win_get_buf(win)
			local ft = vim.bo[b].filetype
			local bt = vim.bo[b].buftype
			local wt = vim.fn.win_gettype(win)

			if bt == "terminal" or wt == "quickfix" or ft == "fugitive" or ft == "oil" then
				if #get_normal_wins() > 1 then
					if bt == "terminal" then
						state.height = vim.api.nvim_win_get_height(win)
						closed_terminal = true
					end
					pcall(vim.api.nvim_win_hide, win)
				end
			end
		end
	end

	if closed_terminal and state.last_win and vim.api.nvim_win_is_valid(state.last_win) then
		vim.api.nvim_set_current_win(state.last_win)
	end
end

vim.api.nvim_create_autocmd("TabClosed", {
	group = term_group,
	callback = function()
		local valid_tabs = vim.api.nvim_list_tabpages()
		local valid_set = {}
		for _, t in ipairs(valid_tabs) do
			valid_set[t] = true
		end

		for tab_id, state in pairs(tab_state) do
			if not valid_set[tab_id] then
				if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
					vim.api.nvim_buf_delete(state.buf, { force = true })
				end
				tab_state[tab_id] = nil
			end
		end
	end,
})

-- Terminal Drawer (:T)
vim.api.nvim_create_user_command("T", function(opts_args)
	local cmd = opts_args.args
	local focus_insert = opts_args.bang

	-- NOTE(jlima): If invoked from a maximized terminal tab with no command payload, collapse the zoom tab
	-- AND hide the drawer in the parent tab so <M-t> acts as a true toggle.
	if vim.t.maximized_win and vim.bo.buftype == "terminal" and #vim.api.nvim_list_tabpages() > 1 then
		local parent_tab = vim.t.parent_tab
		vim.cmd("tabclose")
		if cmd == "" and parent_tab and vim.api.nvim_tabpage_is_valid(parent_tab) then
			local parent_state = get_tab_state(parent_tab)
			for _, win in ipairs(vim.api.nvim_tabpage_list_wins(parent_tab)) do
				if vim.api.nvim_win_get_buf(win) == parent_state.buf and #get_normal_wins() > 1 then
					parent_state.height = vim.api.nvim_win_get_height(win)
					pcall(vim.api.nvim_win_hide, win)
					if parent_state.last_win and vim.api.nvim_win_is_valid(parent_state.last_win) then
						vim.api.nvim_set_current_win(parent_state.last_win)
					end
					break
				end
			end
			return
		end
	end

	local state = get_tab_state()
	close_quickfix()

	local function save_editor_pos()
		local cur_win = vim.api.nvim_get_current_win()
		local cur_buf = vim.api.nvim_win_get_buf(cur_win)
		-- NOTE(jlima): Never record terminal window itself as last editor pos
		if vim.bo[cur_buf].buftype ~= "terminal" then
			state.last_win = cur_win
			state.last_cursor = vim.api.nvim_win_get_cursor(0)
		end
	end

	local function restore_editor_pos()
		if state.last_win and vim.api.nvim_win_is_valid(state.last_win) then
			vim.api.nvim_set_current_win(state.last_win)
			if state.last_cursor then
				pcall(vim.api.nvim_win_set_cursor, state.last_win, state.last_cursor)
			end
		end
	end

	local function focus_terminal()
		if state.win and vim.api.nvim_win_is_valid(state.win) then
			vim.api.nvim_set_current_win(state.win)
			vim.cmd("startinsert")
		end
	end

	local function send_terminal_cmd(job, payload, delay_ms)
		if not payload or payload == "" then
			return
		end
		local delay = delay_ms or 50
		-- NOTE(jlima): Ctrl-C kills active foreground jobs, Ctrl-U purges buffered readline input
		vim.fn.chansend(job, "\x03\x15")
		vim.defer_fn(function()
			if pcall(vim.fn.jobwait, { job }, 0) and vim.fn.jobwait({ job }, 0)[1] == -1 then
				vim.fn.chansend(job, payload .. "\n")
			end
		end, delay)
	end

	local is_alive = state.buf
		and vim.api.nvim_buf_is_valid(state.buf)
		and state.job
		and pcall(vim.fn.jobwait, { state.job }, 0)
		and vim.fn.jobwait({ state.job }, 0)[1] == -1

	-- NOTE(jlima): Resolve file directory strictly from standard file buffers to avoid term:// URI pollution
	local cur_buf = vim.api.nvim_get_current_buf()
	local is_term_buf = vim.bo[cur_buf].buftype == "terminal"
	local current_dir = nil

	if not is_term_buf then
		local current_file = vim.api.nvim_buf_get_name(cur_buf)
		if current_file ~= "" and not current_file:match("^%a+://") then
			current_dir = vim.fs.dirname(current_file)
		elseif vim.bo[cur_buf].filetype == "oil" then
			-- NOTE(jlima): Extract real filesystem path when invoking terminal from an oil.nvim buffer
			current_dir = current_file:gsub("^oil://", "")
		end
	end

	-- NOTE(jlima): Always fall back to live Neovim CWD (vim.fn.getcwd()) rather than cached state.cwd
	-- so unnamed buffers track :cd / :tcd changes instead of sticking to an initial or $HOME directory.
	if not current_dir or current_dir == "" then
		current_dir = vim.fn.getcwd()
	end

	if not is_alive then
		if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
			pcall(vim.api.nvim_buf_delete, state.buf, { force = true })
		end

		save_editor_pos()
		vim.opt_local.winbar = nil
		vim.cmd("botright split")
		vim.wo.winfixheight = true
		vim.cmd("resize " .. state.height)
		vim.cmd("enew")

		state.buf = vim.api.nvim_get_current_buf()
		state.win = vim.api.nvim_get_current_win()
		state.cwd = current_dir
		vim.wo.statusline = "%#Normal# "

		state.job = vim.fn.jobstart(vim.o.shell, {
			term = true,
			cwd = current_dir,
		})

		if cmd ~= "" then
			-- NOTE(jlima): Allow shell startup and direnv initialization to finish before submitting payload
			vim.defer_fn(function()
				if pcall(vim.fn.jobwait, { state.job }, 0) and vim.fn.jobwait({ state.job }, 0)[1] == -1 then
					vim.fn.chansend(state.job, cmd .. "\n")
				end
			end, 150)

			if focus_insert then
				vim.cmd("startinsert")
			else
				restore_editor_pos()
			end
		else
			vim.cmd("startinsert")
		end
		return
	end

	-- NOTE(jlima): Sync directory only when switching from an actual editor buffer in a different directory
	if not is_term_buf and state.cwd ~= current_dir then
		state.cwd = current_dir
		vim.fn.chansend(state.job, "\x15cd " .. vim.fn.shellescape(current_dir) .. "\n")
	end

	local visible_win = nil
	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		if vim.api.nvim_win_get_buf(win) == state.buf then
			visible_win = win
			break
		end
	end

	if visible_win then
		state.win = visible_win
		state.height = vim.api.nvim_win_get_height(visible_win)
		if cmd == "" then
			if #get_normal_wins() > 1 then
				pcall(vim.api.nvim_win_hide, visible_win)
			else
				vim.cmd("enew")
			end
			restore_editor_pos()
			return
		end

		send_terminal_cmd(state.job, cmd)
		if focus_insert then
			focus_terminal()
		end
		return
	end

	save_editor_pos()
	vim.cmd("botright split")
	vim.wo.winfixheight = true
	vim.cmd("resize " .. state.height)
	vim.api.nvim_win_set_buf(0, state.buf)
	state.win = vim.api.nvim_get_current_win()
	vim.wo.statusline = "%#Normal# "

	if cmd ~= "" then
		send_terminal_cmd(state.job, cmd)
		if focus_insert then
			focus_terminal()
		else
			restore_editor_pos()
		end
	else
		vim.cmd("startinsert")
	end
end, { nargs = "*", bang = true })

-- Transient & Maximize Keymaps
local map = vim.keymap.set
local silent = { noremap = true, silent = true }

map("n", "<M-t>", "<cmd>T<CR>", silent)
map("t", "<c-x>", [[<c-\><c-n>]], silent)
map("t", "<M-t>", [[<c-\><c-n><cmd>T<CR>]], silent)

map("n", "<M-y>", M.toggle_maximize, { silent = true, desc = "Toggle maximize current window" })
map("t", "<M-y>", function()
	-- NOTE(jlima): Escape terminal mode to run window command deterministically.
	vim.cmd([[stopinsert]])
	M.toggle_maximize()
end, { silent = true, desc = "Toggle maximize current terminal window" })

map("n", "<C-/>", M.hide_transients, silent)
map("n", "<C-_>", M.hide_transients, silent)
map("t", "<C-/>", function()
	M.hide_transients()
	vim.cmd("stopinsert")
end, silent)
map("t", "<C-_>", function()
	M.hide_transients()
	vim.cmd("stopinsert")
end, silent)

-- Quickfix Toggle
map("n", "<leader>q", function()
	local qf_exists = false
	for _, win in pairs(vim.fn.getwininfo()) do
		if win["quickfix"] == 1 then
			qf_exists = true
			break
		end
	end
	vim.cmd(qf_exists and "cclose" or "copen")
end, { noremap = true, silent = true, desc = "Toggle quickfix window" })

return M
