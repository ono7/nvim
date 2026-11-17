-- NOTE(jlima): Scope <C-x> strictly to the active gitcommit buffer so built-in
-- <C-x> behavior (number decrement in Normal mode, completion in Insert mode)
-- remains intact in all other buffers.
local opts = { buffer = true, silent = true, desc = "Save and close git commit message" }

-- Normal mode: write and close immediately
vim.keymap.set("n", "<C-x>", "<Cmd>x<CR>", opts)

-- Insert mode: exit insert mode first, then write and close
vim.keymap.set("i", "<C-x>", "<Esc><Cmd>x<CR>", opts)
