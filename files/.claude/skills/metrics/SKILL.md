---
name: metrics
description: Gera o relatório de métricas de uma branch (tempo da IA, intervalos, tokens por modelo e PR) em docs/metrics/, sem interação humana.
argument-hint: "[branch]"
disable-model-invocation: true
allowed-tools: Bash(.claude/metrics.py *)
context: fork
background: false
model: haiku
---

Rode exatamente `.claude/metrics.py --save $ARGUMENTS` e devolva a saída do comando, sem fazer mais nada.
