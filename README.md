# Claude Code Fun Config

A few personal touches for your Claude Code terminal:

- **Statusline** at the bottom — model, current dir, time, live **context-window** usage %, and a **plan-usage gauge** (5h window % + time-to-reset, colored 🚀/🔥/🥵/🚨)
- **Random tab color** at session start — muted dark palette, easy on the eyes (macOS Terminal.app only)
- **Wordmark + sound** on each turn-end — discreet `✳ Claude Code` + a soft sound when Claude hands back to you
- **Custom spinner verbs** — `Brewing...`, `Galaxy-braining...`, `Marinating...` mixed with built-ins

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

## How the plan-usage gauge works

`usage-refresh.py` makes a tiny (1-token) `/v1/messages` call using your Claude Code OAuth token and reads the `anthropic-ratelimit-unified-*` response headers, caching them in `~/.claude/usage-cache.json`. `statusline.py` renders from that cache and triggers a background refresh when it's older than `TTL` (180 s). The token is read at runtime from `~/.claude/.credentials.json` (with a macOS Keychain fallback) — **no secret is stored in these files**.

> On Windows, if Claude Code keeps credentials in the Windows Credential Manager instead of `~/.claude/.credentials.json`, the gauge will simply not show. The rest of the statusline still works.

## OS support

| Feature        | macOS              | Windows (native)   | Linux / WSL |
|----------------|--------------------|--------------------|-------------|
| Statusline     | yes                | yes (Python)       | yes         |
| Plan-usage gauge | yes              | yes (if creds file)| yes         |
| Tab color      | yes (Terminal.app) | skipped            | skipped     |
| Sound          | `Pop.aiff`         | PowerShell beep    | skipped     |
| Wordmark       | yes                | yes                | yes         |
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
