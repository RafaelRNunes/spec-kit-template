#!/usr/bin/env bash
# Measures the real time of human review. A pause is an "end" followed by a new start.
# Usage: .claude/human-review.sh <step> | .claude/human-review.sh end
set -euo pipefail

root="$(git rev-parse --show-toplevel)"
state="$root/.claude/human-review.local"
log="$root/docs/human-review.md"
step="${1:-}"

if [ -z "$step" ]; then
  echo 'Uso: /hr <etapa> para começar (spec, plan, code, pr) e /hr end para terminar.' >&2
  exit 1
fi

if [ "$step" != "end" ]; then
  if [ -f "$state" ]; then
    echo "Já há uma revisão em andamento: $(cut -d'|' -f2 "$state"). Encerre com /hr end." >&2
    exit 1
  fi
  printf '%s|%s\n' "$(date +%s)" "$step" >"$state"
  echo "Revisão de \"$step\" iniciada às $(date '+%H:%M:%S'). Encerre com /hr end."
  exit 0
fi

if [ ! -f "$state" ]; then
  echo 'Não há revisão em andamento.' >&2
  exit 1
fi

IFS='|' read -r started_at step <"$state"
ended_at="$(date +%s)"
seconds=$((ended_at - started_at))
duration="$((seconds / 60)) min $((seconds % 60)) s"
if [ ! -f "$log" ]; then
  printf '# Revisão humana\n\nTempo marcado pela pessoa com /hr <etapa> e /hr end.\n\n| Branch | Etapa | Início | Fim | Duração | Segundos |\n|---|---|---|---|---|---|\n' >"$log"
fi
printf '| %s | %s | %s | %s | %s | %s |\n' \
  "$(git branch --show-current)" "$step" \
  "$(date -d "@$started_at" '+%Y-%m-%d %H:%M:%S')" "$(date -d "@$ended_at" '+%Y-%m-%d %H:%M:%S')" \
  "$duration" "$seconds" >>"$log"
rm -f "$state"
echo "Revisão de \"$step\" encerrada: $duration."
