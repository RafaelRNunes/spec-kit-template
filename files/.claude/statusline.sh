#!/usr/bin/env bash
# Writes the usage reported by Claude Code to a local file and shows it in the status line.
# A missing field becomes null: Claude Code only sends rate_limits to subscribers and after
# the first response of the session.

dir="$(cd "$(dirname "$0")" && pwd)"
input="$(cat)"

tmp="$(mktemp "$dir/.usage.XXXXXX")" || exit 0
if printf '%s' "$input" | jq --arg at "$(date '+%Y-%m-%d %H:%M:%S')" '{
  updated_at: $at,
  five_hour_used_percentage: .rate_limits.five_hour.used_percentage,
  seven_day_used_percentage: .rate_limits.seven_day.used_percentage
}' >"$tmp"; then
  mv "$tmp" "$dir/usage.local.json"
else
  rm -f "$tmp"
  exit 0
fi

printf '%s' "$input" | jq -r '
  def pct: if . == null then "não medido" else "\(.)%" end;
  "5h: \(.rate_limits.five_hour.used_percentage | pct) | semana: \(.rate_limits.seven_day.used_percentage | pct)"
'
