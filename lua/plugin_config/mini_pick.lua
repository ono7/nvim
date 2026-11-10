local has_pick, pick = pcall(require, "mini.pick")
if not has_pick then
	return
end

-- NOTE(jlima): preserve standard bottom dock layout and single border
pick.setup({
	window = {
		config = {
			border = "single",
		},
	},
})

-- NOTE(jlima): truncate overflowing paths from the left so the filename remains fully visible
local function show_truncate_left(buf_id, items_to_show, query)
	local win_id = vim.fn.bufwinid(buf_id)
	local max_w = (win_id ~= -1) and vim.api.nvim_win_get_width(win_id) or 80
	-- NOTE(jlima): account for gutter padding and right-side margin
	local limit = math.max(max_w - 6, 20)

	local truncated_items = {}
	for _, item in ipairs(items_to_show) do
		local str = type(item) == "table" and item.text or item
		if vim.fn.strdisplaywidth(str) > limit then
			local tail = "..." .. string.sub(str, -(limit - 3))
			if type(item) == "table" then
				local clone = vim.deepcopy(item)
				clone.text = tail
				table.insert(truncated_items, clone)
			else
				table.insert(truncated_items, tail)
			end
		else
			table.insert(truncated_items, item)
		end
	end

	pick.default_show(buf_id, truncated_items, query)
end

-- NOTE(jlima): Query zoxide database and set window-local cwd safely handling spaces and WSL mount paths
local function pick_zoxide()
	if vim.fn.executable("zoxide") == 0 then
		vim.notify("zoxide executable not found in PATH", vim.log.levels.ERROR)
		return
	end

	local result = vim.system({ "zoxide", "query", "-l" }, { text = true }):wait()
	if result.code ~= 0 or not result.stdout then
		vim.notify("zoxide query failed", vim.log.levels.WARN)
		return
	end

	local dirs = {}
	for line in result.stdout:gmatch("[^\r\n]+") do
		if line ~= "" and vim.uv.fs_stat(line) ~= nil then
			table.insert(dirs, line)
		end
	end

	if #dirs == 0 then
		vim.notify("zoxide database is empty", vim.log.levels.INFO)
		return
	end

	pick.start({
		source = {
			name = "Zoxide",
			items = dirs,
			show = show_truncate_left,
			choose = function(item)
				if not item or item == "" then
					return
				end
				local ok, err = pcall(vim.fn.chdir, item)
				if ok then
					vim.notify("lcd: " .. item, vim.log.levels.INFO)
				else
					vim.notify("Failed to lcd to " .. item .. ": " .. tostring(err), vim.log.levels.ERROR)
				end
			end,
		},
	})
end

pick.registry.zoxide = pick_zoxide
vim.keymap.set("n", "<M-z>", pick_zoxide, { noremap = true, silent = true, desc = "Zoxide (lcd)" })

-- NOTE(jlima): fast fd files picker; excludes build artifacts to restore rg-level throughput
pick.registry.files = function(local_opts)
	local_opts = local_opts or {}
	local cli_opts = {
		command = {
			"fd",
			"--type",
			"f",
			"--hidden",
			"--exclude",
			".git",
			"--exclude",
			"pkg/mod",
			"--exclude",
			".cache",
			"--strip-cwd-prefix",
		},
	}
	local default_opts = {
		source = {
			name = "Files (fd)",
			show = show_truncate_left,
		},
	}
	return pick.builtin.cli(cli_opts, vim.tbl_deep_extend("force", default_opts, local_opts))
end

-- NOTE(jlima): deterministic rg live-grep
pick.registry.grep_live = function(local_opts)
	local_opts = local_opts or {}
	local default_opts = {
		source = {
			name = "Grep Live (rg)",
		},
	}
	local rg_opts = {
		command = {
			"rg",
			"--column",
			"--line-number",
			"--no-heading",
			"--color=never",
			"--smart-case",
			"--hidden",
			"-g",
			"!.git",
		},
	}
	return pick.builtin.grep_live(rg_opts, vim.tbl_deep_extend("force", default_opts, local_opts))
end

local function pick_oldfiles()
	local old = vim.tbl_filter(function(path)
		return path ~= "" and vim.uv.fs_stat(path) ~= nil
	end, vim.v.oldfiles)

	local items = {}
	for i = 1, math.min(#old, 50) do
		table.insert(items, old[i])
	end

	pick.start({
		source = {
			items = items,
			name = "Recent",
			show = show_truncate_left,
			choose = pick.default_choose,
		},
	})
end

-- NOTE(jlima): scoped directory picker using fd streaming with left truncation
local function pick_dir(target_dir, display_name)
	return function()
		local resolved_dir = vim.fn.expand(target_dir)
		if vim.fn.isdirectory(resolved_dir) == 0 then
			vim.notify("Directory does not exist: " .. resolved_dir, vim.log.levels.WARN)
			return
		end

		if vim.fn.executable("fd") == 1 then
			local cli_opts = {
				command = {
					"fd",
					"--type",
					"f",
					"--hidden",
					"--exclude",
					".git",
					"--absolute-path",
					".",
					resolved_dir,
				},
			}
			local start_opts = {
				source = {
					name = display_name or resolved_dir,
					show = show_truncate_left,
					choose = pick.default_choose,
				},
			}
			pick.builtin.cli(cli_opts, start_opts)
		else
			local items = vim.fs.find(function()
				return true
			end, { path = resolved_dir, type = "file", limit = math.huge })

			pick.start({
				source = {
					items = items,
					name = display_name or resolved_dir,
					show = show_truncate_left,
					choose = pick.default_choose,
				},
			})
		end
	end
end

pick.registry.oldfiles = pick_oldfiles

local silent = { noremap = true, silent = true }
vim.keymap.set("n", "<M-f>", "<cmd>Pick files<CR>", silent)
vim.keymap.set("n", "<M-g>", "<cmd>Pick grep_live<CR>", silent)
vim.keymap.set("n", "<M-r>", pick_oldfiles, silent)

local dir_pickers = {
	{ key = "<M-v>", dir = "~/.config/nvim", desc = "Neovim Config" },
	{ key = "<M-i>", dir = "~/.dotfiles", desc = "Dotfiles" },
}

for _, target in ipairs(dir_pickers) do
	vim.keymap.set(
		"n",
		target.key,
		pick_dir(target.dir, target.desc),
		vim.tbl_extend("force", silent, { desc = target.desc })
	)
end
