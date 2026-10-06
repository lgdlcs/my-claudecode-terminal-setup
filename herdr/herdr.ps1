# herdr helpers for PowerShell — dot-sourced from $PROFILE by install.ps1

# Inside herdr, Claude Code starts without permission prompts
if ($env:HERDR_ENV -eq '1') {
    function claude {
        $exe = Get-Command claude -CommandType Application | Select-Object -First 1
        & $exe.Source --dangerously-skip-permissions @args
    }
}

# hr                   -> local herdr session (or $env:HERDR_HOST's when set)
# hr <host> [session]  -> attach over SSH to the herdr session running on <host>
function hr {
    param([string]$Target = $env:HERDR_HOST, [string]$Session)
    if (-not $Target) { herdr; return }
    $a = @('--remote', $Target)
    if ($Session) { $a += @('--session', $Session) }
    herdr @a
}
