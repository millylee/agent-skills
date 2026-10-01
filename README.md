# agent-skills

[English](README.md) | [简体中文](README.zh-CN.md)

A personal collection of [Agent Skills](https://agentskills.io) for AI coding agents such as Claude Code, installable via Vercel's [skills CLI](https://github.com/vercel-labs/skills):

```bash
npx skills add millylee/agent-skills            # interactively pick skills to install
npx skills add millylee/agent-skills -s <name>  # install a specific skill
```

## Skills

| Skill | Description |
| --- | --- |
| [clean-uninstall](skills/clean-uninstall/) | Fully uninstall apps on Windows/macOS/Linux: inventory every footprint → confirm the checklist → run the official uninstaller → sweep leftovers |

## Repository layout

- `skills/` — publishable skills; see [AGENTS.md](AGENTS.md) for development conventions.
