#!/usr/bin/env bash
set -euo pipefail

# NOTE(jlima): Distinctive ANSI-highlighted banner helper for macOS bootstrap output.
log_step() {
    printf "\n\033[1;36m==>\033[0m \033[1m%s\033[0m\n" "$1"
}

# NOTE(jlima): Capture invoking user and home directory for macOS multi-user safety.
TARGET_USER="$(whoami)"
TARGET_HOME="$HOME"

log_step "Target environment: '${TARGET_USER}' (home: ${TARGET_HOME})"

# 1. Check for Homebrew, install if missing
log_step "Checking for Homebrew..."
if ! command -v brew &>/dev/null; then
    log_step "Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # NOTE(jlima): Configure Homebrew in PATH for Apple Silicon vs Intel default locations.
    if [[ -d "/opt/homebrew/bin" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -d "/usr/local/bin" ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
else
    log_step "Homebrew is already installed. Updating..."
    brew update
fi

# 2. Install prerequisites and packages via Homebrew (ctags, tree-sitter-cli, neovim, ripgrep, fd, git)
log_step "Installing packages via Homebrew (ctags, tree-sitter-cli, neovim, ripgrep, fd, git)..."
brew install --quiet ctags tree-sitter-cli neovim ripgrep fd git

# 3. Purge previous Neovim configuration and persistent XDG data trees
log_step "Purging previous ~/.config/nvim and persistent XDG directories..."
rm -rf "${TARGET_HOME}/.config/nvim"
rm -rf "${TARGET_HOME}/.local/share/nvim" "${TARGET_HOME}/.local/state/nvim" "${TARGET_HOME}/.cache/nvim"

CONFIG_REPO="https://github.com/ono7/nvim.git"

# 4. Deploy fresh configurations for the user
log_step "Cloning Neovim configuration repository..."
git clone "$CONFIG_REPO" "${TARGET_HOME}/.config/nvim"

log_step "Symlinking ctags.d configuration..."
rm -rf "${TARGET_HOME}/.ctags.d"
ln -sfnv "${TARGET_HOME}/.config/nvim/ctags.d" "${TARGET_HOME}/.ctags.d"

log_step "Bootstrap starting for nvim..."
nvim --headless "+lua vim.pack.update()" +qa
nvim --headless "+TSInstallMyParsers" +qa

log_step "Bootstrap complete. Verifying nvim version..."
nvim --version

