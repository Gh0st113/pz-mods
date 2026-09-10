# Contributing to pz-mods

Thanks for your interest! These are small **Project Zomboid (Build 42)** mods. Bug reports,
suggestions, and especially **translations** are welcome.

## Reporting bugs / ideas
Open an **issue**. For a bug, please include:
- which mod, and your game version (Build 42.x),
- single-player or a server (and which other mods are loaded),
- the relevant lines from `%USERPROFILE%\Zomboid\console.txt` if there's a Lua error.

## Translations
Translating is easy — all in-game text is externalized to JSON, no code involved.
See **[MilkIntoBarrel/TRANSLATIONS.md](MilkIntoBarrel/TRANSLATIONS.md)**: copy the `EN` folder to
your language code, translate the values (keep the keys and any `%1`), and open a pull request.
Missing languages simply fall back to English.

## Development setup
- **Structure (Build 42):** `<Mod>/42/mod.info` + `<Mod>/42/media/lua/...`. The flat B41 layout
  is invisible in B42. Translations use the `.json` format under `Translate/<LANG>/`.
- **Deploy to the game for testing:**
  ```powershell
  ./deploy.ps1
  ```
  It copies each mod into `%USERPROFILE%\Zomboid\mods`. **Restart PZ** to reload Lua/translations.
- Test in **single-player** first (enable debug mode for logs); validate **multiplayer** on a
  dedicated server (transfers are server-side).

## Pull requests
- Keep changes focused and small.
- Match the existing code style.
- When behavior changes, update the mod's `CHANGELOG.md` and bump `modversion` in `mod.info`.
- Don't commit generated/test files or the deployed copy of the mod.

## License
By contributing, you agree that your contributions are licensed under the repository's
[MIT license](LICENSE).
