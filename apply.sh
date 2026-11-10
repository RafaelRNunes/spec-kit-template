#!/usr/bin/env bash
# Prepares a new project with Spec Kit and the workflow of this template.
# Usage: ./apply.sh <project-path> [language-tag]
# The language tag (BCP 47, like en, en-GB, pt-BR, es) applies to replies, constitution,
# specs, plans, docs, commits and PRs. Code is always in English. Default: en.
set -euo pipefail

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
  echo "Usage: $0 <project-path> [language-tag, like en, en-GB, pt-BR]" >&2
  exit 1
fi

template="$(cd "$(dirname "$0")" && pwd)"
target="$1"
language="${2:-en}"
if ! [[ "$language" =~ ^[A-Za-z]{2,3}(-[A-Za-z]{2}|-[0-9]{3})?$ ]]; then
  echo "Error: invalid language tag: $language. Use a BCP 47 tag, like en, en-US, en-GB or pt-BR." >&2
  exit 1
fi
primary="${language%%-*}"
region="${language#"$primary"}"
language="${primary,,}${region^^}"

if [ -e "$target" ] && [ -n "$(ls -A "$target")" ]; then
  echo "Error: $target exists and is not empty. The template only applies to a new directory." >&2
  exit 1
fi

for command in specify git jq python3; do
  command -v "$command" >/dev/null || { echo "Error: command not found: $command" >&2; exit 1; }
done

specify init "$target" --integration claude --non-interactive

cp -R "$template/files/." "$target/"
name="$(basename "$(cd "$target" && pwd)")"
sed -i "s/{{NAME}}/$name/; s/{{LANGUAGE}}/$language/" "$target/CLAUDE.md"
(cd "$target" && specify extension add bug >/dev/null)

python3 - "$target" <<'PY'
import json
import sys
from pathlib import Path

target = Path(sys.argv[1])

options = target / ".specify" / "init-options.json"
data = json.loads(options.read_text(encoding="utf-8"))
data["feature_numbering"] = "timestamp"
options.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")

FORK = {"context": "fork", "background": "false"}
SKILLS = {
    "speckit-constitution": {**FORK, "model": "opus"},
    "speckit-specify": {**FORK, "model": "sonnet"},
    "speckit-plan": {**FORK, "model": "sonnet"},
    "speckit-tasks": {**FORK, "model": "sonnet"},
    "speckit-analyze": {**FORK, "model": "sonnet"},
    "speckit-checklist": {**FORK, "model": "sonnet"},
    "speckit-converge": {**FORK, "model": "sonnet"},
    "speckit-implement": {**FORK, "model": "haiku"},
    "speckit-clarify": {"model": "sonnet"},
    "speckit-bug-assess": {"model": "sonnet"},
    "speckit-bug-fix": {**FORK, "model": "sonnet"},
    "speckit-bug-test": {**FORK, "model": "sonnet"},
}

for skill, fields in SKILLS.items():
    path = target / ".claude" / "skills" / skill / "SKILL.md"
    lines = path.read_text(encoding="utf-8").split("\n")
    if lines[0] != "---" or "---" not in lines[1:]:
        sys.exit(f"Error: {path} does not have the expected frontmatter.")
    end = lines.index("---", 1)
    added = [f"{key}: {value}" for key, value in fields.items()]
    path.write_text("\n".join(lines[:end] + added + lines[end:]), encoding="utf-8")
PY

git -C "$target" rev-parse --is-inside-work-tree >/dev/null 2>&1 || git -C "$target" init -q -b main

echo
echo "Project ready in $target. Nothing was committed."
echo "Next: review CLAUDE.md, create the repository and open a Claude Code session in the folder."
