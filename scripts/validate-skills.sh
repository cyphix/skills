#!/usr/bin/env bash
# Validate skill directories and frontmatter in this repository.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_DIR="$ROOT/skills"
README="$ROOT/README.md"

errors=0
warnings=0

err() {
  echo "ERROR: $*" >&2
  errors=$((errors + 1))
}

warn() {
  echo "WARN: $*" >&2
  warnings=$((warnings + 1))
}

if [[ ! -d "$SKILLS_DIR" ]]; then
  err "skills/ directory not found at $SKILLS_DIR"
  exit 1
fi

if [[ ! -f "$README" ]]; then
  err "README.md not found at $README"
  exit 1
fi

parse_frontmatter() {
  local file="$1"
  awk '
    BEGIN { in_fm = 0; fm_end = 0; desc = ""; desc_fold = 0 }
    /^---$/ {
      if (NR == 1) { in_fm = 1; next }
      if (in_fm) { fm_end = 1; in_fm = 0; next }
    }
    in_fm {
      if ($1 == "name:") {
        name = $2
        gsub(/^["'\''>]|["'\''>]$/, "", name)
        gsub(/^>/, "", name)
        sub(/^[[:space:]]+/, "", name)
      }
      if ($1 == "description:") {
        rest = substr($0, index($0, "description:") + length("description:"))
        sub(/^[[:space:]]+/, "", rest)
        if (rest == "" || rest == ">") {
          desc_fold = 1
        } else {
          gsub(/^["'\''>]|["'\''>]$/, "", rest)
          sub(/^>[[:space:]]*/, "", rest)
          desc = rest
        }
        next
      }
      if (desc_fold && /^[[:space:]]+/ && $0 !~ /^[[:space:]]*#/ ) {
        line = $0
        sub(/^[[:space:]]+/, "", line)
        desc = (desc == "" ? line : desc " " line)
        next
      }
      if (desc_fold && $1 ~ /^[a-zA-Z0-9_-]+:/ ) {
        desc_fold = 0
      }
    }
    END {
      if (name != "") print "name=" name
      if (desc != "") print "description=" desc
    }
  ' "$file"
}

extract_frontmatter_field() {
  local file="$1"
  local field="$2"
  parse_frontmatter "$file" | sed -n "s/^${field}=//p" | head -n 1
}

found_skills=0

for skill_dir in "$SKILLS_DIR"/*/; do
  [[ -d "$skill_dir" ]] || continue
  skill_name="$(basename "$skill_dir")"
  skill_md="$skill_dir/SKILL.md"
  found_skills=$((found_skills + 1))

  if [[ ! -f "$skill_md" ]]; then
    err "skills/$skill_name/ is missing SKILL.md"
    continue
  fi

  if ! head -n 1 "$skill_md" | grep -q '^---$'; then
    err "skills/$skill_name/SKILL.md must start with YAML frontmatter (---)"
  fi

  name="$(extract_frontmatter_field "$skill_md" "name")"
  description="$(extract_frontmatter_field "$skill_md" "description")"

  if [[ -z "$name" ]]; then
    err "skills/$skill_name/SKILL.md: missing frontmatter field 'name'"
  elif [[ "$name" != "$skill_name" ]]; then
    err "skills/$skill_name/SKILL.md: name '$name' does not match directory '$skill_name'"
  fi

  if [[ -z "$description" ]]; then
    err "skills/$skill_name/SKILL.md: missing frontmatter field 'description'"
  fi

  line_count="$(wc -l < "$skill_md" | tr -d ' ')"
  if [[ "$line_count" -gt 500 ]]; then
    warn "skills/$skill_name/SKILL.md has $line_count lines (recommended max 500)"
  fi

  if ! grep -q "$skill_name" "$README"; then
    err "skills/$skill_name/ is not listed in README.md"
  fi
done

if [[ "$found_skills" -eq 0 ]]; then
  err "no skills found under skills/"
fi

# Ensure every skills/* directory has SKILL.md (catch empty or misnamed dirs)
for entry in "$SKILLS_DIR"/*; do
  [[ -e "$entry" ]] || continue
  if [[ -d "$entry" && ! -f "$entry/SKILL.md" ]]; then
    err "$(basename "$entry")/ directory exists but has no SKILL.md"
  fi
done

echo "Validated $found_skills skill(s)."

if [[ "$warnings" -gt 0 ]]; then
  echo "$warnings warning(s)."
fi

if [[ "$errors" -gt 0 ]]; then
  echo "$errors error(s)." >&2
  exit 1
fi

echo "OK"
