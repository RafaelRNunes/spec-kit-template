# Modelo de projeto com Spec Kit

Prepara um projeto novo com o padrão de trabalho: etapas com revisão humana, subagentes, modelo por etapa, medição de tempo e consumo, e regras de commit e PR.

**Situação:** em validação. Foi extraído de `nestjs-spec-kit-api`. O `context: fork` com Sonnet funcionou em uma spec real, mas falta validar o Haiku, o limite de subagentes e a medição completa de uma etapa.

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

## O que colocar em cada artefato

- **Constitution:** regras que valem para todas as features e dá para verificar. Pode citar ferramentas já decididas. Evite listas de siglas, como Clean Code ou SOLID: "controllers sem regra de negócio" dá para checar, "usar Clean Code" não.
- **Spec:** comportamento e valor, sem tecnologia. Infraestrutura vira spec quando descreve o comportamento, como "a equipe sobe o serviço com um comando". Uma spec gera um PR com valor pronto para produção.
- **Plano:** as escolhas técnicas ainda abertas. Peça o caminho mais padrão do ecossistema, com justificativa para cada dependência, e sem antecipar specs seguintes.
- **Tasks:** os passos, como criar o projeto com o CLI do framework.

## O que conferir na spec

O checklist da própria IA pode passar tudo e deixar excessos. Antes de aprovar, confira:

- Requisitos e metas que você não pediu, como "100% das tentativas" ou prazos sem origem.
- Requisitos que a sua infraestrutura não consegue cumprir, como bloquear merge em repositório privado sem GitHub Pro.
- Código próprio para o que a ferramenta já faz, como mensagens de erro de porta em uso.
- Frases ambíguas, como "voltar ao estado anterior", que podem esconder uma decisão.

Use o `/speckit-clarify` para aplicar as correções, e não rode o `/speckit-specify` de novo, porque ele cria outra pasta.

## O que conferir no plano

- Ferramentas e versões contra a realidade: gere o scaffold do framework em uma pasta temporária, em vez de confiar no que o plano diz que ele traz.
- Comandos críticos, em um teste rápido. Por exemplo, `docker compose up --wait` retorna sucesso em um serviço sem healthcheck, mesmo que ele caia depois.
- Comportamentos que a constitution manda testar e ficaram só como verificação manual ou "onde for viável".
- Como os testes rodam em um clone novo e no CI: variáveis de ambiente, portas e dependências.

## Ajustes

O limite de 2 subagentes vale para a máquina atual. Ajuste em `.claude/settings.json`.

Atualizar o Spec Kit pode sobrescrever o frontmatter das skills. Confira com `git diff` e reaplique.
