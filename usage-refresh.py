#!/usr/bin/env python3
"""Rafraîchit le cache d'utilisation du forfait (fenêtre 5h / 7j).

Appelé en arrière-plan par statusline.py. Écrit ~/.claude/usage-cache.json.
Lit les en-têtes anthropic-ratelimit-unified-* via un appel /v1/messages minimal
(1 token). Cross-platform : credentials par fichier, repli keychain sur macOS.
"""
import sys
import json
import time
import subprocess
import urllib.request
import urllib.error
from pathlib import Path

CLAUDE_DIR = Path.home() / ".claude"
CACHE = CLAUDE_DIR / "usage-cache.json"
LOCK = CLAUDE_DIR / ".usage-refresh.lock"
API_URL = "https://api.anthropic.com/v1/messages"


def get_token():
    cred = CLAUDE_DIR / ".credentials.json"
    if cred.is_file():
        try:
            data = json.loads(cred.read_text(encoding="utf-8"))
            tok = (data.get("claudeAiOauth") or {}).get("accessToken")
            if tok:
                return tok
        except Exception:
            pass
    if sys.platform == "darwin":
        try:
            out = subprocess.run(
                ["security", "find-generic-password", "-s", "Claude Code-credentials", "-w"],
                capture_output=True, text=True, timeout=5,
            )
            data = json.loads(out.stdout)
            return (data.get("claudeAiOauth") or {}).get("accessToken")
        except Exception:
            return None
    return None


def acquire_lock():
    """Lock anti-stampede via mkdir. Lock périmé (>60s) => on le casse."""
    try:
        if LOCK.exists():
            if time.time() - LOCK.stat().st_mtime > 60:
                try:
                    LOCK.rmdir()
                except Exception:
                    pass
            else:
                return False
        LOCK.mkdir()
        return True
    except Exception:
        return False


def fetch_headers(token):
    body = json.dumps({
        "model": "claude-haiku-4-5-20251001",
        "max_tokens": 1,
        "messages": [{"role": "user", "content": "."}],
    }).encode("utf-8")
    req = urllib.request.Request(API_URL, data=body, method="POST")
    req.add_header("authorization", f"Bearer {token}")
    req.add_header("anthropic-version", "2023-06-01")
    req.add_header("anthropic-beta", "oauth-2025-04-20")
    req.add_header("content-type", "application/json")
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            return {k.lower(): v for k, v in resp.headers.items()}
    except urllib.error.HTTPError as e:
        # Même en 429, les en-têtes ratelimit sont présents.
        return {k.lower(): v for k, v in (e.headers or {}).items()}
    except Exception:
        return {}


def main():
    if not acquire_lock():
        return
    try:
        token = get_token()
        if not token:
            return
        h = fetch_headers(token)
        h5u = h.get("anthropic-ratelimit-unified-5h-utilization")
        if h5u is None:
            return  # auth échouée / pas d'en-tête : on garde l'ancien cache
        out = {
            "fetched_at": int(time.time()),
            "h5_util": float(h5u),
            "h5_reset": int(h.get("anthropic-ratelimit-unified-5h-reset") or 0),
            "d7_util": float(h.get("anthropic-ratelimit-unified-7d-utilization") or 0),
            "d7_reset": int(h.get("anthropic-ratelimit-unified-7d-reset") or 0),
            "status": h.get("anthropic-ratelimit-unified-status") or "unknown",
        }
        tmp = CACHE.with_name(CACHE.name + ".tmp")
        tmp.write_text(json.dumps(out), encoding="utf-8")
        tmp.replace(CACHE)
    finally:
        try:
            LOCK.rmdir()
        except Exception:
            pass


if __name__ == "__main__":
    main()
