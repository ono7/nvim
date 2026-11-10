-- NOTE(jlima): Fugitive Git status and staging shortcuts.
vim.keymap.set("n", "<leader>gs", "<cmd>Git<CR>", { noremap = true, silent = true, desc = "Git status" })
vim.keymap.set("n", "<leader>gd", "<cmd>Gdiffsplit<CR>", { noremap = true, silent = true, desc = "Git diff split" })
vim.keymap.set("n", "<leader>gb", "<cmd>Git blame<CR>", { noremap = true, silent = true, desc = "Git blame" })
