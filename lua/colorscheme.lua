-- NOTE(jlima): Reset highlights and syntax state before applying graphite-slate palette.
vim.cmd("hi clear")
if vim.fn.exists("syntax_on") == 1 then
	vim.cmd("syntax reset")
end
vim.o.termguicolors = true
vim.o.background = "dark"
vim.g.colors_name = "custom-paper-minimal"

-- NOTE(jlima): Use neutral-cool graphite (#1E2229) and platinum-white (#DCE1E8) to stop iris muscle burn without brown undertones.
local bg = "#1E2229"
local fg = "#DCE1E8"
local fn_col = "#E56B73"
local type_col = "#61AFEF"
local comment = "#7F8996"
local visual = "#323844"
local hl = "#262B34"
local line_nr = "#5C6573"
local border = "#4B5362"

if vim.g.neovide then
	vim.g.neovide_background_color = bg
end

-- NOTE(jlima): Map ANSI terminal colors to clean, cool-toned pigments matched to #1E2229.
vim.g.terminal_color_0 = "#1E2229"
vim.g.terminal_color_1 = "#E56B73"
vim.g.terminal_color_2 = "#7EC699"
vim.g.terminal_color_3 = "#E5C07B"
vim.g.terminal_color_4 = "#61AFEF"
vim.g.terminal_color_5 = "#C678DD"
vim.g.terminal_color_6 = "#56B6C2"
vim.g.terminal_color_7 = "#DCE1E8"
vim.g.terminal_color_8 = "#7F8996"
vim.g.terminal_color_9 = "#F08088"
vim.g.terminal_color_10 = "#98D4AF"
vim.g.terminal_color_11 = "#EDD096"
vim.g.terminal_color_12 = "#7CC0F5"
vim.g.terminal_color_13 = "#D494E6"
vim.g.terminal_color_14 = "#73C6D1"
vim.g.terminal_color_15 = "#ECEFF4"

-- NOTE(jlima): Align floating window backgrounds to the main canvas and rely exclusively on borders for separation.
local hl_groups = {
	Normal = { fg = fg, bg = bg },
	NormalFloat = { fg = fg, bg = bg },
	FloatBorder = { fg = border, bg = bg },
	Visual = { bg = visual },
	CursorLine = { bg = hl },
	LineNr = { fg = line_nr, bg = bg },
	CursorLineNr = { fg = type_col, bg = hl, bold = true },
	SignColumn = { bg = "none" },
	WinSeparator = { fg = border, bg = "none" },
	StatusLine = { fg = fg, bg = "#2A303B" },
	StatusLineNC = { fg = comment, bg = "#232831" },
	Search = { fg = bg, bg = "#E5C07B" },
	CurSearch = { fg = bg, bg = fn_col, bold = true },
	MatchParen = { fg = bg, bg = "#56B6C2", bold = true },

	Comment = { fg = comment, italic = true },
	Constant = { fg = fg },
	ModeMsg = { fg = fg },
	String = { fg = fg },
	Identifier = { fg = fg },
	Statement = { fg = fn_col },
	Keyword = { fg = fn_col },
	Operator = { fg = fg },
	Delimiter = { fg = "#9AA3B0" },
	Special = { fg = fg },

	Type = { fg = type_col },
	["@type"] = { fg = fg },
	["@module.go"] = { fg = fg },
	["@type.builtin"] = { fg = type_col },
	Function = { fg = fn_col, bold = true },
	["@function"] = { fg = fn_col, bold = true },
	["@function.call"] = { fg = fn_col },
	["@function.method"] = { fg = fn_col },
	["@keyword.conditional"] = { fg = fn_col },
	["@keyword.repeat"] = { fg = fn_col },
	["@function.builtin"] = { fg = fn_col },
	["@property.yaml"] = { fg = fn_col },
	Title = { fg = fn_col, bold = true },

	Pmenu = { fg = fg, bg = bg },
	PmenuSel = { fg = bg, bg = type_col, bold = true },
	PmenuThumb = { bg = border },
	DiagnosticError = { fg = fn_col },
	DiagnosticWarn = { fg = "#E5C07B" },
	DiagnosticInfo = { fg = type_col },
	DiagnosticHint = { fg = comment },

	MiniPickNormal = { fg = fg, bg = bg },
	MiniPickBorder = { fg = border, bg = bg },
	MiniPickMatchRanges = { fg = fn_col, bold = true },
	MiniPickMatchCurrent = { bg = visual },

	DiffAdd = { fg = "#7EC699", bg = "none" },
	DiffText = { fg = bg, bg = fn_col },
	DiffDelete = { fg = fn_col, bg = "none" },
	DiffChange = { bg = "#2A303B" },
	Folded = { fg = comment, bg = bg },
	FoldColumn = { fg = line_nr, bg = "none" },
}

for group, spec in pairs(hl_groups) do
	vim.api.nvim_set_hl(0, group, spec)
end
