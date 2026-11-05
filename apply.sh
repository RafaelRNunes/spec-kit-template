#!/usr/bin/env bash
# Prepares a new project with Spec Kit and the workflow of this template.
# Usage: ./apply.sh <project-path>
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Uso: $0 <caminho-do-projeto>" >&2
  exit 1
fi

template="$(cd "$(dirname "$0")" && pwd)"
target="$1"

if [ -e "$target" ] && [ -n "$(ls -A "$target")" ]; then
  echo "Erro: $target já existe e não está vazio. O modelo só é aplicado em um diretório novo." >&2
  exit 1
fi

for command in specify git jq python3; do
  command -v "$command" >/dev/null || { echo "Erro: comando não encontrado: $command" >&2; exit 1; }
done

specify init "$target" --integration claude --non-interactive

cp -R "$template/files/." "$target/"
name="$(basename "$(cd "$target" && pwd)")"
sed -i "s/{{NAME}}/$name/" "$target/CLAUDE.md"

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
}

for skill, fields in SKILLS.items():
    path = target / ".claude" / "skills" / skill / "SKILL.md"
    lines = path.read_text(encoding="utf-8").split("\n")
    if lines[0] != "---" or "---" not in lines[1:]:
        sys.exit(f"Erro: {path} não tem o frontmatter esperado.")
    end = lines.index("---", 1)
    added = [f"{key}: {value}" for key, value in fields.items()]
    path.write_text("\n".join(lines[:end] + added + lines[end:]), encoding="utf-8")
PY

git -C "$target" rev-parse --is-inside-work-tree >/dev/null 2>&1 || git -C "$target" init -q -b main

echo
echo "Projeto pronto em $target. Nada foi commitado."
echo "Próximos passos: revise o CLAUDE.md, crie o repositório e abra uma sessão do Claude Code na pasta."
