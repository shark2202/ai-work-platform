# 短剧 / 短视频生成平台 · 三组件一体管控

一句话：**pi-agent（agent 内核）+ ComfyUI（渲染执行体）+ 自定义 web 平台（看板/审片/放映/审批）**，
在本机（RTX 2080Ti 22G）跑通「一句话题材 → 本地出成片」。

本仓库是**平台总控**：钉死三个组件的版本（`platform.lock.json`）、保存我们自有的资产
（skill、ComfyUI 补丁、启动参数、服务模板）、并提供一键装配与健康检查。
**不 vendor 上游大仓库**（ComfyUI 本体 10GB、模型权重 127GB），那些用 commit 钉住、用时拉。

```
                      ┌──────────────────────────────────────────┐
   人（浏览器/手机）  │  web 平台：任务看板 · 审片台 · 放映 · 交付审批   │
        │            └───────┬──────────────────────────┬─────────┘
        │ 触发（点按钮）      │ 读状态/产物              │ 写决定
        ▼                    ▼                          ▼
   ┌─────────┐        ┌───────────────┐         ┌──────────────────┐
   │pi-agent │───────▶│ 阶段执行器      │────────▶│ job 目录（真值源） │
   │ agent 内核│        │ episode.py 等 │         │ story/shots/clips │
   └────┬────┘        └───────┬───────┘         └──────────────────┘
        │ 写剧本/台词/审片        │ ComfyUI API
        ▼                       ▼
   ┌─────────┐          ┌─────────────┐      ┌──────────────┐
   │本地 27B │◀─互斥─▶ │  ComfyUI     │─────▶│ H3 W4A8 渲染  │
   │  LLM    │  (C2)   │  :8188       │      │ Z-Image 出图  │
   └─────────┘          └─────────────┘      └──────────────┘
```

## 仓库里有什么

| 路径 | 内容 |
|---|---|
| `platform.lock.json` | **三个组件的版本钉死表**（repo + commit + 装法 + 健康检查口径）+ GPU 互斥纪律 |
| `bootstrap.sh` | 一键装配：校验版本 → 打 ComfyUI 补丁 → 装 pi-agent skill → 装/启审片台服务 → 健康检查 |
| `ops/healthcheck.sh` | 三件套 + GPU 现状一览（退出码即是否全绿） |
| `ops/shortdrama-studio.service` | 审片台的 systemd user unit 模板（审片台常驻、崩溃自愈、开机自启） |
| `components/pi-agent/` | 我们自有的 pi-agent skill（`shortdrama-production`）+ 装法脚本 |
| `components/comfyui/` | ComfyUI 本体版本 + **本地补丁** + custom_nodes 清单（每个节点的仓库与 commit） |
| `components/web/` | 自定义 web 平台的 pin（代码在 `shark2202/shortdrama`，不搬） |
| `docs/` | 架构与运维说明（索引到各仓库自己的 SOP） |

## 三个组件分别在哪

| 组件 | 仓库 | 本机路径 | 角色 |
|---|---|---|---|
| pi-agent | [shark2202/shortdrama](https://github.com/shark2202/shortdrama)（`skills/shortdrama-production`） | `~/.pi/agent/skills/shortdrama-production` | agent 内核：编剧/调度/审片代理/看板触发 |
| ComfyUI | [comfyanonymous/ComfyUI](https://github.com/comfyanonymous/ComfyUI) `v0.33.1` | `/home/a/ai-work/ComfyUI` | 渲染执行体：Z-Image 出图 + MiniMax-H3 W4A8 出镜 + 加速节点 |
| 自定义 web 平台 | [shark2202/shortdrama](https://github.com/shark2202/shortdrama) | `/home/a/ai-work/workspace/shortdrama` | 任务看板 / 审片台 / 放映 / 交付审批 / 上传包 |

配套（不是三组件，但平台依赖）：`shark2202/minimax-h3-turing`（H3 工作流与客户端库）、
`shark2202/qwen3.8-2080ti-256k`（本地 27B）、`shark2202/duanju`（剧集产物与结论）。

## 30 秒上手

```bash
git clone https://github.com/shark2202/ai-work-platform.git
cd ai-work-platform
bash bootstrap.sh          # 装配 + 健康检查
bash bootstrap.sh --check  # 只体检
```

## 纪律（写在 lock 里，也写在各仓库的方案里）

- **单卡 22GB**：本地 LLM（13–19GB）与 H3 渲染/超分（≈20GB）**不能共存** → 阶段串行 + 显存门控
  （`superres.py` 自带 `wait_gpu`，渲染前要求显存 < 4000 MiB）。
- **文件即状态**：job 目录是唯一真相源；看板/审批都只是投影与触发器（不引数据库）。
- **平台代码不 vendor 大仓库**：ComfyUI 本体与模型权重用 commit 钉住，用时拉。

## 不进版本库的东西

模型权重（127GB）、成片与中间产物（每集 ~230MB）、LLM 会话与凭据（`auth.json`、`gh/hosts.yml`）、
可再生产物（关键帧 PNG、审片拼图、上传包快照）——理由与规则见各仓库的 `.gitignore`。
