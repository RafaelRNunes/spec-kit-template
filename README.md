# Modelo de projeto com Spec Kit

Prepara um projeto novo com o padrão de trabalho: etapas com revisão humana, subagentes, modelo por etapa, medição de tempo e consumo, e regras de commit e PR.

**Situação:** em validação. Foi extraído de `nestjs-spec-kit-api`, e os subagentes, o Haiku e a medição por etapa ainda não rodaram em uma spec real. Ajuste com o que a prática mostrar.

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
| `.github/pull_request_template.md` | Corpo padrão do PR |
| `docs/tempos.md` e `docs/diario.md` | Registros de cada etapa |
| `.specify/init-options.json` | Numeração das specs por horário |

## Depois de aplicar

1. Preencha a descrição e a ordem das specs no `CLAUDE.md`.
2. Crie o repositório e faça o primeiro commit na `main`. Depois disso, toda mudança entra por PR.
3. Abra uma sessão do Claude Code na pasta e rode `/speckit-constitution`.
4. Faça a primeira spec criar o projeto e a base do serviço.

O limite de 2 subagentes vale para a máquina atual. Ajuste em `.claude/settings.json`.

Atualizar o Spec Kit pode sobrescrever o frontmatter das skills. Confira com `git diff` e reaplique.
