# Modelo de projeto com Spec Kit e Claude Code

Prepara um projeto novo com o padrão de trabalho: etapas com revisão humana, subagentes, modelo por etapa, medição de tempo e consumo, e regras de commit e PR.

**O passo a passo completo está no [GUIA.md](GUIA.md).**

**Situação:** em validação, a partir do `nestjs-spec-kit-api`. O guia indica o que já funcionou e o que ainda falta.

## Uso

Requer `specify`, `git`, `jq`, `python3` e Claude Code.

```bash
./aplicar.sh ../meu-projeto
```

O script só aceita um diretório novo ou vazio. Ele roda o `specify init`, copia os arquivos de `arquivos/`, ajusta as skills e a numeração, e não faz commit.

## O que é configurado

| Arquivo | O que faz |
|---|---|
| `CLAUDE.md` | Colaboração, etapas, Git, subagentes e registro |
| `.claude/settings.json` | Sonnet na conversa principal, até 2 subagentes e status line |
| `.claude/skills/speckit-*/SKILL.md` | Subagente e modelo de cada etapa |
| `.claude/statusline.sh` | Grava os percentuais de 5 horas e semanal em um arquivo local |
| `.claude/tokens-por-modelo.py` | Soma os tokens por modelo em um intervalo |
| `/revisao-inicio` e `/revisao-fim` | Medem o tempo real de revisão humana em `docs/revisao-humana.md` |
| `.github/pull_request_template.md` | Corpo padrão do PR |
| `docs/tempos.md` e `docs/diario.md` | Registros de cada etapa |
| `.specify/init-options.json` | Numeração das specs por horário |
