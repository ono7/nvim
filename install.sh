#!/usr/bin/env bash
set -euo pipefail

## curl -fsSL https://raw.githubusercontent.com/ono7/nvim/refs/heads/main/install.sh | bash

export PATH="$HOME/.local/bin:$PATH"

# NOTE(jlima): ANSI banner helper for tracking installation progress.
log_step() {
    printf "\n\033[1;36m==>\033[0m \033[1m%s\033[0m\n" "$1"
}

log_step "This installer supports MacOS and Linux"

# NOTE(jlima): Enforce strictly unprivileged user execution.
if [ "${EUID:-$(id -u)}" -eq 0 ] || [ -n "${SUDO_USER:-}" ]; then
    echo "ERROR: Do not execute this script as root or with sudo." >&2
    exit 1
fi

DEST_OPT="$HOME/.local/opt"
DEST_BIN="$HOME/.local/bin"
DEST_LOCAL="$HOME/.local"
mkdir -p "$DEST_OPT" "$DEST_BIN"

# NOTE(jlima): Normalize OS and architecture identifiers across toolchains.
OS_RAW="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH_RAW="$(uname -m)"

case "$OS_RAW" in
    linux*)
        GOOS="linux"
        case "$ARCH_RAW" in
            x86_64|amd64)
                GOARCH="amd64"
                NVIM_RELEASE="nvim-linux-x86_64.tar.gz"
                NVIM_DIR_NAME="nvim-linux-x86_64"
                TS_RELEASE="tree-sitter-cli-linux-x64.zip"
                ;;
            aarch64|arm64)
                GOARCH="arm64"
                NVIM_RELEASE="nvim-linux-arm64.tar.gz"
                NVIM_DIR_NAME="nvim-linux-arm64"
                TS_RELEASE="tree-sitter-cli-linux-arm64.zip"
                ;;
            *) echo "Unsupported Linux architecture: $ARCH_RAW" >&2; exit 1 ;;
        esac
        ;;
    darwin*)
        GOOS="darwin"
        case "$ARCH_RAW" in
            aarch64|arm64)
                GOARCH="arm64"
                NVIM_RELEASE="nvim-macos-arm64.tar.gz"
                NVIM_DIR_NAME="nvim-macos-arm64"
                TS_RELEASE="tree-sitter-cli-macos-arm64.zip"
                ;;
            x86_64|amd64)
                GOARCH="amd64"
                NVIM_RELEASE="nvim-macos-x86_64.tar.gz"
                NVIM_DIR_NAME="nvim-macos-x86_64"
                TS_RELEASE="tree-sitter-cli-macos-x64.zip"
                ;;
            *) echo "Unsupported macOS architecture: $ARCH_RAW" >&2; exit 1 ;;
        esac
        ;;
    *) echo "Unsupported OS: $OS_RAW" >&2; exit 1 ;;
esac

# 1. Install / Reconcile Go Toolchain
log_step "Reconciling Go toolchain..."
GO_VER="$(curl -sSf 'https://go.dev/VERSION?m=text' | head -n1)"
if [ -z "${GO_VER}" ]; then
    echo "ERROR: Failed to retrieve current stable Go version string." >&2
    exit 1
fi

GOROOT="${DEST_LOCAL}/go"
GOPATH="${HOME}/go"

CURRENT_GO_VER=""
if [ -x "${GOROOT}/bin/go" ]; then
    CURRENT_GO_VER="$("${GOROOT}/bin/go" version | awk '{print $3}')"
fi

if [ "${CURRENT_GO_VER}" != "${GO_VER}" ]; then
    log_step "Installing Go (${GO_VER}) for ${GOOS}/${GOARCH}..."
    TMP_GO_DIR="$(mktemp -d "${TMPDIR:-/tmp}/go-install.XXXXXX")"
    GO_ARCHIVE="${GO_VER}.${GOOS}-${GOARCH}.tar.gz"
    GO_ARCHIVE_PATH="${TMP_GO_DIR}/${GO_ARCHIVE}"

    curl -fsSL "https://go.dev/dl/${GO_ARCHIVE}" -o "${GO_ARCHIVE_PATH}"

    # NOTE(jlima): Purge existing root prior to extraction to prevent stale package collisions
    rm -rf "${GOROOT}"
    tar -C "${DEST_LOCAL}" -xzf "${GO_ARCHIVE_PATH}"
    rm -rf "${TMP_GO_DIR}"
else
    printf "  [-] Go %s is already up-to-date at %s\n" "${GO_VER}" "${GOROOT}"
fi

# NOTE(jlima): Symlink binaries directly to ~/.local/bin and export to execution subshell
ln -sfv "${GOROOT}/bin/go" "${DEST_BIN}/go"
ln -sfv "${GOROOT}/bin/gofmt" "${DEST_BIN}/gofmt"
mkdir -p "${GOPATH}/bin"

export GOROOT="${GOROOT}"
export GOPATH="${GOPATH}"
export PATH="${DEST_BIN}:${GOROOT}/bin:${GOPATH}/bin:$HOME/.npm-global/bin:${PATH}"

# 2. Verify external prerequisites
if ! command -v node >/dev/null 2>&1 || ! command -v rg >/dev/null 2>&1 || ! command -v fd >/dev/null 2>&1 || ! command -v hunk >/dev/null 2>&1; then
    log_step "Prerequisites missing from PATH. Invoking prerequisite installer..."
    PREREQ_INSTALL_URL="https://raw.githubusercontent.com/ono7/nvim/refs/heads/main/install-prereqs.sh"
    curl -fsSL "$PREREQ_INSTALL_URL" | bash
fi

# 3. Install tree-sitter-cli (Latest Stable Release)
log_step "Installing latest tree-sitter-cli (${TS_RELEASE})..."
TS_URL="https://github.com/tree-sitter/tree-sitter/releases/latest/download/${TS_RELEASE}"
TMP_ZIP="$(mktemp "${TMPDIR:-/tmp}/tree-sitter.XXXXXX.zip")"
curl -fsSL "$TS_URL" -o "$TMP_ZIP"

unzip -q -o "$TMP_ZIP" -d "$DEST_BIN"
rm -f "$TMP_ZIP"
chmod 0755 "${DEST_BIN}/tree-sitter"

log_step "Cleaning up previous neovim artifacts"
rm -rf ~/.local/share/nvim
rm -rf ~/.local/state/nvim
rm -rf ~/.cache/nvim

# 4. Install Neovim (Latest Stable Release)
log_step "Installing latest Neovim stable (${NVIM_RELEASE})..."
NVIM_URL="https://github.com/neovim/neovim/releases/download/stable/${NVIM_RELEASE}"
NVIM_INSTALL_ROOT="${DEST_OPT}/neovim"

rm -rf "${DEST_OPT:?}/${NVIM_DIR_NAME}" "$NVIM_INSTALL_ROOT"
curl -fsSL "$NVIM_URL" | tar -xz -C "$DEST_OPT"
mv "${DEST_OPT}/${NVIM_DIR_NAME}" "$NVIM_INSTALL_ROOT"

ln -sfv "${NVIM_INSTALL_ROOT}/bin/nvim" "${DEST_BIN}/nvim"

# 5. Deploy Neovim dotfiles configuration
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
    ln -sfvn "${CONFIG_DIR}/ctags.d" "$HOME/.ctags.d"
fi

# 6. Bootstrap plugins and parsers headlessly
log_step "Bootstrapping Neovim plugins and Tree-sitter parsers..."
"${DEST_BIN}/nvim" --headless "+UpdateRemotePlugins" +qa
"${DEST_BIN}/nvim" --headless "+lua vim.pack.update(nil, {force = true})" +qa
"${DEST_BIN}/nvim" --headless "+TSInstallMyParsers" +qa
"${DEST_BIN}/nvim" --headless "+TSInstallMyParsers" +qa
"${DEST_BIN}/nvim" --headless "+MasonToolsInstallSync" +qa

# 7. Shell RC PATH reconciliation
log_step "Configuring shell RC files for PATH and Go environment exports..."

# NOTE(jlima): Configure PATH and Go environment idempotently across target RC files.
ensure_shell_env() {
    local rc_file="$1"

    if [ ! -f "$rc_file" ]; then
        touch "$rc_file"
    fi

    if grep -qs '\.local/bin' "$rc_file"; then
        printf "  [-] %s already contains ~/.local/bin in PATH.\n" "$rc_file"
    else
        printf '\n# NOTE(jlima): Ensure local user binaries take precedence in PATH\nexport PATH="$HOME/.local/bin:$PATH"\n' >> "$rc_file"
        printf "  [+] Appended PATH export to %s\n" "$rc_file"
    fi

    if grep -qs 'GOROOT=' "$rc_file"; then
        printf "  [-] %s already contains GOROOT definition.\n" "$rc_file"
    else
        cat << 'EOF' >> "$rc_file"

# NOTE(jlima): Go toolchain paths
export GOROOT="$HOME/.local/go"
export GOPATH="$HOME/go"
export PATH="$GOROOT/bin:$GOPATH/bin:$PATH"
EOF
        printf "  [+] Appended Go environment exports to %s\n" "$rc_file"
    fi
}

TARGET_RCS=()

if [ -f "$HOME/.zshrc" ] || [[ "${SHELL:-}" =~ "zsh" ]]; then
    TARGET_RCS+=("$HOME/.zshrc")
fi

if [ -f "$HOME/.bashrc" ] || [[ "${SHELL:-}" =~ "bash" ]]; then
    TARGET_RCS+=("$HOME/.bashrc")
fi

if [ "$OS_RAW" = "darwin" ] && [ -f "$HOME/.zprofile" ]; then
    TARGET_RCS+=("$HOME/.zprofile")
elif [ -f "$HOME/.bash_profile" ]; then
    TARGET_RCS+=("$HOME/.bash_profile")
elif [ -f "$HOME/.profile" ]; then
    TARGET_RCS+=("$HOME/.profile")
fi

for rc in "${TARGET_RCS[@]}"; do
    ensure_shell_env "$rc"
done

# 8. Verification
log_step "Verification complete:"
"${DEST_BIN}/nvim" --version | head -n 2
"${DEST_BIN}/tree-sitter" --version
"${DEST_BIN}/go" version

log_step "${OS_RAW} - ${ARCH_RAW}"

printf "\n\033[1;32m==>\033[0m Success. Run \033[1msource <your-rc-file>\033[0m or launch a new terminal to reload PATH.\n\n"
