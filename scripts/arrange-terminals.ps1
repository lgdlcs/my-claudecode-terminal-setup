# Ouvre, range et lance claude dans N fenetres de terminal (N de 1 a 6).
# Equivalent Windows de arrange-terminals.applescript : les fenetres pavent
# l'ecran en grille pour que chacune occupe la place maximale, et toutes les N
# fenetres sont visibles. claude est lance dans les fenetres nouvellement
# ouvertes, puis chaque session neuve passe en /effort max.
# Argument : le nombre de terminaux (1..6). Defaut : 3 si absent/invalide.
# Utilise Windows Terminal (wt.exe) si present, sinon des fenetres PowerShell (conhost).
# Comme macOS : on n'ouvre que les fenetres manquantes (deficit pour atteindre N),
# on range les fenetres existantes au lieu d'en empiler de nouvelles, et on ne lance
# claude QUE dans les fenetres neuves (jamais dans une fenetre deja occupee par un process).

param([int]$Count = 3)

$ErrorActionPreference = "Stop"
if ($Count -lt 1) { $Count = 1 }
if ($Count -gt 6) { $Count = 6 }

Add-Type -AssemblyName System.Windows.Forms
$work = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea

# Grille : nombre de colonnes par rangee (de haut en bas)
switch ($Count) {
    1 { $layout = @(1) }
    2 { $layout = @(2) }
    3 { $layout = @(3) }
    4 { $layout = @(2, 2) }
    5 { $layout = @(3, 2) }
    default { $layout = @(3, 3) }
}
$rowCount = $layout.Count
$rowH = [math]::Floor($work.Height / $rowCount)

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

# Snapshot des terminaux deja ouverts
$before = @([TermWin]::Terminals())

# On n'ouvre que ce qui manque pour atteindre $Count fenetres
$deficit = $Count - $before.Count
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

# Pave les $Count premieres fenetres (existantes d'abord, puis nouvelles) en grille,
# chacune occupant sa cellule (place maximale). Les terminaux au-dela de $Count
# sont laisses tels quels.
$all = @($before + $new) | Select-Object -First $Count
$idx = 0
for ($r = 0; $r -lt $rowCount; $r++) {
    $colsInRow = $layout[$r]
    $colW = [math]::Floor($work.Width / $colsInRow)
    $top = $work.Y + $r * $rowH
    if ($r -eq $rowCount - 1) { $cellH = $work.Height - $r * $rowH } else { $cellH = $rowH }
    for ($c = 0; $c -lt $colsInRow; $c++) {
        if ($idx -ge $all.Count) { break }
        $x = $work.X + $c * $colW
        if ($c -eq $colsInRow - 1) { $cellW = $work.Width - $c * $colW } else { $cellW = $colW }
        [TermWin]::MoveWindow($all[$idx], $x, $top, $cellW, $cellH, $true) | Out-Null
        $idx++
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

Write-Host "OK : $idx fenetre(s) rangee(s) en grille, $($new.Count) nouvelle(s) lancee(s) en /effort max."
