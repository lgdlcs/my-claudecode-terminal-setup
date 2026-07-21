# Enregistre les tâches planifiées de Brad (Windows Task Scheduler). Appelé par install.ps1.
# Best-effort, non testé sur Windows. Equivalent des jobs launchd macOS.
$ErrorActionPreference = "Stop"
$dir = Join-Path $env:USERPROFILE ".claude\twitter-agent"

function Register-BradTask($name, $scriptName, $triggers) {
    $script = Join-Path $dir $scriptName
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$script`""
    $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
    Register-ScheduledTask -TaskName $name -Action $action -Trigger $triggers -Settings $settings -Force | Out-Null
    Write-Host "Tâche planifiée enregistrée : $name"
}

Register-BradTask "Brad - Daily proposals" "brad-daily.ps1" @(
    New-ScheduledTaskTrigger -Daily -At 8:00am
)
Register-BradTask "Brad - Weekly recap" "brad-weekly.ps1" @(
    New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 6:00pm
)

# Brad's automatic X posting is disabled (2026-07-21, owner's decision): Brad only drafts,
# the owner posts by hand. The former "Brad - Monday post" auto-poster is removed. If it was
# registered by a previous install, remove it with:
#   Unregister-ScheduledTask -TaskName "Brad - Monday post" -Confirm:$false
