# Claude Code Fun Config

A few personal touches for your Claude Code terminal:

- **Statusline** at the bottom — model, current dir, last worked file, a 🟢 **dev-server indicator** (clickable `http://localhost:PORT` links for any common dev port that's listening), time, live **context-window** usage %, and a **plan-usage gauge** (5h window % + time-to-reset, colored 🚀/🔥/🥵/🚨)
- **Distinct per-session terminal color** — each concurrent Claude session gets its own muted dark tint, so two windows never share a color (macOS Terminal.app via a `SessionStart` hook; Windows Git Bash via an opt-in `claude` wrapper — see below)
- **Wordmark + sound** on each turn-end — discreet `✳ Claude Code` + a soft sound when Claude hands back to you
- **Custom spinner verbs** — `Brewing...`, `Galaxy-braining...`, `Marinating...` mixed with built-ins
- **Frictionless permissions** — all Bash + `gh` commands run without a confirmation prompt (with a `deny` safety net on destructive `rm -rf` / `sudo rm`), plus an optional `claude` shell alias that launches in bypass-permissions mode — see below

The statusline is **Python** (`statusline.py` + `usage-refresh.py`), so it runs the same on macOS, Linux and **Windows native** (PowerShell/cmd) — no bash or jq required at runtime.

## Requirements

- [Claude Code](https://claude.com/claude-code)
- **Python 3** on PATH (`python3` on macOS/Linux, `python` or `py` on Windows)

## Install

**macOS / Linux / Git Bash / WSL**

```bash
git clone https://github.com/lgdlcs/my-claudecode-terminal-setup.git
cd my-claudecode-terminal-setup
./install.sh
```

**Windows (PowerShell)**

```powershell
git clone https://github.com/lgdlcs/my-claudecode-terminal-setup.git
cd my-claudecode-terminal-setup
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

Both installers:

1. Back up your existing `statusline.py` / `usage-refresh.py` / `settings.json` with a timestamp suffix
2. Copy the Python scripts into `~/.claude/`
3. **Merge** the repo settings into yours (recursive; repo wins on conflicts, your machine-specific keys survive) and set the statusline command to the right Python launcher + absolute path for your OS

## Per-session terminal color

Each concurrent Claude session is tinted a different color from a 6-color dark palette, so you can tell two sessions apart at a glance.

- **macOS (Terminal.app)** — automatic, via the `SessionStart` hook in `settings.json`. It targets the tab by its TTY and picks a color not already used by another live session. Nothing to enable.
- **Windows (Git Bash / mintty / Windows Terminal)** — Claude runs hooks detached from the terminal, so a hook can't emit the color escape. Instead, source the `claude` wrapper, which runs in your live shell and emits `OSC 11`. Add this line to `~/.bashrc`:

  ```bash
  source ~/.claude/claude-session-color.bash
  ```

  Then open a new Git Bash window and run `claude` as usual. (Only triggers when launched via the `claude` command; no-ops on non–Git Bash shells.)

State lives in `~/.claude/session-colors/`; dead sessions are pruned automatically. With more than 6 simultaneous sessions, colors are reused round-robin.

## /terminaux — N Claude sessions tiled to fill the screen

The `/terminaux` slash command takes a number from **1 to 6** (default 3) and opens that many terminal windows, tiled in a grid so each takes the maximum proportion of the screen (all visible), each running `claude`, then switches every freshly launched session to `/effort max`.

Usage: `/terminaux 4`. Grid by N: **1**→full screen · **2**→2 columns · **3**→3 columns · **4**→2×2 · **5**→3 + 2 thirds (6th cell reserved) · **6**→3×3 (two rows of three).

**Match-cells placement:** the grid cells for N are computed, then each window is moved **only if it isn't already sitting in a cell** (within a ~30 px tolerance). Consequences: overlapping or misaligned windows — even ones already open — get re-tiled; re-running the same N when everything is already gridded moves nothing; going from 5 to 6 (same {3,3} geometry) leaves the five in place and drops the new window into the reserved 6th cell; a structure change (e.g. 4→5, {2,2}→{3,3}) shifts the cells so nothing matches and the whole screen is re-tiled.

- **macOS** — `~/Library/Scripts/arrange-terminals.applescript` (Terminal.app): opens the missing windows to reach N, then tiles via match-cells — any window not already in a grid cell is moved into a free cell while aligned windows stay put — launches `claude` in every idle grid window (windows already running a process are left untouched), then after a ~5 s startup delay sends `/effort max` into each session it just launched.
- **Windows** — `~/.claude/scripts/arrange-terminals.ps1`: opens the missing windows to reach N (Windows Terminal if available, plain PowerShell otherwise), then tiles via match-cells (reads each window's bounds with `GetWindowRect`; windows not already in a cell are moved, aligned ones stay put), launches `claude` in each new one, then sends `/effort max` to every new window via `SendKeys`. Only new windows are launched into, since injecting a command into an existing window could type into a running process.

> Contributing rule: any new command or config pushed to this repo must ship **both** a macOS and a Windows implementation (installed by `install.sh` and `install.ps1` respectively), or document the gap in the OS support table below.

## Brad — the build-in-public Twitter/X agent

**Brad** is a Claude Code subagent that runs the owner's Twitter/X presence in build-in-public mode: direct, honest, wins **and** losses. He proposes and drafts content; the owner reviews and posts by hand (automatic posting is disabled — see below).

- **Invoke** with `/brad` (no arg → 3 tweet ideas for today; arg → a specific Twitter task), or just by mentioning *build in public / tweet / Twitter* (the subagent auto-triggers on its description).
- **Installed files:** `agents/brad.md` (subagent), `commands/brad.md` (`/brad`), and `twitter-agent/` (config + scripts) → `~/.claude/agents/`, `~/.claude/commands/`, `~/.claude/twitter-agent/`.
- **Edit his behavior** in `~/.claude/twitter-agent/context.md` (voice, topics, quotas, language) and `strategy.md` (positioning, pillars, cadence). The installer **never overwrites** these once they exist.
- **Kill switch:** `touch ~/.claude/twitter-agent/PAUSED` stops every job.

Two scheduled jobs (background) — **draft-only, nothing is posted automatically:**

| Job | When | Does |
|---|---|---|
| `brad-daily` | every day 8:00 | 3 tweet proposals (grow audience + bring value), grounded in recent `~/code` git activity; opens in VS Code |
| `brad-weekly` | Sunday 18:00 | GitHub regularity recap (week commits, day **streak**, LOC — mocked, since AI makes LOC meaningless) drafted for Monday |

> **Automatic X posting is disabled** (2026-07-21, owner's decision): Brad drafts, the owner reviews and posts by hand. The former `brad-monday-post` job (Monday browser auto-post via Playwright) has been removed; `install.sh` also unloads it from existing machines. Scheduling is **launchd** on macOS (plist templates rendered with `$HOME` and loaded by `install.sh`) and **Task Scheduler** on Windows (`register-tasks.ps1`, run by `install.ps1`).

## Permissions & bypass alias

Two layers, so day-to-day use needs no confirmation clicks:

1. **`permissions` in `settings.json`** — `allow` covers all `Bash` (and `gh`) so commands run without a prompt, while `deny` still blocks destructive `rm -rf /`, `rm -rf ~`, and `sudo rm`. This is the **safe** default and the `deny` net is honored whenever you're *not* in bypass mode.
2. **`claude` shell alias** (macOS/Linux, added by `install.sh` to `~/.zshrc`) — runs `claude --dangerously-skip-permissions` so every session starts with no prompts at all. The alias is only added if no `alias claude=` already exists.

   ```bash
   alias claude='claude --dangerously-skip-permissions'
   ```

   ⚠️ Bypass mode ignores **all** permission rules, including the `deny` net above. To launch *without* the flag for one run, use `\claude` (or `command claude`).

## How the plan-usage gauge works

`usage-refresh.py` makes a tiny (1-token) `/v1/messages` call using your Claude Code OAuth token and reads the `anthropic-ratelimit-unified-*` response headers, caching them in `~/.claude/usage-cache.json`. `statusline.py` renders from that cache and triggers a background refresh when it's older than `TTL` (180 s). The token is read at runtime from `~/.claude/.credentials.json` (with a macOS Keychain fallback) — **no secret is stored in these files**.

> On Windows, if Claude Code keeps credentials in the Windows Credential Manager instead of `~/.claude/.credentials.json`, the gauge will simply not show. The rest of the statusline still works.

## OS support

| Feature        | macOS              | Windows (native)   | Linux / WSL |
|----------------|--------------------|--------------------|-------------|
| Statusline     | yes                | yes (Python)       | yes         |
| Plan-usage gauge | yes              | yes (if creds file)| yes         |
| Per-session color | yes (Terminal.app) | yes (Git Bash wrapper) | skipped  |
| Sound          | `Pop.aiff`         | PowerShell beep    | skipped     |
| Wordmark       | yes                | yes                | yes         |
| /terminaux (3× claude tiled) | yes (Terminal.app) | yes (wt / PowerShell) | no |
| Spinner verbs  | yes                | yes                | yes         |
| Bypass `claude` alias | yes (zsh) | no (add a PowerShell function by hand) | yes (zsh) |
| Brad — `/brad` + daily/weekly proposals | yes (launchd) | yes (Task Scheduler) | partial (jobs need cron, not provided) |
| Brad — automatic X posting | disabled (draft-only) | disabled (draft-only) | disabled (draft-only) |

ANSI colors need a VT-capable terminal — Windows Terminal works out of the box. The `SessionStart`/`Stop` hooks are still shell snippets and no-op silently where they don't apply.

## Customize

| Tweak | Where |
|---|---|
| Refresh cadence of the plan gauge | `TTL = 180` in `statusline.py` |
| Context window size | `CTX_WINDOW = 200_000` in `statusline.py` |
| Gauge thresholds / emojis | `usage_segment()` in `statusline.py` |
| Dev ports scanned for the 🟢 server indicator | `DEV_PORTS` in `statusline.py` (5000/7000 excluded — macOS AirPlay) |
| Add/remove spinner verbs | `spinnerVerbs.verbs` array in `settings.json` |
| Drop built-in verbs | change `spinnerVerbs.mode` from `"append"` to `"replace"` |
| Different macOS sound | swap `Pop.aiff` for `Tink.aiff`, `Glass.aiff`, … (in `/System/Library/Sounds/`) |
| Different beep on Windows | change `880,80` (`Hz,ms`) in the Stop hook |

## Uninstall

```bash
ls ~/.claude/*.bak.*                                  # list backups
cp ~/.claude/settings.json.bak.<TS> ~/.claude/settings.json
```

Or remove the keys `spinnerVerbs`, `statusLine`, and the `SessionStart` / `Stop` entries from `~/.claude/settings.json` by hand, and delete `statusline.py` / `usage-refresh.py` / `usage-cache.json`.
