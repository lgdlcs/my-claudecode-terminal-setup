# Claude Code Fun Config

A few personal touches for your Claude Code terminal:

- **Random tab color** at session start — muted dark palette, easy on the eyes (macOS Terminal.app only)
- **Wordmark + sound** on each turn-end — discreet `✳ Claude Code` + a soft sound when Claude hands back to you
- **Custom spinner verbs** — `Brewing...`, `Galaxy-braining...`, `Marinating...` mixed with built-ins
- **Statusline** at the bottom — model, current dir, time, live context-window usage %

## Requirements

- [Claude Code](https://claude.com/claude-code)
- `jq` (used by the statusline and the installer)
- Bash — built-in on macOS/Linux, install [Git for Windows](https://git-scm.com/download/win) on Windows

## Install

```bash
git clone https://github.com/<you>/claude-code-fun-config.git
cd claude-code-fun-config
./install.sh
```

The installer:

1. Backs up `~/.claude/settings.json` and `~/.claude/statusline.sh` with a timestamp suffix
2. **Merges** the new settings into yours (recursive merge, new keys win on conflict — so your `model`, `permissions`, etc. survive)
3. Copies `statusline.sh` and makes it executable

## Manual install

```bash
cp statusline.sh   ~/.claude/statusline.sh
chmod +x           ~/.claude/statusline.sh
cp settings.json   ~/.claude/settings.json   # or merge by hand
```

## OS support

| Feature        | macOS                | Windows (Git Bash) | Linux / WSL |
|----------------|----------------------|--------------------|-------------|
| Tab color      | yes (Terminal.app)   | skipped            | skipped     |
| Sound          | `Pop.aiff`           | PowerShell beep    | skipped     |
| Wordmark       | yes                  | yes                | yes         |
| Spinner verbs  | yes                  | yes                | yes         |
| Statusline     | yes                  | yes                | yes         |

Skipped features no-op silently; no error.

## Customize

| Tweak | Where |
|---|---|
| Add/remove spinner verbs | `spinnerVerbs.verbs` array in `settings.json` |
| Drop the built-in verbs entirely | change `spinnerVerbs.mode` from `"append"` to `"replace"` |
| Different macOS sound | swap `Pop.aiff` for `Tink.aiff`, `Glass.aiff`, `Submarine.aiff` (in `/System/Library/Sounds/`) |
| Different beep frequency on Windows | change `880,80` in the Stop hook (`Hz,ms`) |
| Different context window | `200000` is hardcoded in `statusline.sh` (Opus 4.7). Change for other models. |

## Uninstall

```bash
ls ~/.claude/*.bak.*                                           # list backups
cp ~/.claude/settings.json.bak.<TS>   ~/.claude/settings.json
cp ~/.claude/statusline.sh.bak.<TS>   ~/.claude/statusline.sh
```

Or remove the keys `spinnerVerbs`, `statusLine`, and the `SessionStart` / `Stop` entries from `~/.claude/settings.json` by hand.
