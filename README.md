# pz-mods

Mods Project Zomboid (Build 42) de Alpha13. Un sous-dossier par mod.

## Mods

| Mod | Description | Dépendances |
|-----|-------------|-------------|
| [MilkIntoBarrel](MilkIntoBarrel/) | Traire un animal directement dans un baril à proximité | [Useful Barrels](https://steamcommunity.com/sharedfiles/filedetails/?id=3436537035) |

## Développement

Ce repo contient les **sources** des mods. Pour tester en jeu, on les copie dans le
dossier de mods locaux de PZ (`%USERPROFILE%\Zomboid\mods`).

```powershell
# Déploie tous les mods du repo vers Zomboid\mods, puis (re)lance PZ pour les charger.
./deploy.ps1
```

Rappels B42 :
- Structure obligatoire : `<Mod>/42/mod.info` + `<Mod>/42/media/lua/...` (le layout plat B41 est invisible en B42).
- Les traductions doivent être au format `.json` (`Translate/<LANG>/ContextMenu.json`).
- Un mod se recharge au **redémarrage** du jeu (Lua + traductions).

## Publication Workshop

Chaque mod a un dossier `workshop/` (poster, preview, texte). Voir `MilkIntoBarrel/workshop/README.md`.
