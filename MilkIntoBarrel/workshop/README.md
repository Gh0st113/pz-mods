# Steam Workshop upload folder — MilkIntoBarrel

These files are used to publish/update the mod on the Steam Workshop (via PZ's built-in tool:
main menu → Workshop → Create and Edit Item):

- **preview.png** — the Workshop preview image (512×512).
- **poster.png** / **icon.png** — the in-game images (also shipped under `../42/`).
- **source.png** — the full-resolution source of the preview.
- **workshop.txt** — Workshop metadata (title, tags, id once published) and the description text
  shown on the Steam page.

## B42 packaging notes

PZ's Workshop tool expects a `Contents/mods/<ModId>/…` folder. Our source (`../42/…`) is the mod
content; the tool builds the `Contents/` wrapper.

`mod.info` already declares:
- `id=MilkIntoBarrel`
- `require=UsefulBarrelsMP` (Useful Barrels dependency)
- `versionMin=42.13`

Remember to add **Useful Barrels** as a required item on the Workshop page.
