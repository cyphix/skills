# Agent instructions

This repository is a catalog of installable agent skills published at [skills.sh/cyphix/skills](https://skills.sh/cyphix/skills). Each skill teaches coding agents how to perform a specialized workflow.

## Layout

```text
skills/
└── <skill-name>/
    ├── SKILL.md              # Required — YAML frontmatter + instructions
    └── <supporting files>    # Optional — examples, templates, scripts (one level deep)
```

Skills are discovered automatically by `npx skills` from committed `skills/<name>/SKILL.md` files. No manifest or registry file is required.

## Required frontmatter

Every `SKILL.md` must start with YAML frontmatter:

```yaml
---
name: skill-name
description: What the skill does and when to use it (third person, WHAT + WHEN).
---
```

| Field | Rule |
|-------|------|
| `name` | Lowercase, hyphens only; **must match** the parent directory name |
| `description` | Non-empty; include trigger terms so agents know when to apply the skill |

Optional fields (`user-invocable`, `author`, `metadata`) are allowed when needed.

## Adding a skill

1. Create `skills/<skill-name>/SKILL.md` with valid frontmatter.
2. Add optional supporting files alongside `SKILL.md` (not nested deeper).
3. List the skill in [README.md](README.md) (Available skills table).
4. Run validation before committing:

```bash
scripts/validate-skills.sh
```

5. Verify discovery:

```bash
npx skills add . --list
```

## Cross-skill dependencies

When a skill depends on another skill in a **different repo**, document the install command and canonical source URL. Do not use relative links like `../other-skill/SKILL.md` to skills that live elsewhere.

Example: `github-issues` requires the **gai-ghcli** skill from [cyphix/gaighcli](https://github.com/cyphix/gaighcli):

```bash
npx skills add cyphix/gaighcli --skill gai-ghcli -g -y
```

After install, agents read `.agents/skills/gai-ghcli/SKILL.md` (project) or `~/.agents/skills/gai-ghcli/SKILL.md` (global).

## Commands

```bash
# Validate all skills in this repo
scripts/validate-skills.sh

# List skills discoverable from local checkout
npx skills add . --list

# List skills from GitHub (after push)
npx skills add cyphix/skills --list

# Install one skill globally for Cursor
npx skills add cyphix/skills --skill <name> -g -a cursor -y
```

## Non-negotiables

- Keep each `SKILL.md` under 500 lines; move detailed material to supporting files.
- Supporting file references from `SKILL.md` should be one level deep only.
- Never commit secrets, tokens, or credentials in skill content.
- Do not add README or changelog files inside individual skill directories.
- Leave unrelated dirty worktree changes untouched.
