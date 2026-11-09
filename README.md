# Modelo de projeto com Spec Kit e Claude Code

Prepara qualquer projeto novo, em qualquer linguagem ou framework, com o padrão de trabalho: etapas com revisão humana, subagentes, modelo por etapa, métricas automáticas e convenções de código, commit e PR.

**O passo a passo e o diagrama do fluxo estão no [GUIA.md](GUIA.md).**

**Situação:** em validação. O guia indica o que já funcionou e o que ainda falta.

## Uso

Requer `specify`, `git`, `jq`, `python3` e Claude Code.

```bash
./apply.sh ../meu-projeto
```

O script só aceita um diretório novo ou vazio. Ele roda o `specify init`, copia os arquivos de `files/`, instala a extensão `bug`, ajusta as skills e a numeração, e não faz commit.

## O que é configurado

| Arquivo | O que faz |
|---|---|
| `CLAUDE.md` | Colaboração, etapas, convenções, Git, subagentes e registro |
| `.claude/settings.json` | Sonnet na conversa principal, até 2 subagentes e status line |
| `.claude/skills/speckit-*/SKILL.md` | Subagente e modelo de cada etapa |
| `.claude/statusline.sh` | Mostra os percentuais de 5 horas e semanal |
| `.specify/extensions.yml` e skill `speckit-feature-branch` | Antes do specify e da correção de bug: atualizam a `main`, salvam as métricas da branch anterior e criam a branch |
| Extensão `bug` do Spec Kit | Diagnóstico, correção e teste de bugs, em `.specify/bugs/<slug>/` |
| `.claude/metrics.py` e `/metrics [branch]` | Métricas da branch, sem interação humana: tempo, tokens por modelo e PR, em `docs/metrics/` |
| `.github/pull_request_template.md` | Corpo padrão do PR |
| `docs/diario.md` | O que aconteceu em cada etapa |
| `.specify/init-options.json` | Numeração das specs por horário |
