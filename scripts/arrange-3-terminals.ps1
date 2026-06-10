# Equivalent Windows de arrange-3-terminals.applescript :
# ouvre 3 fenetres de terminal rangees en trois colonnes (tiers gauche/centre/droit),
# avec claude lance dans chacune.
# Utilise Windows Terminal (wt.exe) si present, sinon des fenetres PowerShell (conhost).
# Difference avec macOS : on ne peut pas injecter une commande dans une fenetre deja
# ouverte sans risquer de taper dans un process en cours, donc on ouvre toujours
# 3 nouvelles fenetres.

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

$before = [TermWin]::Terminals()

$wt = Get-Command wt.exe -ErrorAction SilentlyContinue
for ($i = 0; $i -lt 3; $i++) {
    if ($wt) {
        # "-w new" force une nouvelle fenetre (et non un onglet)
        Start-Process wt.exe -ArgumentList "-w", "new", "powershell", "-NoExit", "-Command", "claude"
    } else {
        Start-Process powershell -ArgumentList "-NoExit", "-Command", "claude"
    }
}

# Attend l'apparition des 3 nouvelles fenetres (10 s max)
$deadline = (Get-Date).AddSeconds(10)
do {
    Start-Sleep -Milliseconds 300
    $new = @([TermWin]::Terminals() | Where-Object { $before -notcontains $_ })
} until ($new.Count -ge 3 -or (Get-Date) -gt $deadline)

if ($new.Count -lt 1) {
    Write-Error "Aucune nouvelle fenetre de terminal detectee."
    exit 1
}

$i = 0
foreach ($h in ($new | Select-Object -First 3)) {
    [TermWin]::MoveWindow($h, $work.X + $i * $colW, $work.Y, $colW, $work.Height, $true) | Out-Null
    $i++
}
Write-Host "OK : $i fenetre(s) rangee(s), claude lance."
