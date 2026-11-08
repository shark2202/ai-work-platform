# pi-agent（agent 内核）

平台里的 agent 负责：写剧本、补台词、逐镜审片结论、触发阶段、给审批出客观门禁。

- **本目录**：我们自有的 skill（`skills/shortdrama-production`）+ 装法脚本（软链到 `~/.pi/agent/skills`）
- **运行时的其余配置**（provider、扩展、模型映射）在 `~/.pi/agent/`，**不入版本库**
  （`auth.json` 含凭据、`models.json` 指向本机权重路径）

## 装法

```bash
bash components/pi-agent/install.sh
ls ~/.pi/agent/skills/shortdrama-production/SKILL.md   # 验证
```

## 与平台的关系

skill 描述"怎么从一句话到成片"，真正的执行器是 web 平台仓库里的 `shortdrama/episode.py` 与 `tools/`；
agent 通过**阶段任务卡**驱动它们（见 `shark2202/shortdrama` 的方案 §4.3/§4.4）。
