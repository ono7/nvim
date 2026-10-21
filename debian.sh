#!/usr/bin/env bash
set -euo pipefail

# NOTE(jlima): Distinctive ANSI-highlighted banner helper to cut through verbose package manager/curl output.
log_step() {
    printf "\n\033[1;36m==>\033[0m \033[1m%s\033[0m\n" "$1"
}

log_step "Authenticating administrative privileges..."

if [ "$EUID" -ne 0 ]; then
    # Determine the preferred downloader tool present on the system
    if command -v curl >/dev/null 2>&1; then
        DOWNLOAD_CMD="curl -sSL https://raw.githubusercontent.com/ono7/nvim/refs/heads/main/debian.sh"
    elif command -v wget >/dev/null 2>&1; then
        DOWNLOAD_CMD="wget -qO- https://raw.githubusercontent.com/ono7/nvim/refs/heads/main/debian.sh"
    else
        DOWNLOAD_CMD="curl -sSL https://raw.githubusercontent.com/ono7/nvim/refs/heads/main/debian.sh"
    fi

    echo "Error: This script requires administrative privileges." >&2
    echo "Please run the command with sudo bash:" >&2
    echo "" >&2
    echo "  $DOWNLOAD_CMD | sudo bash" >&2
    echo "" >&2
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive

# NOTE(jlima): Purge Debian package and legacy /opt directories to eliminate PATH collisions.
sudo apt-get update -qq
sudo apt-get purge -y -qq tree-sitter-cli || true
sudo rm -rf /opt/tree-sitter-*

# NOTE(jlima): Extract upstream binary directly into /usr/local/bin and enforce executable permissions.
TMP_ZIP="$(mktemp /tmp/tree-sitter.XXXXXX.zip)"
curl -fsSL "https://github.com/tree-sitter/tree-sitter/releases/latest/download/tree-sitter-cli-linux-x64.zip" -o "${TMP_ZIP}"
sudo unzip -q -o "${TMP_ZIP}" -d /usr/local/bin
sudo rm -f "${TMP_ZIP}"

sudo chown root:root /usr/local/bin/tree-sitter
sudo chmod 0755 /usr/local/bin/tree-sitter

# NOTE(jlima): Capture invoking user and target home directories accurately.
INVOKING_USER="${SUDO_USER:-$(whoami)}"
if [ "$INVOKING_USER" = "root" ]; then
    TARGET_USER="root"
    TARGET_HOME="/root"
else
    TARGET_USER="$INVOKING_USER"
    TARGET_HOME="$(getent passwd "$INVOKING_USER" | cut -d: -f6)"
fi

log_step "Target environment: '${TARGET_USER}' (home: ${TARGET_HOME})"

# 1. Purge previous Neovim binaries, configs, and all persistent XDG data trees
log_step "Purging previous Neovim binaries, ~/.config/nvim, and persistent XDG directories..."
NVIM_DIR="/opt/neovim"
sudo rm -rf "$NVIM_DIR"

# NOTE(jlima): Wiping ~/.local/share/nvim destroys cached vim.pack locks, plugins, and metadata.
sudo rm -rf /root/.config/nvim
sudo rm -rf /root/.local/share/nvim /root/.local/state/nvim /root/.cache/nvim

if [ "$TARGET_USER" != "root" ]; then
    sudo rm -rf "${TARGET_HOME}/.config/nvim"
    sudo rm -rf "${TARGET_HOME}/.local/share/nvim" "${TARGET_HOME}/.local/state/nvim" "${TARGET_HOME}/.cache/nvim"
fi

# 2. Install system prerequisites via apt
log_step "Installing system prerequisites via apt (ripgrep, fd-find, curl, tar, git)..."
sudo apt-get update
# NOTE(jlima): Ensure git is explicitly present for vim.pack cloning and lock reconciliation.
sudo apt-get install -y ripgrep fd-find curl tar git build-essential tree-sitter-cli

# NOTE(jlima): Ensure native Debian fd-find binary is linked as fd for telescope compatibility.
if [ -f /usr/bin/fdfind ] && [ ! -e /usr/bin/fd ]; then
    log_step "Symlinking /usr/bin/fdfind -> /usr/bin/fd..."
    sudo ln -sf /usr/bin/fdfind /usr/bin/fd
fi

# 3. Download and install Neovim to /opt/neovim
log_step "Downloading and extracting Neovim stable to /opt/neovim..."
sudo mkdir -p "$NVIM_DIR"
curl -sL "https://github.com/neovim/neovim/releases/download/stable/nvim-linux-x86_64.tar.gz" | sudo tar -xzC "$NVIM_DIR" --strip-components=1

# 4. Register and activate Neovim using update-alternatives system-wide
log_step "Configuring update-alternatives (editor, vi, vim, nvim) -> /opt/neovim/bin/nvim..."
for alt in editor vi vim nvim; do
    sudo update-alternatives --install "/usr/bin/$alt" "$alt" "/opt/neovim/bin/nvim" 150
    sudo update-alternatives --set "$alt" "/opt/neovim/bin/nvim"
done

CONFIG_REPO="https://github.com/ono7/nvim.git"

# 5. Deploy fresh configurations for root
log_step "Cloning Neovim configuration repository for root..."
sudo git clone "$CONFIG_REPO" /root/.config/nvim
log_step "(root) strip git from repo /root/.config/nvim"
# sudo rm -rf /root/.config/nvim/.git
# NOTE(jlima): Use explicit absolute paths to avoid shell tilde expansion mismatches under sudo execution.
sudo rm -rf /root/.ctags.d && sudo ln -sfnv /root/.config/nvim/ctags.d /root/.ctags.d

# 6. Deploy fresh configurations for invoking sudo user (if not already root)
if [ "$TARGET_USER" != "root" ]; then
    log_step "Cloning Neovim configuration repository for '${TARGET_USER}'..."
    # NOTE(jlima): Clone directly under user execution context to preserve non-root file ownership across git refs.
    sudo -u "$TARGET_USER" git clone "$CONFIG_REPO" "${TARGET_HOME}/.config/nvim"
    log_step "$TARGET_USER - strip git from repo ${TARGET_HOME}/.config/nvim"
    # sudo -u "$TARGET_USER" rm -rf "${TARGET_HOME}/.config/nvim/.git"
    log_step "Symlinking ctags.d configuration for '${TARGET_USER}'..."
    # NOTE(jlima): Run under target user context so symlink ownership defaults to TARGET_USER without a secondary chown.
    sudo -u "$TARGET_USER" rm -rf "${TARGET_HOME}/.ctags.d"
    sudo -u "$TARGET_USER" ln -sfnv "${TARGET_HOME}/.config/nvim/ctags.d" "${TARGET_HOME}/.ctags.d"

    log_step "bootstrap neovim for target user: '${TARGET_USER}'..."
    sudo -u "$TARGET_USER" nvim --headless "+lua vim.pack.update()" +qa
    sudo -u "$TARGET_USER" nvim --headless "+TSInstallMyParsers" +qa
    log_step "bootstrap neovim for target user: '${TARGET_USER}'...Done!"
fi

log_step "Bootstrap complete. Verifying /usr/bin/nvim version..."

log_step "bootstrap neovim for target user: 'root'..."
nvim --headless "+lua vim.pack.update()" +qa
nvim --headless "+TSInstallMyParsers" +qa
log_step "bootstrap neovim for target user: 'root'...Done!"

/usr/bin/nvim --version

log_step "Done!"
