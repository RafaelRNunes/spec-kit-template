---
name: speckit-feature-branch
description: "Antes do /speckit-specify: atualiza a main, salva as métricas da branch mergeada e cria a branch da feature. Roda como hook before_specify."
argument-hint: "Descrição da feature (o mesmo texto passado ao /speckit-specify)"
user-invocable: true
disable-model-invocation: false
---

## Entrada

```text
$ARGUMENTS
```

Prepara o Git para uma nova spec. Roda sozinho como hook `before_specify`, registrado em `.specify/extensions.yml`, e também pode ser chamado à mão.

## Passos

1. Rode `git status --porcelain`. Se houver alterações, PARE: liste os arquivos e pergunte se a pessoa quer fazer commit, guardar ou descartar. Nunca guarde nem descarte por conta própria.
2. Guarde o nome da branch atual. Se não for a `main`, confira se ela está em um PR mergeado (`gh pr list --head <branch> --state merged`). Se não estiver e tiver commits fora de `origin/main`, PARE e pergunte antes de sair dela.
3. Rode `git checkout main && git pull --ff-only`. Se o pull falhar, PARE e informe.
4. Escolha `<nome-curto>`: de 2 a 4 palavras em kebab-case, tiradas da descrição.
5. Rode `git checkout -b feature/<nome-curto>`. Se a branch já existir, PARE e pergunte.
6. Se a branch guardada no passo 2 foi mergeada e `docs/metrics/<branch com / trocado por ->.md` não existe, rode `.claude/metrics.py --save <branch>`. O arquivo entra no commit da spec. Se o comando falhar, informe e siga.
7. Devolva o JSON abaixo e siga com o `/speckit-specify`:

   ```json
   {"BRANCH_NAME": "feature/<nome-curto>"}
   ```
