# Launches the new-mod wizard (see scripts/New-SptMod.ps1).
$ErrorActionPreference = 'Stop'
& (Join-Path $PSScriptRoot 'scripts\New-SptMod.ps1') @args
