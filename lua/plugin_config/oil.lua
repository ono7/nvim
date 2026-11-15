local has_oil, oil = pcall(require, "oil")
if not has_oil then
	return
end

-- NOTE(jlima): Buffer-based directory editor with immediate edits and hidden file visibility.
oil.setup({
	skip_confirm_for_simple_edits = true,
	view_options = {
		show_hidden = true,
	},

	keymaps = {
		["<C-p>"] = false,
		["<C-h>"] = false,
		-- 2. Explicit Tab binding (<C-t>)
		["<C-t>"] = { "actions.select", opts = { tab = true }, desc = "Open in new tab" },

		-- 3. Splits
		["<C-v>"] = { "actions.select", opts = { vertical = true }, desc = "Open in vertical split" },
		["<M-s>"] = { "actions.select", opts = { horizontal = true }, desc = "Open in horizontal split" },

		["<C-/>"] = "actions.close",
	},
})

vim.keymap.set("n", "<c-\\>", "<CMD>Oil<CR>", { noremap = true, silent = true, desc = "Open Oil file browser" })
