# AGENTS.md

Guidance for AI coding agents working in this repository.

## What this is

`tool-box` is a modular collection of server and macOS automation scripts, background monitors, and system utilities. Each tool lives in an isolated folder under `scripts/<name>/` — or under `apps/<name>/` for GUI applications — and is dispatched through the unified `./install.sh` CLI.

---

## Commands

`./install.sh` is the single entry point: with no arguments (or `setup`) it runs the interactive setup; with arguments it is the tool CLI.

### Fresh-machine setup (`./install.sh` / `./install.sh setup`)
- `./install.sh` — Interactive, idempotent setup for a new clone: first offers zsh + Oh My Zsh (unattended; old `~/.zshrc` saved as `~/.zshrc.pre-oh-my-zsh`) with the `zsh-autosuggestions`, `zsh-syntax-highlighting` and `fast-syntax-highlighting` plugins cloned into `$ZSH_CUSTOM/plugins`, enabled via a `# >>> tool-box zsh plugins >>>` block in `~/.zshrc` (only `fast-syntax-highlighting` is sourced — the two highlighters conflict; `zsh-syntax-highlighting` is the fallback), and `chsh` to zsh. This runs before the aliases step so aliases land in the new `~/.zshrc`. Then offers to install shell aliases, checks/offers to install each tool's external dependency (`aria2`, `python3`, `jq`, `ripgrep`), offers `git-delta` and, once `delta` is on `PATH`, sets it as the global git pager (`core.pager`, `interactive.diffFilter`, `delta.navigate`, `delta.side-by-side`, `diff.algorithm histogram`; warns before replacing another pager), bootstraps the mac-monitor virtualenv. Confirms before any system-modifying step (package install, LaunchAgent, shell rc edits); safe to re-run.

### Global CLI (`./install.sh <command>`)
- `./install.sh help` — Show usage.
- `./install.sh list` — List all installed tools and their descriptions.
- `./install.sh new <tool-name>` — Scaffold a new tool from `scripts/_template/`.
- `./install.sh <tool-name> [action|args]` — Dispatch a command to a specific tool.

### Torrent DL (`torrent-dl`)
- `./install.sh torrent-dl '<link>'` — Download a torrent from a magnet link, a `.torrent` URL, or a local `.torrent` file, via `aria2c` (must be installed separately: `brew install aria2` / `apt-get install aria2`).
- `./install.sh torrent-dl '<link>' -o <dir>` — Set the destination directory (default `~/Downloads/torrents`).
- `./install.sh torrent-dl '<link>' -s <minutes>` — Keep seeding for N minutes after completion (default `0`, no seeding).

### Disk Cleaner (`disk-cleaner`)
- `./install.sh disk-cleaner` — Interactively clean caches, trash, and temp files on macOS or Linux (asks per step).
- `./install.sh disk-cleaner --yes|--all` — Assume "yes" for every step, except the Docker steps (see below), which always prompt.
- `./install.sh disk-cleaner --dry-run` — Preview what would be cleaned without deleting anything.
- `./install.sh disk-cleaner --docker-volumes` — Also offer to prune unused Docker volumes (off by default; may contain database data).

### Aliases (`aliases`)
- `./install.sh aliases install` — Add Tool-Box shell aliases (`tb`, `tb-clean`, `tb-mon-*`, etc.) to `~/.zshrc`/`~/.bashrc`/`~/.bash_profile`, detected from the account login shell (`getent passwd` / `dscl`, so it is correct right after a `chsh`), falling back to `$SHELL`. Idempotent, marked by `# >>> tool-box aliases >>>` / `# <<< tool-box aliases <<<`.
- `./install.sh aliases uninstall` — Remove that marked block.
- `./install.sh aliases status` — Show which rc files have the aliases installed.
- `./install.sh aliases list` — List all available aliases and what they expand to.

### Swain Macros (`swain-macros`) — GUI app
- `./install.sh swain-macros install` — One-time setup on Ubuntu/GNOME (runs `install.sh`): apt packages, udev rule for the mouse and `/dev/uinput`, app menu entry. Run as the normal user; it calls `sudo` itself.
- `./install.sh swain-macros [--background]` — Open the GTK app that maps macros to the Redragon Swain side buttons (`--background` starts hidden).

### Mac Fan (`mac-fan`) — GUI app, T2 Macs running Linux
- `./install.sh mac-fan install` — One-time setup (runs `install.sh`): enables `macsmc_hwmon fan_control` now and via `/etc/modprobe.d/mac-fan.conf`, udev rule chowning `fan*_target` to the user, app menu entry. Run as the normal user; it calls `sudo` itself.
- `./install.sh mac-fan [--background]` — Open the GTK app: Automatic (SMC) / Fixed speed / Temperature curve modes, full speed at ≥ 90 °C in manual modes, hands the fan back to the SMC (writes `0`) on quit.

### Mac Monitor (`mac-monitor`)
- `./install.sh mac-monitor setup` — Create `.venv/` and install Glances into it, without starting the collector.
- `./install.sh mac-monitor report [YYYY-MM-DD]` — Generate the aggregated CPU and Memory report via AWK (defaults to today).
- `./install.sh mac-monitor status` — Check if the monitor daemon and LaunchAgent are active, sample count, and log file size.
- `./install.sh mac-monitor logs [-f]` — View the latest CSV log lines (`-f` to follow in real-time).
- `./install.sh mac-monitor start` — Start the collector daemon in the background.
- `./install.sh mac-monitor stop` — Stop the collector daemon.
- `./install.sh mac-monitor restart` — Restart the collector daemon.
- `./install.sh mac-monitor install-service` — Install and load the macOS LaunchAgent (`~/Library/LaunchAgents/com.guilhermesalviano.toolbox-monitor.plist`).
- `./install.sh mac-monitor uninstall-service` — Unload and remove the LaunchAgent.

---

## Repository layout

- `install.sh` — Single entry point. No arguments (or `setup`): interactive fresh-machine setup (see above). With arguments: the CLI dispatcher — `list`, `new`, `help`, or `<tool>`. Looks up `scripts/<name>/` first, then `apps/<name>/`, and routes to `manage.sh` or `run.sh`. `list` prints the two groups separately; `new` always scaffolds into `scripts/`.
- `scripts/` — Modular tools directory:
  - `scripts/README.md` — User documentation (Portuguese) for the tools in `scripts/`; the root `README.md` only links to it.
  - `scripts/torrent-dl/` — Torrent downloader (magnet link, `.torrent` URL, or local `.torrent` file) via `aria2c`:
    - `run.sh` — Entry point; `-o/--output`, `-s/--seed-minutes` flags.
    - `README.md` — Tool documentation.
  - `scripts/disk-cleaner/` — Cross-platform (macOS/Linux) disk space cleaner:
    - `run.sh` — Interactive cleanup script; asks per step, `-y`/`--all`/`--dry-run`/`--docker-volumes` flags.
    - `README.md` — Tool documentation.
  - `scripts/aliases/` — Shell alias installer for the Tool-Box CLI:
    - `aliases.sh` — Self-locating alias definitions (sourced, not executed; works from bash and zsh).
    - `manage.sh` — Tool-specific controller (`install`, `uninstall`, `status`, `list`).
    - `README.md` — Tool documentation.
  - `scripts/mac-monitor/` — Continuous Mac CPU & Memory monitor:
    - `collector.py` — Python streaming collector daemon reading metrics from Glances and handling midnight CSV rotation.
    - `report.sh` — AWK script calculating daily mean CPU, max CPU, mean Memory, max Memory, and sample count.
    - `manage.sh` — Tool-specific controller (`start`, `stop`, `status`, `report`, `logs`, `install-service`, `uninstall-service`).
    - `launchd/com.guilhermesalviano.toolbox-monitor.plist.template` — LaunchAgent definition for macOS boot/login persistence. Has no absolute paths baked in; `manage.sh install-service` renders it with the actual `ROOT_DIR`/`HOME` via `sed` before installing, since a clone can live anywhere.
    - `README.md` — Tool documentation (first `# Title` line is shown in `./install.sh list`).
  - `scripts/_template/` — Starter boilerplate for new tools (`run.sh` and `README.md`).
- `apps/` — GUI applications; dispatched by `./install.sh` just like `scripts/`:
  - `apps/README.md` — User documentation (Portuguese) for the apps in `apps/`; the root `README.md` only links to it.
  - `apps/swain-macros/` — Linux (Ubuntu/GNOME, Wayland and X11) macro app for the Redragon Swain mouse side buttons (Holtek `04d9:fc63`):
    - `run.sh` — Entry point; launches the app, or `install.sh` with `install`.
    - `install.sh` — One-time setup (apt deps, udev rule, `uinput` module, desktop launcher).
    - `swain-macros` — Python launcher for the `swain_macros` package.
    - `swain_macros/` — `app.py` (GTK4/libadwaita UI), `engine.py` (grabs the mouse via evdev and re-emits events through `uinput`), `macro.py` (macro language parser/player), `config.py` (`~/.config/swain-macros/config.json`, autostart).
    - `data/` — udev rule, `.desktop` template (`@EXEC@` placeholder), app icon.
    - `README.md` — Tool documentation.
  - `apps/mac-fan/` — Fan control for a T2 Mac (Mac mini 2018) running Debian with a T2 kernel, via the `macsmc_hwmon` sysfs interface (`fanN_target`: RPM in `[min,max]` = manual, `0` = automatic):
    - `run.sh` — Entry point; launches the app, or `install.sh` with `install`.
    - `install.sh` — One-time setup (modprobe option, udev rule templated with `$USER`, desktop launcher).
    - `mac-fan` — Python launcher for the `mac_fan` package.
    - `mac_fan/` — `app.py` (GTK4/libadwaita UI and 2 s control loop), `smc.py` (fan/temperature sysfs access), `config.py` (`~/.config/mac-fan/config.json`, autostart).
    - `data/` — udev rule (`@USER@` placeholder), `.desktop` template (`@EXEC@` placeholder), SVG icon.
    - `README.md` — Tool documentation.
- `logs/` — Centralized log directory (gitignored):
  - `glances-YYYY-MM-DD.csv` — Daily CSV metric files.
  - `monitor.pid` — Process ID file of the active collector.
  - `monitor-service.log` / `monitor-service-err.log` — Daemon stdout/stderr logs.
- `.venv/` — Shared Python virtual environment (gitignored) containing `glances`, `psutil`, etc.
- `.gitignore` — Ignores `logs/`, `.venv/`, `__pycache__/`, `.DS_Store`.
- `README.md` — User documentation in Portuguese.
- `AGENTS.md` — This file.

---

## Runtime Constraints & Conventions

1. **Log File Contract (`mac-monitor`)**:
   The CSV log files must be written to:
   `logs/glances-YYYY-MM-DD.csv`
   With the exact header format:
   ```csv
   now.iso,now.custom,cpu.total,mem.used,mem.percent
   ```
   - `$1`: `now.iso` (ISO 8601 timestamp)
   - `$2`: `now.custom` (Formatted local timestamp)
   - **`$3`**: **`cpu.total` (%)**
   - `$4`: `mem.used` (Bytes)
   - **`$5`**: **`mem.percent` (%)**
   
   **CRITICAL**: Do NOT change column positions or header names. External scripts and the user's manual AWK one-liners rely directly on `$3` being CPU% and `$5` being Memory%.

2. **Daily Rotation**:
   The collector process must handle date changes at midnight automatically. When the date changes:
   - Close and flush the previous day's CSV file.
   - Open `logs/glances-<new-date>.csv`.
   - Write the CSV header if the new file is empty.
   - Flush every sample immediately (`f.flush()`) so real-time reports always reflect current data.

3. **Tool Structure**:
   Every tool inside `scripts/<name>/` (or `apps/<name>/`) must:
   - Be self-contained in its own subdirectory. Put it in `apps/` if it is a GUI application; everything else goes in `scripts/`.
   - Provide an executable entrypoint: `manage.sh` (for daemons/services with subcommands) or `run.sh` (for simple runnable scripts).
   - Have a `README.md` whose first line is `# <Tool Name>` so `./install.sh list` can auto-discover it.
   - Use the shared Python virtual environment at `../../.venv/bin/python3` if Python is required. Exception: `swain-macros` and `mac-fan` use the system `python3` because PyGObject (GTK) and evdev come from apt.

4. **macOS LaunchAgents**:
   - Label naming convention: `com.guilhermesalviano.<service-name>`.
   - Ship a `.plist.template` in `scripts/<name>/launchd/`, never a plist with real paths baked in — a clone can live anywhere. Use `__PLACEHOLDER__` tokens and have the tool's `install-service` command render them via `sed` (see `mac-monitor/manage.sh`) into `${HOME}/Library/LaunchAgents/`.
   - Set `WorkingDirectory` to the `tool-box` project root.
   - Use absolute paths in `ProgramArguments` pointing to `.venv/bin/python3` and the tool script.

---

## Adding a New Tool

1. Scaffold using the CLI:
   ```bash
   ./install.sh new <tool-name>
   ```
2. Implement your logic in `scripts/<tool-name>/run.sh` (or create Python/Bash scripts in that folder).
3. Update `scripts/<tool-name>/README.md` with description and instructions.
4. Verify with:
   ```bash
   ./install.sh list
   ./install.sh <tool-name>
   ```
