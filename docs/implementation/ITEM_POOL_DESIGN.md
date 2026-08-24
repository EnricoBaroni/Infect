# Item Pool Design

**Status**: IMPLEMENTED — NOT GAMEPLAY VALIDATED  
**Last Updated**: 2026-08-19  
**Slice**: 42

---

## 1. Pool Definitions

### GACHA Pool (`"gacha"`)

**Purpose:** General combat and build items. These form the foundation of any run.

**Machine:** Normal Gacha Machine (GachaPonMachine with `pool_tag = "gacha"`)

**Contents:** All items that are useful in any combat build — stat increases, projectile modifiers, weapon replacements, status effects, companions, economy items.

**Rules:**
- An item belongs to `gacha` if it provides value regardless of whether the player is actively using the Infection mechanic.
- Nearly all items (293 of 295) are in this pool.

### INFECTION GACHA Pool (`"infection_gacha"`)

**Purpose:** Items specifically oriented toward the Infection mechanic and builds that exploit it. Items that reward infecting enemies before killing them, manage the increased threat of infected enemies, or extend the infection economy.

**Machine:** Infection Gacha Machine (GachaPonMachine with `pool_tag = "infection_gacha"`)

**Contents:** 42 items focused on the infection gameplay loop.

**Rules:**
- An item belongs to `infection_gacha` if it has any of the following:
  - `only_infected_kills = true` (the effect literally requires an infected kill)
  - `infected_bonus > 0` (explicitly rewards infected kills more than normal kills)
  - `inherit_infection = true` (projectile/effect carries the infection mechanic)
  - Is a drop/economy item (infection is fundamentally about generating extra drops)
  - Has thematic infection naming that reflects the infection system
  - Is a control item (slow/fear/freeze/chain) that helps manage the speed-boosted infected enemies

---

## 2. Membership Rules

An item may belong to:
- **Only `gacha`**: General combat items with no meaningful infection synergy
- **Only `infection_gacha`**: Items that are literally useless or misleading without active infection use (`only_infected_kills = true`)
- **Both `gacha` + `infection_gacha`**: Items with infection synergy that are ALSO useful in normal builds

**Current distribution:**
| Pool | Count |
|------|-------|
| `gacha` only | 253 |
| `infection_gacha` only | 2 |
| Both | 40 |
| **Total gacha pool** | **293** |
| **Total infection_gacha pool** | **42** |

---

## 3. Complete Infection Gacha Item Table

### 3A. Exclusive to infection_gacha (NOT in gacha)

These items are effectively useless without the infection mechanic:

| Item | File | Effect | Infection Mechanic |
|------|------|--------|-------------------|
| Infected Rush | infected_rush.tres | TempStatBuffOnKillEffect | `only_infected_kills = true` — buff only triggers on infected kills |
| Plague Feast | plague_feast.tres | StatRampOnKillEffect | `only_infected_kills = true` — damage ramp only from infected kills |

### 3B. In Both Pools (infection_gacha + gacha)

**Core infection mechanics** (`infected_bonus > 0` or `inherit_infection = true`):

| Item | File | Effect | Infection Mechanic |
|------|------|--------|-------------------|
| Green Bounty | green_bounty.tres | GainDropsOnKillEffect | `infected_bonus = 2` — infected kills give 2 extra drops |
| Fever Market | fever_market.tres | GainDropsOnKillEffect | `infected_bonus = 1` — infected kills give 1 extra drop |
| Thrift Crown | thrift_crown.tres | GainDropsOnKillEffect | `infected_bonus = 1` — infected kills give 1 extra drop |
| Bounty Bait | bounty_bait.tres | BaitStatusEffect | `infected_bonus = 1` — bait + infected kill bonus |
| Horror Dividend | horror_dividend.tres | FearStatusEffect | `infected_bonus = 1` — fear + infected kill bonus |
| Chain Bomb | chain_bomb.tres | ChainedStatusEffect + ExplosiveProjectilesEffect | `inherit_infection = true` — explosion carries infection |
| Septic Mortar | septic_mortar.tres | ExplosiveProjectilesEffect (lob_burst) | `inherit_infection = true` — lob carries infection |
| Coward Hook | coward_hook.tres | FearStatusEffect + ExplosiveProjectilesEffect | `inherit_infection = true` — fear projectile carries infection |

**Drop economy items** (infection loop is fundamentally about drops):

| Item | File | Effect | Infection Relevance |
|------|------|--------|---------------------|
| Blood Dividend | blood_dividend.tres | GainDropsOnKillEffect | General drop economy (infected bonus = 0) |
| Eye of Greed | eye_of_greed.tres | GainDropsOnEnemyHitEffect | Drop on enemy hit, infection makes enemies live longer |
| Loan Shark Tooth | loan_shark_tooth.tres | GainDropsOnKillEffect | Drop economy with trade-off |
| Lucky Toe | lucky_toe.tres | GainDropsOnRoomClearEffect | Room clear drops → fuels gacha |
| Contract From Below | contract_from_below.tres | GainDropsOnRoomClearEffect | Room clear drops |
| Sack Head | sack_head.tres | GainDropsOnRoomClearEffect | Room clear drops |
| Piggy Bank | piggy_bank.tres | SpawnDropsOnDamageEffect | Drops when hurt — risk of infected enemies = more drops |
| Echo Heart | echo_heart.tres | SpawnDropsOnDamageEffect + FireRateUp | Drops on damage |
| Fanny Pack | fanny_pack.tres | SpawnDropsOnDamageEffect | Drops on damage |
| Blood Transfusion | blood_transfusion.tres | SpawnDropsOnDamageEffect + SpeedUp | Drops on damage + speed |
| Counterfeit Penny | counterfeit_penny.tres | GainDropsOnDropPickupEffect | Drops from picking up drops |
| Steam Sale | steam_sale.tres | ShopPriceMultiplierEffect | Cheaper gacha = more items per drop |
| Restock | restock.tres | ShopInfiniteRestockEffect | Infinite gacha — core economy amplifier |
| Frenzy Organ | frenzy_organ.tres | TempStatBuffOnKillEffect + SpawnDropsOnDamage | Kill buff + drops on damage |

**Infection-themed items** (infection in name, part of infection identity):

| Item | File | Effect | Infection Relevance |
|------|------|--------|---------------------|
| Sinus Infection | sinus_infection.tres | PoisonStatusEffect | Infection-themed, poison synergizes with infected enemies |
| Contagion | contagion.tres | RoomEntryHazardPulseEffect + PoisonStatusEffect | Room entry poison spread, infection-themed |
| Viral Surge | viral_surge.tres | StatMultiplierEffect | Viral/infection-themed stat multiplier |
| Viral Pulse | viral_pulse.tres | CadenceShotEffect | Viral/infection-themed cadence shot |

**Control items** (infected enemies are faster — control helps manage them):

| Item | File | Effect | Infection Relevance |
|------|------|--------|---------------------|
| Tar Lens | tar_lens.tres | ProjectileHazardPulseEffect + SlowStatusEffect | Slows infected enemies |
| Time Tax | time_tax.tres | SlowStatusEffect | Slows infected enemies |
| Drag Net | drag_net.tres | SlowStatusEffect + HomingProjectilesEffect | Slows infected enemies |
| Heavy Snow | heavy_snow.tres | SlowStatusEffect + SplitShotsEffect | Slows infected enemies |
| Panic Spores | panic_spores.tres | FearStatusEffect | Makes infected enemies flee |
| Dread Compass | dread_compass.tres | FearStatusEffect + HomingProjectilesEffect | Fear + homing for infected |
| Nightmare Fork | nightmare_fork.tres | FearStatusEffect + SplitShotsEffect | Fear + split for infected |
| Terror Cloth | terror_cloth.tres | FearStatusEffect | Fear infected enemies |
| Iron Shackle | iron_shackle.tres | ChainedStatusEffect + DamageUp | Root infected enemies |
| Leash Gland | leash_gland.tres | ChainedStatusEffect + SpeedUp | Root infected enemies |
| Frost Chain | frost_chain.tres | ChainedStatusEffect + FreezeStatusEffect | Root + freeze infected |
| Frost Tip | frost_tip.tres | FreezeStatusEffect | Freeze infected enemies |
| Glacier Shard | glacier_shard.tres | FreezeStatusEffect + CriticalHitsEffect | Freeze + crit on infected |
| Brittle Heart | brittle_heart.tres | FreezeStatusEffect (damage penalty) | Freeze infected enemies |
| Winter Scope | winter_scope.tres | FreezeStatusEffect + DamageUp | Freeze + damage |

---

## 4. Items Exclusively in Gacha (NOT in infection_gacha)

All 253 items that have no meaningful infection synergy. These cover:
- Weapon replacements (Brimstone, returning blade, orbit shot, remote orb, lob burst, elastic ricochet, expanding ring)
- Pure stat upgrades (damage, fire rate, bullet speed, range)
- Projectile modifiers (pierce, bounce, homing, split, spectral)
- Status attacks (poison, burn, bleed, bait, charm, confusion — those not in infection_gacha)
- Companion/orbital items
- Kill scalers without infection restriction (predator_gland, adrenaline_surge, berserker_gland)
- Map reveal items

---

## 5. Pool Statistics and Coverage

| Category | gacha count | infection_gacha count |
|----------|-------------|----------------------|
| Kill-reward (only_infected) | 0 | 2 |
| Kill drops (infected_bonus > 0) | 5 | 5 |
| Drop economy (general) | 13 | 13 |
| Inherit infection | 3 | 3 |
| Control (slow/fear/freeze/chain) | 15 | 15 |
| Infection-themed | 4 | 4 |
| Combat utility (general) | ~200 | 0 |
| Weapon replacements | ~30 | 0 |
| Companion/orbital | ~30 | 0 |
| **TOTAL** | **293** | **42** |

---

## 6. Gaps Detected

### A. infection_gacha has very few EXCLUSIVE items (2)

Only `infected_rush` and `plague_feast` are exclusively in infection_gacha. The remaining 40 infection_gacha items are also in the general gacha. This means a player COULD get infection-synergy items from the normal gacha.

**Design question (unresolved):** Is this intentional (cross-discovery) or should more items be infection_gacha-exclusive?

### B. No items that specifically reward INFECTING enemies (as opposed to KILLING infected ones)

All current infection rewards are for KILLING infected enemies. There are no items that reward the act of INFECTING enemies or reward having infected enemies alive in the room.

**Example gap:** An item that spawns companions when you infect enemies. Or an item that gives drops when you infect enemies (not when you kill them). This would make the "infect without killing" decision more mechanically interesting.

**Future item ideas:**
- "Viral Carrier" - Spawn a companion for each enemy you infect
- "Infection Dividend" - Gain drops when you infect an enemy (not when you kill)
- "Patient Zero" - Infection spreads: when an infected enemy dies near others, those get infected automatically
- "Infectious Fury" - While 3+ enemies are infected, player gets a damage buff

### C. Infection Gacha is small relative to normal Gacha

42 vs 293. If both machines have the same cost, the infection gacha will exhaust its pool much faster (especially with `shop_infinite_restock = false`). 

**Design consideration:** Should the Infection Gacha have a lower cost (since the pool is smaller and more focused)? Or should `steam_sale` and `restock` be more prominent in the infection pool to compensate?

Currently both `steam_sale` and `restock` are in infection_gacha, which helps.

### D. Control items in infection_gacha are somewhat indirect

Slow/fear/freeze/chain items are in infection_gacha because infected enemies are faster. But a new player may not immediately recognize why these appear in the Infection Gacha. The connection requires understanding that infection makes enemies faster.

**Future:** If thematic clarity matters, consider removing control items from infection_gacha and only keeping the direct infection mechanics. This would reduce infection_gacha to ~26 items (the core mechanics) — even thinner but clearer.

---

## 7. Items with Ambiguous Classification

| Item | Current Pool | Question |
|------|-------------|----------|
| `blood_dividend` | Both | infected_bonus=0, just general economy — is it truly infection_gacha? |
| `lucky_toe`, `contract_from_below`, `sack_head` | Both | Room-clear economy, not kill economy. Stretch for infection_gacha. |
| `viral_surge` | Both | Stat multiplier, "viral" is thematic only. Could be gacha-only. |
| `viral_pulse` | Both | Cadence shot, "viral" is thematic only. Could be gacha-only. |
| All slow/fear/freeze/chain items | Both | Useful for managing infected but not exclusive to infection. |

---

## 8. Open Design Decisions

1. **Exclusive vs. shared**: How many items should be EXCLUSIVELY in infection_gacha? Currently only 2.
2. **Pool size balance**: infection_gacha (42) vs gacha (293) — is this ratio right for the demo?
3. **Machine cost**: Should infection_gacha machine be cheaper or more expensive?
4. **Gap items**: Should new infection-specific items be created to fill the gaps identified in Section 6B?
5. **Control items**: Keep all slow/fear/freeze/chain in infection_gacha (indirect but valid) or remove them for clarity?
6. **"treasure" tag**: The existing `pool_tags` entries keep the `"treasure"` tag from the Isaac-inspired original. This tag is currently unused in gameplay. Clean up later or keep for future use?

---

## 9. Implementation Details

### GachaPonMachine changes (gachapon_machine.gd)

Added `@export var pool_tag: String = "gacha"` to control which pool each machine draws from.

Changed `_refresh_passive_item_pool()` to filter:
```gdscript
if item.pool_tags.has(pool_tag):
    passive_item_pool.append(item)
```

To create an Infection Gacha Machine, set `pool_tag = "infection_gacha"` on the scene inspector.

The F1 debug menu bypasses both pools — it loads all items directly by filesystem scan without pool filtering. This is by design (development-only tool).

### ItemData changes (all 295 .tres files)

New pool tags added:
- `"gacha"` → added to 293 items
- `"infection_gacha"` → added to 42 items
- Old tags (`"treasure"`, `"secret"`, `"shop"`, `"angel"`, `"devil"`) preserved for future use

---

## 10. Static Validation Results

- ✅ 293 items have `"gacha"` tag
- ✅ 42 items have `"infection_gacha"` tag
- ✅ 2 items are infection_gacha-exclusive (`infected_rush`, `plague_feast`)
- ✅ 0 items have neither gacha nor infection_gacha tag
- ✅ GachaPonMachine filters by `pool_tag` field
- ✅ No hardcoded item IDs in gachapon_machine.gd
- ✅ No gameplay behavior changed
- ✅ F1 debug menu unaffected (bypasses pool system)
- ✅ No errors in gachapon_machine.gd
