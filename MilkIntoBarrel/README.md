# Traire dans le baril (MilkIntoBarrel)

**Publié sur le Steam Workshop :** https://steamcommunity.com/sharedfiles/filedetails/?id=3798667277 (id `3798667277`)

Addon de **[Useful Barrels](https://steamcommunity.com/sharedfiles/filedetails/?id=3436537035)** pour Project Zomboid **Build 42**.

Permet de **traire un animal directement dans un baril Useful Barrels ouvert** posé à proximité — le pendant, pour les animaux, du siphonnage baril↔véhicule d'Useful Barrels.

## Utilisation en jeu

Trois façons de déclencher l'action (l'option n'apparaît que si les conditions sont réunies) :

- **Clic droit sur l'animal** → « Traire [animal] dans le baril »
- **Clic droit sur le baril** → « Traire [animal] dans le baril » (sous-menu si plusieurs animaux)
- **Radial (touche V)** près de l'animal → même tranche

### Conditions
- Un **animal traiable** avec du lait (vache, brebis… et tout animal moddé traiable — le mod n'est pas limité à une espèce).
- Un **baril Useful Barrels ouvert** (couvercle découpé/dévissé) à **≤ 3 tuiles**, **vide ou contenant déjà le même lait** (pas de mélange de fluides).

Le lait transféré correspond au type de l'animal (`CowMilk`, `SheepMilk`, …). La vitesse est lente (action à minuterie). Donne un peu d'XP Élevage.

## Dépendance
- **Useful Barrels** (`UsefulBarrelsMP`) — requis (déclaré dans `mod.info`).

## Multijoueur
Transfert calculé côté **serveur** (autoritaire) ; la quantité de lait est synchronisée vers les clients. Testé en solo ; validation MP recommandée sur serveur dédié.

## Structure
```
42/mod.info
42/media/lua/shared/MB_Utils.lua                       -- helpers (animaux/barils proches, fluide lait)
42/media/lua/shared/MB_MilkSync.lua                    -- synchro serveur -> clients du lait
42/media/lua/shared/TimedActions/MB_MilkIntoBarrelAction.lua  -- l'action de traite -> baril
42/media/lua/client/MB_MilkContextMenu.lua             -- clic droit animal + baril, radial V
42/media/lua/shared/Translate/{EN,FR}/ContextMenu.*    -- traductions
```
