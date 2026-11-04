# Project audit (interactive)

Copy everything below the line into the agent's chat, from the root of the project to audit.

---

Audit this project. Find bugs and things worth improving, but stop on every finding and let me decide what happens to it. Do not change any file unless I tell you to fix that finding.

## 1. Survey first

Before looking for problems, learn the project:

- Read `AGENTS.md`, `CLAUDE.md`, `README.md`, `CONTRIBUTING.md` and any `docs/` or `specs/` that exist. The conventions written there are rules: breaking one is a finding.
- Map the layout: entry points, modules, scripts, config, tests, CI, dependency manifests.
- Find how the project is built, run, linted and tested. Run the read-only checks (tests, linters, type checker, `--dry-run` modes) if they are cheap and safe, and note what fails.
- Tell me in a few lines what you found and the order you will audit in (most critical code first). Then start.

## 2. What to look for

| Category | Examples |
| --- | --- |
| Bug | wrong logic, off-by-one, unhandled edge case, race condition, wrong return/exit code, broken path or quoting |
| Security | injection (shell, SQL, path), secrets in code or logs, unsafe permissions, unvalidated input, unsafe `eval`/`curl \| sh`, outdated vulnerable deps |
| Data loss / destructive | deletes or overwrites without confirmation, `rm -rf` on a variable that can be empty, no backup before editing user files |
| Error handling | swallowed errors, missing `set -euo pipefail` (or equivalent), no cleanup on failure, misleading error messages |
| Optimization | needless work in loops, repeated I/O or subprocesses, N+1 calls, blocking where it could stream, oversized dependencies |
| Portability | macOS vs Linux differences (GNU vs BSD `sed`/`date`/`stat`), hard-coded paths, bash-only syntax in `sh`, missing dependency checks |
| Idempotency | re-running a setup/install step duplicates config, fails, or clobbers state |
| Dead code / duplication | unused files, functions, flags or variables; copy-pasted logic that should be shared |
| Docs drift | README/AGENTS.md describes commands, flags, paths or behaviour that the code does not match (or misses ones it has) |
| Tests | critical paths with no test, tests that cannot fail, flaky tests |
| Config / dependencies | unpinned or unused dependencies, missing entries in `.gitignore`, wrong file modes (scripts not executable) |
| Consistency / DX | naming or structure that breaks the project's own conventions, confusing CLI output, missing `--help` |

Anything else that a careful senior reviewer would flag also counts.

## 3. Verify before you report

Only report a finding you have confirmed:

- Point to the exact `file:line` and quote the relevant code.
- Show the evidence: the command you ran and its output, or the concrete input that triggers the problem and what happens.
- If you cannot confirm it, either keep digging or drop it. Label anything you still report without proof as **Unconfirmed** and say what would confirm it.
- Do not report style preferences or "could be nicer" as bugs.

## 4. Stop on every finding

As soon as a finding is confirmed, stop the audit and show it in this format:

```
Finding #<n> — <short title>
Category: <category>    Severity: critical | high | medium | low
Where:    <file:line>
Problem:  <what is wrong, in one or two sentences>
Evidence: <quoted code, command output or reproduction>
Impact:   <what breaks, for whom, when>
Fix:      <the smallest change that solves it, and any risk it carries>
```

Severity:

- **critical**: data loss, security hole, or the main flow is broken.
- **high**: a real bug users will hit, or a documented command that does not work.
- **medium**: an edge-case bug, a portability problem, a missing check, a clear optimization.
- **low**: dead code, docs drift, minor cleanup.

Then ask me, and wait for my answer:

> **Fix now**, **continue** (log it and keep auditing), or **stop** (end the audit and give me the list)?

- **Fix now**: apply the smallest fix that solves the finding, touch nothing else, run the relevant check or reproduction again to prove it is fixed, show me the diff, mark it `fixed`, then continue the audit.
- **Continue**: mark it `open` and keep auditing without changing anything.
- **Stop**: go straight to the final report.

Never fix more than the finding I approved, and never commit unless I ask.

## 5. Final report

When the audit is done (or I say stop), give me the full list, most severe first:

| # | Severity | Category | Where | Title | Status |
| --- | --- | --- | --- | --- | --- |
| 1 | high | Bug | `path/file.sh:42` | ... | fixed / open / unconfirmed |

After the table:

- **Open findings**: for each `open` one, the fix you propose, one line each.
- **Not covered**: parts of the project you did not audit, and why.
- **Checks run**: the commands you ran and whether they passed.
- **Suggested next steps**: up to five, in order.
