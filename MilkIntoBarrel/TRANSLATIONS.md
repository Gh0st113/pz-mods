# Translating "Milk Into Barrels"

This mod is fully translatable. **All in-game text lives in small JSON files**, one
folder per language, under:

```
42/media/lua/shared/Translate/<LANG>/
```

English (`EN`) is the reference. Missing languages automatically fall back to English,
so nothing breaks if a language is incomplete.

## How to add / edit a language (3 steps)

1. **Copy** the `EN` folder to a new folder named with your Project Zomboid language
   code — e.g. `.../Translate/DE/` for German. (Both files: `ContextMenu.json` and
   `Sandbox.json`.)
2. **Translate only the values** — the text on the right of `:`. **Keep the keys**
   (left side) and any **`%1`** exactly as they are.
3. Keep it **valid JSON**: keep the quotes and the commas between entries.

### Example (German)
```json
{
  "ContextMenu_MilkBarrel_MilkAnimal": "%1 in das Fass melken"
}
```
`%1` is replaced in-game by the animal (or barrel) name — don't remove it.

## Strings to translate
- `ContextMenu.json` — the right-click / radial menu options.
- `Sandbox.json` — the server sandbox options and their tooltips.

That's it — 2 short menu strings and 5 sandbox strings.

## Project Zomboid language codes
`AR CA CH CN CS DA DE EN ES FI FR HU ID IT JP KO NL NO PH PL PT PTBR RO RU TH TR UA`
(use the same code the game uses for your language).

## Sending your translation
Open an issue / pull request on the repository, or drop the two JSON files in a
Workshop comment / message to the author. Contributions are very welcome — thanks! :)
