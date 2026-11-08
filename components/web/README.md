# 自定义 web 平台（看板 / 审片 / 放映 / 审批）

代码**不在本仓库**：它是独立仓库 `shark2202/shortdrama`（薄编排层，不改动 ComfyUI / H3 两个既有仓库）。
本目录只放 **pin**（仓库地址 + 钉死的 commit + 本机路径），由 `platform.lock.json` 统一管理。

## 为什么不做成 submodule

短剧平台每天都在改（今天就推了 10+ 次），做成 submodule 会让每次改动都要在父仓库里更新指针，
两个仓库的提交历史互相牵制。改成"pin + lock 校验"后：改代码只在自己的仓库提交，
本仓库只在**平台形态变了**（换组件、换版本、换装法）时才动。

## 本机路径

`/home/a/ai-work/workspace/shortdrama`（安装：`bash tools/serve_review.sh install` → systemd user service）
