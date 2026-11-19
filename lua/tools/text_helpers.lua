local M = {}

vim.cmd([[
function! CopyMatches(reg)
  let hits = []
  %s//\=len(add(hits, submatch(0))) ? submatch(0) : ''/gne
  let reg = empty(a:reg) ? 'c' : a:reg
  execute 'let @'.reg.' = join(hits, "\n") . "\n"'
endfunction
command! -register Cm call CopyMatches(<q-reg>)

function! WrapSelection(left, right)
  let save_reg = @"
  " NOTE(jlima): '< jumps to the exact start line and column of the visual selection.
  normal! `<
  call search('\S', 'c')
  let start_pos = getpos('.')
  normal! `>
  let end_pos = getpos('.')

  call setpos('.', end_pos)
  execute "normal! a" . a:right
  call setpos('.', start_pos)
  execute "normal! i" . a:left
  let @" = save_reg
  startinsert
endfunction

xnoremap ' :<C-u>call WrapSelection("'", "'")<CR>
xnoremap ` :<C-u>call WrapSelection('`', '`')<CR>
xnoremap ( :<C-u>call WrapSelection('(', ')')<CR>
xnoremap [ :<C-u>call WrapSelection('[', ']')<CR>

function! DuplicateAndMark()
  let l:c = col('.')
  execute "normal! yyP"
  call cursor(line('.'), l:c)
  execute "normal! j"
  redraw
  echo "Mark set"
endfunction

inoremap <silent> <C-,> <C-o>:call DuplicateAndMark()<CR>
nnoremap <silent> <C-,> <cmd>call DuplicateAndMark()<CR>

function! Rg(args) abort
  let l:pattern = substitute(a:args, '|', '\\|', 'g')
  execute "silent! grep!" l:pattern
  copen
  redraw!
endfunction
command! -nargs=+ -complete=file Rg call Rg(<q-args>)
]])

-- NOTE(jlima): Native floating replacement for dressing.nvim's vim.ui.input.
-- mini.pick already overrides vim.ui.select when mini_pick.setup() runs.
vim.ui.input = function(opts, on_confirm)
	opts = opts or {}
	local prompt = opts.prompt or "Input: "
	local default = opts.default or ""

	-- Create an unlisted scratch buffer
	local buf = vim.api.nvim_create_buf(false, true)
	vim.bo[buf].bufhidden = "wipe"

	-- Calculate dynamic width with sensible bounds
	local min_width = 30
	local max_width = math.floor(vim.o.columns * 0.6)
	local width = math.min(max_width, math.max(min_width, #prompt + #default + 10))

	local win = vim.api.nvim_open_win(buf, true, {
		relative = "cursor",
		row = 1,
		col = 0,
		width = width,
		height = 1,
		style = "minimal",
		border = "rounded",
		title = " " .. vim.trim(prompt) .. " ",
		title_pos = "left",
	})

	-- Pre-fill default text (critical for LSP rename) and enter insert mode at EOL
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, { default })
	vim.cmd("startinsert!")

	local closed = false
	local function close(value)
		if closed then
			return
		end
		closed = true
		vim.cmd("stopinsert")
		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_close(win, true)
		end
		-- Defer callback so window focus returns to the original buffer first
		vim.schedule(function()
			on_confirm(value)
		end)
	end

	-- Confirm with <CR> in Insert or Normal mode
	for _, mode in ipairs({ "i", "n" }) do
		vim.keymap.set(mode, "<CR>", function()
			local line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] or ""
			close(line)
		end, { buffer = buf, silent = true })
	end

	-- Cancel with <Esc> (Normal) or <C-c> (Insert/Normal)
	vim.keymap.set("n", "<Esc>", function()
		close(nil)
	end, { buffer = buf, silent = true })

	vim.keymap.set({ "i", "n" }, "<C-c>", function()
		close(nil)
	end, { buffer = buf, silent = true })

	-- Handle external window closure (e.g., clicking outside in Neovide)
	vim.api.nvim_create_autocmd("BufLeave", {
		buffer = buf,
		once = true,
		callback = function()
			close(nil)
		end,
	})
end

return M
