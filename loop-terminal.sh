#!/bin/bash
# Ouvre (ou réutilise) la fenêtre Terminal dédiée aux loops Claude et y lance un /loop.
#
# Identité robuste d'un terminal de loop : une session claude vivante qui a écrit
# son propre marqueur dans ~/.claude/.loop-sessions/<ttyname>. Le marqueur est créé
# PAR la session loop (qui connaît son tty via $(tty)) et supprimé à sa sortie.
# On ne se fie donc NI au titre d'onglet (écrasé par zsh/Claude Code) NI à un tty
# stocké « en aveugle » (recyclé par macOS et réattribué à une session de travail).
#
# - Aucun marqueur de loop vivant -> nouvelle fenêtre Terminal qui lance `claude "/loop ..."`.
# - Marqueur vivant avec Claude en cours (busy) -> tape le prompt à la suite dans la session.
# - Marqueur vivant revenu au shell -> relance `claude "/loop ..."` dans le même onglet.
#
# Comme la session courante (non-loop) n'a jamais de marqueur, une redirection vers
# soi-même est structurellement impossible.
#
# Usage: loop-terminal.sh "<prompt /loop ...>" "<cwd>"
# CLAUDE_LOOP_BIN permet de substituer le binaire (utilisé pour les tests).
set -u
PROMPT="${1:?prompt manquant}"
WORKDIR="${2:-$HOME}"
CLAUDE_BIN="${CLAUDE_LOOP_BIN:-claude}"
MARKER_DIR="$HOME/.claude/.loop-sessions"
mkdir -p "$MARKER_DIR"

# Ancien état : on purge le fichier mono-tty obsolète s'il traîne encore.
rm -f "$HOME/.claude/.loop-terminal-tty" 2>/dev/null || true

# tty candidats = ttys ayant un marqueur de session loop.
CANDIDATES=""
for f in "$MARKER_DIR"/ttys*; do
	[ -e "$f" ] || continue
	CANDIDATES="$CANDIDATES /dev/${f##*/}"
done

# La session loop pose son marqueur au démarrage (elle seule connaît son tty)
# et le retire à sa sortie -> un marqueur survivant à un crash sera nettoyé
# par l'AppleScript ci-dessous (tty absent des onglets vivants).
LAUNCH_CMD="cd $(printf '%q' "$WORKDIR") && mkdir -p $(printf '%q' "$MARKER_DIR") && _lt=\$(tty) && _ln=\${_lt##*/} && printf '%s' \"\$_lt\" > $(printf '%q' "$MARKER_DIR")/\"\$_ln\" && CLAUDE_LOOP_TERMINAL=1 $CLAUDE_BIN $(printf '%q' "$PROMPT"); rm -f $(printf '%q' "$MARKER_DIR")/\"\$_ln\""

RESULT=$(/usr/bin/osascript - "$PROMPT" "$LAUNCH_CMD" "$CANDIDATES" <<'APPLESCRIPT'
on run argv
	set promptText to item 1 of argv
	set launchCmd to item 2 of argv
	set candidateBlob to item 3 of argv

	-- parse les ttys candidats (séparés par des espaces)
	set AppleScript's text item delimiters to " "
	set candidates to text items of candidateBlob
	set AppleScript's text item delimiters to ""

	tell application "Terminal"
		set loopTab to missing value
		set loopWindow to missing value
		set liveTtys to {}

		repeat with w in windows
			-- certaines fenetres (Reglages...) sans onglets accessibles: on les saute.
			set theTabs to {}
			try
				set theTabs to tabs of w
			end try
			repeat with t in theTabs
				try
					set thisTty to tty of t
					set end of liveTtys to thisTty
					if loopTab is missing value then
						repeat with c in candidates
							if (c as text) is thisTty then
								set loopTab to t
								set loopWindow to w
								exit repeat
							end if
						end repeat
					end if
				end try
			end repeat
		end repeat

		if loopTab is missing value then
			-- aucun onglet de loop vivant -> on en ouvre un neuf
			set loopTab to do script launchCmd
			try
				set custom title of loopTab to "Claude Loops"
			end try
			set chosenTty to (tty of loopTab)
		else
			if busy of loopTab then
				do script promptText in loopTab
			else
				do script launchCmd in loopTab
			end if
			try
				set frontmost of loopWindow to true
			end try
			set chosenTty to (tty of loopTab)
		end if
		activate

		-- renvoie le tty choisi + la liste des ttys vivants (purge des marqueurs morts)
		set AppleScript's text item delimiters to " "
		set liveBlob to liveTtys as text
		set AppleScript's text item delimiters to ""
		return chosenTty & linefeed & liveBlob
	end tell
end run
APPLESCRIPT
) || exit 1

# Purge des marqueurs orphelins : tout marqueur dont le tty n'est plus un onglet vivant.
LIVE_TTYS=$(printf '%s\n' "$RESULT" | sed -n '2p')
for f in "$MARKER_DIR"/ttys*; do
	[ -e "$f" ] || continue
	case " $LIVE_TTYS " in
		*" /dev/${f##*/} "*) : ;;             # vivant -> on garde
		*) rm -f "$f" 2>/dev/null || true ;;  # mort -> on purge
	esac
done
