---
name: speckit-feature-branch
description: "Antes do /speckit-specify e do /speckit-bug-fix: atualiza a main, salva as métricas da branch mergeada e cria a branch. Roda como hook before_specify e before_bug_fix."
argument-hint: "Descrição da feature (o mesmo texto passado ao /speckit-specify) ou o slug do bug"
user-invocable: true
disable-model-invocation: false
---

## Entrada

```text
$ARGUMENTS
```

Prepara o Git para uma nova spec ou para a correção de um bug. Roda sozinho como hook `before_specify` e `before_bug_fix`, registrados em `.specify/extensions.yml`, e também pode ser chamado à mão.

## Passos

1. Rode `git status --porcelain`. Se houver alterações, PARE: liste os arquivos e pergunte se a pessoa quer fazer commit, guardar ou descartar. Nunca guarde nem descarte por conta própria. Exceção: no `/speckit-bug-fix`, arquivos novos em `.specify/bugs/<BUG_SLUG>/` são o diagnóstico do bug e seguem para a nova branch.
2. Guarde o nome da branch atual. Se não for a `main`, confira se ela está em um PR mergeado (`gh pr list --head <branch> --state merged`). Se não estiver e tiver commits fora de `origin/main`, PARE e pergunte antes de sair dela.
3. Rode `git checkout main && git pull --ff-only`. Se o pull falhar, PARE e informe.
4. Escolha a branch:
   - No `/speckit-specify`: `feature/<nome-curto>`, com `<nome-curto>` de 2 a 4 palavras em kebab-case, tiradas da descrição.
   - No `/speckit-bug-fix`: `fix/<BUG_SLUG>`.
5. Rode `git checkout -b <branch>`. Se a branch já existir, PARE e pergunte.
6. Se a branch guardada no passo 2 foi mergeada e `docs/metrics/<branch com / trocado por ->.md` não existe, rode `.claude/metrics.py --save <branch>`. O arquivo entra no primeiro commit da nova branch. Se o comando falhar, informe e siga.
7. Devolva o JSON abaixo e siga com o comando que chamou o hook:

   ```json
   {"BRANCH_NAME": "<branch>"}
   ```
