-- NOTE(jlima): Initialize core registry before dependent bridges.
local has_mason, mason = pcall(require, "mason")
if not has_mason then
	return
end

mason.setup()

local has_lspconfig, mason_lspconfig = pcall(require, "mason-lspconfig")
if has_lspconfig then
	mason_lspconfig.setup({ automatic_enable = false })
end

local has_installer, tool_installer = pcall(require, "mason-tool-installer")
if has_installer then
	tool_installer.setup({
		ensure_installed = {
			"ansiblels",
			"clang-format",
			"gopls",
			"lua_ls",
			"pyright",
			"yamlls",
			-- Linters, Formatters & Binaries
			"gofumpt",
			"goimports",
			"goimports-reviser",
			"golangci-lint",
			"golines",
			"gomodifytags",
			"gotests",
			"jq",
			"json-to-struct",
			"shellcheck",
			"shfmt",
			"sqlfmt",
			"staticcheck",
			"stylua",
			"yamlfmt",
			"yamllint",
		},
		auto_update = false,
		run_on_start = false,
	})
end
