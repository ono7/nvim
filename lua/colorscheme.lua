-- NOTE(jlima): Reset highlights and syntax state before applying explicit hex colorscheme.
vim.cmd("hi clear")
if vim.fn.exists("syntax_on") == 1 then
	vim.cmd("syntax reset")
end
vim.o.termguicolors = true
vim.o.background = "dark"
vim.g.colors_name = "gruber-darker-minimal"

-- NOTE(jlima): Adjusted Gruber Darker hex values mapping to the desaturated amber accent and updated olive green.
local bg = "#181818"
local fg = "#d4d4d4"
local green = "#95B04F"
local yellow = "#f6e281"
local cmt = "#C89863"
local gray = "#949bb0"
local gray_dim = "#A3AEAC"

-- NOTE(jlima): Earthy red and muted steel blue harmonies replacing raw ANSI digital values.
local red = "#D46A60"
local red_bright = "#E07A70"
local blue = "#6C99BB"
local blue_bright = "#82ADCF"

if vim.g.neovide then
	vim.g.neovide_background_color = bg
end

-- NOTE(jlima): Map ANSI terminal colors to the authentic palette.
vim.g.terminal_color_0 = bg
vim.g.terminal_color_1 = red
vim.g.terminal_color_2 = green
vim.g.terminal_color_3 = yellow
vim.g.terminal_color_4 = blue
vim.g.terminal_color_5 = "#9e95c7"
vim.g.terminal_color_6 = "#95a99f"
vim.g.terminal_color_7 = fg
vim.g.terminal_color_8 = gray
vim.g.terminal_color_9 = red_bright
vim.g.terminal_color_10 = green
vim.g.terminal_color_11 = yellow
vim.g.terminal_color_12 = blue_bright
vim.g.terminal_color_13 = "#9e95c7"
vim.g.terminal_color_14 = "#95a99f"
vim.g.terminal_color_15 = "#ffffff"

-- NOTE(jlima): Apply strict monochrome mapping based on reference image. Types, functions, and preprocessors are neutralized to foreground.
local hl_groups = {
	Normal = { fg = fg, bg = bg },
	NormalFloat = { fg = fg, bg = bg },
	FloatBorder = { fg = gray, bg = bg },
	Visual = { bg = "#453d41" },
	CursorLine = { bg = "#282828" },
	LineNr = { fg = gray, bg = bg },
	CursorLineNr = { fg = yellow, bg = "#282828", bold = true },
	SignColumn = { bg = "none" },
	WinSeparator = { fg = gray, bg = "none" },
	StatusLine = { fg = fg, bg = "#282828" },
	StatusLineNC = { fg = gray, bg = bg },
	Search = { fg = bg, bg = yellow },
	CurSearch = { fg = bg, bg = yellow, bold = true },
	MatchParen = { fg = bg, bg = yellow, bold = true },

	Comment = { fg = cmt, italic = true },
	Constant = { fg = fg },
	ModeMsg = { fg = fg },
	String = { fg = green },
	Identifier = { fg = fg },
	Statement = { fg = yellow, bold = true },
	Keyword = { fg = yellow, bold = true },
	Operator = { fg = fg },
	Delimiter = { fg = fg },
	Special = { fg = fg },
	PreProc = { fg = fg },

	-- NOTE(jlima): Strip colors from standard groups to match screenshot minimalism.
	Type = { fg = fg },
	Function = { fg = fg },

	-- NOTE(jlima): Tree-sitter specific overrides to enforce monochrome behavior on AST nodes.
	["@type"] = { fg = fg },
	["@type.builtin"] = { fg = gray_dim },
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

	-- NOTE(jlima): Explicitly target struct, typedef, sizeof, and string includes to match the yellow and green accents.
	["@keyword"] = { fg = gray_dim },
	["@keyword.type"] = { fg = yellow, bold = true },
	["@keyword.operator"] = { fg = yellow, bold = true },
	["@keyword.modifier"] = { fg = yellow, bold = true },
	["@keyword.function"] = { fg = yellow, bold = true },
	["@keyword.return"] = { fg = yellow, bold = true },
	["@keyword.conditional"] = { fg = yellow, bold = true },
	["@keyword.repeat"] = { fg = yellow, bold = true },
	["@string"] = { fg = green },
	["@string.special"] = { fg = green },

	Pmenu = { fg = fg, bg = "#282828" },
	PmenuSel = { fg = bg, bg = yellow, bold = true },
	PmenuThumb = { bg = gray },

	DiagnosticError = { fg = red },
	DiagnosticWarn = { fg = yellow },
	DiagnosticInfo = { fg = fg },
	DiagnosticHint = { fg = fg },

	MiniPickNormal = { fg = fg, bg = bg },
	MiniPickBorder = { fg = gray, bg = bg },
	MiniPickMatchRanges = { fg = yellow, bold = true },
	MiniPickMatchCurrent = { bg = "#453d41" },

	DiffAdd = { fg = green, bg = "none" },
	DiffText = { fg = bg, bg = yellow },
	DiffDelete = { fg = red, bg = "none" },
	DiffChange = { bg = "#282828" },
	Folded = { fg = gray, bg = bg },
	FoldColumn = { fg = gray, bg = "none" },
}

for group, spec in pairs(hl_groups) do
	vim.api.nvim_set_hl(0, group, spec)
end
