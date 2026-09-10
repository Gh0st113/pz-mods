# deploy.ps1 — copy every mod in this repo to Project Zomboid's local mods folder.
# Usage: ./deploy.ps1   (then relaunch PZ to load/reload the mods)
$ErrorActionPreference = "Stop"

$src = $PSScriptRoot
$dst = Join-Path $env:USERPROFILE "Zomboid\mods"
New-Item -ItemType Directory -Force -Path $dst | Out-Null

$deployed = 0
Get-ChildItem -Path $src -Directory | Where-Object { $_.Name -ne '.git' } | ForEach-Object {
    $mod = $_
    # a folder is a mod if it contains a mod.info somewhere
    $hasModInfo = Get-ChildItem -Path $mod.FullName -Recurse -Filter mod.info -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($hasModInfo) {
        $target = Join-Path $dst $mod.Name
        if (Test-Path $target) { Remove-Item -Recurse -Force $target }
        Copy-Item -Recurse -Force $mod.FullName $target
        Write-Host "Deployed: $($mod.Name)  ->  $target"
        $deployed++
    }
}
Write-Host "Done ($deployed mod(s)). Relaunch Project Zomboid to load the changes."
