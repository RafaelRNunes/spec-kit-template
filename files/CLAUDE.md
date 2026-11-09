# {{NAME}}

Descreva aqui, em uma frase, o que é o projeto. Responda em Português do Brasil.

## Regras de colaboração

- A pessoa digita os comandos `/speckit-*`. Não execute um comando do Spec Kit que ela não pediu, nem gere os artefatos dele por conta própria.
- Faça uma etapa por vez. Os pontos de parada obrigatórios, com revisão da pessoa, são a spec (depois do clarify), o plano, o diagnóstico de um bug e o PR. `/speckit-tasks` e `/speckit-analyze` seguem sem parar, a pessoa digita os dois comandos, e a IA só para se o analyze apontar problema crítico ou de severidade alta.
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

## Tipos de mudança

As specs seguem o modelo flow-forward do Spec Kit: depois do merge, uma pasta de `specs/` não é mais editada e fica como histórico. Uma mudança no que já foi entregue vira spec nova, que aponta para a anterior.

| Mudança | Fluxo | Branch | Histórico |
|---|---|---|---|
| Funcionalidade nova ou melhoria | Fluxo completo | `feature/` | `specs/<pasta>/` |
| Feature grande demais para uma spec | `roadmap.md` primeiro, depois uma spec por fatia | `feature/` em cada fatia | `specs/<épico>/roadmap.md` |
| Tarefa técnica que precisa de plano | Fluxo completo, como spec técnica | `feature/` | `specs/<pasta>/` |
| Bug: o código contraria uma spec | Extensão `bug` | `fix/` | `.specify/bugs/<slug>/` |
| Tarefa técnica trivial | PR direto | `chore/` | Commits e PR |

- **Spec que altera outra:** a descrição passada ao `/speckit-specify` cita a spec anterior, e o `spec.md` começa com `Tipo: funcionalidade` ou `Tipo: técnica` e com `Altera: specs/<pasta>`, quando houver uma spec relacionada.
- **Spec técnica:** quem usa é quem mantém ou opera o sistema, e os critérios de aceite são observáveis, como "os testes continuam passando" ou "o contrato da API não muda".
- **Precisa de plano:** tem uma decisão a tomar ou mais de uma tarefa. Exemplos: refatorar um módulo, trocar uma biblioteca com breaking change. Sem plano: atualizar uma dependência patch, ajustar o CI, corrigir um texto.
- **Bug ou mudança:** se o código contraria o que a spec acordou, é bug. Se o que foi acordado precisa mudar, é spec nova.
- **Roadmap:** uma tabela com ID fixo (R1, R2...), intenção, o que entra e o que fica para outra fatia, dependências, status e o link da spec de cada fatia. Cada fatia entrega valor sozinha.
- **Bug:** `/speckit-bug-assess` diagnostica sem alterar código, e a pessoa revisa o diagnóstico antes do `/speckit-bug-fix`. Depois vêm `/speckit-bug-test`, `/code-review`, validação humana e PR, como em uma spec.

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
- O `/speckit-bug-fix` cria a branch `fix/<slug>` pelo mesmo hook, em `before_bug_fix`. Para uma tarefa técnica trivial, crie `chore/<nome-curto>` a partir da `main` atualizada.
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
| `speckit-clarify` e `speckit-bug-assess` | Conversa principal | Sonnet |
| `speckit-bug-fix` e `speckit-bug-test` | Subagente | Sonnet |

- A conversa principal usa Sonnet, e o `/code-review` roda nela.
- No máximo dois subagentes ao mesmo tempo, para não travar a máquina. O limite está em `.claude/settings.json`.
- O subagente segue as regras de branch, devolve um resumo curto e as perguntas em aberto, e não decide pela pessoa nem inicia a etapa seguinte.
- Na implementação, o Haiku repete até as verificações do projeto, como lint e testes, passarem. Se a mesma falha persistir depois de 3 tentativas, ele para e pergunta à pessoa se deve passar para Sonnet.

Perguntas de subagentes: a conversa principal é o orquestrador. Ela mostra cada pergunta em aberto com uma recomendação, e a pessoa decide. Depois, grava a decisão no artefato da etapa antes de seguir, porque o próximo subagente não vê o chat. Perguntas da spec vão para o `/speckit-clarify`. Não rode `/speckit-specify` de novo para responder a uma pergunta, pois ele cria outra pasta de spec.

## O que será construído

Liste aqui a ordem das specs, ou aponte para o `roadmap.md`. Os detalhes são decididos nas etapas do fluxo, e cada biblioteca entra na spec que a usa.

## Registro

- **Métricas:** não registre tempo nem consumo durante as etapas. O hook `before_specify` salva as métricas da branch mergeada em `docs/metrics/`, a partir das transcrições do Claude Code e do GitHub. Para gerar à mão, a pessoa roda `/metrics [branch]`.
- **Diário:** registre em `docs/diario.md` o que realmente aconteceu: o que a IA propôs, o que a pessoa mudou e por quê, surpresas e erros. Não invente nem suavize nada.
