local nore = { noremap = true }
local silent = { noremap = true, silent = true }

vim.g.mapleader = " "

-- ctags completion

-- NOTE(jlima): Register <C-l> globally outside LspAttach so buffer word
-- fallback works when no LSP is running.
vim.keymap.set("i", "<C-l>", function()
	if vim.fn.pumvisible() == 1 then
		return "<C-y>"
	end
	local clients = vim.lsp.get_clients({
		bufnr = 0,
		method = "textDocument/completion",
	})
	return #clients > 0 and "<C-x><C-o>" or "<C-x><C-n>"
end, { expr = true, replace_keycodes = true, desc = "Smart Completion" })

vim.keymap.set("n", "<leader>q", function()
	vim.diagnostic.setqflist({ bufnr = 0 })
end, { desc = "Buffer LSP to Quickfix" })

vim.keymap.set("n", "<leader>nq", function()
	-- Get cursor position (0-indexed for API)
	local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1

	-- Fetch diagnostics for the current line
	local diagnostics = vim.diagnostic.get(0, { lnum = lnum })
	if #diagnostics == 0 then
		vim.notify("No diagnostics found on current line", vim.log.levels.WARN)
		return
	end

	-- Extract the rule ID (code) from the first diagnostic
	local rule_id = diagnostics[1].code
	if not rule_id then
		vim.notify("Diagnostic does not contain a rule ID", vim.log.levels.WARN)
		return
	end

	-- Get current line text
	local line = vim.api.nvim_get_current_line()

	-- Append logic: check if `# noqa` already exists to append vs create
	local new_line
	if line:match("# noqa:") then
		new_line = line .. " " .. rule_id
	elseif line:match("# noqa") then
		new_line = line:gsub("# noqa", "# noqa: " .. rule_id)
	else
		new_line = line .. " # noqa: " .. tostring(rule_id)
	end

	-- Set the updated line
	vim.api.nvim_set_current_line(new_line)

	-- Optional: trigger formatter or clear diagnostics temporarily
	vim.notify("Appended noqa for: " .. tostring(rule_id), vim.log.levels.INFO)
end, { desc = "Automate Ansible noqa appending" })

--- copy diagnostic
vim.keymap.set("n", "<leader>e", function()
	vim.diagnostic.open_float(nil, { focus = true })
end)

-- TODO(jlima): ctags search, we need to revisit this again with lsp integration
-- vim.keymap.set({ "n", "v" }, "<C-]>", "g<C-]>", nore)

-- shortcuts
vim.keymap.set("n", "vw", "viw", nore)
vim.keymap.set("n", "vp", "vip", nore)
vim.keymap.set("n", "vW", "viW", nore)
vim.keymap.set("n", "dW", "diW", nore)

-- copy paragraph
vim.keymap.set("n", "cp", "yap<S-}>p", nore)

vim.keymap.set({ "n", "x" }, ";", ":", nore)
vim.keymap.set("n", "Y", "y$", nore)
vim.keymap.set("n", "j", "gj", nore)
vim.keymap.set("n", "&", ":&&<CR>", nore)
vim.keymap.set("n", "k", "gk", nore)
vim.keymap.set("n", "<leader><leader>", "<cmd>set hlsearch!<CR>", silent)
vim.keymap.set("n", "<leader>a", "ggVG", silent)
vim.keymap.set("n", "<leader>n", "<cmd>e ~/notes.md<CR>", silent)
vim.keymap.set("n", "<C-w>q", "<C-w>c", nore)
vim.keymap.set("n", "<C-w><C-q>", "<C-w>c", nore)
vim.keymap.set("n", "<C-w><C-d>", "<C-w>d", nore)

-- Directional Search Swap
vim.keymap.set("i", "<C-r>", "<C-o>?", silent)
vim.keymap.set("i", "<C-s>", "<C-o>/", silent)
vim.keymap.set("i", "<C-w>", "<C-o>:write<cr>", silent)
vim.keymap.set("n", "<C-r>", "?", nore)
vim.keymap.set("n", "<C-s>", "/", nore)

-- Window Switching
vim.keymap.set("n", "<C-h>", "<C-w>h", silent)
vim.keymap.set("n", "<C-j>", "<C-w>j", silent)
vim.keymap.set("n", "<C-k>", "<C-w>k", silent)
vim.keymap.set("n", "<C-l>", "<C-w>l", silent)

-- Undo
vim.keymap.set("n", "U", "<c-r>", silent)

-- Tab Switching
local modes = { "n", "x" }
for i = 1, 8 do
	vim.keymap.set(modes, "<C-" .. i .. ">", i .. "gt")
end

-- Path lcd helper
local function trim_path(s)
	return #s < 50 and s or s:sub(-(#s / 2))
end

vim.keymap.set("n", "-", function()
	vim.cmd.lcd("%:p:h")
	-- print("new lcd: " .. trim_path(vim.fn.getcwd()))
	print("lcd: " .. trim_path(vim.fn.getcwd()))
end, silent)

-- NOTE(jlima): Bind Alt+Enter in insert mode to break the current line and open a new line below regardless of cursor position.
vim.keymap.set("i", "<M-CR>", "<C-o>o", { noremap = true, silent = true })
vim.keymap.set("i", "<S-M-CR>", "<C-o>O", { noremap = true, silent = true })

-- Deterministic Save Execution
local function safe_write()
	local b = vim.api.nvim_get_current_buf()
	if not vim.api.nvim_buf_is_valid(b) or vim.bo[b].buftype ~= "" then
		vim.notify("Invalid buffer type for write.", vim.log.levels.WARN)
		return
	end
	vim.cmd("write ++p")
end
vim.keymap.set("n", "<leader>w", safe_write, silent)
vim.keymap.set("n", "<M-w>", safe_write, silent)

-- Visual Editing & Clipboard
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", silent)
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", silent)
vim.keymap.set("v", ">", ">gv", silent)
vim.keymap.set("v", "<", "<gv", silent)
vim.keymap.set("x", "p", '"_dP', silent)
vim.keymap.set("x", "y", "ygv<Esc>", silent)
vim.keymap.set({ "n", "v" }, "<leader>y", '"+y', { noremap = true })
vim.keymap.set("n", "<leader>Y", '"+Y', { noremap = true })
vim.keymap.set({ "n", "v" }, "<leader>p", '"+p', { noremap = true })
vim.keymap.set({ "n", "v" }, "<leader>P", '"+P', { noremap = true })
vim.keymap.set("v", "<CR>", [[y/\V<C-r>=escape(@",'/\')<CR><CR>]], silent)

-- Backspace Auto-Pair Deletion
-- NOTE(jlima): Pre-encode keycodes at load time so replace_keycodes can be disabled on the hot path.
local bs_raw = vim.api.nvim_replace_termcodes("<BS>", true, false, true)
local bs_del_raw = vim.api.nvim_replace_termcodes("<BS><Del>", true, false, true)

-- NOTE(jlima): Map ASCII byte values directly to avoid string slicing and allocations per keystroke.
local pair_bytes = {
	[40] = 41, -- ( -> )
	[91] = 93, -- [ -> ]
	[123] = 125, -- { -> }
	[60] = 62, -- < -> >
	[39] = 39, -- ' -> '
	[34] = 34, -- " -> "
	[96] = 96, -- ` -> `
}

vim.keymap.set("i", "<BS>", function()
	local col = vim.api.nvim_win_get_cursor(0)[2]
	if col == 0 then
		return bs_raw
	end

	local line = vim.api.nvim_get_current_line()
	local prev_byte, next_byte = string.byte(line, col, col + 1)

	-- NOTE(jlima): Strictly deletes paired tokens only; nil next_byte at EOL safely evaluates to false.
	if pair_bytes[prev_byte] == next_byte and next_byte ~= nil then
		return bs_del_raw
	end
	return bs_raw
end, { expr = true, replace_keycodes = false, noremap = true })

-- Bracket Expansion with Auto-Close & Whitespace Precondition
local bracket_pair_map = { ["{"] = "}", ["("] = ")", ["["] = "]" }
vim.keymap.set("i", "<CR>", function()
	local col = vim.api.nvim_win_get_cursor(0)[2]
	if col > 0 then
		local line = vim.api.nvim_get_current_line()
		local prev_char = line:sub(col, col)
		local close_char = bracket_pair_map[prev_char]

		if close_char then
			-- NOTE(jlima): Invariant check: only expand if bracket is line-start or preceded by whitespace
			local before_open = col > 1 and line:sub(col - 1, col - 1) or ""
			if col == 1 or before_open == " " or before_open == "\t" then
				local next_char = line:sub(col + 1, col + 1)
				if next_char == close_char then
					return "<CR><C-o>O"
				end
				return close_char .. "<Left><CR><C-o>O"
			end
		end
	end
	return "<CR>"
end, { expr = true })

-- Emacs Insert Mode Navigation
vim.keymap.set("i", "<C-a>", "<C-o>^", silent)
vim.keymap.set("i", "<C-e>", "<End>", silent)
vim.keymap.set("i", "<C-b>", "<Left>", silent)
vim.keymap.set("i", "<C-f>", "<Right>", silent)
vim.keymap.set("i", "<C-p>", "<Up>", silent)
vim.keymap.set("i", "<C-n>", "<Down>", silent)
vim.keymap.set("i", "<M-b>", "<C-o>b", silent)
vim.keymap.set("i", "<M-f>", "<C-o>e<Right>", silent)
vim.keymap.set("i", "<M-a>", "<C-o>{", silent)
vim.keymap.set("i", "<M-e>", "<C-o>}", silent)
vim.keymap.set("i", "<C-d>", "<C-g>u<Del>", silent)
vim.keymap.set("i", "<C-h>", "<C-g>u<BS>", silent)
vim.keymap.set("i", "<C-k>", function()
	local _, col = unpack(vim.api.nvim_win_get_cursor(0))
	local line_len = #vim.api.nvim_get_current_line()
	return col >= line_len and "<C-g>u<Del>" or "<C-g>u<C-o>D"
end, { expr = true, replace_keycodes = true })
vim.keymap.set("i", "<C-u>", "<C-g>u<C-u>", silent)
-- vim.keymap.set("i", "<C-w>", "<C-g>u<C-w>", silent)
vim.keymap.set("i", "<M-d>", "<C-g>u<C-\\><C-o>dw", silent)
vim.keymap.set("i", "<M-BS>", "<C-g>u<C-w>", silent)
vim.keymap.set("i", "<C-BS>", "<C-g>u<C-w>", silent)
vim.keymap.set("i", "<C-y>", '<C-r>"', silent)
vim.keymap.set("i", "<C-S-e>", "<Esc>Go", silent)

-- Emacs Command-Line Mode
vim.keymap.set("c", "<C-a>", "<Home>", nore)
vim.keymap.set("c", "<C-e>", "<End>", nore)
vim.keymap.set("c", "<C-b>", "<Left>", nore)
-- disable this so that we can use completion in command mode
-- map("c", "<C-d>", "<Del>", nore)
vim.keymap.set("c", "<C-BS>", "<C-w>", nore)
vim.keymap.set("c", "<M-b>", "<S-Left>", nore)
vim.keymap.set("c", "<M-f>", "<S-Right>", nore)
vim.keymap.set("c", "<M-d>", "<S-Right><C-w>", nore)
vim.keymap.set("c", "<C-f>", function()
	return vim.fn.getcmdpos() > #vim.fn.getcmdline() and vim.o.cedit or "<Right>"
end, { expr = true, replace_keycodes = true })
vim.keymap.set("c", "<C-k>", function()
	return string.rep("<Del>", #vim.fn.getcmdline() - vim.fn.getcmdpos() + 1)
end, { expr = true, replace_keycodes = true })
vim.keymap.set("c", "<C-u>", function()
	return string.rep("<BS>", vim.fn.getcmdpos() - 1)
end, { expr = true, replace_keycodes = true })

-- Quickfix & Execution Maps
vim.keymap.set("n", "<M-m>", function()
	local save = vim.fn.winsaveview()
	vim.cmd("silent make!")
	vim.fn.winrestview(save)
	if vim.fn.getqflist({ size = 0 }).size > 0 then
		vim.cmd("copen")
		vim.cmd("wincmd p")
	else
		vim.cmd("cclose")
		print("Build complete..")
	end
end, silent)

vim.keymap.set("x", "@", function()
	return vim.fn.mode() == "V" and (":normal! @" .. vim.fn.getcharstr() .. "<CR>") or "@"
end, { expr = true })

vim.keymap.set("n", "<leader>te", function()
	local dir = vim.fn.expand("%:p:h")
	vim.fn.jobstart({ "alacritty", "--working-directory", dir }, { detach = true })
end, { desc = "Open Alacritty in current directory" })

-- Native VimL Utility Remaps & Abbreviations
vim.cmd([[
  nnoremap gm :lcd %:p:h<CR>:!git add %:t && git commit -m "<C-r>=expand('%:t')<CR>: "<Left>
  nnoremap <expr> gp '`[' . strpart(getregtype(), 0, 1) . '`]'
  inoremap <M-u> <Esc>gUiwea
  inoremap <M-l> <Esc>guiwea
  xnoremap & :<C-u>'<,'>s/\%V\v

  cnoreabbrev qq qa!
  cnoreabbrev mktags Mktags
  cnoreabbrev mt Mktags
  cabbrev <expr> w!! (getcmdtype() == ':' && getcmdline() == 'w!!') ? 'w !sudo tee > /dev/null %' : 'w!!'
  " cabbrev <expr> make (getcmdtype() ==# ':' && getcmdline() ==# 'make') ? 'silent update \| silent make! \| redraw!' : 'make'
]])

vim.keymap.set("v", "gh", function()
	-- NOTE(jlima): Temporarily use the 's' register to grab the visual selection without destroying the unnamed register
	local saved_reg = vim.fn.getreg("s")
	vim.cmd('normal! "sy')
	local text = vim.fn.getreg("s")
	vim.fn.setreg("s", saved_reg)

	-- NOTE(jlima): Prepend the current buffer's filetype to the query for better search context
	local filetype = vim.bo.filetype
	local query = filetype .. " " .. text

	-- NOTE(jlima): Replace newlines with spaces and URL-encode special characters for the web request
	local function urlencode(str)
		if str then
			str = str:gsub("\n", " ")
			str = str:gsub("([^%w _%%%-%.~])", function(c)
				return string.format("%%%02X", string.byte(c))
			end)
			str = str:gsub(" ", "+")
		end
		return str
	end

	local encoded_query = urlencode(query)
	local url = "https://www.google.com/search?q=" .. encoded_query

	-- NOTE(jlima): Utilize Neovim 0.10+ native URL opener (uses xdg-open on your Linux setups)
	vim.ui.open(url)
end, { desc = "Search Google for visual selection + filetype" })
