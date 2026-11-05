# Guia: do diretório vazio ao primeiro PR

Passo a passo para criar qualquer projeto com Spec Kit e Claude Code, em qualquer linguagem ou framework: a IA propõe e executa, e a pessoa decide.

**Situação:** em validação. Já funcionou em uma spec real: especificação e plano em subagente com Sonnet, dúvidas na conversa principal e implementação de 36 tarefas com Haiku, a partir de tarefas detalhadas pelo Sonnet. Ainda falta validar o limite de subagentes, o comando `/hr` e um ciclo completo até o merge.

## Fluxo

Em azul, o que a pessoa faz; em verde, o que a IA faz.

```mermaid
flowchart TD
    A["./apply.sh e primeiro commit"]:::human --> B["/speckit-constitution"]:::ai
    B --> C["/hr constitution: revisar as regras"]:::human
    C --> D["Definir a ordem das specs"]:::human

    D --> F["/speckit-specify: cria a branch a partir da main atualizada e gera a spec"]:::ai
    F --> G["/hr spec: revisar a spec"]:::human
    G --> H["/speckit-clarify: aplicar correções e decisões"]:::human
    H --> I{"Spec aprovada?"}:::human
    I -- Não --> H
    I -- Sim --> J["/speckit-plan"]:::ai

    J --> K["/hr plan: revisar e conferir o plano"]:::human
    K --> L{"Plano aprovado?"}:::human
    L -- Não --> M["IA corrige o plano"]:::ai
    M --> K
    L -- Sim --> N["/speckit-tasks e /speckit-analyze"]:::ai

    N --> O{"Problema crítico ou alto?"}:::ai
    O -- Sim --> P["Pessoa decide, e a IA corrige"]:::human
    P --> N
    O -- Não --> Q["/speckit-implement com Haiku"]:::ai

    Q --> R{"Lint e testes passam?"}:::ai
    R -- "Não, até 3 tentativas" --> Q
    R -- "Falha persistente" --> S["Pessoa decide se passa para Sonnet"]:::human
    S --> Q
    R -- Sim --> T["/speckit-converge com Sonnet"]:::ai

    T --> T2["/code-review: revisão do código pela IA"]:::ai
    T2 --> U["/hr code: ler o código e executar"]:::human
    U --> V{"Código aprovado?"}:::human
    V -- Não --> Q
    V -- Sim --> W["Push e abertura do PR"]:::ai
    W --> X["CI roda em cada PR"]:::ai
    X --> Y["/hr pr: revisar o PR e o CI"]:::human
    Y --> Z{"Aprovado?"}:::human
    Z -- Não --> Q
    Z -- Sim --> AA["Merge feito pela pessoa"]:::human
    AA --> AB{"Há outra spec?"}:::human
    AB -- Sim --> F
    AB -- Não --> AC["Fim"]:::human

    classDef human fill:#dbeafe,stroke:#1d4ed8,color:#1e3a8a
    classDef ai fill:#dcfce7,stroke:#15803d,color:#14532d
```

## 1. Preparar o projeto

```bash
./apply.sh ../meu-projeto
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

Rode `/speckit-constitution` com regras que valem para todas as features e dá para verificar. Pode citar as ferramentas já decididas. Troque o que está entre `<>`:

```text
/speckit-constitution Projeto de <propósito> com <linguagem, framework e ferramentas já
decididas>. A documentação oficial e o que o CLI do framework gera são a referência, e
desvios precisam de justificativa. Código em inglês e documentação em português. Todo
comportamento novo tem teste: testes unitários isolam dependências externas com mocks, e
testes de integração usam as dependências reais. Lint e testes rodam no CI em cada PR.
Nenhuma abstração sem um problema atual que a justifique. Regras do projeto: <regras
específicas e verificáveis da arquitetura>.
```

Para decidir se uma regra entra, pergunte:

- Vale para todas as features? Se não, vai para a spec ou o plano.
- Dá para apontar uma violação no código ou no plano? "Toda regra de negócio fica fora da camada de entrada" dá; "usar Clean Code" não.
- Eu rejeitaria um PR por causa dela? Se não, é preferência.

Não fique polindo: a constitution pode ser alterada depois, rodando o comando de novo. Nossa primeira levou muitas rodadas de revisão.

## 3. Dividir em specs

Regra: **uma spec = uma branch = um PR = valor pronto para produção.**

- A primeira spec cria o projeto e a base. Depois, vá para uma capacidade por spec.
- Cada biblioteca entra na spec que a usa.
- "Pronto" significa que funciona, passou no CI e cumpre as regras no que entrega. O restante segue a ordem das specs.

A base também vira spec quando descreve um comportamento, e não uma ferramenta. As tarefas de criar o projeto com o CLI e de configurar o CI aparecem depois, em `tasks.md`.

## 4. Ciclo de cada spec

| # | Etapa | Comando | Quem produz | Sua parte |
|---|---|---|---|---|
| 1 | Especificação | `/speckit-specify` | IA, com sua descrição | Descreva comportamento, sem tecnologia |
| 2 | Dúvidas | `/speckit-clarify` | IA pergunta | **Revise a spec e decida** |
| 3 | Plano | `/speckit-plan` | IA | **Revise e aprove** |
| 4 | Tarefas | `/speckit-tasks` e `/speckit-analyze` | IA | Só decide se houver problema crítico ou alto |
| 5 | Implementação | `/speckit-implement` e `/speckit-converge` | IA | - |
| 6 | Validação da IA | `/code-review` | IA | Decida o que corrigir |
| 7 | Validação humana | - | Pessoa | Leia o código e execute a feature |
| 8 | Pull request | - | IA abre | **Revise e faça o merge** |

Uma etapa por vez. Você digita os comandos, e uma aprovação vale só para a etapa revisada.

O Spec Kit não tem um comando de revisão de código. O `/speckit-converge` confere se o código cumpre spec, plano e tarefas, e o `/code-review`, do Claude Code, procura bugs. Os dois são necessários, porque um código pode cumprir a spec e ainda ter problemas.

### Spec

O próprio `/speckit-specify` cria a branch a partir da `main` atualizada, seguindo a regra do `CLAUDE.md`, para a spec já nascer nela.

```text
/speckit-specify <Nome da capacidade>. <Quem> consegue <fazer o quê>, e <o que acontece
nos casos de erro>. Fora do escopo: <o que fica para as próximas specs>.
```

O checklist da própria IA pode passar tudo e deixar excessos. Antes de aprovar, confira:

- Requisitos e metas que você não pediu, como "100% das tentativas" ou prazos sem origem.
- O que a sua infraestrutura não consegue cumprir, como bloquear merge em repositório privado sem GitHub Pro.
- Código próprio para o que a ferramenta já faz, como mensagens de erro que ela já dá.
- Frases ambíguas, como "voltar ao estado anterior", que podem esconder uma decisão.

Aplique as correções com `/speckit-clarify`. Não rode `/speckit-specify` de novo, porque ele cria outra pasta.

### Plano

```text
/speckit-plan Use <decisões técnicas ainda abertas>. Siga a documentação oficial e o que o
CLI do framework gera, e justifique cada biblioteca. Mantenha o plano simples, sem
antecipar as specs seguintes.
```

Antes de aprovar, confira:

- **Ferramentas:** gere o scaffold do framework em uma pasta temporária, em vez de confiar no que o plano diz que ele traz. Já vimos um plano citar ferramentas que a versão atual do CLI não gerava mais.
- **Comandos críticos:** faça um teste rápido do que o plano assume. Já vimos um comando de "esperar ficar pronto" retornar sucesso em um serviço que caiu logo depois, e um mesmo processo sair com códigos diferentes conforme o ambiente.
- **Arquivos do scaffold:** veja o que o CLI traz além do código, como instruções para IA ou serviços de terceiros que você não escolheu.
- **Testes:** o que a constitution manda testar não pode ficar só como verificação manual ou "onde for viável".
- **Clone novo e CI:** de onde vêm as variáveis de ambiente, as portas e as dependências.
- **Sua máquina:** veja se as portas do plano estão livres (`ss -ltn`). Um teste que mira a porta padrão pode até atingir o serviço de outro projeto.

## 5. Convenções

- **Idioma:** código em inglês; documentação, specs, planos, commits e PRs em português.
- **Referência:** a documentação oficial e o que o CLI do framework gera. Desvios ficam justificados no Complexity Tracking do plano.
- **Testes:** unitários isolam dependências externas com mocks, e os de integração usam as dependências reais.
- **Simplicidade:** nenhuma abstração, camada ou dependência sem um problema atual.
- **Segredos:** nunca no repositório.

## 6. Subagentes e modelos

Cada comando digitado roda direto no subagente, configurado no frontmatter da skill com `context: fork`, `background: false` e `model`. Isso mantém a conversa principal pequena e usa um modelo adequado a cada tarefa.

| Etapa | Modelo | Onde roda |
|---|---|---|
| Conversa principal (orquestrador) | Sonnet | - |
| Constitution | Opus | Subagente |
| Spec, plano, tarefas, análise e converge | Sonnet | Subagente |
| Dúvidas da spec | Sonnet | Conversa principal, porque depende de diálogo |
| Implementação | Haiku, passando para Sonnet se a mesma falha persistir depois de 3 tentativas | Subagente |
| Validação da IA (`/code-review`) | Sonnet, o modelo da conversa principal | Conversa principal, com revisores próprios |
| `/hr` | Haiku | Subagente |

- **Perguntas:** o subagente não vê o chat. Ele devolve as perguntas, o orquestrador mostra cada uma com uma recomendação, você decide, e a decisão vai para o artefato da etapa.
- **Máquina:** o modelo roda nos servidores, mas build, testes e contêineres rodam localmente. Ajuste `CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS` em `.claude/settings.json`. O padrão do modelo é 2, e ainda não sabemos se esse limite cobre skills com fork.
- **Atualização do Spec Kit:** pode sobrescrever o frontmatter. Confira com `git diff` e reaplique.

## 7. Limites do plano

- Eles medem consumo, não horas: uma janela de 5 horas, que começa na primeira mensagem, e um limite semanal.
- São compartilhados entre os modelos e com o Claude no navegador, no desktop e no celular. A Anthropic não publica o tamanho deles e pode ajustá-los.
- O consumo depende do modelo, do esforço e do tamanho do contexto. Cada subagente faz as próprias requisições, que contam no mesmo limite.
- Use `/usage` para acompanhar e `/clear` ou uma sessão nova entre tarefas para reduzir o contexto.

## 8. Registros

A IA preenche a cada etapa, seguindo o `CLAUDE.md`:

- **`docs/tempos.md`:** horários reais, tempo da IA, consumo e tokens por modelo.
- **`docs/human-review.md`:** o tempo exato de revisão. Rode `/hr spec` ao começar (ou `plan`, `code`, `pr`) e `/hr end` ao terminar. Para uma pausa, rode `/hr end` e, depois, a etapa de novo. Sem essa marcação, o tempo humano é só um limite máximo.
- **`docs/diario.md`:** o que a IA propôs, o que você mudou e por quê, surpresas e erros.

Os percentuais são da conta inteira e arredondados. Para comparar etapas, use os tokens e deixe só a sessão do projeto ativa durante a etapa.

## 9. Git

- Branches a partir da `main` atualizada: `feature/<nome-curto>` para specs e `chore/<nome-curto>` para o resto.
- A `main` não recebe commit direto.
- Um commit ao fim de cada etapa aprovada e, na implementação, um por tarefa ou pequeno grupo. Push e PR ficam para o final.
- Commits e títulos de PR usam `tipo: descrição`, no presente e em português, como `feat: adiciona cadastro`. Tipos: `feat`, `fix`, `docs`, `test`, `refactor` e `chore`.
- O corpo do PR segue `.github/pull_request_template.md`.
- As specs são numeradas por horário, para evitar número repetido em trabalho paralelo.
- Repositório privado sem GitHub Pro não permite proteger a branch, e você não consegue aprovar um PR aberto com a própria conta. Nesse caso, o merge vale como aprovação.

## 10. Quando automatizar mais

Só depois de validar o fluxo com dados de tempo, consumo e retrabalho. Comece por tarefas de baixo risco, como testes e dependências. Cada spec depende do merge da anterior, então um loop entre specs para nesse ponto.
