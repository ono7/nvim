-- NOTE(jlima): Reset highlights and syntax state before applying explicit hex colorscheme.
vim.cmd("hi clear")
if vim.fn.exists("syntax_on") == 1 then
	vim.cmd("syntax reset")
end
vim.o.termguicolors = true
vim.o.background = "dark"
vim.g.colors_name = "google-dark-minimal"

-- NOTE(jlima): Core palette mapped to specific RGB requirements.
local bg = "#2C2E35"
local fg = "#EEF0FF"
local green = "#81C995"
local orange = "#FA903E"
local purple = "#C58AF9"
local cmt = "#9AA0A6"

-- NOTE(jlima): Complementary UI and terminal shades harmonized with the background.
local bg_light = "#363840"
local bg_visual = "#42444D"
local gray = "#A7A9B2"
local gray_dim = "#515A7B"
local red = "#F28B82"
local blue = "#8AB4F8"

if vim.g.neovide then
	-- NOTE(jlima): Enforce absolute opacity (FF) to block the OS compositor from
	-- gamma-shifting the background.
	-- this results in accurate colors being renderede by neovide
	vim.g.neovide_background_color = bg .. "FF"
end

-- NOTE(jlima): Map ANSI terminal colors to complementary palette for integrated shells.
vim.g.terminal_color_0 = bg
vim.g.terminal_color_1 = red
vim.g.terminal_color_2 = green
vim.g.terminal_color_3 = orange
vim.g.terminal_color_4 = blue
vim.g.terminal_color_5 = purple
vim.g.terminal_color_6 = "#78D9EC"
vim.g.terminal_color_7 = fg
vim.g.terminal_color_8 = gray
vim.g.terminal_color_9 = red
vim.g.terminal_color_10 = green
vim.g.terminal_color_11 = orange
vim.g.terminal_color_12 = blue
vim.g.terminal_color_13 = purple
vim.g.terminal_color_14 = "#78D9EC"
vim.g.terminal_color_15 = fg

-- NOTE(jlima): Apply strict monochrome mapping with explicit callouts for strings, numbers, and core keywords.
local hl_groups = {
	Normal = { fg = fg, bg = bg },
	NormalFloat = { fg = fg, bg = bg_light },
	FloatBorder = { fg = gray, bg = bg_light },
	Visual = { bg = bg_visual },
	CursorLine = { bg = bg_light },
	LineNr = { fg = gray, bg = bg },
	CursorLineNr = { fg = purple, bg = bg_light, bold = false },
	SignColumn = { bg = "none" },
	WinSeparator = { fg = gray, bg = "none" },
	StatusLine = { fg = fg, bg = bg_light },
	StatusLineNC = { fg = gray, bg = bg },
	Search = { fg = bg, bg = purple },
	CurSearch = { fg = bg, bg = purple, bold = false },
	MatchParen = { fg = bg, bg = purple, bold = false },

	Comment = { fg = cmt, italic = true },
	Constant = { fg = fg },
	ModeMsg = { fg = fg },
	String = { fg = green },
	Number = { fg = orange },
	Float = { fg = orange },
	Identifier = { fg = fg },
	Statement = { fg = purple, bold = false },
	Keyword = { fg = purple, bold = false },
	Operator = { fg = fg },
	Delimiter = { fg = fg },
	Special = { fg = fg },
	PreProc = { fg = fg },

	Type = { fg = fg },
	Function = { fg = fg },

	["@type"] = { fg = fg },
	["@type.builtin"] = { fg = purple },
	["@function"] = { fg = fg },
	["@function.call"] = { fg = fg },
	["@function.builtin"] = { fg = fg },
	["@variable"] = { fg = fg },
	["@variable.parameter"] = { fg = fg },
	["@variable.builtin"] = { fg = fg },
	["@property"] = { fg = fg },
	["@punctuation"] = { fg = fg },
	["@operator"] = { fg = fg },
	["@preproc"] = { fg = fg },
	["@module"] = { fg = fg },

	["@number"] = { fg = orange },
	["@float"] = { fg = orange },
	["@string"] = { fg = green },
	["@string.special"] = { fg = green },

	["@keyword"] = { fg = purple },
	["@keyword.type"] = { fg = purple, bold = false },
	["@keyword.operator"] = { fg = purple, bold = false },
	["@keyword.modifier"] = { fg = purple, bold = false },
	["@keyword.function"] = { fg = purple, bold = false },
	["@keyword.return"] = { fg = purple, bold = false },
	["@keyword.conditional"] = { fg = purple, bold = false },
	["@keyword.repeat"] = { fg = purple, bold = false },

	Pmenu = { fg = fg, bg = bg_light },
	PmenuSel = { fg = bg, bg = purple, bold = false },
	PmenuThumb = { bg = gray },

	DiagnosticError = { fg = red },
	DiagnosticWarn = { fg = orange },
	DiagnosticInfo = { fg = blue },
	DiagnosticHint = { fg = fg },

	MiniPickNormal = { fg = fg, bg = bg },
	MiniPickBorder = { fg = gray, bg = bg },
	MiniPickMatchRanges = { fg = purple, bold = false },
	MiniPickMatchCurrent = { bg = bg_visual },

	DiffAdd = { fg = green, bg = "none" },
	DiffText = { fg = bg, bg = purple },
	DiffDelete = { fg = red, bg = "none" },
	DiffChange = { bg = bg_light },
	Folded = { fg = gray, bg = bg_light },
	FoldColumn = { fg = gray, bg = "none" },
}

for group, spec in pairs(hl_groups) do
	vim.api.nvim_set_hl(0, group, spec)
end
