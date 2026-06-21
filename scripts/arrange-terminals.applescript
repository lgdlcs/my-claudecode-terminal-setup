-- Ouvre, range et lance claude dans N fenêtres Terminal (N de 1 à 6).
-- Les fenêtres pavent l'écran en grille pour que chacune occupe la place
-- maximale, et toutes les N fenêtres sont visibles. claude est lancé dans
-- chaque fenêtre libre, puis chaque session ainsi lancée passe en /effort max.
-- Argument : le nombre de terminaux (1..6). Défaut : 3 si absent/invalide.

on run argv
	set n to 3
	if (count argv) > 0 then
		try
			set n to (item 1 of argv) as integer
		end try
	end if
	if n < 1 then set n to 1
	if n > 6 then set n to 6

	-- Grille : nombre de colonnes par rangée (de haut en bas)
	if n = 1 then
		set layout to {1}
	else if n = 2 then
		set layout to {2}
	else if n = 3 then
		set layout to {3}
	else if n = 4 then
		set layout to {2, 2}
	else if n = 5 then
		set layout to {3, 2}
	else
		set layout to {3, 3}
	end if

	tell application "Finder" to set {x0, y0, x1, y1} to bounds of window of desktop
	set screenW to x1 - x0
	set topEdge to 25 -- hauteur de la barre de menus
	set usableH to y1 - topEdge
	set rowCount to (count layout)
	set rowH to round (usableH / rowCount)

	tell application "Terminal"
		activate
		set vis to every window whose visible is true
		set deficit to n - (count vis)
		if deficit > 0 then
			repeat deficit times
				do script ""
			end repeat
			repeat 25 times
				set vis to every window whose visible is true
				if (count vis) ≥ n then exit repeat
				delay 0.2
			end repeat
		end if
		if (count vis) < n then error "Moins de " & n & " fenêtres Terminal visibles après ouverture."

		-- Pave les n premières fenêtres selon la grille (place maximale chacune)
		set idx to 1
		repeat with r from 1 to rowCount
			set colsInRow to item r of layout
			set colW to round (screenW / colsInRow)
			set rowTop to topEdge + (r - 1) * rowH
			set rowBottom to topEdge + r * rowH
			if r = rowCount then set rowBottom to y1 -- dernière rangée jusqu'en bas
			repeat with c from 1 to colsInRow
				set w to item idx of vis
				set leftX to (c - 1) * colW
				set rightX to c * colW
				if c = colsInRow then set rightX to screenW -- dernière colonne jusqu'au bord
				set bounds of w to {leftX, rowTop, rightX, rowBottom}
				set idx to idx + 1
			end repeat
		end repeat

		-- Lance claude dans chaque fenêtre libre, puis passe chaque session en /effort max.
		-- On ne touche qu'aux fenêtres où l'on vient de lancer claude.
		set launched to {}
		repeat with i from 1 to n
			set w to item i of vis
			if not busy of w then
				do script "claude" in w
				set end of launched to w
			end if
		end repeat
		if (count launched) > 0 then
			delay 5
			repeat with w in launched
				do script "/effort max" in w
			end repeat
		end if
	end tell
end run
