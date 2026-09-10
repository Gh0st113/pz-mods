# Milk Into Barrels

**Published on the Steam Workshop:** https://steamcommunity.com/sharedfiles/filedetails/?id=3798667277 (id `3798667277`)

> 🌍 **Translators welcome** — the mod is translation-ready (all text is externalized to JSON, EN + FR provided). See [TRANSLATIONS.md](TRANSLATIONS.md): 3 steps, ~7 short strings.

An add-on for **[Useful Barrels](https://steamcommunity.com/sharedfiles/filedetails/?id=3436537035)** for Project Zomboid **Build 42**.

Milk a milkable animal **straight into a nearby open Useful Barrels barrel** — the animal counterpart of Useful Barrels' barrel↔vehicle siphoning.

## In-game usage

Three ways to trigger it (the option only shows when the conditions are met):

- **Right-click the animal** → "Milk <animal> into the barrel"
- **Right-click the barrel** → "Milk <animal> into the barrel" (submenu if several animals)
- **Radial menu (V key)** near the animal → same slice

### How it works
With a **bucket** on you, milking goes through the vanilla milking action (so you get the exact
Husbandry XP, the correct amounts and the stress mechanic) into the bucket, and the milk is then
**poured automatically into the barrel**. If the animal is very productive it fills several buckets
and empties them all into the barrel. A bucket is required by default.

A server sandbox option **"Allow milking without a bucket"** (off by default) lets you milk straight
into the barrel with no bucket — convenient, but it grants **no XP**.

### Requirements
- An **open Useful Barrels barrel** (empty, or already holding the same milk) within ~3 tiles.
- A **milkable animal** with milk (cows, sheep… and any modded milkable animal — not limited to one species).
- A **bucket** (unless the no-bucket sandbox option is enabled).

The milk type matches the animal (`CowMilk`, `SheepMilk`, …).

## Dependency
- **Useful Barrels** (`UsefulBarrelsMP`) — required (declared in `mod.info`).

## Multiplayer
The transfer is computed **server-side** (authoritative). Tested in single-player; MP validation
recommended on a dedicated server.

## Structure
```
42/mod.info
42/media/lua/shared/MB_Utils.lua                                  -- helpers (nearby animals/barrels, milk fluid)
42/media/lua/shared/MB_MilkSync.lua                               -- server -> client milk sync
42/media/lua/shared/TimedActions/MB_MilkAnimalToBarrelAction.lua  -- vanilla milking (XP) + auto-pour into the barrel
42/media/lua/shared/TimedActions/MB_MilkIntoBarrelAction.lua      -- direct no-bucket transfer (no XP)
42/media/lua/client/MB_MilkContextMenu.lua                        -- right-click animal + barrel, radial V
42/media/lua/shared/Translate/{EN,FR}/*.json                      -- translations
42/media/ui/MilkIntoBarrel_Milk.png                               -- radial icon
```

## License
MIT © Gh0st113. See [../LICENSE](../LICENSE).
