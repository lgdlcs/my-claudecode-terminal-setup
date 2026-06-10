-- Place 3 fenêtres Terminal côte à côte (tiers gauche / centre / droit)
-- Ouvre des fenêtres supplémentaires si moins de 3 sont ouvertes,
-- puis lance claude dans chaque fenêtre libre.
-- Ne considère que les fenêtres visibles (ignore les fenêtres réduites
-- ou fantômes) et attend qu'elles soient prêtes au lieu d'un délai fixe.

tell application "Finder" to set {x0, y0, x1, y1} to bounds of window of desktop
set screenWidth to x1 - x0
set colW to round (screenWidth / 3)
set topEdge to 25 -- hauteur de la barre de menus

tell application "Terminal"
	activate
	set vis to every window whose visible is true
	set deficit to 3 - (count vis)
	if deficit > 0 then
		repeat deficit times
			do script ""
		end repeat
		repeat 25 times
			set vis to every window whose visible is true
			if (count vis) ≥ 3 then exit repeat
			delay 0.2
		end repeat
	end if
	if (count vis) < 3 then error "Moins de 3 fenêtres Terminal visibles après ouverture."
	set bounds of item 3 of vis to {0, topEdge, colW, y1}
	set bounds of item 2 of vis to {colW, topEdge, colW * 2, y1}
	set bounds of item 1 of vis to {colW * 2, topEdge, screenWidth, y1}
	repeat with i from 1 to 3
		set w to item i of vis
		if not busy of w then
			do script "claude" in w
		end if
	end repeat
end tell
return
