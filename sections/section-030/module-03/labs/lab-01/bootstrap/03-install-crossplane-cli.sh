#!/usr/bin/env bash
# Downloads the crossplane command line tool 2.4.1 (released separately from
# Crossplane 2.4.2) into the lab work folder that `astrona shell` mounts as
# /workspace. A failed download only prints a warning: the cluster still works
# and only `crossplane resource trace` is missing.
set -uo pipefail

VERSION=v2.4.1
LAB_NAME="${ASTRONA_LAB:-ats-019-lab-030-03}"
BIN_DIR="${HOME}/.astrona/runtime/${LAB_NAME}/work/bin"
case "$(uname -m)" in
  arm64|aarch64) ARCH=arm64 ;;
  *) ARCH=amd64 ;;
esac
mkdir -p "$BIN_DIR"
if curl -sSfL -o "$BIN_DIR/crossplane" \
  "https://cli.crossplane.io/stable/${VERSION}/bin/linux_${ARCH}/crossplane"; then
  chmod +x "$BIN_DIR/crossplane"
else
  echo "warning: could not download the crossplane CLI ${VERSION}" >&2
fi
exit 0
