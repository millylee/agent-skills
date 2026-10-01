# AGENTS.md

本仓库是一个 Agent Skills 集合，通过 [npx skills](https://github.com/vercel-labs/skills)（索引见 [skills.sh](https://skills.sh)）分发安装。
任何改动前先读本文件；仓库约定以本文件为唯一事实源，`CLAUDE.md` 仅是指向本文件的一行指针，内容只在这里维护。

## 目录结构

- `skills/<skill-name>/` — 可发布的技能，每个技能一个目录，入口为 `SKILL.md`。这是对外分发物，不要放仓库私有内容。
- `README.md` — 面向人的介绍与安装说明（英文默认版），另有 `README.zh-CN.md` 中文版，两者内容保持同步；技能索引表须与 `skills/` 保持同步。

> 注意：**不要**创建 `.agents/skills/`——`npx skills` 扫描源仓库时也会读这个路径，放进去的技能会被使用者一并安装。

## 新建技能

1. 新建 `skills/<name>/`，`name` 用小写中划线，体现「动词 + 对象」（如 `weekly-report`）。
2. `SKILL.md` 必须含 YAML frontmatter：
   - `name`：与目录名完全一致；
   - `description`：一句话写清「做什么 + 何时该用」，用英文，这是 agent 判断是否加载该技能的依据。
3. 正文是写给 agent 的操作指令，用祈使句，按「目的 → 步骤 → 校验」组织；保持精简，细节拆到正文引用的参考文件里。
4. 技能自包含：脚本放 `scripts/`、模板与静态资源放 `assets/`，正文用相对路径引用。
5. 起步可用官方模板：`npx skills init <name>`。
6. 在 `README.md` 技能索引表补一行。

## 本地测试

```bash
npx skills add ./skills/<name> -a claude-code --copy
```

- 在 Windows 上默认的符号链接安装方式不可靠，一律加 `--copy`。
- 安装目标只选 `claude-code` 或临时目录；**不要**选 cursor / codex 等 agent——它们会把项目级技能装进 `.agents/skills/`，而该路径会被 `npx skills` 扫描发布。
- 本地自测产物 `.claude/skills/` 已在 `.gitignore` 中，不要提交。

## Commit 规范

遵循 [Conventional Commits](https://www.conventionalcommits.org/)，格式 `<type>(<scope>): <subject>`：

- message 用英文祈使句，结尾不加句号。
- 常用 `type`：`feat` / `fix` / `docs` / `refactor` / `test` / `chore` / `build` / `ci`。
- `scope` 可选：改动单个技能时用技能名（如 `feat(clean-uninstall): ...`）；仓库级改动（README、AGENTS.md）省略 scope。
- 破坏性变更：subject 行尾加 `!`，并在 footer 写 `BREAKING CHANGE: <说明>`。

示例：

```text
feat(clean-uninstall): detect scoop installations
fix(clean-uninstall): skip Defender exclusions on PowerShell 5
docs: sync skill index in both READMEs
```

## 发布

推送到 GitHub 后即可安装：

```bash
npx skills add millylee/agent-skills
```

新增或修改技能只需正常提交推送，使用者通过 `npx skills update` 获取更新，安装统计自动出现在 skills.sh。
