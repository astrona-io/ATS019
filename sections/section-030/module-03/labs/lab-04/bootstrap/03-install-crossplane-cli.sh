#!/usr/bin/env bash
# Install CLI 2.4.1 in the work folder mounted as /workspace on terminal.
# Fail bootstrap if the required CLI cannot be downloaded.
set -euo pipefail
VERSION=v2.4.1
LAB_NAME="${ASTRONA_LAB:-ats-019-lab-030-03-04}"
BIN_DIR="${HOME}/.astrona/runtime/${LAB_NAME}/work/bin"
case "$(uname -m)" in
  arm64|aarch64) ARCH=arm64 ;;
  x86_64|amd64) ARCH=amd64 ;;
  *) echo "Unsupported terminal architecture" >&2; exit 1 ;;
esac
mkdir -p "$BIN_DIR"
curl -fsSL --retry 3 -o "$BIN_DIR/crossplane" \
  "https://cli.crossplane.io/stable/${VERSION}/bin/linux_${ARCH}/crossplane"
chmod +x "$BIN_DIR/crossplane"
