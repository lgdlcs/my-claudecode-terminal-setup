-- Ouvre, range et lance claude dans N fenêtres Terminal (N de 1 à 6).
-- Les fenêtres pavent l'écran en grille pour que chacune occupe la place
-- maximale. claude est lancé dans chaque fenêtre libre, puis chaque session
-- ainsi lancée passe en /effort max.
--
-- Positionnement « match-cells » : on calcule les cases de la grille de N, puis
-- chaque fenêtre n'est déplacée QUE si elle n'occupe pas déjà une case (à une
-- tolérance près). Conséquences :
--   * fenêtres superposées / mal placées (même si déjà ouvertes) -> re-pavées ;
--   * relance du même N alors que tout est déjà en grille -> rien ne bouge ;
--   * 5 -> 6 (même géométrie {3,3}) -> les 5 fenêtres en place ne bougent pas,
--     la nouvelle prend la 6e case ;
--   * changement de structure (ex. 4 -> 5, {2,2} -> {3,3}) -> les cases changent
--     donc aucune fenêtre ne « matche » : ré-agencement complet.
-- Argument : le nombre de terminaux (1..6). Défaut : 3 si absent/invalide.

on layoutFor(k)
	-- Grille de réserve : nombre de colonnes par rangée (de haut en bas).
	if k = 1 then
		return {1}
	else if k = 2 then
		return {2}
	else if k = 3 then
		return {3}
	else if k = 4 then
		return {2, 2}
	else if k = 5 then
		return {3, 3} -- 5 = {3,3} avec la 6e case réservée vide
	else
		return {3, 3}
	end if
end layoutFor

on near(v, target, tol)
	return (v ≥ target - tol) and (v ≤ target + tol)
end near

on run argv
	set n to 3
	if (count argv) > 0 then
		try
			set n to (item 1 of argv) as integer
		end try
	end if
	if n < 1 then set n to 1
	if n > 6 then set n to 6

	set layout to layoutFor(n)

	tell application "Finder" to set {x0, y0, x1, y1} to bounds of window of desktop
	set screenW to x1 - x0
	set topEdge to 25 -- hauteur de la barre de menus
	set usableH to y1 - topEdge
	set rowCount to (count layout)
	set rowH to round (usableH / rowCount)

	-- Rectangles des cellules (ordre de lecture) de la grille de réserve de n.
	-- Pour n=5 la grille {3,3} produit 6 cellules : on n'en remplira que 5.
	set cellRects to {}
	repeat with r from 1 to rowCount
		set colsInRow to item r of layout
		set colW to round (screenW / colsInRow)
		set rowTop to topEdge + (r - 1) * rowH
		set rowBottom to topEdge + r * rowH
		if r = rowCount then set rowBottom to y1 -- dernière rangée jusqu'en bas
		repeat with c from 1 to colsInRow
			set leftX to (c - 1) * colW
			set rightX to c * colW
			if c = colsInRow then set rightX to screenW -- dernière colonne jusqu'au bord
			set end of cellRects to {leftX, rowTop, rightX, rowBottom}
		end repeat
	end repeat

	-- On ne remplit que les n premières cases (n=5 -> 5 cases sur 6).
	set cellCount to (count cellRects)
	if cellCount > n then set cellCount to n
	set targetCells to {}
	repeat with i from 1 to cellCount
		set end of targetCells to item i of cellRects
	end repeat

	tell application "Terminal"
		activate
		-- Fenêtres déjà ouvertes (mémorisées par id) : sert à distinguer les
		-- fenêtres neuves (claude lancé à l'ouverture) des préexistantes.
		set existingIds to {}
		repeat with w in (every window whose visible is true)
			set end of existingIds to (id of w)
		end repeat
		set existingCount to (count existingIds)
		set deficit to n - existingCount

		-- Ouvre les fenêtres manquantes (chaque fenêtre neuve lance directement
		-- claude pour éviter la course sur « busy » pendant l'init du shell).
		if deficit > 0 then
			repeat deficit times
				do script "claude"
			end repeat
			repeat 25 times
				if (count (every window whose visible is true)) ≥ n then exit repeat
				delay 0.2
			end repeat
		end if

		set vis to every window whose visible is true
		if (count vis) < n then error "Moins de " & n & " fenêtres Terminal visibles après ouverture."

		-- Positionnement match-cells.
		set tol to 30
		set gridWindowIds to {}
		-- filledCell : une case déjà occupée par une fenêtre (à tol près).
		set filledCell to {}
		repeat with i from 1 to cellCount
			set end of filledCell to false
		end repeat

		-- Passe 1 : les fenêtres déjà dans une case conservent leur place.
		repeat with w in vis
			set {a, b, c, d} to bounds of w
			repeat with i from 1 to cellCount
				if (item i of filledCell) is false then
					set {ca, cb, cc, cd} to item i of targetCells
					if (my near(a, ca, tol)) and (my near(b, cb, tol)) and (my near(c, cc, tol)) and (my near(d, cd, tol)) then
						set item i of filledCell to true
						set end of gridWindowIds to (id of w)
						exit repeat
					end if
				end if
			end repeat
		end repeat

		-- Passe 2 : les fenêtres non placées remplissent les cases libres.
		set freeCells to {}
		repeat with i from 1 to cellCount
			if (item i of filledCell) is false then set end of freeCells to i
		end repeat
		set fi to 0
		repeat with w in vis
			if fi ≥ (count freeCells) then exit repeat
			if gridWindowIds does not contain (id of w) then
				set fi to fi + 1
				set bounds of w to (item (item fi of freeCells) of targetCells)
				set end of gridWindowIds to (id of w)
			end if
		end repeat

		-- Lance claude là où il manque dans les fenêtres de la grille, puis passe
		-- chaque session lancée en /effort max. Fenêtres neuves : claude déjà
		-- lancé à l'ouverture. Préexistantes : claude seulement si elles sont libres.
		set launched to {}
		repeat with w in vis
			if gridWindowIds contains (id of w) then
				if existingIds contains (id of w) then
					if not busy of w then
						do script "claude" in w
						set end of launched to w
					end if
				else
					set end of launched to w
				end if
			end if
		end repeat
		if (count launched) > 0 then
			delay 5
			repeat with w in launched
				do script "/effort max" in w
			end repeat
		end if
	end tell
	return -- évite qu'osascript imprime la référence de la dernière commande
end run
