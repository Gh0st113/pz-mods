# Testing locally (dev loop)

Local testing in Project Zomboid B42 has one big trap: **mod loading precedence**.
PZ loads mods from several places, keyed by the mod **`id`**:

- `Zomboid\mods\<id>\` — your local copy
- `Zomboid\Workshop\<id>\Contents\mods\<id>\` — the Workshop **upload staging** folder
- `steamapps\workshop\content\108600\<workshopId>\mods\<id>\` — a **subscribed** Workshop mod

If any of those has the **same `id`**, it can shadow your local copy and you end up
testing an old version without noticing. To remove all doubt, we test under a **different
`id`** so nothing can shadow it.

## Fast loop: the isolated TEST build

```powershell
# from the pz-mods repo root
./deploy-test.ps1                 # deploys MilkIntoBarrel as id "MilkIntoBarrelTEST"
```

This copies the mod to `Zomboid\mods\MilkIntoBarrelTEST` and rewrites its `mod.info`:
- `id` → `MilkIntoBarrelTEST` (can never collide with the published Workshop mod)
- `name` → `[TEST v1.2.8] Milk Into Barrels …` (instantly recognizable in the mod list)

Then in game:
1. **Relaunch PZ** (full quit, not just back-to-menu).
2. Enable **`[TEST …]`** in the mod list; **disable** the published version to avoid confusion.
3. Test.

Remove the test build when done:

```powershell
./deploy-test.ps1 -Remove
```

## When do I need a NEW save?

- **Lua / timing / animation change** → just **relaunch**. No new save needed.
- **Sandbox change** (new option, changed default or label) → **new sandbox save**.
  Sandbox values are frozen per-save, so an existing save keeps the old defaults.

## Confirming the right version is loaded

- The mod list shows `[TEST v<version>] …`.
- On a **new** save, the sandbox section header shows the version (e.g. **Milk Into Barrels - v1.2.8**)
  and the expected defaults (e.g. *Allow milking without a bucket (hybrid)*, duration multiplier default `10`).

## Shipping a normal (non-test) local copy

`./deploy.ps1` copies every mod verbatim (same `id`) into `Zomboid\mods\`. Use it only when
you are **not** subscribed to the Workshop version and there is **no** staging folder for it —
otherwise those will shadow it. When in doubt, use `deploy-test.ps1`.

## Publishing (reminder)

Never publish to the Workshop or tag/create a GitHub release before an in-game test has passed.
Pushing source commits to GitHub is fine (backup/history, revertible).
