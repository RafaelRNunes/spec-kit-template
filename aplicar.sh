#!/usr/bin/env bash
# Prepara um projeto novo com Spec Kit e o padrão de trabalho deste modelo.
# Uso: ./aplicar.sh <caminho-do-projeto>
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Uso: $0 <caminho-do-projeto>" >&2
  exit 1
fi

modelo="$(cd "$(dirname "$0")" && pwd)"
destino="$1"

if [ -e "$destino" ] && [ -n "$(ls -A "$destino")" ]; then
  echo "Erro: $destino já existe e não está vazio. O modelo só é aplicado em um diretório novo." >&2
  exit 1
fi

for comando in specify git jq python3; do
  command -v "$comando" >/dev/null || { echo "Erro: comando não encontrado: $comando" >&2; exit 1; }
done

specify init "$destino" --integration claude --non-interactive

cp -R "$modelo/arquivos/." "$destino/"
nome="$(basename "$(cd "$destino" && pwd)")"
sed -i "s/{{NOME}}/$nome/" "$destino/CLAUDE.md"

python3 - "$destino" <<'PY'
import json
import sys
from pathlib import Path

destino = Path(sys.argv[1])

opcoes = destino / ".specify" / "init-options.json"
dados = json.loads(opcoes.read_text(encoding="utf-8"))
dados["feature_numbering"] = "timestamp"
opcoes.write_text(json.dumps(dados, indent=2) + "\n", encoding="utf-8")

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

for skill, campos in SKILLS.items():
    arquivo = destino / ".claude" / "skills" / skill / "SKILL.md"
    linhas = arquivo.read_text(encoding="utf-8").split("\n")
    if linhas[0] != "---" or "---" not in linhas[1:]:
        sys.exit(f"Erro: {arquivo} não tem o frontmatter esperado.")
    fim = linhas.index("---", 1)
    novas = [f"{chave}: {valor}" for chave, valor in campos.items()]
    arquivo.write_text("\n".join(linhas[:fim] + novas + linhas[fim:]), encoding="utf-8")
PY

git -C "$destino" rev-parse --is-inside-work-tree >/dev/null 2>&1 || git -C "$destino" init -q -b main

echo
echo "Projeto pronto em $destino. Nada foi commitado."
echo "Próximos passos: revise o CLAUDE.md, crie o repositório e abra uma sessão do Claude Code na pasta."
