-- NOTE(jlima): Abort execution if not running in Neovide.
if not vim.g.neovide then
	return
end

-- NOTE(jlima): Determine operating system environment.
local os_name = jit.os
local is_mac = os_name == "OSX" or vim.fn.has("macunix") == 1
local is_wsl = os_name == "Linux" and (vim.uv.os_uname().release:lower():find("microsoft") ~= nil)

-- NOTE(jlima): Disable audio and visual bells.
vim.o.errorbells = false
vim.o.visualbell = false

-- NOTE(jlima): Limit terminal scrollback to 50,000 rows.
vim.o.scrollback = 50000

-- NOTE(jlima): Enforce black cursor color.
vim.api.nvim_set_hl(0, "Cursor", { bg = "#000000", fg = "#ffffff" })

-- NOTE(jlima): Configure fluid cursor animation parameters.
vim.g.neovide_cursor_animation_length = 0.09
vim.g.neovide_cursor_trail_size = 0.75
vim.g.neovide_cursor_smooth_blink = true
vim.g.neovide_cursor_blink = true
vim.g.neovide_cursor_blink_interval = 600
vim.g.neovide_title_text_color = "#000000"
vim.g.neovide_cursor_animate_in_insert_mode = true
vim.g.neovide_cursor_animate_command_line = true
vim.g.neovide_cursor_antialiasing = true

-- NOTE(jlima): Configure fluid viewport scrolling.
vim.g.neovide_scroll_animation_length = 0.12
vim.g.neovide_scroll_animation_far_lines = 1

-- NOTE(jlima): Disable floating window blur and shadows to maximize performance.
vim.g.neovide_floating_blur_amount_x = 0.0
vim.g.neovide_floating_blur_amount_y = 0.0
vim.g.neovide_floating_shadow = false
vim.g.neovide_floating_z_height = 10
vim.g.neovide_light_angle_degrees = 45
vim.g.neovide_light_radius = 5

-- NOTE(jlima): Hide progress bar.
vim.g.neovide_progress_bar_enabled = false
vim.g.neovide_progress_bar_height = 5.0
vim.g.neovide_progress_bar_animation_speed = 200.0
vim.g.neovide_progress_bar_hide_delay = 0.2

-- NOTE(jlima): Configure platform-specific typography and keybindings.
if os_name == "Windows" or is_wsl then
	vim.o.guifont = "Menlo:h16"
	vim.g.neovide_input_use_logo = false
	vim.opt.winaltkeys = "yes"
elseif is_mac then
	vim.g.neovide_pixel_geometry = "Unknown"
	vim.o.guifont = "Menlo,IosevkaTerm Nerd Font:h22:#e-subpixelantialias:#h-full"
	vim.g.neovide_padding_top = 0
	vim.g.neovide_padding_bottom = 0
	vim.g.neovide_padding_right = 0
	vim.g.neovide_padding_left = 0
else
	-- vim.o.guifont = "Iosevka Custom:h17:#e-subpixelantialias:#h-full"
	vim.o.guifont = "Menlo:h17"
end

-- NOTE(jlima): Replicate Alacritty font rendering and contrast.
-- vim.g.neovide_text_gamma = 0.8
-- vim.g.neovide_text_contrast = 0.1

-- NOTE(jlima): Set line height for astigmatism readability.
vim.opt.linespace = 14

-- NOTE(jlima): Configure Option key as Meta, disable frame, and set UI behavior.
vim.g.neovide_input_macos_option_key_is_meta = "both"
vim.g.neovide_frame_no_title = true
vim.g.neovide_fullscreen = false
vim.g.neovide_idle = true
vim.g.neovide_hide_mouse_when_typing = true
vim.g.neovide_confirm_quit = true

-- NOTE(jlima): Set default window padding.
vim.g.neovide_padding_top = 0
vim.g.neovide_padding_bottom = 0
vim.g.neovide_padding_left = 10
vim.g.neovide_padding_right = 10

-- NOTE(jlima): Initialize baseline scale factor.
vim.g.neovide_scale_factor = 1.0

-- NOTE(jlima): Map dynamic scale factor adjustments.
local function change_scale_factor(delta)
	local s = vim.g.neovide_scale_factor * delta
	vim.g.neovide_scale_factor = math.max(0.7, math.min(1.2, s))
end

local cmd_or_ctrl = "<C-"

vim.keymap.set("n", cmd_or_ctrl .. "=>", function()
	change_scale_factor(1.02)
end)

vim.keymap.set("n", cmd_or_ctrl .. "->", function()
	change_scale_factor(1 / 1.05)
end)

vim.keymap.set("n", cmd_or_ctrl .. "0>", function()
	vim.g.neovide_scale_factor = 1.0
end)

-- NOTE(jlima): Configure deduplicated clipboard and window keymaps.
vim.keymap.set({ "n", "v" }, "<C-S-v>", '"+p')
vim.keymap.set({ "i", "c" }, "<C-S-v>", "<C-r>+")
vim.keymap.set("t", "<C-S-v>", '<C-\\><C-n>"+pi')
if is_mac then
	vim.keymap.set("t", "<D-S-v>", '<C-\\><C-n>"+pi')
end

vim.keymap.set("n", "<C-k>", "<C-w>k")

-- NOTE(jlima): Implement tab navigation loop.
for i = 1, 9 do
	vim.keymap.set({ "n", "t", "x" }, "<C-" .. i .. ">", i .. "gt")
end
