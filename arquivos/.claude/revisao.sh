#!/usr/bin/env bash
# Mede o tempo real de revisão humana. Uma pausa é um fim seguido de um novo início.
# Uso: .claude/revisao.sh inicio "etapa" | .claude/revisao.sh fim
set -euo pipefail

raiz="$(git rev-parse --show-toplevel)"
estado="$raiz/.claude/revisao.local"
registro="$raiz/docs/revisao-humana.md"

case "${1:-}" in
  inicio)
    etapa="${2:-}"
    if [ -z "$etapa" ]; then
      echo 'Informe a etapa: revisao.sh inicio "spec"' >&2
      exit 1
    fi
    if [ -f "$estado" ]; then
      echo "Já há uma revisão em andamento: $(cut -d'|' -f2 "$estado"). Encerre-a antes." >&2
      exit 1
    fi
    printf '%s|%s\n' "$(date +%s)" "$etapa" >"$estado"
    echo "Revisão de \"$etapa\" iniciada às $(date '+%H:%M:%S')."
    ;;
  fim)
    if [ ! -f "$estado" ]; then
      echo 'Não há revisão em andamento.' >&2
      exit 1
    fi
    IFS='|' read -r inicio etapa <"$estado"
    fim="$(date +%s)"
    duracao=$((fim - inicio))
    texto="$((duracao / 60)) min $((duracao % 60)) s"
    if [ ! -f "$registro" ]; then
      printf '# Revisão humana\n\nTempo marcado pela pessoa com /revisao-inicio e /revisao-fim.\n\n| Branch | Etapa | Início | Fim | Duração | Segundos |\n|---|---|---|---|---|---|\n' >"$registro"
    fi
    printf '| %s | %s | %s | %s | %s | %s |\n' \
      "$(git branch --show-current)" "$etapa" \
      "$(date -d "@$inicio" '+%Y-%m-%d %H:%M:%S')" "$(date -d "@$fim" '+%Y-%m-%d %H:%M:%S')" \
      "$texto" "$duracao" >>"$registro"
    rm -f "$estado"
    echo "Revisão de \"$etapa\" encerrada: $texto."
    ;;
  *)
    echo 'Uso: revisao.sh inicio "etapa" | revisao.sh fim' >&2
    exit 1
    ;;
esac
