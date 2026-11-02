#!/usr/bin/env bash
set -euo pipefail

log_step() {
    printf "\n\033[1;36m==>\033[0m \033[1m%s\033[0m\n" "$1"
}

log_step "Checking user..."

# NOTE(jlima): Prevent execution under root or sudo
if [ "${EUID:-$(id -u)}" -eq 0 ] || [ -n "${SUDO_USER:-}" ]; then
  echo "ERROR: Do not execute this script as root or with sudo." >&2
  exit 1
fi

NODE_VERSION="v20.18.0"

# NOTE(jlima): Normalize host platform
OS_RAW=$(uname -s | tr '[:upper:]' '[:lower:]')
case "$OS_RAW" in
  linux*)  PLATFORM="linux" ;;
  darwin*) PLATFORM="darwin" ;;
  *) echo "Unsupported OS: $OS_RAW" >&2; exit 1 ;;
esac

log_step "Checking platform and CPU arch"
# NOTE(jlima): Normalize host architecture
ARCH_RAW=$(uname -m)
case "$ARCH_RAW" in
  x86_64|amd64)  ARCH="x64" ;;
  aarch64|arm64) ARCH="arm64" ;;
  *) echo "Unsupported architecture: $ARCH_RAW" >&2; exit 1 ;;
esac

# NOTE(jlima): Determine packaging format explicitly
if [ "$PLATFORM" = "linux" ]; then
  EXT="tar.xz"
  TAR_FLAG="-xJ"
else
  EXT="tar.gz"
  TAR_FLAG="-xz"
fi

RELEASE="node-${NODE_VERSION}-${PLATFORM}-${ARCH}"
TARBALL="${RELEASE}.${EXT}"
BASE_URL="https://nodejs.org/dist/${NODE_VERSION}"

DEST_OPT="$HOME/.local/opt"
DEST_BIN="$HOME/.local/bin"

log_step "Creating local directories if !exists"
mkdir -p "$DEST_OPT" "$DEST_BIN"


log_step "Downloading node ${BASE_URL}"

# NOTE(jlima): Extract tarball using deterministic flag without fallback chain
curl -fsSL "${BASE_URL}/${TARBALL}" | tar "$TAR_FLAG" -C "$DEST_OPT"

# NOTE(jlima): Atomically update symlinked tree
rm -rf "${DEST_OPT}/node"
mv "${DEST_OPT}/${RELEASE}" "${DEST_OPT}/node"

log_step "Linking to ~/.local/bin"
# NOTE(jlima): Symlink binaries
ln -sf "${DEST_OPT}/node/bin/node" "${DEST_BIN}/node"
ln -sf "${DEST_OPT}/node/bin/npm"  "${DEST_BIN}/npm"
ln -sf "${DEST_OPT}/node/bin/npx"  "${DEST_BIN}/npx"

log_step "set prefix for global packages ${HOME}/.local"
# NOTE(jlima): Enforce npm prefix for global packages
"${DEST_BIN}/npm" config set prefix "$HOME/.local"

log_step "Done!"
# NOTE(jlima): Verify runtime output
"${DEST_BIN}/node" -v
"${DEST_BIN}/npm" -v
