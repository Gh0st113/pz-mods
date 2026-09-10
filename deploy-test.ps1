# deploy-test.ps1 — deploy an ISOLATED TEST build of a mod to Project Zomboid.
#
# Why: the Workshop (a subscription OR the Zomboid\Workshop\ staging folder) loads a mod
# by its "id". If that id matches your local copy, the Workshop SHADOWS it and you end up
# testing an old version without knowing. Here we republish under a DIFFERENT id (…TEST): it
# can never collide with the published version, and it is recognizable at a glance in the mod
# list ("[TEST vX.Y.Z] …").
#
# Usage:
#   ./deploy-test.ps1                 # deploy MilkIntoBarrel as TEST
#   ./deploy-test.ps1 -Mod MilkIntoBarrel
#   ./deploy-test.ps1 -Remove         # remove the TEST build only
#
# After deploying: relaunch PZ. Enable "[TEST …]" in the mods, disable the published
# version, and to SEE new sandbox settings -> new save (sandbox values are frozen per save).
# A plain Lua code change only needs a relaunch.
param(
    [string]$Mod = "MilkIntoBarrel",
    [switch]$Remove
)
$ErrorActionPreference = "Stop"

$src   = Join-Path $PSScriptRoot $Mod
$dst   = Join-Path $env:USERPROFILE "Zomboid\mods"
$testId = "${Mod}TEST"
$target = Join-Path $dst $testId

if (-not (Test-Path $src)) { throw "Mod not found in the repo: $src" }

# Always start clean
if (Test-Path $target) { Remove-Item -Recurse -Force $target }

if ($Remove) {
    Write-Host "TEST build removed: $target"
    return
}

# Full copy of the mod
Copy-Item -Recurse -Force $src $target

# Rewrite EVERY mod.info of the test build: id -> …TEST, name -> "[TEST vX.Y.Z] …"
Get-ChildItem -Path $target -Recurse -Filter mod.info | ForEach-Object {
    $lines = Get-Content $_.FullName
    $version = ($lines | Where-Object { $_ -match '^\s*modversion\s*=' }) -replace '^\s*modversion\s*=\s*', ''
    $tag = if ($version) { "[TEST v$version]" } else { "[TEST]" }
    $out = foreach ($l in $lines) {
        if     ($l -match '^\s*id\s*=')   { "id=$testId" }
        elseif ($l -match '^\s*name\s*=') { "name=$tag " + ($l -replace '^\s*name\s*=\s*', '') }
        else   { $l }
    }
    Set-Content -Path $_.FullName -Value $out -Encoding UTF8
}

# NB: the version is shown in the sandbox section TITLE (translation Sandbox_MilkIntoBarrel,
# e.g. "Milk Into Barrels - v1.2.8") = no editable field. The TEST build stays identifiable by
# its "[TEST vX.Y.Z]" name in the mod list (rewritten above). We inject nothing into the files.

Write-Host "Deployed (TEST): $Mod  ->  $target"
Write-Host "  id       = $testId   (can NOT be shadowed by the Workshop)"
Write-Host "  visible  = '$tag ...' in the mod list"
Write-Host ""
Write-Host "Relaunch PZ, enable the [TEST] mod, disable the published version, then test."
