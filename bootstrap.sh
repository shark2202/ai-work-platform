#!/usr/bin/env bash
# 平台装配：按 platform.lock.json 把三个组件装到位（幂等，可重复跑）。
#
#   bash bootstrap.sh            # 装配 + 健康检查
#   bash bootstrap.sh --check    # 只做健康检查
#
# 装配做四件事：
#   1. 校验三个组件的本地路径与 commit 是否与 lock 一致（不一致就报出来，让人决定）
#   2. 给 ComfyUI 打本地补丁（只打一次，幂等）
#   3. 装 pi-agent 的 skill（软链到 ~/.pi/agent/skills）
#   4. 装/启审片台的 systemd user service
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCK="$HERE/platform.lock.json"
EPY=/home/a/ai-work/.venv/bin/python
ONLY_CHECK=0
[ "${1:-}" = "--check" ] && ONLY_CHECK=1

# systemd user bus 在 SSH 会话里缺环境变量 → 补上
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus"

j() { $EPY -c "import json,sys;d=json.load(open('$LOCK'));print($1)"; }

echo "══ 平台装配（$(date '+%F %T')）"
echo

# ── 1. 组件校验 ───────────────────────────────────────────────
check_component() {
  local key="$1" path="$2" want="$3"
  if [ ! -d "$path/.git" ]; then
    printf "  ✗ %-14s 缺目录或不是 git 仓库：%s\n" "$key" "$path"; return 1
  fi
  local have; have=$(git -C "$path" rev-parse HEAD)
  if [ -n "$want" ] && [ "${have:0:${#want}}" != "$want" ]; then
    printf "  ! %-14s 版本不符：本地 %s，lock 写 %s\n" "$key" "${have:0:10}" "${want:0:10}"; return 2
  fi
  printf "  ✓ %-14s %s @ %s\n" "$key" "$path" "${have:0:10}"; return 0
}

rc=0
while IFS=$'\t' read -r key path commit; do
  check_component "$key" "$path" "$commit" || rc=1
done < <($EPY - <<PY
import json
d = json.load(open("$LOCK"))
for c in d["components"]:
    if c["key"] == "pi-agent":
        # skill 是从 shortdrama 仓库软链过去的：校验源仓库 + skill 文件
        print("\t".join([c["key"], "/home/a/ai-work/workspace/shortdrama", ""]))
    else:
        print("\t".join([c["key"], c["local_path"], c.get("commit","")]))
PY
)

if [ -f "$HOME/.pi/agent/skills/shortdrama-production/SKILL.md" ]; then
  printf "  ✓ %-14s %s\n" "skill 链接" "$HOME/.pi/agent/skills/shortdrama-production"
else
  printf "  ! %-14s 未安装（bash components/pi-agent/install.sh）\n" "skill 链接"
fi

if [ $ONLY_CHECK -eq 1 ]; then
  echo "── 健康检查"
  bash "$HERE/ops/healthcheck.sh"
  exit $rc
fi

# ── 2. ComfyUI 本地补丁 ───────────────────────────────────────
PATCH="$HERE/components/comfyui/patches/comfyui-v0.33.1-local.patch"
COMFY="/home/a/ai-work/ComfyUI"
if [ -f "$PATCH" ] && [ -d "$COMFY" ]; then
  if git -C "$COMFY" apply --reverse --check "$PATCH" >/dev/null 2>&1; then
    echo "  ✓ ComfyUI 补丁已应用（跳过）"
  elif git -C "$COMFY" apply --check "$PATCH" >/dev/null 2>&1; then
    git -C "$COMFY" apply "$PATCH" && echo "  ✓ ComfyUI 补丁已应用"
  else
    echo "  ! ComfyUI 补丁无法干净应用（上游可能已变），需人工处理"
  fi
fi
echo

# ── 3. pi-agent skill ─────────────────────────────────────────
echo "── pi-agent skill"
bash "$HERE/components/pi-agent/install.sh" || echo "  ! skill 安装有出入"
echo

# ── 4. 审片台服务 ─────────────────────────────────────────────
echo "── 审片台服务"
bash /home/a/ai-work/workspace/shortdrama/tools/serve_review.sh install 2>&1 | tail -3 || \
  echo "  ! 服务安装失败（shortdrama 仓库不在预期路径）"
echo

echo "── 健康检查"
bash "$HERE/ops/healthcheck.sh"
exit $rc
