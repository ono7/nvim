-- NOTE(jlima): Reset highlights and syntax state before applying explicit hex colorscheme.
vim.cmd("hi clear")
if vim.fn.exists("syntax_on") == 1 then
	vim.cmd("syntax reset")
end
vim.o.termguicolors = true
vim.o.background = "dark"
vim.g.colors_name = "google-dark-minimal"

-- NOTE(jlima): Core palette mapped to specific RGB requirements.
-- local bg = "#2C2E35"
-- local fg = "#C8CCD4"
-- local green = "#81C995"
-- local green = "#99b456"
-- local green = "#a4bb68"
-- local green = "#97b252"
local bg_subtle = "#252932"
-- local bg = "#1E2229" -- works good but one below is slightly better
local bg = "#1D2129"

local fg = "#D8DBE1"
local yellow = "#D4B976" -- NOTE(jlima): matches desaturated earthy tone and luminance of the green
-- local orange = "#CD916A"
-- local green = "#aec379"
local green = "#A3BE8C"
local orange = "#FA903E"
local purple = "#C58AF9"
local cmt = "#7F8996"
local bg_light = "#363840"
local bg_visual = "#42444D"
local gray = "#A7A9B2"
-- local gray_dim = "#515A7B"
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
vim.g.terminal_color_3 = yellow
vim.g.terminal_color_4 = blue
vim.g.terminal_color_5 = purple
vim.g.terminal_color_6 = "#78D9EC"
vim.g.terminal_color_7 = fg
vim.g.terminal_color_8 = gray
vim.g.terminal_color_9 = red
vim.g.terminal_color_10 = green
vim.g.terminal_color_11 = yellow
vim.g.terminal_color_12 = blue
vim.g.terminal_color_13 = purple
vim.g.terminal_color_14 = "#78D9EC"
vim.g.terminal_color_15 = fg

-- NOTE(jlima): Apply strict monochrome mapping with explicit callouts for strings, numbers, and core keywords.
local hl_groups = {
	Normal = { fg = fg, bg = bg },
	NormalFloat = { fg = fg, bg = "none" },
	FloatBorder = { fg = bg_light, bg = "none" },
	Visual = { bg = bg_visual },
	CursorLine = { bg = bg_light },
	LineNr = { fg = gray, bg = bg },
	CursorLineNr = { fg = yellow, bg = bg_light, bold = true },
	SignColumn = { bg = "none" },
	WinSeparator = { fg = gray, bg = "none" },
	StatusLine = { fg = fg, bg = bg_light },
	StatusLineNC = { fg = gray, bg = bg_subtle },
	Search = { fg = bg, bg = yellow },
	CurSearch = { fg = bg, bg = purple, bold = false },
	MatchParen = { fg = bg, bg = purple, bold = false },

	Comment = { fg = cmt, italic = true },
	Constant = { fg = fg },
	ModeMsg = { fg = fg },
	String = { fg = green },
	Number = { fg = purple },
	Float = { fg = purple },
	Identifier = { fg = fg },
	Statement = { fg = yellow, bold = true },
	Keyword = { fg = yellow, bold = true },
	Operator = { fg = fg },
	Delimiter = { fg = fg },
	Special = { fg = fg },
	PreProc = { fg = fg },

	Type = { fg = fg },
	Function = { fg = fg },

	["@type"] = { fg = red },
	["@type.builtin"] = { fg = red },
	["@number"] = { fg = red },
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

	["@float"] = { fg = red },
	["@string"] = { fg = green },
	["@string.special"] = { fg = green },

	["@keyword"] = { fg = yellow, bold = true },
	["@keyword.type"] = { fg = yellow, bold = true },
	["@keyword.operator"] = { fg = yellow, bold = true },
	["@keyword.modifier"] = { fg = yellow, bold = true },
	["@keyword.function"] = { fg = yellow, bold = true },
	["@keyword.return"] = { fg = yellow, bold = true },
	["@keyword.conditional"] = { fg = yellow, bold = true },
	["@keyword.repeat"] = { fg = yellow, bold = true },

	Pmenu = { fg = fg, bg = bg_light },
	PmenuSel = { fg = bg, bg = yellow, bold = true },
	PmenuThumb = { bg = gray },

	DiagnosticError = { fg = red },
	DiagnosticWarn = { fg = orange },
	DiagnosticInfo = { fg = blue },
	DiagnosticHint = { fg = fg },

	MiniPickNormal = { fg = fg, bg = bg },
	MiniPickBorder = { fg = gray, bg = bg },
	MiniPickMatchRanges = { fg = yellow, bold = true },
	MiniPickMatchCurrent = { bg = bg_visual },

	DiffAdd = { fg = green, bg = "none" },
	DiffText = { fg = bg, bg = yellow },
	DiffDelete = { fg = red, bg = "none" },
	DiffChange = { bg = bg_light },
	Folded = { fg = gray, bg = bg_light },
	FoldColumn = { fg = gray, bg = "none" },
}

for group, spec in pairs(hl_groups) do
	vim.api.nvim_set_hl(0, group, spec)
end
