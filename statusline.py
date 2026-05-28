#!/usr/bin/env python3
"""Statusline cross-platform pour Claude Code (macOS + Windows natif).

Lit le JSON de session sur stdin et affiche :
  ✳ Model · dir · HH:MM · <emoji> NN% ctx · <emoji> jauge quota ⏳reset

Le quota de forfait (fenêtre 5h) est lu depuis ~/.claude/usage-cache.json,
rafraîchi en arrière-plan par usage-refresh.py quand le cache est périmé.
"""
import sys
import os
import json
import time
import subprocess
from pathlib import Path

CLAUDE_DIR = Path.home() / ".claude"
CACHE = CLAUDE_DIR / "usage-cache.json"
CTX_WINDOW = 200_000
TTL = 180  # secondes avant rafraîchissement du cache quota

RESET = "\033[0m"
DIM = "\033[2m"
ORANGE = "\033[38;5;208m"


def read_input():
    try:
        raw = sys.stdin.read()
    except Exception:
        return {}
    try:
        return json.loads(raw) if raw.strip() else {}
    except Exception:
        return {}


def context_segment(transcript):
    if not transcript or not os.path.isfile(transcript):
        return ""
    tokens = last_usage_tokens(transcript)
    if tokens <= 0:
        return ""
    pct = tokens * 100 // CTX_WINDOW
    if pct < 40:
        emoji, label, color = "🧠", "chill", "\033[32m"
    elif pct < 70:
        emoji, label, color = "🤔", "thinking", "\033[33m"
    elif pct < 90:
        emoji, label, color = "🥵", "hot", ORANGE
    else:
        emoji, label, color = "🤯", "melting", "\033[31m"
    return f"  ·  {emoji} {color}{pct}% {label}{RESET}"


def last_usage_tokens(path):
    try:
        with open(path, "r", encoding="utf-8", errors="replace") as f:
            lines = f.readlines()
    except Exception:
        return 0
    for line in reversed(lines):
        line = line.strip()
        if not line or '"usage"' not in line:
            continue
        try:
            obj = json.loads(line)
        except Exception:
            continue
        usage = (obj.get("message") or {}).get("usage")
        if usage:
            return (
                (usage.get("input_tokens") or 0)
                + (usage.get("cache_read_input_tokens") or 0)
                + (usage.get("cache_creation_input_tokens") or 0)
            )
    return 0


def usage_segment():
    now = int(time.time())
    fetched = 0
    seg = ""
    if CACHE.is_file():
        try:
            c = json.loads(CACHE.read_text(encoding="utf-8"))
        except Exception:
            c = {}
        fetched = int(c.get("fetched_at") or 0)
        h5u = c.get("h5_util")
        if h5u is not None:
            pct = int(h5u * 100 + 0.5)
            rem = int(c.get("h5_reset") or 0) - now
            cd = f"{rem // 3600}h{(rem % 3600) // 60:02d}" if rem > 0 else "reset!"
            filled = max(0, min(8, int(h5u * 8 + 0.5)))
            bar = "▰" * filled + "▱" * (8 - filled)
            if pct < 50:
                color, emo, lab = "\033[32m", "🚀", "cruise"
            elif pct < 75:
                color, emo, lab = "\033[33m", "🔥", "warm"
            elif pct < 90:
                color, emo, lab = ORANGE, "🥵", "danger"
            else:
                color, emo, lab = "\033[31m", "🚨", "MAX!"
            seg = f"  ·  {emo} {color}{bar} {pct}% {lab}{RESET} {DIM}⏳{cd}{RESET}"
    if (not CACHE.is_file()) or (now - fetched > TTL):
        spawn_refresh()
    return seg


def spawn_refresh():
    script = CLAUDE_DIR / "usage-refresh.py"
    if not script.is_file():
        return
    try:
        kwargs = dict(
            stdin=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        if os.name == "nt":
            kwargs["creationflags"] = 0x00000008 | 0x08000000 | 0x00000200  # DETACHED | NO_WINDOW | NEW_GROUP
        else:
            kwargs["start_new_session"] = True
        subprocess.Popen([sys.executable, str(script)], **kwargs)
    except Exception:
        pass


def main():
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass

    data = read_input()
    model = (data.get("model") or {})
    model_name = model.get("display_name") or model.get("id") or "claude"

    ws = data.get("workspace") or {}
    cwd = ws.get("current_dir") or data.get("cwd") or ""
    home = str(Path.home())
    if cwd.startswith(home):
        cwd = "~" + cwd[len(home):]
    dir_short = os.path.basename(cwd.rstrip("/\\")) or cwd or "~"

    tstr = time.strftime("%H:%M", time.localtime())
    ctx = context_segment(data.get("transcript_path") or "")
    usage = usage_segment()

    sys.stdout.write(f"{ORANGE}✳ {model_name}{RESET}  ·  {dir_short}  ·  {tstr}{ctx}{usage}")


if __name__ == "__main__":
    main()
