# ComfyUI（渲染执行体）

- 本体：`https://github.com/comfyanonymous/ComfyUI.git` **v0.33.1**（commit `72865f4f`），**不 vendor**（10GB）
- 本机路径：`/home/a/ai-work/ComfyUI`
- 启动：`bash /home/a/ai-work/minimax-h3-turing/scripts/h3_launch.local.sh`
  （防黑屏参数固定：`--reserve-vram 2.5 --vram-headroom 0.5 --disable-pinned-memory`）

## 本目录内容

| 文件 | 作用 |
|---|---|
| `patches/comfyui-v0.33.1-local.patch` | 我们对 ComfyUI 本体的本地改动（10 行，节点兼容修补）——`bootstrap.sh` 幂等应用 |
| `patches/font_util.py.new` | 新增文件（ComfyUI 本体里是未跟踪状态，补丁不含新文件） |
| `custom_nodes.tsv` | 7 个加速/扩展节点的 **仓库 URL + commit**（可复现） |

## custom_nodes 清单

| 节点 | 仓库 | commit |
|---|---|---|
| ComfyUI-ClipProj | nicolab28/ComfyUI-ClipProj | c01ba8f |
| ComfyUI-GGUF | city96/ComfyUI-GGUF | 6ea2651 |
| comfyui-minimax-h3-blockcache-T8 | T8mars/comfyui-minimax-h3-blockcache-T8 | 36336dc |
| ComfyUI-MiniMaxH3-FirstBlockCache | duckyshell/ComfyUI-MiniMaxH3-FirstBlockCache | d474755 |
| ComfyUI-MiniMax-H3-PDD-Acc | kijai/ComfyUI-MiniMax-H3-PDD-Acc | — |
| ComfyUI-MiniMax-H3-TeaCache | — | — |
| ComfyUI-MiniMax-H3-Turbo | — | — |

（完整 commit 见 `custom_nodes.tsv`；加速节点只用于草稿档，成片必须用可复现档。）
