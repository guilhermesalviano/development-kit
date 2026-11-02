# Spec-driven development

Work is spec-driven. The repository-wide workflow, conventions and checks this process relies on are in [AGENTS.md](../AGENTS.md).

A change that adds or changes behaviour (a feature, an API, schema or migration change, a new kind of queued work, anything spanning more than one app) starts here. A refactor or copy change that keeps behaviour as it is goes straight to code. A bug fix also skips the spec, but starts with a test that fails on the bug, then the fix.

## Layout

Each feature has its own folder, `specs/<nnn>-<slug>/`, numbered in the order features were started (`001-…`, `002-…`; take the next number after the highest in `specs/`), with three files copied from `specs/templates/`:

| File | Answers | Written |
| --- | --- | --- |
| `prd.md` | Why, and what people get | first |
| `spec.md` | What exactly must be true, and how | after the PRD is approved |
| `tasks.md` | In what order it gets built | after the spec is approved |

## What each file contains

### prd.md

The product requirements, in plain language and free of tables, routes and code:

- **Problem**: what is missing or wrong today, and for whom.
- **Goals** and **Non-goals**.
- **Users and scenarios**: who is affected and when.
- **Behaviour**: what the user or system sees after the change.
- **Success measures**: how we will know it worked.
- **Open questions**: everything the user must answer.

### spec.md

The testable contract and the design:

- `Status: draft | approved | done | superseded` on its own line, with links to the PRD and the tasks.
- **Acceptance criteria**: a checklist of `- [ ] AC<n>: Given …, when …, then …`, each one testable and numbered from 1.
- **Design**: apps, repositories, tables, migrations, routes and queues touched, and why this shape.
- **Out of scope** and **Open questions**.
- **Validation**: the test files (or the directory holding them) that carry each criterion's id, and the checks that were run. Name files, not the command that ran them.
- **Convergence**: `Converged`, or what drifted and where it was recorded. Filled before `done`.

### tasks.md

The build plan, as a checklist of `- [ ] T<n> (AC<m>): …` items in the order they are done:

- a failing test per acceptance criterion, then the code that makes it pass;
- the `README.md` and `docs/` updates when users see a change;
- the Workflow checks, the spec re-read and the Convergence entry as the last tasks.

Tick a task when it is done.

## Steps

1. **PRD.** Create the folder and write `prd.md` from `specs/templates/prd.md`. Put every open question to the user, then stop. The step is done when the user approves the PRD.
2. **Spec.** Write `spec.md` from `specs/templates/spec.md` with its status `draft`, put every open question to the user, then stop. The step is done when the user approves it and its status reads `approved`.
3. **Tasks.** Write `tasks.md` from `specs/templates/tasks.md`, breaking the acceptance criteria into ordered tasks. It needs no separate approval unless it raises open questions.
4. **Build.** Work through the tasks. For each acceptance criterion, write a test named with its id (`it('AC1: …')`) that fails, then the code that makes it pass, then tick its box in `spec.md` and its task in `tasks.md`. A test may carry several ids (`it('AC2/AC8: …')`) or a prefix (`it('validator direction AC12: …')`).
5. **Changes.** If the code must change the behaviour or the acceptance criteria of an approved spec, stop and ask the user, and update the PRD to match once they agree. A different design needs only the spec's Design section updated in the same change.
6. **Converge.** Before `done`, re-read the PRD and the spec against the diff: the Behaviour, the acceptance criteria and the Design must still describe what shipped, and the Validation section must name the test files that carry each criterion's id. Record the outcome in the `Convergence` section. A spec that must change its behaviour or acceptance criteria follows step 5 first.
7. **Done.** The change is done when every acceptance criterion has a passing test named with its id and a ticked box, every task is ticked, the Validation section names the files that carry those ids, the Convergence section is filled and `bun run test` and `bun run typecheck` pass. Set the spec's status to `done`.

`test/spec-ac-coverage.test.ts` enforces the acceptance-criteria rules for every `done` spec, in both layouts.
