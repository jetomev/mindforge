# mindForge from PowerShell (Windows) -- 0.1.9, #21.
#   mindforge wrap 'Focus with spaces' 'b1|b2'
#
# The obvious wrapper, a .cmd file running  bash -lc "mindforge %*", pastes the
# arguments into ONE command string: everything after the first word of a
# quoted focus was lost, and cmd.exe read the "|" between wrap's bullets as a
# pipe and crashed. Here every argument goes to bash as its own argument, and
# cmd.exe is never involved.
#
# Install: put this folder on PATH, or add to your PowerShell profile:
#   Set-Alias mindforge "$HOME\Programs\mindforge\bin\mindforge.ps1"
# Windows PowerShell 5.1 (not 7) can still mangle a double quote INSIDE an
# argument when calling a program; PowerShell 7 does not. Use 7 where you can.

$ErrorActionPreference = 'Stop'

# Git for Windows' bash, never WSL's C:\Windows\System32\bash.exe.
$bash = $env:MINDFORGE_BASH
if (-not $bash) {
    $git = Get-Command git.exe -ErrorAction SilentlyContinue
    if ($git) {
        $root = Split-Path (Split-Path $git.Source -Parent) -Parent
        $candidate = Join-Path $root 'bin\bash.exe'
        if (Test-Path $candidate) { $bash = $candidate }
    }
}
if (-not $bash) {
    $candidate = Join-Path $env:ProgramFiles 'Git\bin\bash.exe'
    if (Test-Path $candidate) { $bash = $candidate }
}
if (-not $bash) {
    Write-Error 'mindforge: Git for Windows bash.exe not found -- install Git for Windows, or set MINDFORGE_BASH'
    exit 2
}

$script = (Join-Path $PSScriptRoot 'mindforge') -replace '\\', '/'
& $bash $script @args
exit $LASTEXITCODE
