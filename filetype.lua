vim.filetype.add({
	extension = {
		-- Map Go templates
		tmpl = "gotmpl",
	},
	pattern = {
		-- Map any YAML file inside an 'ansible' directory or matching typical playbook names
		[".*/playbooks/.*%.ya?ml"] = "yaml.ansible",
		[".*/roles/.*%.ya?ml"] = "yaml.ansible",
		[".*/tasks/.*%.ya?ml"] = "yaml.ansible",
		[".*ansible.*%.ya?ml"] = "yaml.ansible",
	},
})
