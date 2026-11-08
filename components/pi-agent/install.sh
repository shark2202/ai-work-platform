#!/usr/bin/env bash
# 把平台自有的 pi-agent skill 装到 ~/.pi/agent/skills（幂等：软链，重装不会断链）
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="$HOME/.pi/agent/skills"
mkdir -p "$DEST"
for s in "$HERE"/skills/*/; do
  name=$(basename "$s")
  ln -sfn "$s" "$DEST/$name"
  echo "  装上 $name → $DEST/$name"
done
