-- Ouvre, range et lance claude dans N fenêtres Terminal (N de 1 à 6).
-- Les fenêtres pavent l'écran en grille pour que chacune occupe la place
-- maximale. claude est lancé dans chaque fenêtre libre, puis chaque session
-- ainsi lancée passe en /effort max.
-- Mode « réserver la place » : les fenêtres DÉJÀ ouvertes ne sont jamais
-- déplacées tant que la structure de grille ne change pas. N=5 utilise la
-- grille {3,3} en réservant la 6e case vide (même géométrie que N=6), si bien
-- que passer de 5 à 6 ajoute la nouvelle fenêtre dans la case libre sans bouger
-- les 5 premières. Relancer le même N ne déplace rien non plus. Seul un
-- changement de structure de grille (ex. 4→5) ré-agence l'ensemble
-- (géométriquement inévitable quand l'écran est déjà plein).
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

	tell application "Terminal"
		activate
		-- Fenêtres déjà ouvertes : mémorisées par id (jamais déplacées sauf
		-- changement de structure de grille).
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

		-- Fenêtres neuves (id absent du snapshot), dans leur ordre d'apparition.
		set newIds to {}
		repeat with w in vis
			if existingIds does not contain (id of w) then set end of newIds to (id of w)
		end repeat

		-- Croissance « propre » : on ne déplace pas l'existant si la grille de
		-- existingCount a la même structure que celle de n (cellules
		-- 1..existingCount aux mêmes emplacements). En pratique : 5→6, et
		-- toute relance du même N (deficit nul).
		set sameBaseGrid to false
		if existingCount > 0 and existingCount < n then
			if (my layoutFor(existingCount)) is equal to layout then set sameBaseGrid to true
		end if

		if deficit ≤ 0 then
			-- Rien de neuf : aucune fenêtre n'est déplacée.
		else if sameBaseGrid then
			-- On place UNIQUEMENT les fenêtres neuves, dans les cases de queue
			-- (existingCount+1 .. n). Les fenêtres existantes ne bougent pas.
			repeat with k from 1 to (count newIds)
				set targetIdx to existingCount + k
				if targetIdx ≤ (count cellRects) then
					set bounds of (window id (item k of newIds)) to (item targetIdx of cellRects)
				end if
			end repeat
		else
			-- Changement de structure de grille (ou premier lancement) :
			-- on pave les n premières fenêtres dans les cellules 1..n.
			repeat with i from 1 to n
				if i ≤ (count cellRects) then
					set bounds of (item i of vis) to (item i of cellRects)
				end if
			end repeat
		end if

		-- Lance claude là où il manque, puis passe chaque session lancée en
		-- /effort max. Fenêtres neuves : claude déjà lancé à l'ouverture.
		-- Fenêtres pré-existantes : claude seulement si elles sont libres.
		set launched to {}
		repeat with i from 1 to n
			set w to item i of vis
			if existingIds contains (id of w) then
				if not busy of w then
					do script "claude" in w
					set end of launched to w
				end if
			else
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
	return -- évite qu'osascript imprime la référence de la dernière commande
end run
