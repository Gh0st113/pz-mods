# Dossier d'upload Workshop — MilkIntoBarrel

À préparer avant publication sur le Steam Workshop (via l'outil intégré de PZ : menu principal → Workshop → Create/Edit) :

- **poster.png** — l'affiche du mod (recommandé 256×256, PNG).
- **preview.png** — l'aperçu Workshop (recommandé 256×256 ou plus, PNG).
- **workshop.txt** — métadonnées Workshop (titre, description, tags, id une fois publié).

## Rappels de packaging B42

L'outil Workshop de PZ attend un dossier `Contents/mods/<ModId>/…`. Notre source (`../42/…`)
correspond au contenu du mod ; l'outil s'occupe de l'emballage `Contents/`.

Le `mod.info` référence déjà :
- `id=MilkIntoBarrel`
- `require=UsefulBarrelsMP` (dépendance Useful Barrels)
- `versionMin=42.13`

Pensez à ajouter Useful Barrels comme **dépendance requise** sur la page Workshop.

*(Placeholders : ajoutez ici poster.png / preview.png / workshop.txt quand prêts.)*
