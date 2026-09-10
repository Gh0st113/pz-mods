# deploy-test.ps1 — deploie un build de TEST ISOLE d'un mod vers Project Zomboid.
#
# Pourquoi : le Workshop (abonnement OU dossier de staging Zomboid\Workshop\) charge un mod
# par son "id". Si l'id est identique a ta copie locale, le Workshop la MASQUE et tu testes
# sans le savoir une vieille version. Ici on republie sous un id DIFFERENT (…TEST) : il ne
# peut jamais entrer en collision avec la version publiee, et il est reconnaissable au premier
# coup d'oeil dans la liste des mods ("[TEST vX.Y.Z] …").
#
# Usage :
#   ./deploy-test.ps1                 # deploie MilkIntoBarrel en TEST
#   ./deploy-test.ps1 -Mod MilkIntoBarrel
#   ./deploy-test.ps1 -Remove         # retire uniquement le build de TEST
#
# Apres deploiement : relance PZ. Active "[TEST …]" dans les mods, desactive la version
# publiee, et pour VOIR de nouveaux reglages bac a sable -> nouvelle sauvegarde (les valeurs
# sandbox sont figees par save). Un simple changement de code Lua ne demande qu'un relancement.
param(
    [string]$Mod = "MilkIntoBarrel",
    [switch]$Remove
)
$ErrorActionPreference = "Stop"

$src   = Join-Path $PSScriptRoot $Mod
$dst   = Join-Path $env:USERPROFILE "Zomboid\mods"
$testId = "${Mod}TEST"
$target = Join-Path $dst $testId

if (-not (Test-Path $src)) { throw "Mod introuvable dans le repo : $src" }

# Toujours repartir propre
if (Test-Path $target) { Remove-Item -Recurse -Force $target }

if ($Remove) {
    Write-Host "Build de TEST retire : $target"
    return
}

# Copie integrale du mod
Copy-Item -Recurse -Force $src $target

# Reecrit CHAQUE mod.info du build de test : id -> …TEST, name -> "[TEST vX.Y.Z] …"
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

# NB : la version est affichee dans le TITRE de la section bac a sable (traduction Sandbox_MilkIntoBarrel,
# ex. "Traire dans le baril - v1.2.6") = pas de champ modifiable. Le build de TEST reste identifiable a
# son nom "[TEST vX.Y.Z]" dans la liste des mods (reecrit ci-dessus). On n'injecte rien dans les fichiers.

Write-Host "Deploye (TEST) : $Mod  ->  $target"
Write-Host "  id       = $testId   (ne peut PAS etre masque par le Workshop)"
Write-Host "  visible  = '$tag ...' dans la liste des mods"
Write-Host ""
Write-Host "Relance PZ, active le mod [TEST], desactive la version publiee, puis teste."
