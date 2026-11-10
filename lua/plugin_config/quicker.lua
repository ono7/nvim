local has_quicker, quicker = pcall(require, "quicker")
if not has_quicker then
	return
end

-- NOTE(jlima): Configure quickfix buffer ergonomics and context expansion.
quicker.setup({
	keys = {
		{
			">",
			function()
				quicker.expand({ before = 2, after = 2, add_to_existing = true })
			end,
			desc = "Expand quickfix context",
		},
		{
			"<",
			function()
				quicker.collapse()
			end,
			desc = "Collapse quickfix context",
		},
		{
			"<c-/>",
			"<cmd>cclose<CR>",
			desc = "Close quickfix window",
		},
	},
})
