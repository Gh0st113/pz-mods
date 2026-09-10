# pz-mods

Project Zomboid (Build 42) mods by Gh0st113. One subfolder per mod.

## Mods

| Mod | Description | Workshop | Dependencies |
|-----|-------------|----------|--------------|
| [MilkIntoBarrel](MilkIntoBarrel/) | Milk an animal straight into a nearby barrel | [3798667277](https://steamcommunity.com/sharedfiles/filedetails/?id=3798667277) | [Useful Barrels](https://steamcommunity.com/sharedfiles/filedetails/?id=3436537035) |

## Development

This repo holds the **source** of the mods. To test in-game, copy them into PZ's
local mods folder (`%USERPROFILE%\Zomboid\mods`):

```powershell
# Deploy every mod in this repo to Zomboid\mods, then (re)launch PZ to load them.
./deploy.ps1
```

Build 42 reminders:
- Required structure: `<Mod>/42/mod.info` + `<Mod>/42/media/lua/...` (the flat B41 layout is invisible in B42).
- Translations use the `.json` format (`Translate/<LANG>/ContextMenu.json`).
- A mod is reloaded on game **restart** (Lua + translations).

## Workshop publishing

Each mod has a `workshop/` folder (poster, preview, text). See `MilkIntoBarrel/workshop/README.md`.

## License

Code under the [MIT](LICENSE) license © Gh0st113. These are **standalone add-ons**: they
depend on their required mods (e.g. Useful Barrels) at runtime but do not redistribute
their code.
