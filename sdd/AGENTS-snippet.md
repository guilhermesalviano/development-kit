## Spec-Driven Development (SDD) — MANDATORY

A change that adds or changes behaviour starts from a feature folder `specs/<nnn>-<slug>/` holding `prd.md`, `spec.md` and `tasks.md`, copied from `specs/templates/` (take the next number after the highest in `specs/`). A refactor or copy change goes straight to code, and a bug fix starts with a failing test. The full rules are in [specs/index.md](specs/index.md).

1. **PRD** — write `prd.md`, put every open question to the user, then stop until they approve it.
2. **Spec** — write `spec.md` (`Status: draft`) with `- [ ] AC<n>: Given …, when …, then …` criteria and the design; stop until the user approves it and the status reads `approved`.
3. **Tasks** — write `tasks.md`, ordered, each task naming its acceptance criteria.
4. **Build** — per criterion, write a test named with its id (`it("AC1: …")`) that fails, then the code that passes it; tick the boxes in `spec.md` and `tasks.md`.
5. **Update, don't bypass** — if the code must change an approved spec's behaviour or criteria, stop and ask. Drift between spec and code is a bug.
6. **Converge, then done** — re-read PRD and spec against the diff, fill `Convergence` and `Validation` (name the test files), set `Status: done`. `test/spec-ac-coverage.test.ts` enforces this for every spec with a `Status:` line.

Exemptions (spec not required): typo/comment fixes, dependency bumps, config/build fixes, and single-file bug fixes with an obvious root cause. When in doubt, write the spec.
