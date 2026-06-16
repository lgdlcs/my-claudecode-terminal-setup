#!/usr/bin/env python3
"""Statusline cross-platform pour Claude Code (macOS + Windows natif).

Lit le JSON de session sur stdin et affiche :
  ✳ Model · dir · 📄 fichier · 🟢 serveurs · HH:MM · <emoji> NN% ctx · <emoji> jauge quota ⏳reset

Le segment serveur sonde les ports de dev courants sur 127.0.0.1 (cross-platform,
sans lsof/netstat) et affiche en vert ceux qui écoutent, en liens cliquables.

Le quota de forfait (fenêtre 5h) est lu depuis ~/.claude/usage-cache.json,
rafraîchi en arrière-plan par usage-refresh.py quand le cache est périmé.
"""
import sys
import os
import re
import json
import time
import hashlib
import tempfile
import subprocess
from pathlib import Path

CLAUDE_DIR = Path.home() / ".claude"
CACHE = CLAUDE_DIR / "usage-cache.json"
CTX_WINDOW = 200_000
TTL = 180  # secondes avant rafraîchissement du cache quota
PROJ_TTL = 30  # secondes de cache pour la résolution git du projet
TMP = Path(tempfile.gettempdir())

RESET = "\033[0m"
DIM = "\033[2m"
CYAN = "\033[36m"
GREEN = "\033[32m"
ORANGE = "\033[38;5;208m"

# Ports de dev courants sondés pour détecter un serveur local actif
# NB : 5000 et 7000 sont exclus (AirPlay Receiver de macOS y écoute en permanence)
DEV_PORTS = [3000, 3001, 4000, 4200, 5173, 5174, 8000, 8080, 8081, 8888, 9000, 19000]
PORT_TTL = 3  # secondes de cache pour le scan des ports

# Outils du transcript qui « touchent » un fichier
EDIT_TOOLS = ("Edit", "Write", "MultiEdit", "NotebookEdit")
READ_TOOLS = ("Read",)


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


def last_worked_file(path):
    """Retourne le dernier fichier travaillé : modifié (Edit/Write/...) en priorité,
    sinon le dernier fichier lu (Read). None si rien."""
    if not path or not os.path.isfile(path):
        return None
    try:
        with open(path, "r", encoding="utf-8", errors="replace") as f:
            lines = f.readlines()
    except Exception:
        return None
    fallback_read = None
    for line in reversed(lines):
        line = line.strip()
        if not line or '"tool_use"' not in line or '"file_path"' not in line:
            continue
        try:
            obj = json.loads(line)
        except Exception:
            continue
        msg = obj.get("message")
        content = msg.get("content") if isinstance(msg, dict) else None
        if not isinstance(content, list):
            continue
        for b in content:
            if not isinstance(b, dict) or b.get("type") != "tool_use":
                continue
            name = b.get("name")
            fp = (b.get("input") or {}).get("file_path")
            if not fp:
                continue
            if name in EDIT_TOOLS:
                return fp  # priorité absolue : on s'arrête au 1er modifié
            if name in READ_TOOLS and fallback_read is None:
                fallback_read = fp
    return fallback_read


def _git(args, cwd):
    try:
        out = subprocess.check_output(
            ["git", "-C", cwd] + args,
            stderr=subprocess.DEVNULL, text=True, timeout=2,
        )
        return out.strip()
    except Exception:
        return ""


def remote_to_https(url):
    """Convertit une URL git (SSH ou HTTPS) en URL web https, sans .git."""
    if not url:
        return ""
    url = url.strip()
    # git@host:owner/repo(.git)  ->  https://host/owner/repo
    m = re.match(r"^[\w.-]+@([\w.-]+):(.+)$", url)
    if m:
        url = "https://{}/{}".format(m.group(1), m.group(2))
    url = re.sub(r"^ssh://git@", "https://", url)
    url = re.sub(r"\.git$", "", url)
    return url


def project_link(file_path):
    """Résout (texte, lien) pour le projet du fichier. Caché ~PROJ_TTL secondes.
    lien priorité : URL remote https -> file://racine -> file://dossier."""
    d = os.path.dirname(file_path) or "."
    key = hashlib.md5(d.encode("utf-8", "replace")).hexdigest()[:16]
    cache_file = TMP / f"statusline-proj-{key}"
    now = time.time()
    cached = None
    try:
        if cache_file.is_file() and now - cache_file.stat().st_mtime < PROJ_TTL:
            cached = json.loads(cache_file.read_text(encoding="utf-8"))
    except Exception:
        cached = None
    if cached is None:
        root = _git(["rev-parse", "--show-toplevel"], d)
        remote = remote_to_https(_git(["remote", "get-url", "origin"], d))
        cached = {"root": root, "remote": remote}
        try:
            cache_file.write_text(json.dumps(cached), encoding="utf-8")
        except Exception:
            pass
    root = cached.get("root") or ""
    remote = cached.get("remote") or ""

    # Texte = chemin relatif à la racine du repo, sinon parent/fichier
    if root and file_path.startswith(root):
        text = file_path[len(root):].lstrip("/\\") or os.path.basename(file_path)
    else:
        parent = os.path.basename(os.path.dirname(file_path))
        text = os.path.join(parent, os.path.basename(file_path)) if parent else os.path.basename(file_path)

    if remote:
        link = remote
    elif root:
        link = "file://" + root
    else:
        link = "file://" + d
    return text, link


def truncate_path(text, max_len):
    if max_len <= 0 or len(text) <= max_len:
        return text
    base = os.path.basename(text)
    if len(base) + 2 >= max_len:
        return "…" + base[-(max_len - 1):]
    return "…/" + text[-(max_len - 2):]


def file_segment(transcript):
    fp = last_worked_file(transcript)
    if not fp:
        return ""
    text, link = project_link(fp)
    try:
        cols = int(os.environ.get("COLUMNS", "0"))
    except ValueError:
        cols = 0
    if cols > 40:
        text = truncate_path(text, max(12, cols // 3))
    # OSC 8 : \033]8;;URL\033\\  TEXTE  \033]8;;\033\\
    osc_open = f"\033]8;;{link}\033\\"
    osc_close = "\033]8;;\033\\"
    return f"  ·  {osc_open}{CYAN}📄 {text}{RESET}{osc_close}"


def _port_open(port):
    """True si un service écoute sur 127.0.0.1:port (connexion TCP brève)."""
    import socket
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(0.04)
    try:
        return s.connect_ex(("127.0.0.1", port)) == 0
    except Exception:
        return False
    finally:
        try:
            s.close()
        except Exception:
            pass


def server_segment():
    """Affiche les ports de dev qui écoutent, en vert et cliquables.
    Résultat caché ~PORT_TTL secondes pour éviter de re-scanner à chaque rendu."""
    cache_file = TMP / "statusline-ports"
    now = time.time()
    ports = None
    try:
        if cache_file.is_file() and now - cache_file.stat().st_mtime < PORT_TTL:
            ports = json.loads(cache_file.read_text(encoding="utf-8"))
    except Exception:
        ports = None
    if ports is None:
        ports = [p for p in DEV_PORTS if _port_open(p)]
        try:
            cache_file.write_text(json.dumps(ports), encoding="utf-8")
        except Exception:
            pass
    if not ports:
        return ""
    parts = []
    for p in ports[:3]:
        link = f"http://localhost:{p}"
        osc_open = f"\033]8;;{link}\033\\"
        osc_close = "\033]8;;\033\\"
        parts.append(f"{osc_open}:{p}{osc_close}")
    extra = "+" if len(ports) > 3 else ""
    return f"  ·  {GREEN}🟢 {' '.join(parts)}{extra}{RESET}"


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

    transcript = data.get("transcript_path") or ""
    tstr = time.strftime("%H:%M", time.localtime())
    fileseg = file_segment(transcript)
    serverseg = server_segment()
    ctx = context_segment(transcript)
    usage = usage_segment()

    sys.stdout.write(f"{ORANGE}✳ {model_name}{RESET}  ·  {dir_short}{fileseg}{serverseg}  ·  {tstr}{ctx}{usage}")


if __name__ == "__main__":
    main()
