---
name: hr
description: Marca o início ou o fim de uma revisão humana. Use só quando a pessoa pedir.
argument-hint: "spec | plan | code | pr | end"
disable-model-invocation: true
allowed-tools: Bash(.claude/human-review.sh *)
context: fork
background: false
model: haiku
---

Rode exatamente `.claude/human-review.sh "$ARGUMENTS"` e devolva a saída do comando, sem fazer mais nada.
