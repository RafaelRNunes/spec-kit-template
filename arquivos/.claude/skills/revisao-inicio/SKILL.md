---
name: revisao-inicio
description: Marca o início de uma revisão humana. Use só quando a pessoa pedir.
argument-hint: "etapa, como spec, plano ou codigo"
disable-model-invocation: true
allowed-tools: Bash(.claude/revisao.sh *)
context: fork
background: false
model: haiku
---

Rode exatamente `.claude/revisao.sh inicio "$ARGUMENTS"` e devolva a saída do comando, sem fazer mais nada.
