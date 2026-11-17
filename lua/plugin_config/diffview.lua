-- lua/plugins/diffview.lua (or wherever you source plugin configs)
local has_diffview, diffview = pcall(require, "diffview")
if not has_diffview then
	return
end

-- NOTE(jlima): Require diffview.actions only after confirming diffview is on runtimepath.
local actions = require("diffview.actions")

diffview.setup({
	enhanced_diff_hl = true,
	view = {
		merge_tool = {
			layout = "diff3_mixed",
		},
	},
	keymaps = {
		merge_tool = {
			{ "n", "co", actions.conflict_choose("ours"), { desc = "Choose OURS" } },
			{ "n", "ct", actions.conflict_choose("theirs"), { desc = "Choose THEIRS" } },
			{ "n", "ca", actions.conflict_choose("all"), { desc = "Choose ALL" } },
			{ "n", "dx", actions.conflict_choose("none"), { desc = "Choose NONE" } },
			{ "n", "1", actions.conflict_choose("ours"), { desc = "Choose OURS" } },
			{ "n", "2", actions.conflict_choose("theirs"), { desc = "Choose THEIRS" } },
		},
	},
})

-- NOTE(jlima): Replaces lazy.nvim's `keys` table; native :Diffview* commands are registered automatically by diffview's plugin/ directory on rtp.
vim.keymap.set("n", "<leader>do", "<cmd>DiffviewOpen<cr>", { desc = "Diffview Open" })
vim.keymap.set("n", "<leader>dc", "<cmd>DiffviewClose<cr>", { desc = "Diffview Close" })
