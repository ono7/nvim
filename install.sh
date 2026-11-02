#!/usr/bin/env bash
# curl -fsSL https://raw.githubusercontent.com/ono7/nvim/refs/heads/main/install-nvim.sh | bash
set -euo pipefail

# NOTE(jlima): ANSI banner helper for tracking installation progress.
log_step() {
    printf "\n\033[1;36m==>\033[0m \033[1m%s\033[0m\n" "$1"
}

# NOTE(jlima): Enforce strictly unprivileged user execution.
if [ "${EUID:-$(id -u)}" -eq 0 ] || [ -n "${SUDO_USER:-}" ]; then
    echo "ERROR: Do not execute this script as root or with sudo." >&2
    exit 1
fi

DEST_OPT="$HOME/.local/opt"
DEST_BIN="$HOME/.local/bin"
mkdir -p "$DEST_OPT" "$DEST_BIN"

# NOTE(jlima): Export PATH locally within execution subshell so dependent bootstrap steps resolve new binaries immediately.
export PATH="${DEST_BIN}:${PATH}"

# NOTE(jlima): Verify prerequisite tools (node, rg, fd) exist; pull installer if absent.
if ! command -v node >/dev/null 2>&1 || ! command -v rg >/dev/null 2>&1 || ! command -v fd >/dev/null 2>&1; then
    log_step "Prerequisites missing from PATH. Invoking prerequisite installer..."
    PREREQ_INSTALL_URL="https://raw.githubusercontent.com/ono7/nvim/refs/heads/main/install-node.sh"
    curl -fsSL "$PREREQ_INSTALL_URL" | bash
fi

# NOTE(jlima): Target release mapping for upstream assets across Linux and macOS.
OS_RAW="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH_RAW="$(uname -m)"

case "$OS_RAW" in
    linux*)
        case "$ARCH_RAW" in
            x86_64|amd64)
                NVIM_RELEASE="nvim-linux-x86_64.tar.gz"
                NVIM_DIR_NAME="nvim-linux-x86_64"
                TS_RELEASE="tree-sitter-cli-linux-x64.zip"
                ;;
            aarch64|arm64)
                NVIM_RELEASE="nvim-linux-arm64.tar.gz"
                NVIM_DIR_NAME="nvim-linux-arm64"
                TS_RELEASE="tree-sitter-cli-linux-arm64.zip"
                ;;
            *) echo "Unsupported Linux architecture: $ARCH_RAW" >&2; exit 1 ;;
        esac
        ;;
    darwin*)
        case "$ARCH_RAW" in
            aarch64|arm64)
                NVIM_RELEASE="nvim-macos-arm64.tar.gz"
                NVIM_DIR_NAME="nvim-macos-arm64"
                TS_RELEASE="tree-sitter-cli-macos-arm64.zip"
                ;;
            *) echo "Unsupported macOS architecture: $ARCH_RAW" >&2; exit 1 ;;
        esac
        ;;
    *) echo "Unsupported OS: $OS_RAW" >&2; exit 1 ;;
esac

# 1. Install tree-sitter-cli (Latest Stable Release)
log_step "Installing latest tree-sitter-cli (${TS_RELEASE})..."
TS_URL="https://github.com/tree-sitter/tree-sitter/releases/latest/download/${TS_RELEASE}"
TMP_ZIP="$(mktemp "${TMPDIR:-/tmp}/tree-sitter.XXXXXX.zip")"
curl -fsSL "$TS_URL" -o "$TMP_ZIP"

unzip -q -o "$TMP_ZIP" -d "$DEST_BIN"
rm -f "$TMP_ZIP"
chmod 0755 "${DEST_BIN}/tree-sitter"

# 2. Install Neovim (Latest Stable Release)
log_step "Installing latest Neovim stable (${NVIM_RELEASE})..."
NVIM_URL="https://github.com/neovim/neovim/releases/download/stable/${NVIM_RELEASE}"
NVIM_INSTALL_ROOT="${DEST_OPT}/neovim"

rm -rf "${DEST_OPT:?}/${NVIM_DIR_NAME}" "$NVIM_INSTALL_ROOT"
curl -fsSL "$NVIM_URL" | tar -xz -C "$DEST_OPT"
mv "${DEST_OPT}/${NVIM_DIR_NAME}" "$NVIM_INSTALL_ROOT"

ln -sf "${NVIM_INSTALL_ROOT}/bin/nvim" "${DEST_BIN}/nvim"

# 3. Deploy Neovim dotfiles configuration
CONFIG_REPO="https://github.com/ono7/nvim.git"
CONFIG_DIR="$HOME/.config/nvim"

log_step "Reconciling Neovim configuration repository at ${CONFIG_DIR}..."
if [ -d "$CONFIG_DIR/.git" ]; then
    git -C "$CONFIG_DIR" pull --ff-only
else
    rm -rf "$CONFIG_DIR"
    git clone "$CONFIG_REPO" "$CONFIG_DIR"
fi

if [ -d "${CONFIG_DIR}/ctags.d" ]; then
    rm -rf "$HOME/.ctags.d"
    ln -sfnv "${CONFIG_DIR}/ctags.d" "$HOME/.ctags.d"
fi

# 4. Bootstrap plugins and parsers headlessly
log_step "Bootstrapping Neovim plugins and Tree-sitter parsers..."
"${DEST_BIN}/nvim" --headless "+lua vim.pack.update()" +qa
"${DEST_BIN}/nvim" --headless "+TSInstallMyParsers" +qa

# 5. Shell RC PATH reconciliation
log_step "Configuring shell RC files for PATH exports..."

# NOTE(jlima): Configure PATH export idempotently across active and default shell configurations.
ensure_path_in_file() {
    local rc_file="$1"
    local export_line='export PATH="$HOME/.local/bin:$PATH"'

    if [ ! -f "$rc_file" ]; then
        touch "$rc_file"
    fi

    if grep -qs '\.local/bin' "$rc_file"; then
        printf "  [-] %s already contains ~/.local/bin in PATH.\n" "$rc_file"
    else
        printf "\n# NOTE(jlima): Ensure local user binaries take precedence in PATH\n%s\n" "$export_line" >> "$rc_file"
        printf "  [+] Appended PATH export to %s\n" "$rc_file"
    fi
}

# NOTE(jlima): Resolve user target RC files depending on shell environments.
TARGET_RCS=()

# zsh detection
if [ -f "$HOME/.zshrc" ] || [[ "${SHELL:-}" =~ "zsh" ]]; then
    TARGET_RCS+=("$HOME/.zshrc")
fi

# bash detection
if [ -f "$HOME/.bashrc" ] || [[ "${SHELL:-}" =~ "bash" ]]; then
    TARGET_RCS+=("$HOME/.bashrc")
fi

# login profile fallback on macOS/BSD where interactive login shells read .profile or .bash_profile
if [ "$OS_RAW" = "darwin" ] && [ -f "$HOME/.zprofile" ]; then
    TARGET_RCS+=("$HOME/.zprofile")
elif [ -f "$HOME/.bash_profile" ]; then
    TARGET_RCS+=("$HOME/.bash_profile")
elif [ -f "$HOME/.profile" ]; then
    TARGET_RCS+=("$HOME/.profile")
fi

for rc in "${TARGET_RCS[@]}"; do
    ensure_path_in_file "$rc"
done

# 6. Verification
log_step "Verification complete:"
"${DEST_BIN}/nvim" --version | head -n 2
"${DEST_BIN}/tree-sitter" --version

printf "\n\033[1;32m==>\033[0m Success. Run \033[1msource <your-rc-file>\033[0m or launch a new terminal to reload PATH.\n\n"h
