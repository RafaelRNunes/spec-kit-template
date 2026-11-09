# {{NAME}}

Describe the project in one sentence here.

## Language

- Code in English: files, identifiers, tests and comments. Names translate the domain terms of the spec.
- Replies, constitution, specs, plans, docs, commits and PRs in {{LANGUAGE}}.

## Collaboration

- The person types the `/speckit-*` commands. Never run a Spec Kit command they did not ask for, nor write its artifacts on your own.
- One step at a time. Mandatory human review stops: the spec (after clarify), the plan, a bug assessment and the PR. `/speckit-tasks` and `/speckit-analyze` run without a stop, unless analyze reports a critical or high issue.
- An approval covers only the reviewed step. "Go on" does not approve the next ones.
- A decision without an explicit answer stays open. Ask, with your recommendation.

## Flow

| # | Step | Command | Who |
|---|---|---|---|
| 0 | Project rules, changed when needed | `/speckit-constitution` | Person and AI |
| 1 | Spec | `/speckit-specify` | Person and AI |
| 2 | Spec questions | `/speckit-clarify` | AI asks, person answers |
| 3 | Plan | `/speckit-plan` | AI writes, person approves |
| 4 | Tasks | `/speckit-tasks` and `/speckit-analyze` | AI |
| 5 | Implementation | `/speckit-implement` and `/speckit-converge` | AI |
| 6 | AI review | `/code-review` of the branch; the person decides what to fix | AI |
| 7 | Human review | Read the code and run it | Person |
| 8 | Pull request | AI pushes and opens it; the person reviews and merges | Both |

A spec is small: it delivers value on its own and is easy to review. If specify produces many stories or the plan grows large, suggest splitting it into specs that each still deliver value.

## Kinds of change

Specs are flow-forward: after the merge, a `specs/` directory is never edited again and stays as history. A change to delivered work is a new spec that links to the previous one.

| Change | Flow | Branch | History |
|---|---|---|---|
| New feature or improvement | Full flow | `feature/` | `specs/<dir>/` |
| Feature too large for one spec | `roadmap.md` first, then one spec per slice | `feature/` per slice | `specs/<epic>/roadmap.md` |
| Technical task that needs a plan | Full flow, as a technical spec | `feature/` | `specs/<dir>/` |
| Bug: the code contradicts a spec | `bug` extension | `fix/` | `.specify/bugs/<slug>/` |
| Trivial technical task | Direct PR | `chore/` | Commits and PR |

- **Spec that changes another:** the `/speckit-specify` description cites the previous spec, and `spec.md` starts with `Type: feature` or `Type: technical`, plus `Builds on: specs/<dir>` when there is a related spec.
- **Technical spec:** the user is whoever maintains or operates the system, and acceptance criteria are observable, such as "tests still pass" or "the API contract does not change".
- **Needs a plan:** it has a decision to make or more than one task, like refactoring a module or replacing a library with breaking changes. Trivial: a patch dependency bump, a CI tweak, a typo.
- **Bug or change:** if the code contradicts what the spec agreed, it is a bug. If what was agreed must change, it is a new spec.
- **Roadmap:** a table with a fixed ID (R1, R2...), intent, scope boundary, dependencies, status and the link to each slice's spec. Each slice delivers value on its own.
- **Bug:** `/speckit-bug-assess` diagnoses without touching code, and the person reviews the assessment before `/speckit-bug-fix`. Then `/speckit-bug-test`, `/code-review`, human review and PR, as with a spec.

When in doubt, ask the person which path to take.

## Conventions

- The official docs and what the framework CLI generates are the reference. Deviations are justified in the plan's Complexity Tracking.
- Unit tests isolate external dependencies with mocks. Integration tests use the real ones.
- No abstraction, layer or dependency without a current problem that justifies it. Each library comes in with the spec that uses it.
- Secrets never go into the repository.

## Git

- One spec, one branch, one PR. After the merge, it delivers production-ready value.
- No direct commits to `main`. What is on it works, passed CI and follows the rules.
- The `before_specify` hook (`.specify/extensions.yml` and the `speckit-feature-branch` skill) updates `main` and creates `feature/<short-name>`. The `before_bug_fix` hook creates `fix/<slug>`. For a trivial technical task, create `chore/<short-name>` from an updated `main`.
- Commit, push or open a PR only when the flow step calls for it. The merge is always the person's.
- Small commits: one per approved step and, during implementation, one per task or small group of tasks. Push and PR at step 8.
- Commit messages and PR titles use [Conventional Commits](https://www.conventionalcommits.org/): `type: description`, with `feat`, `fix`, `docs`, `test`, `refactor`, `build`, `ci` or `chore`.
- The PR body follows `.github/pull_request_template.md`. Under "Verification", state what actually ran and what did not.

## Subagents

A subagent works without seeing this conversation and returns its result to it.

| Skill | Runs in | Model |
|---|---|---|
| `speckit-constitution` | Subagent | Opus |
| `speckit-specify`, `speckit-plan`, `speckit-tasks`, `speckit-analyze`, `speckit-checklist`, `speckit-converge` | Subagent | Sonnet |
| `speckit-implement` | Subagent | Haiku |
| `speckit-clarify`, `speckit-bug-assess` | Main conversation | Sonnet |
| `speckit-bug-fix`, `speckit-bug-test` | Subagent | Sonnet |

- The main conversation uses Sonnet and runs `/code-review`.
- At most two subagents at a time, set in `.claude/settings.json`.
- A subagent follows the branch rules, returns a short summary and its open questions, and never decides for the person or starts the next step.
- During implementation, Haiku retries until lint and tests pass. If the same failure persists after 3 attempts, it stops and asks whether to switch to Sonnet.
- The main conversation shows each open question with a recommendation, and the person decides. Record the decision in the step's artifact before moving on, because the next subagent does not see the chat. Spec questions go to `/speckit-clarify`; never rerun `/speckit-specify`, which creates another spec directory.

## What will be built

List the order of the specs here, or point to `roadmap.md`.

## Records

- **Metrics:** never log time or usage during the steps. The hooks save the merged branch's metrics to `docs/metrics/` from Claude Code transcripts and GitHub. To generate them by hand, the person runs `/metrics [branch]`.
- **Journal:** in `docs/journal.md`, record what actually happened: what the AI proposed, what the person changed and why, surprises and mistakes.
