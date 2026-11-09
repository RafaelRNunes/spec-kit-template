---
name: metrics
description: Writes the metrics report of a branch (AI time, gaps, tokens by model and PR) to docs/metrics/, with no human input.
argument-hint: "[branch]"
disable-model-invocation: true
allowed-tools: Bash(.claude/metrics.py *)
context: fork
background: false
model: haiku
---

Run exactly `.claude/metrics.py --save $ARGUMENTS` and return its output. Do nothing else.
