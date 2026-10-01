# agent-skills

[English](README.md) | [简体中文](README.zh-CN.md)

个人 Agent Skills 集合，遵循 [Agent Skills](https://agentskills.io) 规范，适用于 Claude Code 等 AI 编程 agent，通过 Vercel 的 [skills CLI](https://github.com/vercel-labs/skills) 安装：

```bash
npx skills add millylee/agent-skills            # 交互式选择要安装的技能
npx skills add millylee/agent-skills -s <name>  # 安装指定技能
```

## 技能列表

| 技能 | 说明 |
| --- | --- |
| [clean-uninstall](skills/clean-uninstall/) | 跨平台软件干净卸载（Windows/macOS/Linux）：盘点痕迹 → 清单确认 → 卸载 → 清扫残留 |

## 目录约定

- `skills/` — 可发布的技能，见 [AGENTS.md](AGENTS.md) 的开发规范。
