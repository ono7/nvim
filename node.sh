#!/usr/bin/env bash
set -euo pipefail

# NOTE(jlima): Fail closed if executed via sudo or as root
if [ "${EUID:-$(id -u)}" -eq 0 ] || [ -n "${SUDO_USER:-}" ]; then
  echo "ERROR: Do not execute this script as root or with sudo." >&2
  exit 1
fi

# NOTE(jlima): Pin target Node.js LTS release
NODE_VERSION="v20.18.0"

# NOTE(jlima): Normalize operating system identification
OS_RAW=$(uname -s | tr '[:upper:]' '[:lower:]')
case "$OS_RAW" in
  linux*)  PLATFORM="linux" ;;
  darwin*) PLATFORM="darwin" ;;
  *) echo "Unsupported OS: $OS_RAW" >&2; exit 1 ;;
esac

# NOTE(jlima): Normalize architecture identification
ARCH_RAW=$(uname -m)
case "$ARCH_RAW" in
  x86_64|amd64) ARCH="x64" ;;
  aarch64|arm64) ARCH="arm64" ;;
  *) echo "Unsupported architecture: $ARCH_RAW" >&2; exit 1 ;;
esac

# NOTE(jlima): Select extension based on platform distribution availability
if [ "$PLATFORM" = "linux" ]; then
  EXT="tar.xz"
else
  EXT="tar.gz"
fi

# NOTE(jlima): Construct artifact identifiers
RELEASE="node-${NODE_VERSION}-${PLATFORM}-${ARCH}"
TARBALL="${RELEASE}.${EXT}"
BASE_URL="https://nodejs.org/dist/${NODE_VERSION}"

# NOTE(jlima): Create deterministic directory structure
DEST_OPT="$HOME/.local/opt"
DEST_BIN="$HOME/.local/bin"
mkdir -p "$DEST_OPT" "$DEST_BIN"

# NOTE(jlima): Download and unpack release into isolated opt path
echo "Fetching ${BASE_URL}/${TARBALL}..."
curl -fsSL "${BASE_URL}/${TARBALL}" | tar -xz -C "$DEST_OPT" 2>/dev/null || \
curl -fsSL "${BASE_URL}/${TARBALL}" | tar -xJ -C "$DEST_OPT"

# NOTE(jlima): Atomically update version pointer
rm -rf "${DEST_OPT}/node"
mv "${DEST_OPT}/${RELEASE}" "${DEST_OPT}/node"

# NOTE(jlima): Symlink binaries directly to user bin directory
ln -sf "${DEST_OPT}/node/bin/node" "${DEST_BIN}/node"
ln -sf "${DEST_OPT}/node/bin/npm"  "${DEST_BIN}/npm"
ln -sf "${DEST_OPT}/node/bin/npx"  "${DEST_BIN}/npx"

# NOTE(jlima): Ensure npm global installations deploy binaries to ~/.local/bin
"${DEST_BIN}/npm" config set prefix "$HOME/.local"

# NOTE(jlima): Verify installation resolution
"${DEST_BIN}/node" -v
"${DEST_BIN}/npm" -v
