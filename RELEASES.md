# Release status — what is LIVE vs what is in TEST

This file is the single source of truth for **which version is actually published on the
Steam Workshop**, versus what is only tagged on GitHub / still being tested.

It exists because it is easy to lose track: GitHub can have many tags that were **never
uploaded to Steam**. When writing a Steam "change note", only the changes **between the live
Steam version and the version being uploaded** should be listed.

## Current status

| Channel | Version | Notes |
|---|---|---|
| 🟢 **Live on Steam** | **v1.2.8** | Workshop item `3798667277`. Uploaded 2026-09-10. No-bucket milking now plays the milking animation + its duration is calibrated; version shown in the sandbox header; English source. |
| 🧪 **In test (not on Steam)** | — (none) | `main` == v1.2.8, which is live. |

Steam upload history: **1.1.0** (first) → **1.2.2** (second) → **1.2.8** (current).

> Update the **Live on Steam** row **only when the mod is actually uploaded** to the Workshop.

## Convention (so this stays unambiguous)

- **GitHub "Latest" release = the version that is live on Steam.**
- **GitHub "Pre-release" = tagged/tested but NOT yet on Steam.**
- So the newest **non**-pre-release GitHub release always matches what players actually have.

## When you upload a new version to Steam

1. Do the Workshop upload in-game.
2. In this file, move that version to the **Live on Steam** row (and set the next dev version
   as **In test**).
3. On GitHub, that version's release becomes the full **Latest** release; everything older
   than it that was pre-release can stay as-is.

## Writing the Steam change note ("what's new")

List only the changes **since the Live-on-Steam version** — i.e. `git log <live-tag>..HEAD`.
Do **not** list features that already shipped in the live version. The full per-version
history lives in `MilkIntoBarrel/CHANGELOG.md` and in the Workshop page description.
