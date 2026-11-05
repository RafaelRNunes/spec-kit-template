#!/usr/bin/env bash
# Mede o tempo real de revisão humana. Uma pausa é um "end" seguido de um novo início.
# Uso: .claude/human-review.sh <etapa> | .claude/human-review.sh end
set -euo pipefail

raiz="$(git rev-parse --show-toplevel)"
estado="$raiz/.claude/human-review.local"
registro="$raiz/docs/human-review.md"
etapa="${1:-}"

if [ -z "$etapa" ]; then
  echo 'Uso: /hr <etapa> para começar (spec, plan, code, pr) e /hr end para terminar.' >&2
  exit 1
fi

if [ "$etapa" != "end" ]; then
  if [ -f "$estado" ]; then
    echo "Já há uma revisão em andamento: $(cut -d'|' -f2 "$estado"). Encerre com /hr end." >&2
    exit 1
  fi
  printf '%s|%s\n' "$(date +%s)" "$etapa" >"$estado"
  echo "Revisão de \"$etapa\" iniciada às $(date '+%H:%M:%S'). Encerre com /hr end."
  exit 0
fi

if [ ! -f "$estado" ]; then
  echo 'Não há revisão em andamento.' >&2
  exit 1
fi

IFS='|' read -r inicio etapa <"$estado"
fim="$(date +%s)"
duracao=$((fim - inicio))
texto="$((duracao / 60)) min $((duracao % 60)) s"
if [ ! -f "$registro" ]; then
  printf '# Revisão humana\n\nTempo marcado pela pessoa com /hr <etapa> e /hr end.\n\n| Branch | Etapa | Início | Fim | Duração | Segundos |\n|---|---|---|---|---|---|\n' >"$registro"
fi
printf '| %s | %s | %s | %s | %s | %s |\n' \
  "$(git branch --show-current)" "$etapa" \
  "$(date -d "@$inicio" '+%Y-%m-%d %H:%M:%S')" "$(date -d "@$fim" '+%Y-%m-%d %H:%M:%S')" \
  "$texto" "$duracao" >>"$registro"
rm -f "$estado"
echo "Revisão de \"$etapa\" encerrada: $texto."
