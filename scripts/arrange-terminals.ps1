# Ouvre, range et lance claude dans N fenetres de terminal (N de 1 a 6).
# Equivalent Windows de arrange-terminals.applescript.
#
# Positionnement "match-cells" : on calcule les cases de la grille de N, puis
# chaque fenetre n'est deplacee QUE si elle n'occupe pas deja une case (a une
# tolerance pres). Consequences :
#   * fenetres superposees / mal placees (meme deja ouvertes) -> re-pavees ;
#   * relance du meme N alors que tout est deja en grille -> rien ne bouge ;
#   * 5 -> 6 (meme geometrie {3,3}) -> les 5 fenetres en place ne bougent pas,
#     la nouvelle prend la 6e case ;
#   * changement de structure (ex. 4 -> 5, {2,2} -> {3,3}) -> les cases changent
#     donc aucune fenetre ne "matche" : re-agencement complet.
# claude est lance uniquement dans les fenetres neuves, puis chaque session
# neuve passe en /effort max (Windows ne sait pas detecter "busy" -> on ne
# relance pas claude dans une fenetre preexistante).
# Argument : le nombre de terminaux (1..6). Defaut : 3 si absent/invalide.
# Utilise Windows Terminal (wt.exe) si present, sinon des fenetres PowerShell.

param([int]$Count = 3)

$ErrorActionPreference = "Stop"
if ($Count -lt 1) { $Count = 1 }
if ($Count -gt 6) { $Count = 6 }

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
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT { public int Left, Top, Right, Bottom; }
    [DllImport("user32.dll")] static extern bool EnumWindows(EnumProc cb, IntPtr lParam);
    [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr hWnd);
    [DllImport("user32.dll")] static extern int GetClassName(IntPtr hWnd, StringBuilder sb, int max);
    [DllImport("user32.dll")] public static extern bool MoveWindow(IntPtr hWnd, int x, int y, int w, int h, bool repaint);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT r);
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

# Snapshot des terminaux deja ouverts (pour distinguer les fenetres neuves).
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

# Positionnement match-cells : on ne remplit que les $Count premieres cases
# (n=5 -> 5 cases sur 6).
$all = @([TermWin]::Terminals())
$cellCount = [math]::Min($cellRects.Count, $Count)
$targets = @($cellRects[0..($cellCount - 1)])

$tol = 30
$filled = New-Object 'bool[]' $cellCount
$gridHandles = @()

# Passe 1 : les fenetres deja dans une case conservent leur place.
foreach ($h in $all) {
    $rect = New-Object TermWin+RECT
    if (-not [TermWin]::GetWindowRect($h, [ref]$rect)) { continue }
    $x = $rect.Left; $y = $rect.Top; $w = $rect.Right - $rect.Left; $hh = $rect.Bottom - $rect.Top
    for ($i = 0; $i -lt $cellCount; $i++) {
        if (-not $filled[$i]) {
            $c = $targets[$i]
            if (([math]::Abs($x - $c.X) -le $tol) -and ([math]::Abs($y - $c.Y) -le $tol) -and `
                ([math]::Abs($w - $c.W) -le $tol) -and ([math]::Abs($hh - $c.H) -le $tol)) {
                $filled[$i] = $true
                $gridHandles += $h
                break
            }
        }
    }
}

# Passe 2 : les fenetres non placees remplissent les cases libres.
$freeCells = @()
for ($i = 0; $i -lt $cellCount; $i++) { if (-not $filled[$i]) { $freeCells += $i } }
$fi = 0
$placed = 0
foreach ($h in $all) {
    if ($fi -ge $freeCells.Count) { break }
    if ($gridHandles -notcontains $h) {
        $cell = $targets[$freeCells[$fi]]
        [TermWin]::MoveWindow($h, $cell.X, $cell.Y, $cell.W, $cell.H, $true) | Out-Null
        $gridHandles += $h
        $fi++
        $placed++
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

Write-Host "OK : $placed fenetre(s) re-pavee(s), $($new.Count) nouvelle(s) lancee(s) en /effort max."
