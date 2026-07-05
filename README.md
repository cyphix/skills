# Skills

[![skills.sh](https://skills.sh/b/cyphix/skills)](https://skills.sh/cyphix/skills)

Reusable agent skills for AI coding tools. Each skill is a folder under `skills/` with a `SKILL.md` file following the [Agent Skills](https://github.com/anthropics/skills) format.

Install with [skills.sh](https://skills.sh) / `npx skills`:

```bash
# List available skills
npx skills add cyphix/skills --list

# Install all skills
npx skills add cyphix/skills

# Install one skill
npx skills add cyphix/skills --skill godot-csharp
```

## Available skills

| Skill | Description | Dependencies |
|-------|-------------|--------------|
| [godot-csharp](skills/godot-csharp/) | Godot 4 + C# game development (C# only — never GDScript) | None |
| [github-issues](skills/github-issues/) | GitHub issue triage and Projects v2 status transitions (Backlog → Done) | [gai-ghcli](https://github.com/cyphix/gaighcli) skill + CLI |

### godot-csharp

Godot 4 + C# guidance: partial classes, signals, lifecycle, input, physics, and GDScript-to-C# porting rules.

```bash
npx skills add cyphix/skills --skill godot-csharp
```

### github-issues

Issue lifecycle and project-board staging on GitHub Projects v2. Requires **gai-ghcli** from a separate repo.

```bash
# 1. Install the CLI wrapper
go install github.com/cyphix/gaighcli/cmd/gai-ghcli@latest

# 2. Install the gai-ghcli agent skill (separate repo)
npx skills add cyphix/gaighcli --skill gai-ghcli

# 3. Install github-issues from this repo
npx skills add cyphix/skills --skill github-issues
```

Copy [issue-board.json.example](skills/github-issues/issue-board.json.example) to `.github/issue-board.json` in your project and set `projectNumber`.

## Adding skills

See [AGENTS.md](AGENTS.md) for authoring conventions, validation, and dependency rules.

## License

MIT — see [LICENSE](LICENSE).
