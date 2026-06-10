-- Place 3 fenêtres Terminal côte à côte (tiers gauche / centre / droit)
-- Ouvre des fenêtres supplémentaires si moins de 3 sont ouvertes,
-- puis lance claude dans chaque fenêtre libre.

tell application "Finder" to set {x0, y0, x1, y1} to bounds of window of desktop
set screenWidth to x1 - x0
set colW to round (screenWidth / 3)
set topEdge to 25 -- hauteur de la barre de menus

tell application "Terminal"
	activate
	set n to count windows
	if n < 3 then
		repeat (3 - n) times
			do script ""
		end repeat
		delay 0.3
	end if
	set bounds of window 3 to {0, topEdge, colW, y1}
	set bounds of window 2 to {colW, topEdge, colW * 2, y1}
	set bounds of window 1 to {colW * 2, topEdge, screenWidth, y1}
	repeat with i from 1 to 3
		if not busy of window i then
			do script "claude" in window i
		end if
	end repeat
end tell
