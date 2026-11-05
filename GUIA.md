# Guia: do diretório vazio ao primeiro PR

Passo a passo para criar um projeto com Spec Kit e Claude Code: a IA propõe e executa, e a pessoa decide.

**Situação:** em validação, a partir do `nestjs-spec-kit-api`. Já funcionou em uma spec real: `/speckit-specify` e `/speckit-plan` em subagente com Sonnet, e `/speckit-clarify` na conversa principal. O Haiku implementou 36 tarefas de uma spec simples, a partir de tarefas detalhadas pelo Sonnet. Ainda falta validar o limite de subagentes, os comandos de revisão e um ciclo completo até o merge.

## 1. Preparar o projeto

```bash
./aplicar.sh ../meu-projeto
cd ../meu-projeto
```

1. No `CLAUDE.md`, preencha a descrição e a ordem das specs.
2. Faça o primeiro commit na `main` e crie o repositório. Depois disso, toda mudança entra por PR.

   ```bash
   git add -A
   git commit -m "chore: inicializa o projeto com Spec Kit"
   gh repo create meu-projeto --private --source . --remote origin --push
   ```

3. Abra o Claude Code na pasta com `claude`. Abra uma sessão nova sempre que o contexto ficar longo.

## 2. Definir a constitution

Rode `/speckit-constitution` com regras que valem para todas as features e dá para verificar. Pode citar as ferramentas já decididas.

```text
/speckit-constitution API com NestJS, Express e TypeORM. A documentação oficial e o que a
Nest CLI gera são a referência, e desvios precisam de justificativa. Controllers não têm
regra de negócio. Todo comportamento novo tem teste. Testes unitários isolam dependências
externas com mocks, e testes de integração usam o banco real. Lint e testes rodam no CI
em cada PR. Nenhuma abstração sem um problema atual que a justifique.
```

Para decidir se uma regra entra, pergunte:

- Vale para todas as features? Se não, vai para a spec ou o plano.
- Dá para apontar uma violação no código ou no plano? "Controllers sem regra de negócio" dá; "usar Clean Code" não.
- Eu rejeitaria um PR por causa dela? Se não, é preferência.

Não fique polindo: a constitution pode ser alterada depois, rodando o comando de novo. Na referência, ela consumiu mais rodadas de revisão do que qualquer outra etapa.

## 3. Dividir em specs

Regra: **uma spec = uma branch = um PR = valor pronto para produção.**

- Comece pela base do serviço, que cria o projeto, e siga com uma capacidade por spec.
- Cada biblioteca entra na spec que a usa.
- "Pronto" significa que funciona, passou no CI e cumpre as regras no que entrega. O restante segue a ordem das specs.

Exemplo: serviço no ar, logs, métricas, cadastro, consulta, atualização.

## 4. Ciclo de cada spec

| # | Etapa | Comando | Quem produz | Sua parte |
|---|---|---|---|---|
| 1 | Especificação | `/speckit-specify` | IA, com sua descrição | Descreva comportamento, sem tecnologia |
| 2 | Dúvidas | `/speckit-clarify` | IA pergunta | **Revise a spec e decida** |
| 3 | Plano | `/speckit-plan` | IA | **Revise e aprove** |
| 4 | Tarefas | `/speckit-tasks` e `/speckit-analyze` | IA | Só decide se houver problema crítico ou alto |
| 5 | Implementação | `/speckit-implement` e `/speckit-converge` | IA | - |
| 6 | Validação da IA | Testes e revisão do código | IA | - |
| 7 | Validação humana | - | Pessoa | Leia o código e execute a feature |
| 8 | Pull request | - | IA abre | **Revise e faça o merge** |

Uma etapa por vez. Você digita os comandos, e uma aprovação vale só para a etapa revisada.

### Spec

Infraestrutura também vira spec, se descrever o comportamento:

```text
/speckit-specify Serviço no ar. A equipe sobe o serviço e o banco de dados com um único
comando e confirma que os dois estão saudáveis. Toda mudança proposta passa por verificação
automática antes do merge. Fora do escopo: regras de negócio, logs e métricas.
```

O checklist da própria IA pode passar tudo e deixar excessos. Antes de aprovar, confira:

- Requisitos e metas que você não pediu, como "100% das tentativas" ou prazos sem origem.
- O que a sua infraestrutura não consegue cumprir, como bloquear merge em repositório privado sem GitHub Pro.
- Código próprio para o que a ferramenta já faz, como mensagens de erro de porta em uso.
- Frases ambíguas, como "voltar ao estado anterior", que podem esconder uma decisão.

Aplique as correções com `/speckit-clarify`. Não rode `/speckit-specify` de novo, porque ele cria outra pasta.

### Plano

```text
/speckit-plan Use PostgreSQL com Docker Compose e GitHub Actions no CI. Siga a documentação
oficial e o que o CLI do framework gera, e justifique cada biblioteca. Mantenha o plano
simples, sem antecipar as specs seguintes.
```

Antes de aprovar, confira:

- **Ferramentas:** gere o scaffold do framework em uma pasta temporária, em vez de confiar no que o plano diz que ele traz. Na referência, o plano citava Jest e ESLint, mas o CLI gerava Vitest e oxlint.
- **Comandos críticos:** faça um teste rápido. Por exemplo, `docker compose up --wait` retorna sucesso em um serviço sem healthcheck, mesmo que ele caia depois. E um app NestJS com `enableShutdownHooks()` que recebe `SIGTERM` saiu com 143 como processo filho e com 0 como PID 1 no contêiner, então o teste precisa esperar o resultado do ambiente em que roda.
- **Arquivos do scaffold:** veja o que o CLI traz além do código. A Nest CLI 12 gera um `AGENTS.md` que orienta o uso de um serviço de terceiros.
- **Testes:** o que a constitution manda testar não pode ficar só como verificação manual ou "onde for viável".
- **Clone novo e CI:** de onde vêm as variáveis de ambiente, as portas e as dependências.
- **Sua máquina:** veja se as portas do plano estão livres (`ss -ltn`). Um teste que mira a porta padrão pode até atingir o banco de outro projeto.

## 5. Subagentes e modelos

Cada comando digitado roda direto no subagente, configurado no frontmatter da skill com `context: fork`, `background: false` e `model`. Isso mantém a conversa principal pequena e usa um modelo adequado a cada tarefa.

| Etapa | Modelo | Onde roda |
|---|---|---|
| Conversa principal (orquestrador) | Sonnet | - |
| Constitution | Opus | Subagente |
| Spec, plano, tarefas, análise e converge | Sonnet | Subagente |
| Dúvidas da spec | Sonnet | Conversa principal, porque depende de diálogo |
| Implementação | Haiku, passando para Sonnet se a mesma falha persistir depois de 3 tentativas | Subagente |
| Validação da IA | Sonnet | Subagente |

- **Perguntas:** o subagente não vê o chat. Ele devolve as perguntas, o orquestrador mostra cada uma com uma recomendação, você decide, e a decisão vai para o artefato da etapa.
- **Máquina:** o modelo roda nos servidores, mas build, testes e Docker rodam localmente. Ajuste `CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS` em `.claude/settings.json`. Aqui usamos 2, e ainda não sabemos se esse limite cobre skills com fork.
- **Atualização do Spec Kit:** pode sobrescrever o frontmatter. Confira com `git diff` e reaplique.

## 6. Limites do plano

- Eles medem consumo, não horas: uma janela de 5 horas, que começa na primeira mensagem, e um limite semanal.
- São compartilhados entre os modelos e com o Claude no navegador, no desktop e no celular. A Anthropic não publica o tamanho deles e pode ajustá-los.
- O consumo depende do modelo, do esforço e do tamanho do contexto. Cada subagente faz as próprias requisições, que contam no mesmo limite.
- Use `/usage` para acompanhar e `/clear` ou uma sessão nova entre tarefas para reduzir o contexto.

## 7. Registros

A IA preenche a cada etapa, seguindo o `CLAUDE.md`:

- **`docs/tempos.md`:** horários reais, tempo da IA, consumo e tokens por modelo.
- **`docs/revisao-humana.md`:** o tempo exato de revisão. Rode `/revisao-inicio spec` ao começar e `/revisao-fim` ao terminar. Para uma pausa, rode os dois de novo. Sem essa marcação, o tempo humano é só um limite máximo.
- **`docs/diario.md`:** o que a IA propôs, o que você mudou e por quê, surpresas e erros.

Os percentuais são da conta inteira e arredondados. Para comparar etapas, use os tokens e deixe só a sessão do projeto ativa durante a etapa.

## 8. Git

- Branches a partir da `main` atualizada: `feature/<nome-curto>` para specs e `chore/<nome-curto>` para o resto.
- A `main` não recebe commit direto.
- Um commit ao fim de cada etapa aprovada e, na implementação, um por tarefa ou pequeno grupo. Push e PR ficam para o final.
- Commits e títulos de PR usam `tipo: descrição`: `feat`, `fix`, `docs`, `test`, `refactor` ou `chore`.
- O corpo do PR segue `.github/pull_request_template.md`.
- As specs são numeradas por horário, para evitar número repetido em trabalho paralelo.
- Repositório privado sem GitHub Pro não permite proteger a branch, e você não consegue aprovar um PR aberto com a própria conta. Nesse caso, o merge vale como aprovação.

## 9. Quando automatizar mais

Só depois de validar o fluxo com dados de tempo, consumo e retrabalho. Comece por tarefas de baixo risco, como testes e dependências. Cada spec depende do merge da anterior, então um loop entre specs para nesse ponto.
