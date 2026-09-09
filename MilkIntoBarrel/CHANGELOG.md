# Changelog — Milk Into Barrels

Format: date (YYYY-MM-DD). Newest first.

## 1.2.2 — 2026-09-09
- The radial menu (V) option now uses a **custom icon** (a barrel with a milk drop) instead of the vanilla milk-bucket icon, so it no longer looks identical to the normal "Milk" option.

## 1.2.1 — 2026-09-09
- Fix: the milk now actually **pours into the barrel**. The previous version chained a separate pour action after milking, but vanilla milking ends with a force-stop that cancelled it — so nothing was transferred. Milking + pouring now happen inside a single action.
- Milking now **empties the whole animal across several buckets** if needed, and pours all of them into the barrel (up to the barrel's free capacity; any leftover stays in the buckets).

## 1.2.0 — 2026-09-09
- **Real Husbandry XP.** Milking now routes through the vanilla milking action into a bucket — so you get the exact engine-computed XP (scaled by the animal's Animal Care), the correct amounts, and the stress mechanic — then the milk is **automatically poured from the bucket into the barrel**. A bucket is required by default.
- New sandbox option **"Allow milking without a bucket"** (off by default): permits the old direct animal->barrel transfer when the player has no bucket, but it grants **no XP** (a tooltip warns about it).
- The **duration multiplier** sandbox option now applies **only** to the no-bucket direct transfer (with a bucket, the vanilla milking timing is used).

## 1.1.2 — 2026-09-09
- Reverted the placeholder Husbandry XP from 1.1.1: it was an arbitrary value. Vanilla's milking XP is computed by the engine (scaled by the animal's *Animal Care*) and cannot be reproduced by a fixed Lua number, so **no XP is granted for now** rather than risk unbalancing the game. A faithful option (routing through the vanilla milking so the real XP applies) is under consideration.

## 1.1.1 — 2026-09-09
- (superseded by 1.1.2) Attempted to grant Husbandry XP with a placeholder value; removed because it was not the real vanilla calculation.

## 1.1.0 — 2026-09-09
- New: **sandbox options** (server-configurable):
  - *Milking duration multiplier* (default **2.0** = twice as long as the very first build; lower = faster).
  - *Require a bucket* (optional, off by default): the option only shows if the player carries a bucket. Cosmetic — the bucket is not consumed.
- Fix: the **radial menu (V)** now works on any milkable animal, **including wild ones** (the vanilla radial skips wild animals; we build our slice ourselves in that case).

## 1.0.0 — 2026-09-09
- Initial release.
- Milk any milkable animal (cows, sheep, and modded animals) **directly into an open Useful Barrels barrel**.
- Three ways to trigger: right-click the animal, right-click the barrel, or the radial menu (V).
- Multiplayer-safe (transfer computed server-side).
- Requires [Useful Barrels](https://steamcommunity.com/sharedfiles/filedetails/?id=3436537035).
