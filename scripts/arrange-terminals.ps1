# Ouvre, range et lance claude dans N fenetres de terminal (N de 1 a 6).
# Equivalent Windows de arrange-terminals.applescript.
# Mode "reserver la place" : les fenetres DEJA ouvertes ne sont jamais
# deplacees tant que la structure de grille ne change pas. N=5 utilise la
# grille {3,3} en reservant la 6e case vide (meme geometrie que N=6), si bien
# que passer de 5 a 6 ajoute la nouvelle fenetre dans la case libre sans bouger
# les 5 premieres. Relancer le meme N ne deplace rien non plus. Un changement
# de structure de grille (ex. 4->5) re-agence l'ensemble (geometriquement
# inevitable quand l'ecran est deja plein).
# claude est lance uniquement dans les fenetres neuves, puis chaque session
# neuve passe en /effort max.
# Argument : le nombre de terminaux (1..6). Defaut : 3 si absent/invalide.
# Utilise Windows Terminal (wt.exe) si present, sinon des fenetres PowerShell.

param([int]$Count = 3)

$ErrorActionPreference = "Stop"
if ($Count -lt 1) { $Count = 1 }
if ($Count -gt 6) { $Count = 6 }

# Signature de la grille de reserve (colonnes par rangee) pour un nombre donne.
# Sert a detecter qu'une croissance reste dans la meme structure de grille.
function Get-LayoutSig([int]$k) {
    switch ($k) {
        1 { "1" }
        2 { "2" }
        3 { "3" }
        4 { "2,2" }
        5 { "3,3" }   # 5 = {3,3} avec la 6e case reservee vide
        default { "3,3" }
    }
}

Add-Type -AssemblyName System.Windows.Forms
$work = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea

# Grille de reserve : nombre de colonnes par rangee (de haut en bas).
switch ($Count) {
    1 { $layout = @(1) }
    2 { $layout = @(2) }
    3 { $layout = @(3) }
    4 { $layout = @(2, 2) }
    5 { $layout = @(3, 3) }   # 5 = {3,3} avec la 6e case reservee vide
    default { $layout = @(3, 3) }
}
$rowCount = $layout.Count
$rowH = [math]::Floor($work.Height / $rowCount)

# Rectangles des cellules (ordre de lecture) de la grille de reserve de $Count.
# Pour $Count=5 la grille {3,3} produit 6 cellules : on n'en remplira que 5.
$cellRects = @()
for ($r = 0; $r -lt $rowCount; $r++) {
    $colsInRow = $layout[$r]
    $colW = [math]::Floor($work.Width / $colsInRow)
    $top = $work.Y + $r * $rowH
    if ($r -eq $rowCount - 1) { $cellH = $work.Height - $r * $rowH } else { $cellH = $rowH }
    for ($c = 0; $c -lt $colsInRow; $c++) {
        $x = $work.X + $c * $colW
        if ($c -eq $colsInRow - 1) { $cellW = $work.Width - $c * $colW } else { $cellW = $colW }
        $cellRects += , @{ X = $x; Y = $top; W = $cellW; H = $cellH }
    }
}

Add-Type @"
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Text;
public class TermWin {
    public delegate bool EnumProc(IntPtr hWnd, IntPtr lParam);
    [DllImport("user32.dll")] static extern bool EnumWindows(EnumProc cb, IntPtr lParam);
    [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr hWnd);
    [DllImport("user32.dll")] static extern int GetClassName(IntPtr hWnd, StringBuilder sb, int max);
    [DllImport("user32.dll")] public static extern bool MoveWindow(IntPtr hWnd, int x, int y, int w, int h, bool repaint);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    public static List<IntPtr> Terminals() {
        var found = new List<IntPtr>();
        EnumWindows(delegate(IntPtr h, IntPtr l) {
            if (!IsWindowVisible(h)) return true;
            var sb = new StringBuilder(256);
            GetClassName(h, sb, 256);
            string c = sb.ToString();
            // Windows Terminal / console classique / Git Bash (mintty)
            if (c == "CASCADIA_HOSTING_WINDOW_CLASS" || c == "ConsoleWindowClass" || c == "mintty") found.Add(h);
            return true;
        }, IntPtr.Zero);
        return found;
    }
}
"@

# Snapshot des terminaux deja ouverts (jamais deplaces sauf changement de structure).
$before = @([TermWin]::Terminals())
$existingCount = $before.Count

# On n'ouvre que ce qui manque pour atteindre $Count fenetres.
$deficit = $Count - $existingCount
$new = @()

if ($deficit -gt 0) {
    $wt = Get-Command wt.exe -ErrorAction SilentlyContinue
    for ($i = 0; $i -lt $deficit; $i++) {
        if ($wt) {
            # "-w new" force une nouvelle fenetre (et non un onglet)
            Start-Process wt.exe -ArgumentList "-w", "new", "powershell", "-NoExit", "-Command", "claude"
        } else {
            Start-Process powershell -ArgumentList "-NoExit", "-Command", "claude"
        }
    }

    # Attend l'apparition des nouvelles fenetres (10 s max)
    $deadline = (Get-Date).AddSeconds(10)
    do {
        Start-Sleep -Milliseconds 300
        $new = @([TermWin]::Terminals() | Where-Object { $before -notcontains $_ })
    } until ($new.Count -ge $deficit -or (Get-Date) -gt $deadline)

    if ($new.Count -lt 1) {
        Write-Error "Aucune nouvelle fenetre de terminal detectee."
        exit 1
    }
}

# Croissance "propre" : on ne deplace pas l'existant si la grille de $existingCount
# a la meme structure que celle de $Count (cellules 1..$existingCount aux memes
# emplacements). En pratique : 5->6, et toute relance du meme N (deficit nul).
$sameBaseGrid = ($existingCount -gt 0) -and ($existingCount -lt $Count) -and `
    ((Get-LayoutSig $existingCount) -eq (Get-LayoutSig $Count))

$placed = 0
if ($deficit -le 0) {
    # Rien de neuf : aucune fenetre n'est deplacee.
} elseif ($sameBaseGrid) {
    # On place UNIQUEMENT les fenetres neuves, dans les cases de queue
    # ($existingCount .. ). Les fenetres existantes ne bougent pas.
    for ($j = 0; $j -lt $new.Count; $j++) {
        $ci = $existingCount + $j
        if ($ci -lt $cellRects.Count) {
            $cell = $cellRects[$ci]
            [TermWin]::MoveWindow($new[$j], $cell.X, $cell.Y, $cell.W, $cell.H, $true) | Out-Null
            $placed++
        }
    }
} else {
    # Changement de structure de grille (ou premier lancement) :
    # on pave les $Count premieres fenetres dans les cellules 0..$Count-1.
    $all = @($before + $new) | Select-Object -First $Count
    for ($i = 0; $i -lt $all.Count; $i++) {
        if ($i -lt $cellRects.Count) {
            $cell = $cellRects[$i]
            [TermWin]::MoveWindow($all[$i], $cell.X, $cell.Y, $cell.W, $cell.H, $true) | Out-Null
            $placed++
        }
    }
}

# Passe chaque session claude nouvellement lancee en /effort max.
# On laisse claude demarrer, puis on cible la fenetre et on tape la commande.
# Seules les fenetres neuves sont touchees (les sessions deja occupees sont intactes).
if ($new.Count -gt 0) {
    Start-Sleep -Seconds 5
    foreach ($h in $new) {
        [TermWin]::SetForegroundWindow($h) | Out-Null
        Start-Sleep -Milliseconds 400
        [System.Windows.Forms.SendKeys]::SendWait("/effort max{ENTER}")
        Start-Sleep -Milliseconds 250
    }
}

Write-Host "OK : $placed fenetre(s) placee(s), $($new.Count) nouvelle(s) lancee(s) en /effort max."
