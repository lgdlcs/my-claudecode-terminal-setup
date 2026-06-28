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
Register-BradTask "Brad - Monday post" "brad-monday-post.ps1" @(
    (New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At 11:00am),
    (New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At 5:00pm)
)
