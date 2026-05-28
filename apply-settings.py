#!/usr/bin/env python3
"""Fusionne le settings.json du repo dans ~/.claude/settings.json.

Merge récursif (les réglages du repo gagnent sur les conflits, les clés
spécifiques à la machine de l'utilisateur sont préservées), puis fixe la
commande statusLine adaptée à l'OS avec un chemin absolu (pas d'expansion ~).

Usage : python apply-settings.py [launcher]
  launcher = nom de l'exécutable Python à utiliser dans la commande statusLine
             (défaut : "python" sous Windows, "python3" ailleurs).
"""
import json
import os
import sys
import time
from pathlib import Path

REPO_DIR = Path(__file__).resolve().parent
CLAUDE_DIR = Path.home() / ".claude"


def deep_merge(base, over):
    out = dict(base)
    for k, v in over.items():
        if isinstance(v, dict) and isinstance(out.get(k), dict):
            out[k] = deep_merge(out[k], v)
        else:
            out[k] = v
    return out


def main():
    launcher = sys.argv[1] if len(sys.argv) > 1 else ("python" if os.name == "nt" else "python3")
    CLAUDE_DIR.mkdir(parents=True, exist_ok=True)

    repo_settings = json.loads((REPO_DIR / "settings.json").read_text(encoding="utf-8"))

    user_path = CLAUDE_DIR / "settings.json"
    user_settings = {}
    if user_path.is_file():
        try:
            user_settings = json.loads(user_path.read_text(encoding="utf-8"))
        except Exception:
            user_settings = {}
        bak = CLAUDE_DIR / f"settings.json.bak.{time.strftime('%Y%m%d-%H%M%S')}"
        bak.write_text(json.dumps(user_settings, indent=2, ensure_ascii=False), encoding="utf-8")
        print(f"Backed up: {bak.name}")

    merged = deep_merge(user_settings, repo_settings)

    script = CLAUDE_DIR / "statusline.py"
    merged.setdefault("statusLine", {})
    merged["statusLine"]["type"] = "command"
    merged["statusLine"]["command"] = f'{launcher} "{script}"'
    merged["statusLine"].setdefault("padding", 1)

    user_path.write_text(json.dumps(merged, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"Installed: {user_path}")
    print(f"statusLine command: {merged['statusLine']['command']}")


if __name__ == "__main__":
    main()
