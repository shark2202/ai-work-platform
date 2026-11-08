#!/usr/bin/env bash
# 刷新 platform.lock.json 里的 commit（从各组件本地 HEAD 读）。
#
# 为什么需要这个脚本：lock 里的 commit 手抄会打错（今天就错过一次：多了一个 1 vs 6），
# 校验会一直报"版本不符"。所以：**lock 的 commit 一律由本脚本刷新，不要手改**。
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EPY=/home/a/ai-work/.venv/bin/python
$EPY - "$HERE/platform.lock.json" <<'PY'
import json, subprocess, sys
from pathlib import Path

lock = Path(sys.argv[1])
d = json.loads(lock.read_text(encoding="utf-8"))
changed = []

def head(path):
    try:
        return subprocess.run(["git", "-C", path, "rev-parse", "HEAD"],
                              capture_output=True, text=True).stdout.strip()
    except Exception:
        return ""

for c in d["components"] + d.get("supporting_repos", []):
    path = c.get("local_path")
    if not path or not Path(path, ".git").exists():
        continue
    h = head(path)
    if h and c.get("commit") != h:
        changed.append((c["key"], (c.get("commit") or "")[:10], h[:10]))
        c["commit"] = h

# web-platform 与 pi-agent 指向同一个仓库 → commit 同步
web = next((c for c in d["components"] if c["key"] == "web-platform"), None)
if web and web.get("commit"):
    for c in d["components"]:
        if c["key"] == "pi-agent" and c.get("repo") == web["repo"]:
            c["commit"] = web["commit"]

lock.write_text(json.dumps(d, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
for k, old, new in changed:
    print(f"  {k}: {old} → {new}")
print(f"[relock] 已刷新 {len(changed)} 处 commit")
PY
