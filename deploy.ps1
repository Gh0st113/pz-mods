# deploy.ps1 — copie tous les mods de ce repo vers le dossier de test de Project Zomboid.
# Usage : ./deploy.ps1   (puis relance PZ pour charger/recharger les mods)
$ErrorActionPreference = "Stop"

$src = $PSScriptRoot
$dst = Join-Path $env:USERPROFILE "Zomboid\mods"
New-Item -ItemType Directory -Force -Path $dst | Out-Null

$deployed = 0
Get-ChildItem -Path $src -Directory | Where-Object { $_.Name -ne '.git' } | ForEach-Object {
    $mod = $_
    # un dossier est un mod s'il contient un mod.info quelque part
    $hasModInfo = Get-ChildItem -Path $mod.FullName -Recurse -Filter mod.info -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($hasModInfo) {
        $target = Join-Path $dst $mod.Name
        if (Test-Path $target) { Remove-Item -Recurse -Force $target }
        Copy-Item -Recurse -Force $mod.FullName $target
        Write-Host "Deploye : $($mod.Name)  ->  $target"
        $deployed++
    }
}
Write-Host "Termine ($deployed mod(s)). Relance Project Zomboid pour charger les changements."
