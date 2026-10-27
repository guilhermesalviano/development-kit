# development-kit

My personal kit of AI skills, agents and prompts. I reuse it in every new project and on every new PC.

## Skills

Install with the [`skills` CLI](https://www.npmjs.com/package/skills) (`npx skills add ...`).

- [caveman](https://github.com/JuliusBrussee/caveman) (JuliusBrussee/caveman, v4.0.1): terse "caveman" output mode plus caveman-commit, caveman-review, caveman-compress, cavecrew, investigate-first, lean-build, safe-refactor, surgical-patch, verify-and-stop and more.
  `npx skills add JuliusBrussee/caveman`
- [web-design-guidelines](https://github.com/vercel-labs/agent-skills/tree/main/skills/web-design-guidelines) (vercel-labs/agent-skills): reviews UI code against web interface guidelines.
  `npx skills add vercel-labs/agent-skills --skill web-design-guidelines`
- [security-audit](https://github.com/cloudflare/security-audit-skill) (cloudflare/security-audit-skill): security guidance and full codebase security audits.
  `npx skills add https://github.com/cloudflare/security-audit-skill --skill security-audit`
- [ponytail](https://github.com/DietrichGebert/ponytail) (DietrichGebert/ponytail): "lazy senior dev" mode, the smallest change that fully solves the task, plus ponytail-audit, ponytail-review, ponytail-debt, ponytail-gain and ponytail-help.
  `npx skills add DietrichGebert/ponytail` (Hermes: `hermes plugins install DietrichGebert/ponytail --enable`)

See [skills.md](skills.md) for the full list of skills inside each pack.

## Tools

- [rtk](https://github.com/rtk-ai/rtk) (Rust Token Killer): a CLI proxy that compresses command output (git, ls, tests, gh, docker...) before the AI agent reads it, so it uses fewer tokens. Docs: [rtk-ai.app/guide](https://www.rtk-ai.app/guide).
  - Install (official README):
    - `brew install rtk` (macOS / Linux)
    - `curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh`
    - `winget install rtk-ai.rtk` (Windows)
  - Check: `rtk --version` and `rtk gain` (must show the savings dashboard; another crate named "rtk" exists).
  - Hook it into your agents:
    - Claude Code: `rtk init -g`
    - Codex: `rtk init -g --codex`
    - OpenCode: `rtk init -g --opencode`
    - Cursor: `rtk init -g --agent cursor`
    - Hermes: `rtk init --agent hermes`
  - Restart the agent afterwards. See savings with `rtk gain`.

## Agents

_Nothing yet._ Put agent definitions in [`agents/`](agents/).

## Prompts

_Nothing yet._ Put reusable prompts in [`prompts/`](prompts/).
