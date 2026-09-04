#!/usr/bin/env python3
"""Garde-fou worktree : empeche deux sessions Claude de travailler
simultanement dans le meme checkout git.

- SessionStart : enregistre la session, et si un autre process claude vivant
  occupe deja le meme worktree, injecte une consigne imposant la creation
  d'un worktree dedie.
- SessionEnd   : desenregistre la session.

Registre : ~/.claude/worktree-guard/sessions/<session_id>.json (un fichier par
session, pas de lock necessaire).
"""
import json
import os
import subprocess
import sys
import time

REG = os.path.expanduser("~/.claude/worktree-guard/sessions")


def sh(args, cwd=None):
    try:
        out = subprocess.run(args, cwd=cwd, capture_output=True, text=True, timeout=5)
    except Exception:
        return None
    if out.returncode != 0:
        return None
    return out.stdout.strip() or None


def claude_pid():
    """Remonte la chaine des parents jusqu'au process `claude`."""
    pid = os.getppid()
    for _ in range(8):
        info = sh(["ps", "-o", "ppid=,comm=", "-p", str(pid)])
        if not info:
            break
        parts = info.split(None, 1)
        if len(parts) == 2 and "claude" in parts[1]:
            return pid
        try:
            pid = int(parts[0])
        except (ValueError, IndexError):
            break
        if pid <= 1:
            break
    return os.getppid()


def alive(pid):
    try:
        os.kill(int(pid), 0)
    except (OSError, ValueError, TypeError):
        return False
    return True


def load_others(session_id):
    others = []
    try:
        names = os.listdir(REG)
    except OSError:
        return others
    for name in names:
        if not name.endswith(".json"):
            continue
        path = os.path.join(REG, name)
        try:
            with open(path, encoding="utf-8") as fh:
                entry = json.load(fh)
        except Exception:
            try:
                os.remove(path)
            except OSError:
                pass
            continue
        if not alive(entry.get("pid")):
            try:
                os.remove(path)  # purge des sessions mortes
            except OSError:
                pass
            continue
        if entry.get("session_id") == session_id:
            continue
        others.append(entry)
    return others


def main():
    action = sys.argv[1] if len(sys.argv) > 1 else "session"
    try:
        payload = json.load(sys.stdin)
    except Exception:
        payload = {}

    if payload.get("agent_id"):  # sous-agent : ignore
        return

    session_id = payload.get("session_id") or os.environ.get("CLAUDE_SESSION_ID")
    if not session_id:
        return
    path = os.path.join(REG, "%s.json" % str(session_id).replace("/", "_"))

    if action == "end":
        try:
            os.remove(path)
        except OSError:
            pass
        return

    cwd = payload.get("cwd") or os.getcwd()
    toplevel = sh(["git", "rev-parse", "--show-toplevel"], cwd=cwd)
    if not toplevel:
        return  # pas un depot git : rien a garder
    common = sh(["git", "rev-parse", "--path-format=absolute", "--git-common-dir"], cwd=cwd) or toplevel

    os.makedirs(REG, exist_ok=True)
    others = load_others(session_id)

    entry = {
        "session_id": session_id,
        "pid": claude_pid(),
        "cwd": cwd,
        "toplevel": toplevel,
        "git_common_dir": common,
        "started": time.time(),
    }
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8") as fh:
        json.dump(entry, fh)
    os.replace(tmp, path)

    same_checkout = [o for o in others if o.get("toplevel") == toplevel]
    if not same_checkout:
        return

    same_repo = [
        o for o in others
        if o.get("git_common_dir") == common and o.get("toplevel") != toplevel
    ]
    busy = "\n".join(
        "  - session %s (pid %s)" % (str(o.get("session_id"))[:8], o.get("pid"))
        for o in same_checkout
    )
    taken = "\n".join(
        "  - %s" % o.get("toplevel") for o in same_repo
    ) or "  (aucun)"

    msg = (
        "REGLE WORKTREE — OBLIGATOIRE (hook worktree-guard)\n\n"
        "Une autre session Claude est deja active dans CE checkout :\n"
        "  %s\n%s\n\n"
        "Autres worktrees deja occupes :\n%s\n\n"
        "Avant toute modification de fichier, de branche ou tout lancement de "
        "serveur de dev dans ce depot, tu DOIS travailler dans un worktree git "
        "dedie :\n"
        "  1. Utilise l'outil EnterWorktree (le charger via ToolSearch si besoin), "
        "ou a defaut :\n"
        "     git -C %s worktree add ../$(basename %s)-wt-<sujet> -b wt/<sujet>\n"
        "     puis travaille depuis ce repertoire.\n"
        "  2. Choisis un port de dev distinct (3000 pris -> 3001, 3002, ...).\n"
        "  3. Annonce a l'utilisateur, en une ligne, le worktree, la branche et "
        "le port retenus.\n\n"
        "Seules exceptions, sans creer de worktree : lecture seule "
        "(consultation, recherche, explication) et commandes git de lecture. "
        "Si l'utilisateur demande explicitement de rester sur ce checkout, "
        "signale le conflit puis obeis."
    ) % (toplevel, busy, taken, toplevel, toplevel)

    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "SessionStart",
            "additionalContext": msg,
        },
        "systemMessage": "⚠ worktree-guard : session concurrente detectee sur %s -> worktree dedie requis" % os.path.basename(toplevel),
    }))


if __name__ == "__main__":
    try:
        main()
    except Exception:
        pass
