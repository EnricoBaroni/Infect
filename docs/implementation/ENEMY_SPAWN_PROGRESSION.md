# Enemy Spawn Progression Classification

**Status**: IMPLEMENTED — NOT GAMEPLAY VALIDATED  
**Last Updated**: 2026-08-19  
**Slice**: 41

---

## 1. Sources Consulted

| Source | URL | Date |
|--------|-----|------|
| The Binding of Isaac: Rebirth Wiki — Fly/Hopper | bindingofisaacrebirth.fandom.com/wiki/Fly | 2026-08-19 |
| The Binding of Isaac: Rebirth Wiki — Hopper/Leaper | bindingofisaacrebirth.fandom.com/wiki/Hopper (also contains Leaper) | 2026-08-19 |
| The Binding of Isaac: Rebirth Wiki — Gaper | bindingofisaacrebirth.fandom.com/wiki/Gaper | 2026-08-19 |
| The Binding of Isaac: Rebirth Wiki — Mulligan | bindingofisaacrebirth.fandom.com/wiki/Mulligan | 2026-08-19 |
| The Binding of Isaac: Rebirth Wiki — Globin | bindingofisaacrebirth.fandom.com/wiki/Globin | 2026-08-19 |
| The Binding of Isaac: Rebirth Wiki — Charger | bindingofisaacrebirth.fandom.com/wiki/Charger | 2026-08-19 |
| The Binding of Isaac: Rebirth Wiki — Host | bindingofisaacrebirth.fandom.com/wiki/Host | 2026-08-19 |
| The Binding of Isaac: Rebirth Wiki — Pooter | bindingofisaacrebirth.fandom.com/wiki/Pooter | 2026-08-19 |

---

## 2. Isaac Progression Principles (Facts from Wiki)

Isaac organizes enemy appearances by **Chapter** (each chapter = 2 floors):

| Chapter | Floors | Notes |
|---------|--------|-------|
| Chapter 1 | Basement/Cellar (I & II) | Introductory enemies — simplest behaviors |
| Chapter 2 | Caves/Catacombs (I & II) | Intermediate enemies — adds ranged attacks, dodge mechanics, spawning |
| Chapter 3 | Depths/Necropolis (I & II) | Hard enemies — tougher HP, more threatening patterns |
| Chapter 4 | Womb/Utero (I & II) | Near-end enemies — highest threat outside of final floors |
| Final Floors | Sheol/Cathedral, Dark Room/Chest | Endgame content — not relevant to our demo |

**Key principle Isaac uses:**
- Chapter 1 enemies are simple melee chasers or basic single-shot ranged enemies
- Chapter 2 introduces enemies that charge, take cover, spawn others, or require player adaptation
- Chapter 3 enemies are Chapter 1/2 variants made more dangerous, or new enemies with complex mechanics
- Most enemies introduced in an early chapter **continue to appear in later chapters** (they don't disappear)
- Some enemies have hard cap on where they appear (e.g., Gapers stop after Downpour/Dross in Repentance)

**What we copy:**
- The *introduction-by-floor* principle: earlier enemies introduced in Chapter 1, more complex in Chapter 2+
- Enemies don't suddenly stop; `spawn_tier_max = 0` means "no upper limit" and is the default
- Early-game enemies (Gaper, Mulligan) *can* be capped at a max tier to avoid them drowning out later-game content

---

## 3. Our Tier Scale

For our demo, we use a simple 1–5 tier scale:

| Tier | Equivalent Isaac Chapter | Our Design Intent |
|------|--------------------------|-------------------|
| 1 | Chapter 1 (Basement) | Beatable without items; tutorial-difficulty |
| 2 | Chapter 2 (Caves) | Requires player to adapt; has ranged/complex behavior |
| 3 | Chapter 3 (Depths) | Challenging; designed for player with 2–4 items |
| 4 | Chapter 4 (Womb) | Highly dangerous; late-run content |
| 5 | Final floors | Reserved for boss-adjacent or endgame use |

Tier is used for **spawn eligibility** only. It does NOT modify HP, speed, damage, or behavior.

HP/speed scaling is handled separately by `Global.difficulty_level` and the `health_multiplier` / `speed_multiplier` system in `Room.respawn_enemies()`.

---

## 4–10. Enemy Classification Table

| Our Enemy | Class | Isaac Closest Equivalent | Isaac Floors (Confirmed) | Our Tier Min | Our Tier Max | Spawn Weight | Confidence | Justification |
|-----------|-------|--------------------------|--------------------------|-------------|-------------|-------------|-----------|----------------|
| BatEnemy | bat_enemy.gd | **Fly / Attack Fly** | Basement through all floors | 1 | 0 (no max) | 10 | HIGH | Fly/Attack Fly appear from Chapter 1 through endgame; basic mobile chase; lowest HP in our roster (2) |
| BullyEnemy | bully_enemy.gd | **Gaper / Frowning Gaper** | Basement/Cellar/Downpour only (Chapter 1) | 1 | 3 | 8 | HIGH | Gapers are the iconic Chapter 1 melee chaser in Isaac; pure contact damage, no ranged attack; capped at tier 3 to avoid oversaturation in late floors |
| MulliganEnemy | mulligan_enemy.gd | **Mulligan** | Basement/Cellar only (Chapter 1) | 1 | 3 | 7 | HIGH | Mulligan is a Chapter 1 enemy exclusively; wanders and flees (no attack). Our MulliganEnemy mirrors this exactly; attack stub confirms it; capped at tier 3 |
| PooterEnemy | pooter_enemy.gd | **Pooter** | Basement through Depths (Chapters 1–3) | 1 | 4 | 8 | HIGH | Pooter appears from Basement and continues through Depths in Isaac; wanders slowly and shoots single projectile; matches our PooterEnemy behavior exactly |
| ChargerEnemy | charger_enemy.gd | **Charger** | Caves/Catacombs onwards (Chapter 2+) | 2 | 0 (no max) | 7 | HIGH | Isaac Charger first appears in Chapter 2 (Caves); wanders, then charges in straight line when aligned; our ChargerEnemy implements the same alignment-charge pattern |
| GlobinEnemy | globin_enemy.gd | **Globin** | Caves/Catacombs onwards (Chapter 2+) | 2 | 0 (no max) | 6 | HIGH | Isaac Globin introduced in Chapter 2; chases and spawns secondary on death; our GlobinEnemy uses `spawn_enemy_on_death` — exact match |
| HopperEnemy | hopper_enemy.gd | **Leaper** (Hopper subtype) | Caves → Depths (Chapter 2+) | 2 | 4 | 6 | HIGH | Isaac **Hopper** appears in Basement onward, but our HopperEnemy's behavior (jump + flee, attack timer halved when infected) matches the more advanced **Leaper** (Caves onward), not the basic Hopper. Using Leaper as reference. |
| NerdEnemy | nerd_enemy.gd | No direct equivalent (closest: Eye/Maw family) | Caves/Depths (Chapter 2+) | 2 | 0 (no max) | 6 | MEDIUM | Original design. Stationary shooter archetype in Isaac (Eye, Maw) appears in Chapter 2+. NerdEnemy is stationary with `ChaseState: velocity = ZERO` and shoots at player; same archetype. |
| HostEnemy | host_enemy.gd | **Host** | Caves/Catacombs onwards (Chapter 2+) | 2 | 0 (no max) | 5 | HIGH | Isaac Host first appears in Chapter 2; stationary, toggles open/closed, shoots when open; invulnerable when closed. Our HostEnemy mirrors this toggle mechanic (`toggle_state()`, `can_take_damage() → opened`). |
| RapperEnemy | rapper_enemy.gd | No direct equivalent | N/A | 3 | 0 (no max) | 4 | LOW | Original design. Wanders + cross shot pattern + diagonal shots when infected + highest base HP in roster (4). No Isaac enemy shoots cross + diagonal based on infection state. Design decision: Tier 3 because of combined complexity and HP. |

---

## 11. Notes on spawn_tier_max

- `spawn_tier_max = 0` means **no upper limit** — the enemy can appear on any floor >= its min tier
- `spawn_tier_max = 3` means the enemy stops being eligible after tier 3 (early-game retiring)
- `spawn_tier_max = 4` means the enemy can appear up to and including tier 4

Early-game cap rationale: Bully, Mulligan capped at tier 3 to ensure late-floor rooms feel qualitatively different from early ones, consistent with how Isaac's Chapter 1 enemies taper off in later chapters.

---

## 12. Data Model Implemented

Added to each enemy `.gd` file after `speed_multiplier`:

```gdscript
@export var spawn_tier_min: int = N    # Floor tier must be >= this for enemy to be eligible
@export var spawn_tier_max: int = N    # Floor tier must be <= this (0 = no upper limit)
@export var spawn_weight: int = N      # Relative probability when eligible; higher = more frequent
```

**These fields are data-only.** They do not directly modify HP, speed, or behavior.

**Current consumer (implemented 2026-08-19):**
- `world/enemy_spawn_selector.gd` reads `spawn_tier_min`, `spawn_tier_max`, and `spawn_weight`.
- `Room.respawn_enemies()` uses this selector for non-boss combat rooms.
- Tier source is `WorldDungeon.get_current_spawn_tier()` (`Global.floor_number`, clamped).

The selector determines **eligibility** and **relative probability** only. Difficulty scaling remains a separate system (`Global.difficulty_level`, `health_multiplier`, `speed_multiplier`).

**Selection semantics:**
- Selection is weighted by `spawn_weight`.
- Selection is performed **with replacement**; the same enemy can be selected multiple times for one room.
- Enemies outside the current tier are excluded before weighting.
- If a generated combat room has an enemy pool but zero eligible enemies for the current tier, Room now emits a warning and does not silently fall back to out-of-tier baked enemies.

---

## 13. Separation of Concerns (Important)

| System | What it does | Fields involved |
|--------|-------------|-----------------|
| Difficulty scaling | Scales HP and speed based on current run difficulty | `health_multiplier`, `speed_multiplier`, `Global.difficulty_level` |
| Spawn eligibility | Determines which enemies can appear on a given floor/tier | `spawn_tier_min`, `spawn_tier_max` (new) |
| Spawn frequency | Determines relative probability of each eligible enemy | `spawn_weight` (new) |

These are explicitly **independent systems**. A tier-3 enemy on floor 1 would have no health/speed scaling advantage over a tier-1 enemy. Difficulty scaling remains controlled by `Global.difficulty_level`, not spawn tier.

---

## 14. What Requires Gameplay Validation (Provisional Values)

The following values were assigned by design reasoning but **require playtest adjustment**:

| Value | Rationale for Review |
|-------|---------------------|
| `BullyEnemy spawn_tier_max = 3` | May be too restrictive; Gapers appear in many Isaac floors |
| `MulliganEnemy spawn_tier_max = 3` | Mulligans stop at Cellar in Isaac, but our demo may need early content on all floors |
| `HopperEnemy spawn_tier_max = 4` | Based on Leaper floor range; may be adjusted |
| `RapperEnemy spawn_tier_min = 3` | Original design assumption; if combat feels too hard at tier 3, drop to 2 |
| All `spawn_weight` values | No Isaac-derived weight data available; weights are design assumptions |

---

## 15. Decisions That Still Need Human Input

1. **Boss enemy tier**: The eventual boss enemy is not in the current roster. What tier should it be?
2. **Enemy composition rules**: When a room has 3+ enemies, should tier diversity be enforced? (e.g., "at least one tier-1 enemy per room"?)
3. **Spawn weight normalization**: Should spawn weights be normalized to 100 per floor, or just used as relative ratios?
4. **Max tier for BullyEnemy/MulliganEnemy**: Gameplay may reveal that these enemies are fine in later floors even if Isaac retires them. Verify through playtest.
