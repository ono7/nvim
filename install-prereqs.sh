#!/usr/bin/env bash
set -euo pipefail

# NOTE(jlima): ANSI banner helper for tracking installation progress.
log_step() {
    printf "\n\033[1;36m==>\033[0m \033[1m%s\033[0m\n" "$1"
}

# NOTE(jlima): Prevent execution under root or sudo to avoid file permission corruption in user home.
if [ "${EUID:-$(id -u)}" -eq 0 ] || [ -n "${SUDO_USER:-}" ]; then
    echo "ERROR: Do not execute this script as root or with sudo." >&2
    exit 1
fi

DEST_OPT="$HOME/.local/opt"
DEST_BIN="$HOME/.local/bin"

log_step "Ensuring local directories exist..."
mkdir -p "$DEST_OPT" "$DEST_BIN"

# NOTE(jlima): Resolve host platform.
OS_RAW="$(uname -s | tr '[:upper:]' '[:lower:]')"
case "$OS_RAW" in
    linux*)  PLATFORM="linux" ;;
    darwin*) PLATFORM="darwin" ;;
    *) echo "Unsupported OS: $OS_RAW" >&2; exit 1 ;;
esac

# NOTE(jlima): Resolve host architecture.
ARCH_RAW="$(uname -m)"
case "$ARCH_RAW" in
    x86_64|amd64)  ARCH="x64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    *) echo "Unsupported architecture: $ARCH_RAW" >&2; exit 1 ;;
esac

# -----------------------------------------------------------------------------
# 1. Node.js (Latest Active LTS)
# -----------------------------------------------------------------------------
log_step "Resolving latest stable Node.js release..."
# NOTE(jlima): Query latest LTS release directory metadata to avoid hardcoded version pins.
NODE_DIST_URL="https://nodejs.org/dist/latest-v22.x"
NODE_VERSION="$(curl -fsSL "${NODE_DIST_URL}/SHASUMS256.txt" | head -n 1 | awk '{print $2}' | sed -E 's/node-(v[0-9.]+).*/\1/')"

if [ "$PLATFORM" = "linux" ]; then
    NODE_EXT="tar.xz"
    NODE_TAR_FLAG="-xJ"
else
    NODE_EXT="tar.gz"
    NODE_TAR_FLAG="-xz"
fi

NODE_RELEASE="node-${NODE_VERSION}-${PLATFORM}-${ARCH}"
NODE_TARBALL="${NODE_RELEASE}.${NODE_EXT}"

log_step "Downloading Node.js (${NODE_VERSION})..."
curl -fsSL "${NODE_DIST_URL}/${NODE_TARBALL}" | tar "$NODE_TAR_FLAG" -C "$DEST_OPT"

rm -rf "${DEST_OPT}/node"
mv "${DEST_OPT}/${NODE_RELEASE}" "${DEST_OPT}/node"

log_step "Symlinking Node binaries into ${DEST_BIN}..."
ln -sf "${DEST_OPT}/node/bin/node" "${DEST_BIN}/node"
ln -sf "${DEST_OPT}/node/bin/npm"  "${DEST_BIN}/npm"
ln -sf "${DEST_OPT}/node/bin/npx"  "${DEST_BIN}/npx"

log_step "Configuring npm global prefix to ~/.local..."
"${DEST_BIN}/npm" config set prefix "$HOME/.local"

# -----------------------------------------------------------------------------
# 2. ripgrep (rg) - Latest Stable Tag
# -----------------------------------------------------------------------------
log_step "Resolving latest ripgrep release tag..."
# NOTE(jlima): Follow HTTP 302 redirect on releases/latest to extract upstream release tag without API rate limits.
RG_LATEST_URL="$(curl -fsSL -o /dev/null -w "%{url_effective}" "https://github.com/BurntSushi/ripgrep/releases/latest")"
RG_TAG="${RG_LATEST_URL##*/}"

if [ "$PLATFORM" = "linux" ]; then
    if [ "$ARCH" = "x64" ]; then
        RG_TARGET="x86_64-unknown-linux-musl"
    else
        RG_TARGET="aarch64-unknown-linux-gnu"
    fi
else
    RG_TARGET="aarch64-apple-darwin"
fi

RG_NAME="ripgrep-${RG_TAG}-${RG_TARGET}"
RG_URL="https://github.com/BurntSushi/ripgrep/releases/download/${RG_TAG}/${RG_NAME}.tar.gz"

log_step "Installing ripgrep (${RG_TAG})..."
TMP_RG_DIR="$(mktemp -d "${TMPDIR:-/tmp}/rg.XXXXXX")"
curl -fsSL "$RG_URL" | tar -xz -C "$TMP_RG_DIR"
cp -f "${TMP_RG_DIR}/${RG_NAME}/rg" "${DEST_BIN}/rg"
chmod 0755 "${DEST_BIN}/rg"
rm -rf "$TMP_RG_DIR"

# -----------------------------------------------------------------------------
# 3. fd-find (fd) - Latest Stable Tag
# -----------------------------------------------------------------------------
log_step "Resolving latest fd release tag..."
# NOTE(jlima): Follow HTTP 302 redirect on releases/latest to extract upstream release tag.
FD_LATEST_URL="$(curl -fsSL -o /dev/null -w "%{url_effective}" "https://github.com/sharkdp/fd/releases/latest")"
FD_TAG="${FD_LATEST_URL##*/}"

if [ "$PLATFORM" = "linux" ]; then
    if [ "$ARCH" = "x64" ]; then
        FD_TARGET="x86_64-unknown-linux-musl"
    else
        FD_TARGET="aarch64-unknown-linux-gnu"
    fi
else
    FD_TARGET="aarch64-apple-darwin"
fi

FD_NAME="fd-${FD_TAG}-${FD_TARGET}"
FD_URL="https://github.com/sharkdp/fd/releases/download/${FD_TAG}/${FD_NAME}.tar.gz"

log_step "Installing fd (${FD_TAG})..."
TMP_FD_DIR="$(mktemp -d "${TMPDIR:-/tmp}/fd.XXXXXX")"
curl -fsSL "$FD_URL" | tar -xz -C "$TMP_FD_DIR"
cp -f "${TMP_FD_DIR}/${FD_NAME}/fd" "${DEST_BIN}/fd"
chmod 0755 "${DEST_BIN}/fd"
rm -rf "$TMP_FD_DIR"

# -----------------------------------------------------------------------------
# Verification
# -----------------------------------------------------------------------------
log_step "Verification complete:"
"${DEST_BIN}/node" -v
"${DEST_BIN}/npm" -v
"${DEST_BIN}/rg" --version | head -n 1
"${DEST_BIN}/fd" --version
