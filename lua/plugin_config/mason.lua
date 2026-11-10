-- NOTE(jlima): Initialize core registry before dependent bridges.
local has_mason, mason = pcall(require, "mason")
if not has_mason then
	return
end

mason.setup()

local has_lspconfig, mason_lspconfig = pcall(require, "mason-lspconfig")
if has_lspconfig then
	mason_lspconfig.setup()
end

-- NOTE(jlima): Defer tool installation until Mason registry index is fully loaded into memory.
local has_installer, tool_installer = pcall(require, "mason-tool-installer")
local has_registry, mr = pcall(require, "mason-registry")

if has_installer and has_registry then
	local function setup_installer()
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
				"goimports-revisor",
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

	-- Run immediately if registry is populated, otherwise attach to registry init event.
	if mr.refresh then
		mr.refresh(setup_installer)
	else
		setup_installer()
	end
end
