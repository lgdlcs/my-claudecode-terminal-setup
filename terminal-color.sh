#!/usr/bin/env bash
# Change the background color of THIS Claude session's Terminal.app tab.
#
# Companion to terminal-session-color.sh (which auto-assigns a distinct color at
# session start): this one is manual, driven by the /couleur slash command.
# Same TTY-targeting trick — the hook shell has no controlling tty, so we walk up
# the process tree to find the Claude process's tty and color that exact tab.
#
# Usage: terminal-color.sh <nom|#rrggbb|random|liste>
# macOS / Terminal.app only; no-ops (with a message) everywhere else.

set -u

ARG="${1:-}"

# --- Named palette: hex, dark tints (light text) unless noted -----------------
color_hex() {
  case "$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')" in
    bleu|blue)             echo "1F3656" ;;
    teal|turquoise|cyan)   echo "173E46" ;;
    vert|green)            echo "1F462B" ;;
    violet|purple)         echo "3E2756" ;;
    rouge|red)             echo "56232F" ;;
    ambre|amber|orange)    echo "563A1B" ;;
    rose|pink)             echo "50213D" ;;
    gris|grey|gray)        echo "2B2B2B" ;;
    noir|black|defaut|default|reset) echo "000000" ;;
    blanc|white|clair|light) echo "F2F0E8" ;;
    *) return 1 ;;
  esac
}

NAMES="bleu teal vert violet rouge ambre rose gris noir blanc"

if [ -z "$ARG" ] || [ "$ARG" = "liste" ] || [ "$ARG" = "list" ]; then
  echo "Couleurs : $NAMES"
  echo "Ou un hex (#1F3656 / 1f3656), ou 'random'."
  exit 0
fi

if [ "$(uname)" != "Darwin" ] || [ "${TERM_PROGRAM:-}" != "Apple_Terminal" ]; then
  echo "Non supporté ici : ce script ne pilote que Terminal.app sur macOS."
  exit 1
fi
command -v osascript >/dev/null 2>&1 || { echo "osascript introuvable."; exit 1; }

# --- Resolve the requested color to a 6-digit hex ----------------------------
if [ "$ARG" = "random" ] || [ "$ARG" = "aleatoire" ] || [ "$ARG" = "aléatoire" ]; then
  set -- $NAMES
  n=$#
  pick=$(( (RANDOM % (n - 1)) + 1 ))   # exclude 'blanc' (last) from random picks
  eval "ARG=\${$pick}"
fi

if hex=$(color_hex "$ARG"); then
  label="$ARG"
else
  candidate=$(printf '%s' "$ARG" | tr -d '#' | tr '[:lower:]' '[:upper:]')
  case "$candidate" in
    [0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F]) hex="$candidate"; label="#$candidate" ;;
    *)
      echo "Couleur inconnue : $ARG"
      echo "Couleurs : $NAMES  — ou un hex (#1F3656), ou 'random'."
      exit 1 ;;
  esac
fi

r=$((16#${hex:0:2})); g=$((16#${hex:2:2})); b=$((16#${hex:4:2}))

# AppleScript wants 16-bit channels.
r16=$((r * 257)); g16=$((g * 257)); b16=$((b * 257))

# Readable text: dark ink on light backgrounds, light ink on dark ones.
lum=$(( (r * 299 + g * 587 + b * 114) / 1000 ))
if [ "$lum" -gt 140 ]; then
  txt="6000, 6000, 6000"
else
  txt="60000, 60000, 60000"
fi

# --- Find this session's Terminal tab by walking up the process tree ---------
# The nearest tty isn't always a Terminal tab (wrappers like Herd or `script`
# allocate their own pty), so we keep walking and take the first ancestor tty
# that Terminal actually owns.
tabs_ttys=$(osascript -e 'tell application "Terminal" to get tty of every tab of every window' 2>/dev/null \
  | tr ',' '\n' | sed 's#.*/##; s/ //g')
mytty=""
pid=$$
for _ in 1 2 3 4 5 6 7 8 9 10 11 12; do
  t=$(ps -o tty= -p "$pid" 2>/dev/null | tr -d ' ')
  case "$t" in
    ttys*)
      if printf '%s\n' "$tabs_ttys" | grep -qx "$t"; then mytty="$t"; break; fi
      ;;
  esac
  pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
  { [ -z "$pid" ] || [ "$pid" = "0" ]; } && break
done

# --- Apply: to the matching tab if found, else to the front window -----------
applied=$(osascript 2>/dev/null <<EOF
tell application "Terminal"
  set hit to false
  repeat with w in windows
    repeat with t in tabs of w
      if (tty of t) is "/dev/$mytty" then
        set background color of t to {$r16, $g16, $b16}
        set normal text color of t to {$txt}
        set cursor color of t to {$txt}
        set hit to true
      end if
    end repeat
  end repeat
  if not hit then
    set t to selected tab of front window
    set background color of t to {$r16, $g16, $b16}
    set normal text color of t to {$txt}
    set cursor color of t to {$txt}
  end if
  return hit as text
end tell
EOF
) || { echo "Échec AppleScript (Terminal.app pilotable ?)."; exit 1; }

# Keep the auto session-color state consistent: forget the auto index for this
# tab so the next session start doesn't look like it "lost" a manual choice.
if [ -n "$mytty" ]; then
  rm -f "$HOME/.claude/session-colors/$mytty" 2>/dev/null || true
fi

if [ "$applied" = "true" ]; then
  echo "OK : onglet ($mytty) passé en $label (#$hex)."
else
  echo "OK : fenêtre au premier plan passée en $label (#$hex) — onglet de la session non identifié."
fi
