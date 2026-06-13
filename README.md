# Claude Code Fun Config

A few personal touches for your Claude Code terminal:

- **Statusline** at the bottom — model, current dir, time, live **context-window** usage %, and a **plan-usage gauge** (5h window % + time-to-reset, colored 🚀/🔥/🥵/🚨)
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

## /terminaux — 3 Claude sessions side by side

The `/terminaux` slash command opens and arranges 3 terminal windows in thirds of the screen (left/center/right column), each running `claude`.

- **macOS** — `~/Library/Scripts/arrange-3-terminals.applescript` (Terminal.app): reuses existing windows, opens the missing ones, then launches `claude` in every idle window (windows already running a process are left untouched).
- **Windows** — `~/.claude/scripts/arrange-3-terminals.ps1`: opens 3 new windows (Windows Terminal if available, plain PowerShell otherwise), tiles them in thirds and launches `claude` in each. Always opens new windows, since injecting a command into an existing window could type into a running process.

> Contributing rule: any new command or config pushed to this repo must ship **both** a macOS and a Windows implementation (installed by `install.sh` and `install.ps1` respectively), or document the gap in the OS support table below.

## /loop — redirect to a dedicated loop terminal

`/loop` runs an autonomous, self-paced loop. A `UserPromptSubmit` hook (`loop-terminal-hook.sh`) intercepts it and shunts it into a **dedicated "Claude Loops" terminal**, so a long-running loop never hijacks the session you typed it in.

- **macOS (Terminal.app)** — `loop-terminal.sh` finds (or opens) the dedicated tab. A loop session is identified by a per-session marker file `~/.claude/.loop-sessions/<tty>` that the session writes on start and removes on exit — **not** by tab title (overwritten by the shell / Claude Code) nor by a remembered TTY (recycled by macOS, which previously made `/loop` redirect onto the *current* session). A live busy loop tab is reused, a stale marker is purged, otherwise a fresh window opens. The loop session is marked with `CLAUDE_LOOP_TERMINAL=1` so its own hook lets `/loop` through instead of re-redirecting.
- **Windows** — not implemented; the hook is guarded by `case "$OSTYPE" in darwin*)`, so `/loop` runs in the current session.

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
| /loop → dedicated terminal | yes (Terminal.app) | no                 | no          |
| Spinner verbs  | yes                | yes                | yes         |

ANSI colors need a VT-capable terminal — Windows Terminal works out of the box. The `SessionStart`/`Stop` hooks are still shell snippets and no-op silently where they don't apply.

## Customize

| Tweak | Where |
|---|---|
| Refresh cadence of the plan gauge | `TTL = 180` in `statusline.py` |
| Context window size | `CTX_WINDOW = 200_000` in `statusline.py` |
| Gauge thresholds / emojis | `usage_segment()` in `statusline.py` |
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
