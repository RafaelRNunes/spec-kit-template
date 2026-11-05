---
name: revisao-fim
description: Marca o fim de uma revisão humana. Use só quando a pessoa pedir.
disable-model-invocation: true
allowed-tools: Bash(.claude/revisao.sh *)
context: fork
background: false
model: haiku
---

Rode exatamente `.claude/revisao.sh fim` e devolva a saída do comando, sem fazer mais nada.
