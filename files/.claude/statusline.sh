#!/usr/bin/env bash
# Shows the plan usage reported by Claude Code. Claude Code only sends rate_limits to
# subscribers and after the first response of the session.
jq -r '
  def pct: if . == null then "não medido" else "\(.)%" end;
  "5h: \(.rate_limits.five_hour.used_percentage | pct) | semana: \(.rate_limits.seven_day.used_percentage | pct)"
'
