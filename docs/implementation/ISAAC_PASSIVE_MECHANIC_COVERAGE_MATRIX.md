# Isaac Passive Mechanic Coverage Matrix (Rebirth + AB + AB+ + Repentance)

## Purpose
This document defines a complete internal coverage matrix for passive-item design space, classified by reusable mechanic families instead of by item names.

Scope is passive collectible mechanics across official expansions:
- Rebirth
- Afterbirth
- Afterbirth+
- Repentance

This matrix is intended to drive implementation in Infect without recreating Isaac content literally.

## Classification Rules
- Classify by reusable mechanic family, not by item identity.
- Group equivalent behavior under one family even if many items apply it.
- Keep passive mechanics as primary scope; include room/shop/curse/luck systems where passive items interact with them.
- Use representative sources only for verification, not for item-by-item mapping.

## Source Baseline (research input)
- Fandom: Items, Tear Effects, Status Effects, Item Pool, Curses, Bombs, Luck, Shop, Pickups.
- tboi.com and Platinum God used as supplementary count/context references.
- Note: Bomb_effects page was unavailable; bomb mechanic taxonomy was taken from Bombs/Luck/Items references.

## Coverage Status Legend
- Implemented: Mechanic family already supported in Infect core + effects pipeline.
- Partial: Infrastructure exists but family is not fully generalized.
- Planned: Not yet implemented.

## Canonical Reusable Mechanic Families

| ID | Reusable mechanic family | Primary dimension | Secondary dimensions | Earliest expansion | Infect status |
|---|---|---|---|---|---|
| M001 | Flat stat up/down | Stat effect | Gameplay mechanic | Rebirth | Implemented |
| M002 | Multiplicative stat scaler | Stat effect | Gameplay mechanic | Rebirth | Planned |
| M003 | Conditional stat bonus (state-gated) | Trigger effect | Stat effect, Gameplay mechanic | Rebirth | Planned |
| M004 | Temporary timed stat buff | Trigger effect | Stat effect, Gameplay mechanic | Rebirth | Planned |
| M005 | On-damage stat ramp | Trigger effect | Stat effect | Rebirth | Planned |
| M006 | On-kill stat ramp | Trigger effect | Stat effect | Rebirth | Planned |
| M007 | Per-floor/per-room stacking stat growth | Trigger effect | Stat effect, Room effect | AB/AB+ | Planned |
| M008 | Health container conversion/exchange | Special mechanic | Economy effect, Stat effect | Rebirth | Planned |
| M009 | Cost-for-power conversion (HP/coins to damage) | Economy effect | Special mechanic, Stat effect | Rebirth | Planned |
| M010 | Fire rate model replacement (delay formula override) | Weapon mechanic | Stat effect | Rebirth | Partial |
| M011 | Weapon archetype replacement: charge beam | Weapon mechanic | Projectile mechanic | Rebirth | Implemented |
| M012 | Weapon archetype replacement: returning blade | Weapon mechanic | Projectile mechanic | Rebirth-like | Implemented |
| M013 | Weapon archetype replacement: persistent controlled projectile | Weapon mechanic | Projectile mechanic, Special mechanic | AB/Rep-style | Implemented |
| M014 | Weapon archetype replacement: orbital firing origin | Weapon mechanic | Projectile mechanic | Rebirth-like | Implemented |
| M015 | Weapon archetype replacement: lobbed ballistic projectile | Weapon mechanic | Projectile mechanic | Rebirth-like | Implemented |
| M016 | Weapon archetype replacement: bouncing elastic shot | Weapon mechanic | Projectile mechanic | Rebirth-like | Implemented |
| M017 | Multi-directional volley pattern | Projectile mechanic | Weapon mechanic | Rebirth | Planned |
| M018 | Backward/side shot appenders | Projectile mechanic | Weapon mechanic | Rebirth | Planned |
| M019 | Burst cadence (every Nth shot special) | Trigger effect | Projectile mechanic, Luck interaction | Rebirth | Planned |
| M020 | Charged release tiers | Weapon mechanic | Trigger effect | Rebirth | Planned |
| M021 | Projectile homing | Projectile mechanic | Luck interaction | Rebirth | Implemented |
| M022 | Projectile piercing | Projectile mechanic | Luck interaction | Rebirth | Implemented |
| M023 | Projectile spectral (terrain pass-through) | Projectile mechanic | Luck interaction | Rebirth | Implemented |
| M024 | Projectile bounce/ricochet | Projectile mechanic | Luck interaction | Rebirth | Implemented |
| M025 | Projectile split/fork | Projectile mechanic | Trigger effect | Rebirth | Implemented |
| M026 | Projectile boomerang/return path | Projectile mechanic | Weapon mechanic | Rebirth | Implemented |
| M027 | Projectile acceleration/deceleration curve | Projectile mechanic | Special mechanic | Rebirth | Planned |
| M028 | Projectile size/mass modifier | Projectile mechanic | Stat effect | Rebirth | Planned |
| M029 | Projectile friction and drag field | Projectile mechanic | Aura effect | AB/Rep | Planned |
| M030 | Projectile orbit around player | Projectile mechanic | Weapon mechanic | Rebirth | Implemented |
| M031 | Projectile path warping (spiral/wave/sine) | Projectile mechanic | Special mechanic | Rebirth | Planned |
| M032 | Continuum/wrap-around room edges | Room effect | Projectile mechanic | AB | Planned |
| M033 | Sticky projectile that latches and ticks | Projectile mechanic | Status effect, Trigger effect | AB/Rep | Planned |
| M034 | Delayed detonation projectile | Projectile mechanic | Death effect, Spawn effect | Rebirth | Planned |
| M035 | Tear-to-laser conversion | Weapon mechanic | Projectile mechanic | Rebirth | Planned |
| M036 | Tear-to-bomb conversion | Weapon mechanic | Economy effect, Projectile mechanic | Rebirth | Planned |
| M037 | Contact-damage aura while firing | Aura effect | Trigger effect, Status effect | AB | Planned |
| M038 | Persistent damaging orbitals | Companion effect | Aura effect, Gameplay mechanic | Rebirth | Implemented |
| M039 | Passive follower shooters | Companion effect | Projectile mechanic | Rebirth | Implemented |
| M040 | Contextual familiar mode shift | Companion effect | Trigger effect, Special mechanic | AB/Rep | Planned |
| M041 | Familiar spawn scale by condition | Companion effect | Trigger effect, Spawn effect | AB | Planned |
| M042 | Temporary ally spawn on room entry | Spawn effect | Companion effect, Trigger effect | AB | Planned |
| M043 | Temporary ally spawn on damage taken | Spawn effect | Companion effect, Trigger effect | Rebirth/AB | Planned |
| M044 | Temporary ally spawn on kill | Spawn effect | Companion effect, Trigger effect | AB | Planned |
| M045 | Kill-generated blue flies/spiders locusts | Spawn effect | Death effect, Trigger effect | Rebirth | Planned |
| M046 | Projectile-on-hit extra spawn | Spawn effect | Trigger effect, Projectile mechanic | AB/Rep | Planned |
| M047 | Room-entry hazard proc (mass status pulse) | Room effect | Status effect, Trigger effect, Luck interaction | AB/Rep | Planned |
| M048 | Room-clear reward amplification | Economy effect | Room effect, Luck interaction | Rebirth | Planned |
| M049 | Pickup quality reroll or substitution | Economy effect | Room effect, Shop effect | AB/Rep | Planned |
| M050 | Pedestal reroll pipeline (single target) | Economy effect | Shop effect, Room effect | Rebirth | Planned |
| M051 | Global reroll/reset of passive loadout | Special mechanic | Economy effect, Stat effect | Rebirth | Planned |
| M052 | Item pool cross-pool chaos mixing | Economy effect | Shop effect, Room effect, Special mechanic | AB | Planned |
| M053 | Item quality bias up/down | Economy effect | Shop effect, Room effect | Rep | Planned |
| M054 | Deal chance manipulation (angel/devil/planetarium) | Economy effect | Room effect, Special mechanic | Rebirth/Rep | Planned |
| M055 | Shop price multiplier reduction | Shop effect | Economy effect | Rebirth | Planned |
| M056 | Shop free purchase tokenization | Shop effect | Economy effect, Trigger effect | Rebirth | Planned |
| M057 | Shop restock behavior modification | Shop effect | Economy effect, Trigger effect | AB | Planned |
| M058 | Shop stock expansion and guaranteed slots | Shop effect | Economy effect | Rebirth/AB | Planned |
| M059 | Shop access rule override (keyless, floor extension) | Shop effect | Room effect, Economy effect | Rebirth/AB | Planned |
| M060 | Bomb modifier package (brimstone/sad/scatter/hot/ghost/etc.) | Projectile mechanic | Economy effect, Luck interaction | AB/Rep | Planned |
| M061 | Explosion override and tile interaction modifiers | Projectile mechanic | Room effect, Special mechanic | Rebirth | Planned |
| M062 | Creep trail spawn on movement/firing/hit | Aura effect | Spawn effect, Status effect | Rebirth/AB | Planned |
| M063 | Creep immunity/self-protection clauses | Special mechanic | Status effect | Rebirth/AB | Planned |
| M064 | Status infliction: poison | Status effect | Projectile mechanic, Luck interaction | Rebirth | Implemented |
| M065 | Status infliction: burn | Status effect | Projectile mechanic, Luck interaction | Rebirth | Implemented |
| M066 | Status infliction: slow | Status effect | Projectile mechanic, Aura effect, Luck interaction | Rebirth | Implemented |
| M067 | Status infliction: fear | Status effect | Projectile mechanic, Aura effect, Luck interaction | Rebirth | Implemented |
| M068 | Status infliction: charm | Status effect | Projectile mechanic, Trigger effect | Rebirth | Planned |
| M069 | Status infliction: confusion | Status effect | Projectile mechanic, Trigger effect | Rebirth | Planned |
| M070 | Status infliction: petrify/freeze hard-CC | Status effect | Death effect, Projectile mechanic, Luck interaction | Rebirth/Rep | Partial |
| M071 | Status infliction: bleed | Status effect | Projectile mechanic, Trigger effect | AB | Planned |
| M072 | Status infliction: bait/mark | Status effect | Projectile mechanic, Trigger effect | Rep | Planned |
| M073 | Status infliction: chained/root | Status effect | Trigger effect | Rep | Planned |
| M074 | Randomized status roulette per shot | Special mechanic | Status effect, Luck interaction | AB/Rep | Planned |
| M075 | Status immunity on player | Special mechanic | Status effect | Rep | Planned |
| M076 | Enemy on-death replacement (frozen statue, no split) | Death effect | Status effect, Spawn effect | Rep | Planned |
| M077 | Enemy death nova/ring burst | Death effect | Projectile mechanic, Spawn effect | Rebirth | Planned |
| M078 | On-hit/on-kill explosion chains | Death effect | Trigger effect, Projectile mechanic | Rebirth/AB | Planned |
| M079 | Room-wide pulse on event (damage/kill/entry) | Room effect | Trigger effect, Status effect | Rebirth/AB | Planned |
| M080 | Room curse removal or suppression | Curse effect | Room effect, Trigger effect | Rebirth/Rep | Planned |
| M081 | Room reveal/map intelligence | Room effect | Economy effect, Special mechanic | Rebirth | Planned |
| M082 | Secret/ultra secret room discovery assist | Room effect | Economy effect, Luck interaction | AB/Rep | Planned |
| M083 | Curse susceptibility modulation | Curse effect | Special mechanic | Rebirth | Planned |
| M084 | Curse injection/imposed penalties | Curse effect | Special mechanic, Economy effect | Rebirth/AB | Planned |
| M085 | Luck stat direct up/down | Luck interaction | Stat effect | Rebirth | Planned |
| M086 | Luck-scaled proc curves (linear/exponential/capped) | Luck interaction | Trigger effect, Status effect | Rebirth | Planned |
| M087 | Luck-capped room reward quality | Luck interaction | Economy effect, Room effect | Rebirth | Planned |
| M088 | Luck-dependent special object outcomes | Luck interaction | Economy effect, Special mechanic | Rebirth/AB | Planned |
| M089 | Damage prevention layers (shields/mantles/procs) | Special mechanic | Trigger effect, Aura effect | Rebirth | Planned |
| M090 | Projectile blocking/deflection fields | Aura effect | Special mechanic, Companion effect | AB | Planned |
| M091 | Contact damage retaliation (thorns/aura) | Aura effect | Trigger effect, Status effect | Rebirth | Planned |
| M092 | Invulnerability windows from passive procs | Special mechanic | Trigger effect | Rebirth | Planned |
| M093 | Revive/extra life orchestration | Special mechanic | Economy effect, Trigger effect | Rebirth | Planned |
| M094 | Character form state swaps and twin-state logic | Special mechanic | Stat effect, Trigger effect | Rep | Planned |
| M095 | Pickup conversion pipelines (heart<->coin<->bomb<->key) | Economy effect | Special mechanic, Room effect | Rebirth | Planned |
| M096 | On-use external trigger bridge (pill/card usage hooks) | Trigger effect | Special mechanic, Economy effect | AB/Rep | Planned |
| M097 | Terrain/object conversion (rocks to poop, etc.) | Room effect | Economy effect, Luck interaction | Rep | Planned |
| M098 | Transformation set-bonus accumulators | Special mechanic | Stat effect, Companion effect, Projectile mechanic | Rebirth | Planned |
| M099 | Achievement/unlock-sensitive behavior toggles | Special mechanic | Economy effect | Rebirth | Planned |
| M100 | Seed/challenge rule overrides affecting passive behavior | Special mechanic | Curse effect, Room effect | Rebirth/Rep | Planned |

## Dimension Index (required matrix dimensions)

### Gameplay mechanic
- M001-M010, M037-M045, M089-M100

### Weapon mechanic
- M010-M020, M035-M036

### Projectile mechanic
- M017-M036, M060-M061, M077-M078

### Status effect
- M064-M075

### Economy effect
- M008-M009, M048-M059, M095, M099

### Companion effect
- M038-M045, M090, M098

### Trigger effect
- M003-M007, M019-M020, M033, M037, M042-M047, M057, M073, M078-M080, M086, M091-M093, M096

### Stat effect
- M001-M008, M010, M028, M085, M098

### Aura effect
- M029, M037, M062, M066-M067, M090-M091

### Spawn effect
- M042-M047, M062, M076-M078

### Death effect
- M045, M076-M078

### Room effect
- M032, M047-M054, M059, M061, M079-M082, M087, M095, M097, M100

### Shop effect
- M049-M059

### Curse effect
- M080, M083-M084, M100

### Luck interaction
- M019, M021-M024, M047, M060, M064-M067, M070, M074, M082, M085-M088, M097

### Special mechanic
- M008-M009, M013, M029, M051-M052, M063, M074-M075, M081, M083-M084, M089-M100

## Current Infect Coverage Snapshot (derived from implemented systems)

Implemented families:
- Core stat ops: M001
- Weapon/projection archetypes: M011-M016, M025-M026, M030
- Projectile traits: M021-M024
- Status families: M064-M067 and partial M070
- Companion base: M038-M039
- Trigger/economy baseline: partial M048 via drop-related effects

Missing high-priority infrastructure families:
- Shop/room/curse/luck systemic families: M049-M059, M080-M088
- Broader status repertoire: M068-M074
- Bomb/explosion modular families: M060-M061
- On-death and spawn chain families: M045-M047, M076-M078
- Meta/special systems: M089-M100

## Implementation Phase Entry (post-matrix)
The implementation phase should now proceed by reusable family batches, not item batches:
1. Build shared infra for room/shop/curse/luck hooks.
2. Build shared infra for status extensions (charm/confusion/bleed/bait/chained).
3. Build shared infra for economy/shop pool modifiers.
4. Build shared infra for death/spawn chain mechanics.
5. Add passive item content only after each infra batch is validated.

This keeps feature coverage aligned with the matrix while preserving the project rule: no item-ID conditionals in systems.
