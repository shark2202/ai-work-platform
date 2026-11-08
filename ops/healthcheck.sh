#!/usr/bin/env bash
# 平台健康检查：三件套是否都活着（渲染体 / agent 侧 web / 本地 LLM）+ GPU 现状。
# 退出码 0 = 全绿；1 = 有红项。
set -uo pipefail

ok=0; bad=0
row() { # row <名称> <状态> <说明>
  printf "  %-14s %-6s %s\n" "$1" "$2" "$3"
  [ "$2" = "OK" ] && ok=$((ok+1)) || bad=$((bad+1))
}

echo "── 服务"
code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 http://127.0.0.1:8188/queue 2>/dev/null)
[ "$code" = "200" ] && row "ComfyUI" OK ":8188 渲染体" || row "ComfyUI" DOWN ":8188 无响应"

code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 http://127.0.0.1:8095/api/state 2>/dev/null)
[ "$code" = "200" ] && row "审片台" OK ":8095 看板/审片/放映/审批" || row "审片台" DOWN ":8095 无响应"

if curl -s --max-time 5 http://127.0.0.1:8080/v1/models >/dev/null 2>&1; then
  row "本地LLM" OK ":8080 剧本/台词/逻辑体检"
else
  row "本地LLM" IDLE ":8080 未启动（与渲染互斥，属正常）"
fi

echo "── GPU"
if command -v nvidia-smi >/dev/null 2>&1; then
  nvidia-smi --query-gpu=name,temperature.gpu,memory.used,memory.total,utilization.gpu \
             --format=csv,noheader | while IFS= read -r l; do echo "  $l"; done
  echo "  提醒：本地 LLM 常驻 19GB 时不能跑渲染/超分（C2 硬约束）"
fi

echo "── 结果：OK $ok / 异常 $bad"
exit $((bad > 0 ? 1 : 0))
