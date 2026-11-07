# {{NAME}}

Descreva aqui, em uma frase, o que é o projeto. Responda em Português do Brasil.

## Regras de colaboração

- A pessoa digita os comandos `/speckit-*`. Não execute um comando do Spec Kit que ela não pediu, nem gere os artefatos dele por conta própria.
- Faça uma etapa por vez. Os pontos de parada obrigatórios, com revisão da pessoa, são a spec (depois do clarify), o plano e o PR. `/speckit-tasks` e `/speckit-analyze` seguem sem parar, a pessoa digita os dois comandos, e a IA só para se o analyze apontar problema crítico ou de severidade alta.
- Uma aprovação vale apenas para a etapa revisada. "Segue" não autoriza as etapas seguintes.
- Uma decisão sem resposta explícita continua em aberto. Pergunte, com a sua recomendação, em vez de aplicá-la.
- Explique um termo novo antes de usá-lo.

## Fluxo

| # | Etapa | Comando | Quem faz |
|---|---|---|---|
| 0 | Regras do projeto, alteradas quando necessário | `/speckit-constitution` | Pessoa e IA |
| 1 | Especificação | `/speckit-specify` | Pessoa e IA |
| 2 | Dúvidas da spec | `/speckit-clarify` | IA pergunta, pessoa responde |
| 3 | Plano | `/speckit-plan` | IA gera, pessoa analisa e aprova |
| 4 | Tarefas | `/speckit-tasks` e `/speckit-analyze` | IA gera e só para se houver problema crítico ou alto |
| 5 | Implementação | `/speckit-implement` e `/speckit-converge` | IA |
| 6 | Validação da IA | `/code-review` da branch, antes da revisão humana. A pessoa decide o que corrigir | IA |
| 7 | Validação humana | Leitura do código e execução | Pessoa |
| 8 | Pull request | IA faz push e abre o PR, pessoa revisa e faz o merge | Ambos |

Uma spec é pequena: entrega valor sozinha e é fácil de revisar. Se o specify gerar muitas histórias ou o plano ficar grande, sugira dividir em specs que ainda entreguem valor cada uma.

## Mudanças sem spec

O fluxo completo é para comportamento novo. O resto entra por um PR direto, com CI e revisão, e o histórico fica nos commits e no PR:

- **Bug:** a spec já diz como deveria funcionar. O PR cita o requisito, por exemplo `RF-009`, e traz um teste que falha sem a correção.
- **Ajuste sem comportamento novo** (visual, refatoração, dependência, configuração): o PR diz o que mudou e por quê.
- **Mudança de comportamento de uma feature existente:** atualize o `spec.md` dela no mesmo PR. Se a mudança for grande, abra uma spec nova.

Em caso de dúvida, pergunte à pessoa qual caminho seguir.

## Convenções

- Código em inglês: nomes de arquivos, variáveis, funções, classes, testes e comentários. Os nomes traduzem os termos de domínio da spec.
- Documentação, specs, planos, commits e PRs em português.
- A documentação oficial e o que o CLI do framework gera são a referência. Desvios precisam de justificativa na seção Complexity Tracking do plano.
- Testes unitários isolam dependências externas com mocks. Testes de integração usam as dependências reais.
- Nenhuma abstração, camada ou dependência sem um problema atual que a justifique. Cada biblioteca entra na spec que a usa.
- Segredos nunca entram no repositório.

## Git

- Uma spec tem uma branch e um PR. Depois do merge, ela entrega valor pronto para produção.
- A `main` não recebe commit direto. O que está nela funciona, passou no CI e cumpre as regras no que entrega.
- O `/speckit-specify` cria a branch `feature/<nome-curto>` a partir da `main` atualizada pelo hook `before_specify` (`.specify/extensions.yml` e skill `speckit-feature-branch`). Com alterações sem commit ou branch não mergeada, o hook para e pergunta.
- Para mudanças sem spec, crie a branch a partir da `main` atualizada: `fix/<nome-curto>` para bugs e `chore/<nome-curto>` para o resto.
- Faça commit, push ou PR apenas quando a etapa do fluxo pedir, nunca na `main`. O merge é sempre da pessoa.
- Faça commits pequenos: um ao fim de cada etapa aprovada e, na implementação, um por tarefa ou pequeno grupo de tarefas. O push e o PR ficam para a etapa 8.
- Mensagens de commit e títulos de PR usam `tipo: descrição`, no presente do indicativo e em português, como `feat: adiciona cadastro`. Tipos: `feat`, `fix`, `docs`, `test`, `refactor` e `chore`.
- O corpo do PR segue `.github/pull_request_template.md`. Em "Verificação", diga o que realmente rodou e o que não rodou.

## Subagentes

Um subagente é um agente separado, que trabalha sem ver esta conversa e devolve o resultado a ela.

| Skill | Execução | Modelo |
|---|---|---|
| `speckit-constitution` | Subagente | Opus |
| `speckit-specify`, `speckit-plan`, `speckit-tasks`, `speckit-analyze`, `speckit-checklist` e `speckit-converge` | Subagente | Sonnet |
| `speckit-implement` | Subagente | Haiku |
| `speckit-clarify` | Conversa principal | Sonnet |

- A conversa principal usa Sonnet, e o `/code-review` roda nela.
- No máximo dois subagentes ao mesmo tempo, para não travar a máquina. O limite está em `.claude/settings.json`.
- O subagente segue as regras de branch, devolve um resumo curto e as perguntas em aberto, e não decide pela pessoa nem inicia a etapa seguinte.
- Na implementação, o Haiku repete até as verificações do projeto, como lint e testes, passarem. Se a mesma falha persistir depois de 3 tentativas, ele para e pergunta à pessoa se deve passar para Sonnet.

Perguntas de subagentes: a conversa principal é o orquestrador. Ela mostra cada pergunta em aberto com uma recomendação, e a pessoa decide. Depois, grava a decisão no artefato da etapa antes de seguir, porque o próximo subagente não vê o chat. Perguntas da spec vão para o `/speckit-clarify`. Não rode `/speckit-specify` de novo para responder a uma pergunta, pois ele cria outra pasta de spec.

## O que será construído

Liste aqui a ordem das specs. Os detalhes são decididos nas etapas do fluxo, e cada biblioteca entra na spec que a usa.

## Registro

- **Métricas:** não registre tempo nem consumo durante as etapas. O hook `before_specify` salva as métricas da branch mergeada em `docs/metrics/`, a partir das transcrições do Claude Code e do GitHub. Para gerar à mão, a pessoa roda `/metrics [branch]`.
- **Diário:** registre em `docs/diario.md` o que realmente aconteceu: o que a IA propôs, o que a pessoa mudou e por quê, surpresas e erros. Não invente nem suavize nada.
