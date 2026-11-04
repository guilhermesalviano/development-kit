# Spec-driven development

Work is spec-driven, and this process is mandatory. The repository-wide workflow, conventions and checks this process relies on are in [AGENTS.md](../AGENTS.md).

A change that adds or changes behaviour (a feature, an API, schema or migration change, a new kind of queued work, anything spanning more than one app) starts here. A refactor or copy change that keeps behaviour as it is goes straight to code. A bug fix also skips the Plano técnico, but starts with a test that fails on the bug, then the fix.

Exemptions (Plano técnico not required): typo/comment fixes, dependency bumps, config/build fixes, and single-file bug fixes with an obvious root cause. When in doubt, write the Plano técnico.

## Layout

Each feature has its own folder, `specs/<nnn>-<slug>/`, numbered in the order features were started (`001-…`, `002-…`; take the next number after the highest in `specs/`), with three files copied from `specs/templates/`:

| File | Answers | Written |
| --- | --- | --- |
| `prd.md` | Why, and what people get | first |
| `plan.md` | What exactly must be true, and how | after the PRD is approved |
| `tasks.md` | In what order it gets built | after the Plano técnico is approved; approved before code |

## What each file contains

### prd.md

The product requirements, in plain language and free of tables, routes and code:

- **Problem**: what is missing or wrong today, and for whom.
- **Goals** and **Non-goals**.
- **Users and scenarios**: who is affected and when.
- **Behaviour**: what the user or system sees after the change.
- **Success measures**: how we will know it worked.
- **Open questions**: everything the user must answer.

### plan.md

The Plano técnico: the testable contract and the design:

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
- the Workflow checks, the Plano técnico re-read and the Convergence entry as the last tasks.

Tick a task when it is done.

## Steps

Steps 1–3 are interactive. They are written together with the user, never in one go:

- **Ask before writing.** Before drafting each file, ask the user what you cannot settle from the request or the code, a few questions at a time, each with concrete options and your recommendation first. Use the agent's interactive question tool when it has one (`AskUserQuestion` in Claude Code); otherwise ask in chat and wait for the answers.
- **Show, then confirm.** Present the draft, ask whether to approve it or what to change, and revise until the user approves it explicitly. Silence or "ok, go on" about something else is not approval.
- **One file at a time.** Do not start the next file before the current one is approved, and do not write code before `tasks.md` is approved.
- **Record the answers.** Each answer goes into the file it settles; the `Open questions` section is empty when the file is approved.

1. **PRD.** Ask the user about the problem, goals, non-goals, users and success measures. Then create the folder, write `prd.md` from `specs/templates/prd.md` and ask for approval. The step is done when the user approves the PRD.
2. **Plano técnico.** Ask the user about the acceptance criteria and every design choice with more than one reasonable answer. Then write `plan.md` from `specs/templates/plan.md` with its status `draft` and ask for approval. The step is done when the user approves it and its status reads `approved`.
3. **Tasks.** Ask the user about the order and size of the work where it is not obvious. Then write `tasks.md` from `specs/templates/tasks.md`, breaking the acceptance criteria into ordered tasks, and ask for approval. The step is done when the user approves the tasks.
4. **Build.** Work through the tasks. For each acceptance criterion, write a test named with its id (`it('AC1: …')`) that fails, then the code that makes it pass, then tick its box in `plan.md` and its task in `tasks.md`. A test may carry several ids (`it('AC2/AC8: …')`) or a prefix (`it('validator direction AC12: …')`).
5. **Changes.** If the code must change the behaviour or the acceptance criteria of an approved Plano técnico, stop and ask the user, and update the PRD to match once they agree. A different design needs only the Plano técnico's Design section updated in the same change.
6. **Converge.** Before `done`, re-read the PRD and the Plano técnico against the diff: the Behaviour, the acceptance criteria and the Design must still describe what shipped, and the Validation section must name the test files that carry each criterion's id. Record the outcome in the `Convergence` section. A Plano técnico that must change its behaviour or acceptance criteria follows step 5 first.
7. **Done.** The change is done when every acceptance criterion has a passing test named with its id and a ticked box, every task is ticked, the Validation section names the files that carry those ids, the Convergence section is filled and `bun run test` and `bun run typecheck` pass. Set the Plano técnico's status to `done`.

`test/spec-ac-coverage.test.ts` enforces the acceptance-criteria rules for every `done` Plano técnico, in both layouts.
