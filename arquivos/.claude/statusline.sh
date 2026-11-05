#!/usr/bin/env bash
# Grava o consumo informado pelo Claude Code em um arquivo local e o mostra na status line.
# Um campo ausente fica null no arquivo: o Claude Code só envia rate_limits para assinantes
# e depois da primeira resposta da sessão.

dir="$(cd "$(dirname "$0")" && pwd)"
input="$(cat)"

tmp="$(mktemp "$dir/.consumo.XXXXXX")" || exit 0
if printf '%s' "$input" | jq --arg at "$(date '+%Y-%m-%d %H:%M:%S')" '{
  atualizado_em: $at,
  five_hour_used_percentage: .rate_limits.five_hour.used_percentage,
  seven_day_used_percentage: .rate_limits.seven_day.used_percentage
}' >"$tmp"; then
  mv "$tmp" "$dir/consumo.local.json"
else
  rm -f "$tmp"
  exit 0
fi

printf '%s' "$input" | jq -r '
  def pct: if . == null then "não medido" else "\(.)%" end;
  "5h: \(.rate_limits.five_hour.used_percentage | pct) | semana: \(.rate_limits.seven_day.used_percentage | pct)"
'
