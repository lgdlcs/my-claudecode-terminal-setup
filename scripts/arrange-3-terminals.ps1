# Equivalent Windows de arrange-3-terminals.applescript :
# range 3 fenetres de terminal en trois colonnes (tiers gauche/centre/droit),
# avec claude lance dans les fenetres nouvellement ouvertes, puis chaque session
# neuve passee en /effort max.
# Utilise Windows Terminal (wt.exe) si present, sinon des fenetres PowerShell (conhost).
# Comme macOS : on n'ouvre que les fenetres manquantes (deficit pour atteindre 3),
# on range les fenetres existantes au lieu d'en empiler de nouvelles, et on ne lance
# claude QUE dans les fenetres neuves (jamais dans une fenetre deja occupee par un process).

$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Windows.Forms
$work = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
$colW = [math]::Floor($work.Width / 3)

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

# On n'ouvre que ce qui manque pour atteindre 3 fenetres
$deficit = 3 - $before.Count
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

# Range les 3 premieres fenetres (existantes d'abord, puis nouvelles) dans les tiers.
# Les terminaux au-dela de 3 sont laisses tels quels.
$all = @($before + $new) | Select-Object -First 3
$i = 0
foreach ($h in $all) {
    [TermWin]::MoveWindow($h, $work.X + $i * $colW, $work.Y, $colW, $work.Height, $true) | Out-Null
    $i++
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

Write-Host "OK : $i fenetre(s) rangee(s), $($new.Count) nouvelle(s) lancee(s) en /effort max."
