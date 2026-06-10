#!/bin/bash
# Ouvre (ou réutilise) la fenêtre Terminal dédiée aux loops Claude et y lance un /loop.
# L'onglet dédié est identifié par son TTY (persisté dans ~/.claude/.loop-terminal-tty),
# car les titres d'onglet sont écrasés par zsh et par Claude Code.
# - Pas d'onglet dédié vivant -> nouvelle fenêtre Terminal qui lance `claude "/loop ..."`.
# - Onglet dédié avec Claude en cours (busy) -> tape le prompt à la suite dans la session.
# - Onglet dédié revenu au shell -> relance `claude "/loop ..."` dans le même onglet.
# Usage: loop-terminal.sh "<prompt /loop ...>" "<cwd>"
# CLAUDE_LOOP_BIN permet de substituer le binaire (utilisé pour les tests).
set -u
PROMPT="${1:?prompt manquant}"
WORKDIR="${2:-$HOME}"
CLAUDE_BIN="${CLAUDE_LOOP_BIN:-claude}"
STATE_FILE="$HOME/.claude/.loop-terminal-tty"
SAVED_TTY=""
[ -f "$STATE_FILE" ] && SAVED_TTY=$(cat "$STATE_FILE")

NEW_TTY=$(/usr/bin/osascript - "$PROMPT" "$WORKDIR" "$CLAUDE_BIN" "$SAVED_TTY" <<'APPLESCRIPT'
on run argv
	set promptText to item 1 of argv
	set workDir to item 2 of argv
	set claudeBin to item 3 of argv
	set savedTty to item 4 of argv
	set launchCmd to "cd " & quoted form of workDir & " && CLAUDE_LOOP_TERMINAL=1 " & claudeBin & " " & quoted form of promptText
	tell application "Terminal"
		set loopTab to missing value
		set loopWindow to missing value
		if savedTty is not "" then
			repeat with w in windows
				repeat with t in tabs of w
					try
						if tty of t is savedTty then
							set loopTab to t
							set loopWindow to w
							exit repeat
						end if
					end try
				end repeat
				if loopTab is not missing value then exit repeat
			end repeat
		end if
		if loopTab is missing value then
			set loopTab to do script launchCmd
			try
				set custom title of loopTab to "Claude Loops"
			end try
		else
			if busy of loopTab then
				do script promptText in loopTab
			else
				do script launchCmd in loopTab
			end if
			try
				set frontmost of loopWindow to true
			end try
		end if
		activate
		return tty of loopTab
	end tell
end run
APPLESCRIPT
) || exit 1

[ -n "$NEW_TTY" ] && printf '%s' "$NEW_TTY" > "$STATE_FILE"
