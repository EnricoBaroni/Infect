# AGENT_CONTEXT.md

Permanent implementation guide for GitHub Copilot Agent sessions on this repository.

Before starting any task, read this document. Then read, in order:
1. [README.md](../../README.md)
2. [ITEM_ARCHITECTURE.md](../../ITEM_ARCHITECTURE.md)
3. [docs/architecture/system-map.md](../architecture/system-map.md)
4. [docs/implementation/backlog.md](backlog.md)
5. [docs/implementation/DUNGEON_GENERATION_DESIGN.md](DUNGEON_GENERATION_DESIGN.md) *(when working on procedural dungeon/floor system)*
6. [docs/implementation/ENEMY_SPAWN_PROGRESSION.md](ENEMY_SPAWN_PROGRESSION.md) *(when working on enemy spawn tiers, room difficulty, or floor generation)*
7. [docs/implementation/ITEM_POOL_DESIGN.md](ITEM_POOL_DESIGN.md) *(when working on item pools, gacha machines, or infection economy)*

If those documents conflict with this one, defer to this document and update it after resolving the conflict.

### Persistent Context Policy

This document and its supporting docs are the primary engineering memory for AI-assisted sessions. Follow these rules every session:

**Before starting work:** Read this document and relevant supporting docs. Do NOT re-audit the entire repository if the relevant subsystem is already documented. Inspect only source files directly affected by the planned change.

**After completing meaningful work:** Update Section 7 (implementation status), Section 8 (next milestone), add pending gameplay tests to PLAYTEST_MATRIX.md, and update backlog.md status. Do not wait for explicit instructions to do this.

**Source of truth hierarchy:** (1) source code, (2) this document + supporting docs, (3) backlog for intended future work, (4) session instructions. If documentation conflicts with code, trust code, investigate, then update docs.

**Validation status vocabulary:** Use exactly these terms: *analyzed/designed*, *implemented*, *statically validated*, *gameplay validated*, *deferred*. Never describe something as gameplay-validated if the game was not actually run.

**Isaac-like composition rule:** An item becoming ineffective when a weapon replacement is active is not automatically a bug. Weapon replacements intentionally change which modifiers apply (e.g., beam doesn't split, ring doesn't bounce). Verify the intended behavior against Isaac mechanics before classifying as a defect.

### How to read this document

This document has two kinds of content:

**Stable** — sections 1–6 and section 16 (Key File Reference). These describe the project vision, system contracts, and architecture decisions. They change only when a deliberate architectural decision is made and recorded in the [Decision Log](#13-decision-log).

**Evolving** — sections 7, 8, 9, 13, and 14. These reflect the current state of the project and must be updated after every completed milestone by the session that completed the work.

> If you are starting a new Agent session, go directly to [Section 8 — Current Recommended Next Milestone](#8-current-recommended-next-milestone) first. Read the rest of the document for context only if the task demands it.

---

## 1. Project Vision

A small top-down action roguelike built in **Godot 4**, inspired by *The Binding of Isaac* and especially its *Tainted Keeper* character.

The objective is **not** to clone Isaac. The objective is to reproduce the architectural principles that give Isaac its replayability — hundreds of items, emergent synergies, scalable content — while building around a unique core mechanic: **Infection**.

### Design pillars
- Fast runs.
- Clear, continuous gameplay — minimal menus, no pausing for decisions.
- High replayability through emergent item builds.
- Strong risk/reward decisions.
- "One more run" feeling.

### Current prototype question
> "Is infecting enemies fun and does it produce interesting combat decisions?"

Nothing should be over-engineered before this question is answered.

---

## 2. Infection System — Core Unique Mechanic

The player has two attack modes, toggled by holding **Space**:

| Mode | Trigger | Effect |
|---|---|---|
| Normal shot | Default | Deals damage. Kills enemies. |
| Infection shot | Hold Space | Sets `infection_power > 0` on the bullet. Does **zero damage**. Infects the enemy. |

### What infection does to enemies
- Sets `InfectionState.is_infected = true` on the enemy.
- Tints the enemy green (`modulate = Color.GREEN`).
- Multiplies movement speed by `INFECTION_MULTIPLIER` (currently `1.5`).
- Calls `on_infected()` — an overridable hook on each enemy subclass.
- Changes the drop value: an infected enemy drops **2 drops** instead of 1.

### Risk/reward logic
- Infecting enemies makes them more dangerous (faster, more aggressive).
- Infected drops yield more currency (drops), enabling more purchases at the Gachapon Machine.
- This is the core Tainted Keeper-inspired decision loop: "Do I infect to earn more, or kill immediately to stay safe?"

---

## 3. Current Architecture

### 3.1 File / folder structure

```
attacks/        AttackData, Bullet, BeamSegment (projectiles)
audio/          Audio assets (SFX, music)
assets/         Sprite imports
docs/           Architecture and implementation documentation
effects/        Visual effect scenes (death, hit, grass)
enemies/        EnemyBase + 10 enemy subclasses
items/
  data/         ItemData .gd class + 295 item .tres resources
  effects/      EffectData base class + reactive + concrete effect classes (see Section 7 for current total)
player/
  player.gd     Player controller
  systems/      InventorySystem, StatEvaluationSystem, EffectRuntimeSystem,
                AttackEvaluationSystem, WeaponSystem, ProjectileSystem
system/         Stats, Global, EventBus, Hitbox, Hurtbox, InfectionState
ui/             StatsUI, Pauser, DeathScreen, DebugMenu
world/          Room, Door, WorldDungeon, WorldDungeonRandom, Drop, UpgradePickup,
                GachaPon Machine, Difficulty Machine, Respawn Machine,
                FloorTransition, Grass, Bush, Tree, Wall
world/templates/ gacha_room_template, combat_room_template_01, boss_room_template
```

### 3.2 System responsibilities

#### `Player` (player/player.gd)
- WASD movement via `input_vector`.
- Directional shooting via `attack_vector` (arrow keys / gamepad equivalent).
- Toggles `infection_mode` from `Input.is_action_pressed("infection_mode")`.
- Delegates firing to `WeaponSystem`.
- Receives damage via `Hurtbox` → `take_hit()`.
- Holds references to `InventorySystem` and `StatEvaluationSystem` as child nodes.
- On `_ready()`, resolves `stats` from `StatEvaluationSystem.current_stats`.

**Player stats used at runtime** (all sourced from the `Stats` resource):
`move_speed`, `damage`, `fire_rate`, `bullet_speed`, `range`, `health`, `max_health`, `luck`.

#### `EnemyBase` (enemies/enemy_base.gd)
- Base class for all enemies (`CharacterBody2D`).
- Owns an `InfectionState` instance and a duplicated `Stats` resource.
- `take_hit()`: if `infection_power > 0`, calls `infect()`; otherwise reduces health.
- `infect()`: sets `InfectionState.is_infected`, tints green, boosts speed, calls `on_infected()` hook.
- Supports generic runtime status payload application (poison, burn, freeze, slow, fear) with stacking, duration handling, and timed updates.
- Supports multiple simultaneous statuses and source stacking through status dictionaries keyed by status id.
- Applies combined visual tint feedback from infection + active statuses.
- `die()`: spawns death effect + drop, then `queue_free()`.
- Provides movement helpers: `chase_player()`, `get_direction_to_player()`, `face_direction()`, `wander()`, `flee_player()`, `jump_randomly()`, `shoot_at_player()`, `shoot_cross()`, `shoot_diagonals()`.
- Enemies check `get_room().active` before acting.

#### `AttackData` (attacks/attack_data.gd)
- `RefCounted` (not a scene node).
- Fields include core projectile data (`direction`, `damage`, `speed`, `max_distance`), capability fields (`pierce_count`, `bounce_count`), weapon-shape data (`weapon_type`, `beam_segment_count`, `beam_segment_spacing`, `beam_segment_duration`), and `appended_shot_offsets: Array[float]` (angles in degrees relative to firing direction, populated by `DirectionalShotAppenderEffect`, consumed by `ProjectileSystem` to spawn additional tear volleys per shot).
- Transfer object between the shooting intent and the physical projectile.

#### `Bullet` (attacks/bullet.gd)
- `Area2D`.
- Reads `AttackData` via `setup_attack(attack_data)`.
- If `infection_shot`, sets `hitbox.infection_power = 1`, `hitbox.damage = 0`, tints green.
- Moves by `direction * SPEED + inherited_velocity * MOVEMENT_INHERITANCE` per frame.
- Destroys itself on distance, wall collision, or Hurtbox contact.

#### `BeamSegment` (attacks/beam_segment.gd)
- `Area2D` beam segment materialized by `ProjectileSystem` for `weapon_type = "segmented_beam"`.
- Uses `Hitbox`/`Hurtbox` like other projectiles.
- Applies infection mode through `AttackData` when enabled.
- Auto-destroys on a short lifetime timer.

#### `Hitbox` (system/hitbox.gd)
- `Area2D`.
- Exports: `damage`, `infection_power`, `knockback_amount`, `knockback_direction`.

#### `Hurtbox` (system/hurtbox.gd)
- `Area2D`.
- Emits signal `hurt(hitbox: Hitbox)` on area entry with a `Hitbox`.

#### `InfectionState` (system/infection_state.gd)
- `RefCounted`.
- Single field: `is_infected: bool`.
- Owned by `EnemyBase`; currently a thin wrapper around a flag.

#### `Stats` (system/stats.gd)
- `Resource`.
- Fields: `health`, `max_health`, `move_speed`, `damage`, `fire_rate`, `bullet_speed`, `range`.
- Emits `health_changed`, `max_health_changed`, `no_health` signals.

#### `Global` (system/Global.gd)
- Autoload singleton.
- Run-state fields: `drops: int`, `difficulty_level: int`, `floor_number: int`, `is_dead: bool`, `recently_moved: bool`.
- Shop fields: `shop_price_multiplier: float`, `shop_flat_discount: int`, `shop_infinite_restock_sources: int`.
- Map-intel fields: `reveal_map_level`, `reveal_room_types_level`, etc. (used by future map system; currently no consumer).
- `reset_run_state()`: resets all per-run transient fields to their defaults. Called by DeathScreen on restart before scene reload.
- `get_effective_shop_cost(base_cost)`: applies shop price multiplier and discount.

#### `ItemData` (items/data/item_data.gd)
- `Resource`.
- Fields: `id: String`, `name: String`, `description: String`, `quality: int`, `pool_tags: PackedStringArray`, `effects: Array[EffectData]`.
- Contains **data only**. No gameplay logic.

#### `EffectData` (items/effects/effect_data.gd)
- `Resource`.
- Single virtual method: `apply_to_stats(stats: Stats)`.
- Base class for all concrete effects.

#### `ReactiveEffectData` + `ReactiveEffectInstance` (items/effects/reactive_effect_data.gd, items/effects/reactive_effect_instance.gd)
- `ReactiveEffectData` extends `EffectData` and provides `create_runtime(player)`.
- `ReactiveEffectInstance` encapsulates runtime behavior with `activate()` / `deactivate()`.
- Reactive effects subscribe to `EventBus` through runtime instances, not through `InventorySystem` or `StatEvaluationSystem`.

#### `AttackEffectData` (items/effects/attack_effect_data.gd)
- Extends `EffectData` with `apply_to_attack_data(attack_data)`.
- Allows item effects to modify projectile capabilities without item-specific logic in combat systems.

#### `SetWeaponTypeEffect` (items/effects/set_weapon_type_effect.gd)
- Extends `AttackEffectData`.
- Replaces `attack_data.weapon_type` and sets reusable archetype parameters (beam, blade, ring, orb, orbit, lob, elastic).
- Enables weapon replacement as data, not as conditional code in systems.

#### Concrete effect classes (all in items/effects/)
| Class | File | What it does |
|---|---|---|
| `DamageUpEffect` | damage_up_effect.gd | `stats.damage += amount` |
| `MoveSpeedUpEffect` | move_speed_up_effect.gd | `stats.move_speed += amount` |
| `BulletSpeedUpEffect` | bullet_speed_up_effect.gd | `stats.bullet_speed += amount` |
| `FireRateUpEffect` | fire_rate_up_effect.gd | `stats.fire_rate = max(min, fire_rate - amount)` |
| `RangeUpEffect` | range_up_effect.gd | `stats.range += amount` |
| `SpawnDropsOnDamageEffect` | spawn_drops_on_damage_effect.gd | Creates runtime behavior that grants drops when player damage event is emitted |
| `GainDropsOnKillEffect` | gain_drops_on_kill_effect.gd | Creates runtime behavior that grants drops on enemy kill events (with optional infected bonus) |
| `PiercingProjectilesEffect` | piercing_projectiles_effect.gd | `attack_data.pierce_count += extra_pierces` |
| `BouncyProjectilesEffect` | bouncy_projectiles_effect.gd | `attack_data.bounce_count += extra_bounces` |
| `HomingProjectilesEffect` | homing_projectiles_effect.gd | Adds homing strength/radius steering to tears |
| `SplitShotsEffect` | split_shots_effect.gd | Adds additional spread shots through ProjectileSystem |
| `SpectralProjectilesEffect` | spectral_projectiles_effect.gd | Allows tears to pass through obstacle body collisions |
| `CriticalHitsEffect` | critical_hits_effect.gd | Adds crit chance/multiplier to `AttackData` and resolves per projectile/beam segment |
| `KnockbackModifierEffect` | knockback_modifier_effect.gd | Modifies projectile/beam hitbox knockback using multiplier + flat bonus |
| `ExplosiveProjectilesEffect` | explosive_projectiles_effect.gd | Adds impact explosions with radius/damage scaling and optional infection inheritance |
| `PoisonStatusEffect` | poison_status_effect.gd | Appends poison status payload with DoT and stack rule config |
| `BurnStatusEffect` | burn_status_effect.gd | Appends burn status payload with DoT and stack rule config |
| `FreezeStatusEffect` | freeze_status_effect.gd | Appends freeze status payload with movement-lock multiplier config |
| `SlowStatusEffect` | slow_status_effect.gd | Appends slow status payload with movement multiplier config |
| `FearStatusEffect` | fear_status_effect.gd | Appends fear status payload that inverts chase intent |
| `CompanionFormationEffect` | companion_formation_effect.gd | Spawns composable orbitals/followers through `CompanionSystem` via reactive runtime |
| `SetWeaponTypeEffect` | set_weapon_type_effect.gd | Replaces `attack_data.weapon_type` and configures reusable archetype parameters |
| `BeamLengthUpEffect` | beam_length_up_effect.gd | Increases beam segment count/duration via `AttackData` |
| `DirectionalShotAppenderEffect` | directional_shot_appender_effect.gd | Appends angle offsets (degrees) to `attack_data.appended_shot_offsets`; `ProjectileSystem` spawns additional tear volleys at those angles per shot. Supports composition with split/pierce/homing/etc. Tear weapon only. |

#### `InventorySystem` (player/systems/inventory_system.gd)
- Child node of Player.
- Stores `passive_items: Array[ItemData]`, `active_item: ItemData`, `trinkets: Array[ItemData]`.
- Emits `passive_item_added` / `passive_item_removed` signals.
- On `add_passive_item()` / `remove_passive_item()`, triggers `StatEvaluationSystem.recalculate()`.
- **Does not** calculate stats or execute gameplay.

#### `EffectRuntimeSystem` (player/systems/effect_runtime_system.gd)
- Child node of Player (created at runtime if missing).
- Listens to `InventorySystem` item-added/item-removed signals.
- Creates and activates runtime instances for effects that are `ReactiveEffectData`.
- Deactivates runtime instances when items are removed.

#### `CompanionSystem` (player/systems/companion_system.gd)
- Child node of Player (created at runtime if missing).
- Spawns and removes reusable companion entities keyed by source runtime.
- Supports orbitals and passive followers with configurable count, speed, radius/distance, and contact damage.

#### `AttackEvaluationSystem` (player/systems/attack_evaluation_system.gd)
- Child node of Player (created at runtime if missing).
- Reads inventory effects that are `AttackEffectData`.
- Applies attack modifiers to `AttackData` before projectile spawn.

#### `WeaponSystem` (player/systems/weapon_system.gd)
- Child node of Player (created at runtime if missing).
- Receives fire intent and builds `AttackData`.
- Delegates projectile materialization to `ProjectileSystem`.
- Owns fire-rate timing via player's `FireRate` timer.
- Contains no item-specific logic.

#### `ProjectileSystem` (player/systems/projectile_system.gd)
- Child node of Player (created at runtime if missing).
- Materializes `AttackData` into projectile entities.
- Keeps projectile spawn/configuration out of `WeaponSystem`.

#### `StatEvaluationSystem` (player/systems/stat_evaluation_system.gd)
- Child node of Player.
- Exports: `base_stats: Stats`, `current_stats: Stats`.
- `recalculate()`: resets `current_stats` from `base_stats`, iterates `inventory.passive_items`, calls `effect.apply_to_stats(current_stats)` for each effect, then restores runtime health.
- Player's `stats` reference always points to `current_stats`.

#### `Room` (world/room.gd)
- Manages an `Enemies` node and four `Door` nodes.
- Supports room roles via `room_type` enum: `GACHA`, `COMBAT`, `BOSS`.
- If `combat_room`, doors close while enemies exist; open when cleared.
- Boss rooms notify `WorldDungeon` when cleared (`notify_boss_room_cleared`) so floor transition can be spawned.
- Supports `respawn_enemies()` using:
   - boss rooms: stored templates + difficulty multipliers;
   - non-boss combat rooms: tier-gated weighted selection (`EnemySpawnSelector`) + difficulty multipliers.

#### `Door` (world/door.gd + world/door.tscn)
- Teleports player to a target room (`tp_position` node path).
- Animates camera to target via Tween.
- Calls `current_room.deactivate()` / `destination_room.activate()`.
- Exposes semantic `connection_role` (`NONE`, `FORWARD`, `BACKWARD`) so generators do not depend on child node names.

**Door architecture invariant: transition detection and physical blocking are SEPARATE responsibilities.**

| Node | Type | Purpose |
|------|------|---------|
| `TransitionArea` | `Area2D` (`collision_layer=0, collision_mask=2`) | Detects player entering the open door gap; performs the room transition. Does NOT act as a physical obstacle. |
| `BlockerBody` | `StaticBody2D` (`collision_layer=1, collision_mask=0`) | Acts as a physical wall when the door is CLOSED. Blocks the same layers as `wall.tscn`. Enabled/disabled by `CollisionPolygon2D.disabled`. |

**State semantics:**

| State | `enabled` | `BlockerBody` | `TransitionArea` | Effect |
|-------|-----------|---------------|-----------------|--------|
| CLOSED | `false` | collision active (`disabled=false`) | present, but player cannot reach it | Physical wall; projectiles bounce/destroy on impact; player cannot enter. |
| OPEN | `true` | collision inactive (`disabled=true`) | active | Player can pass through; on entry performs room transition. |

**Collision layer convention (matches `wall.tscn`):**
- `BlockerBody.collision_layer = 1` — matches `wall.tscn`'s `StaticBody2D` (default layer 1)
- `BlockerBody.collision_mask = 0` — walls do not need to detect others; others detect walls
- `Bullet.collision_mask = 65` (layers 1 and 7) includes layer 1 → bullet detects the blocker automatically
- `Player.collision_layer = 2` → `TransitionArea.collision_mask = 2` detects the player

**Why projectile code must NOT contain Door-specific logic:**
- Bullet's `_on_body_entered()` fires for ANY `PhysicsBody2D` in its collision mask (layer 1). `BlockerBody` is on layer 1. Therefore closed doors already behave identically to walls for all projectiles (bounce, destroy, beam segments, explosion triggers). No projectile needs to know it hit a door specifically.
- Adding `if body is Door` would reintroduce coupling that the architecture is explicitly designed to avoid.

**`_ready()` initial state:** `blocker_shape.disabled = enabled` — since `enabled` defaults to `false`, a freshly instantiated Door starts CLOSED (blocker active). Room calls `door.open()`/`door.close()` to change state.

**Never manipulate `BlockerBody` directly from outside `door.gd`.** The `open()` and `close()` methods are the only authorized state changers.

#### `WorldDungeon` (world/world_dungeon.gd)
- Holds references to all rooms (currently 5: Room1–Room5).
- Discovers enemy roster (`res://enemies/*_enemy.tscn`) and injects it into non-boss combat rooms.
- Activates starting room on `_ready()` and performs initial respawn under current floor tier.
- Exposes `respawn_all_enemies()`.
- Exposes `get_current_spawn_tier()` from `Global.floor_number`.
- Handles boss clear progression (`notify_boss_room_cleared`) and spawns `FloorTransition` object.
- Handles floor advancement (`advance_to_next_floor`): increments floor/difficulty, respawns rooms, returns player to gacha room.

#### `WorldDungeonRandom` (world/world_dungeon_random.gd)
- Isolated experimental implementation; does NOT replace manual `WorldDungeon`.
- Builds each floor at runtime using templates:
   - gacha template,
   - random combat template picks (repetition allowed),
   - boss template.
- Generates linear chain only: `GACHA -> COMBAT x N -> BOSS`.
- Reuses `Door` transitions by wiring `tp_position` at runtime through semantic door roles (`FORWARD` / `BACKWARD`).
- Reuses `Room.respawn_enemies()` + `EnemySpawnSelector` for tier-gated weighted enemy selection.
- Reuses `FloorTransition` by exposing `advance_to_next_floor()`.
- Uses standard room spacing convention `352 x 216` world units and currently spaces generated rooms by `Vector2(352, 0)`.
- Owns the shared generation RNG for template selection, spawn-count rolls, and weighted enemy picks.
- Designer-facing setup, authoring workflow, and return-to-Godot operational steps are documented in `docs/implementation/ROOM_GENERATION_DESIGN.md`.

#### `Drop` (world/drop.gd)
- Spawned by `EnemyBase.die()`.
- `setup(is_infected)`: determines sprite frame and drop value.
- On player body entry: `Global.drops += 2` (infected) or `+= 1` (normal).
- Auto-destroys on timer.

#### `UpgradePickup` (world/upgrade_pickup.gd)
- `Area2D` pickup in the world.
- Holds an `ItemData` reference.
- On player entry: calls `player.inventory.add_passive_item(item_data)`.

#### `GachaPonMachine` (world/gachapon_machine.gd)
- Press E to purchase a random item from the passive item pool.
- Costs `cost` drops (`Global.drops -= cost`).
- Loads all `.tres` files from `res://items/data/` at runtime to build the pool.
- Spawns an `UpgradePickup` scene next to itself.

#### `DifficultyMachine` (world/difficulty_machine.gd)
- Press E to increment `Global.difficulty_level`.

#### `RespawnMachine` (world/respawn_machine.gd)
- Press E to call `world_dungeon.respawn_all_enemies()` at current difficulty.

#### `StatsUI` (ui/stats_ui.gd)
- Binds to player's `Stats` resource via signals.
- Displays health hearts, damage, fire rate, speed, range, drops.

#### `Pauser` (ui/pauser.gd)
- Press `ui_cancel` (ESC) to toggle `get_tree().paused`.

#### `DebugMenu` (ui/debug_menu.gd) — **DEVELOPMENT ONLY**

**Purpose:** Expedite gameplay testing during development by allowing the developer to acquire specific items without waiting for natural drops.

**Constraints (Non-negotiable):**
- Development-only — must not influence normal item generation, drop pools, economy, room progression, or any gameplay system
- Uses only the existing `InventorySystem.add_passive_item()` acquisition path
- No hardcoded item lists — discovers all `.tres` item resources dynamically from `res://items/data/`
- Does not modify runtime item generation code
- Respects existing duplicate/stacking behavior (same semantics as pickup)

**Input:**
- Press **F1** to toggle the debug menu (CanvasLayer on top of gameplay).

**UI Elements:**
- Title bar: `"DEBUG MENU [F1 toggle]"`
- **"+ 10 Drops"** button — adds 10 to `Global.drops` for economy testing
- Item list (scrollable):
  - ~290 buttons (dynamically populated)
  - Each button labeled with item name (or filename if name is empty)
  - Tooltip shows item description
  - Clicking a button calls `player.inventory.add_passive_item(item_data.duplicate())`

**Behavior:**
- Menu opens/closes with F1; does not pause gameplay while open
- Each item acquisition fires the full item initialization pipeline (effects register, stats recalculate, UI updates)
- Menu can be opened and closed during combat without affecting active gameplay state
- Remains present in all builds as a development tool (no #ifdef or conditionals needed; it's a debug-only artifact)

**Item Discovery Mechanism:**
- On `_ready()`, scans `res://items/data/` directory
- Loads all `.tres` files matching `is ItemData`
- Sorts alphabetically; displays count
- No hardcoding of item names or IDs

**Verification:**
- Adding a new `.tres` item to `items/data/` automatically makes it available in the debug menu (no code changes needed)
- Item acquisition respects the existing inventory pipeline: `.duplicate()` cloning, effect runtime instantiation, stat recalculation

---

## 4. Enemy Roster

| Class | Color | Movement | Attack | On Infected | HP | Speed |
|---|---|---|---|---|---|---|
| `BatEnemy` | Default | Chase (navigation) | None | Speed ×1.5 | 2 | 30 |
| `BullyEnemy` | Red | Chase (navigation agent) | None | Speed ×1.5 | — | 15 |
| `ChargerEnemy` | Purple | Wander → align → charge | None | Speed ×1.5 | — | 20 |
| `GlobinEnemy` | Black | Chase | None; spawns a transformed enemy on death | Speed ×1.5 | — | 30 |
| `HopperEnemy` | Pink | Jump randomly; flee when close | None | Speed ×1.5, attack timer ×0.5 | — | 20 |
| `HostEnemy` | Saddle Brown / Red | Stationary; toggles open/closed | Shoots at player when open | Speed ×1.5, attack timer ×0.5 | — | 12 |
| `MulliganEnemy` | Lime Green | Wander; flee when close | (start_attack is stub) | Speed ×1.5, attack timer ×0.5 | — | 20 |
| `NerdEnemy` | Yellow | Stationary | Shoots at player | Speed ×1.5 | 3 | 30 |
| `PooterEnemy` | Orange | Wander | Shoots at player | Speed ×1.5, attack timer ×0.5 | — | 12 |
| `RapperEnemy` | Cyan | Wander | Shoots cross pattern; **when infected**: also shoots diagonals | Speed ×1.5 | 4 | 8 |

*HP "—" = uses Stats resource default (not explicitly overridden in .tscn). Speed = stats.move_speed base value.*

All enemy subclasses share: `health_multiplier`, `speed_multiplier` (applied by Room on respawn based on `Global.difficulty_level`).

### Enemy Spawn Tier Classification (IMPLEMENTED — NOT GAMEPLAY VALIDATED)

Added to all 10 enemy `.gd` files. Based on Isaac Rebirth wiki research (confirmed floor appearances) + design decisions for enemies without direct Isaac equivalents.

Full classification table and methodology: [docs/implementation/ENEMY_SPAWN_PROGRESSION.md](ENEMY_SPAWN_PROGRESSION.md)

| Enemy | spawn_tier_min | spawn_tier_max | spawn_weight | Isaac Reference | Confidence |
|-------|---------------|----------------|-------------|-----------------|------------|
| `BatEnemy` | 1 | 0 (no max) | 10 | Fly/Attack Fly (Basement+) | HIGH |
| `BullyEnemy` | 1 | 3 | 8 | Gaper (Basement/Cellar only) | HIGH |
| `MulliganEnemy` | 1 | 3 | 7 | Mulligan (Basement/Cellar only) | HIGH |
| `PooterEnemy` | 1 | 4 | 8 | Pooter (Basement–Depths) | HIGH |
| `ChargerEnemy` | 2 | 0 (no max) | 7 | Charger (Caves+) | HIGH |
| `GlobinEnemy` | 2 | 0 (no max) | 6 | Globin (Caves+) | HIGH |
| `HopperEnemy` | 2 | 4 | 6 | Leaper (Caves–Depths) | HIGH |
| `NerdEnemy` | 2 | 0 (no max) | 6 | Eye/Maw archetype (design decision) | MEDIUM |
| `HostEnemy` | 2 | 0 (no max) | 5 | Host (Caves+) | HIGH |
| `RapperEnemy` | 3 | 0 (no max) | 4 | No equivalent — original design | LOW |

**Tier scale:** 1 = Floor 1 beatable without items. 5 = Reserved for endgame.  
**spawn_tier_max = 0** means no upper limit (enemy eligible from min tier onward).  
All weights are provisional — require playtest adjustment.

---

## 5. Item Content (Current)

**290 passive item `.tres` resources** exist in `items/data/`. They are loaded dynamically by `GachaPonMachine`. The effect system supports:

| Effect type | Stat modified |
|---|---|
| `DamageUpEffect` | `damage` |
| `MoveSpeedUpEffect` | `move_speed` |
| `BulletSpeedUpEffect` | `bullet_speed` |
| `FireRateUpEffect` | `fire_rate` (lower = faster) |
| `RangeUpEffect` | `range` |

Reactive support now exists through:
- `SpawnDropsOnDamageEffect` + `SpawnDropsOnDamageRuntime` (Piggy Bank behavior).
- `GainDropsOnKillEffect` + `GainDropsOnKillRuntime` (economy rewards on enemy kills, optional infected bonus).
- `CompanionFormationEffect` + `CompanionFormationRuntime` (configurable orbitals and passive followers via `CompanionSystem`).

Projectile capability support now exists through:
- `PiercingProjectilesEffect` (adds `pierce_count` to `AttackData`).
- `BouncyProjectilesEffect` (adds `bounce_count` to `AttackData`).
- `HomingProjectilesEffect` (adds homing steering via `homing_strength` and `homing_radius`).
- `SplitShotsEffect` (adds projectile fan-out via `split_count` and `split_spread_degrees`).
- `SpectralProjectilesEffect` (marks tears as spectral so they ignore obstacle body collisions).
- `CriticalHitsEffect` (adds `crit_chance` and `crit_multiplier`; resolved per tear and beam segment).
- `KnockbackModifierEffect` (adds `knockback_multiplier` and `knockback_flat_bonus` to attack payloads).
- `ExplosiveProjectilesEffect` (adds `explosion_radius`, `explosion_damage_multiplier`, `explosion_inherits_infection` for AoE impact payloads).
- Status payload effects (`PoisonStatusEffect`, `BurnStatusEffect`, `FreezeStatusEffect`, `SlowStatusEffect`, `FearStatusEffect`) with generic runtime processing in `EnemyBase`.

Weapon replacement support now exists through:
- `SetWeaponTypeEffect` (switches weapon archetype by writing `attack_data.weapon_type`).
- `Brimstone` item (segmented beam weapon replacement).

Advanced weapon archetype support now exists through reusable `ProjectileSystem` paths:
- `returning_blade` (recalled melee projectile with outbound/return phases).
- `expanding_ring` (radial ring wave with timed contact ticks).
- `remote_orb` (persistent steerable orb).
- `orbit_shot` (player-centered orbital shot trajectories).
- `lob_burst` (gravity lob with fragment burst on impact).
- `elastic_ricochet` (high-bounce tears with retention/chaos tuning).

Items can compose multiple effects. The `StatEvaluationSystem` applies them all on recalculate.

---

## 6. Architecture Decisions

These decisions are **stable**. They do not change because a task is inconvenient or a shortcut is tempting. If a decision genuinely needs to change, record it in the [Decision Log](#13-decision-log) first, then update `docs/architecture/system-map.md`.

### Why these decisions exist

The entire architecture is built on one principle from `ITEM_ARCHITECTURE.md`:

> "Gameplay belongs to Systems. Items modify Systems. Systems never belong to Items."

Every rule below is a concrete expression of that principle applied to this codebase.

### Decision: Stats are always rebuilt from base, never mutated in place.
**Rule:** Never mutate `Stats` directly from a pickup or effect outside of `StatEvaluationSystem.recalculate()`.
- Correct flow: `InventorySystem.add_passive_item()` → `StatEvaluationSystem.recalculate()` → `EffectData.apply_to_stats()`.
- **Why:** Mutable stats drift. After ten pickups, no one can predict the final value without tracing all mutations. A recalculate loop from a fixed base means the state is always inspectable and rebuildable. This is the architectural property that makes hundreds of items possible without special-case code.

### Decision: InventorySystem is a container, not a coordinator.
**Rule:** `InventorySystem` must never calculate stats, shoot, or spawn entities.
- **Why:** When inventory starts executing gameplay, it becomes impossible to test or reason about independently. It also creates hidden ordering dependencies between items. A container that only stores and notifies keeps all execution in systems, where it belongs.

### Decision: StatEvaluationSystem is the single source of final player stats.
**Rule:** `StatEvaluationSystem` is the only place that produces the runtime stat values the player acts on.
- **Why:** Multiple writers produce inconsistent state. One writer, one reader, one clear moment of recalculation. Any stat is inspectable at any time by calling `recalculate()`.

### Decision: AttackData is the handoff between intent and physics.
**Rule:** `AttackData` is the transfer object between shooting intent and the physical projectile. The player (or future `WeaponSystem`) builds it; the bullet reads it.
- **Why:** This decouples the shooter from the projectile. A `WeaponSystem` can produce `AttackData` without knowing about `Bullet`. A `ProjectileSystem` can interpret `AttackData` without knowing about the player. The seam is intentional and load-bearing — it is the insertion point for all future weapon variety.

### Decision: ItemData is pure data.
**Rule:** `ItemData` contains no gameplay logic. Only resource exports.
- **Why:** When items contain behavior, items become order-dependent and stateful. Two items that both modify the same system create hidden coupling. Data-only items let systems own behavior, which is what makes emergent synergies possible without explicit synergy code.

### Decision: EffectData subclasses communicate exclusively through apply_to_stats().
**Rule:** `EffectData` subclasses call `apply_to_stats(stats)` only. No direct field writes outside of `Stats`, no signaling, no spawning.
- **Why:** This is the only approved seam between content and system. Widening it is the first step toward item-specific conditional logic. Every widening of this seam must be justified and recorded in the Decision Log.

### Decision: InfectionState is an explicit object, not a raw bool.
**Rule:** `InfectionState` must remain a typed object on the enemy, not a loose `var infected := false` scattered across scripts.
- **Why:** When infection gains sub-states (duration, intensity, source, propagation), a bare bool forces a breaking refactor across every enemy. The object preserves that upgrade path at zero cost today.

### Decision: Player is not a global coordinator.
**Rule:** `Player` is responsible for movement, input, shooting, and receiving damage — nothing more.
- **Why:** When the Player starts brokering between all systems, every system becomes coupled to it. Extracting `WeaponSystem` and `ProjectileSystem` later becomes surgery on a tightly coupled node rather than a clean insertion.

### Decision: EnemyBase is the single source of enemy behavior.
**Rule:** All enemies extend `EnemyBase`. Subclasses override hooks (`on_hit`, `on_infected`); they do not rewrite the base.
- **Why:** Ten enemy types. Without a shared base, the same bug must be fixed in ten places. The hook pattern is the safe extension point that keeps each enemy subclass small.

### Prohibited patterns
- `if has_brimstone:` or any item-specific conditional anywhere in a system.
- `player.damage += 1` called from any pickup, effect, or room script.
- Hardcoded item IDs in system code.
- New top-level managers (EventBus, WeaponController, CombatResolver, EnemyStatusModel, RoomEncounterController) unless a completed milestone demonstrates they are necessary.
- Skipping `StatEvaluationSystem.recalculate()` after inventory changes.

### Structural rules
- Keep the project **playable after every task**.
- Work in **small, verifiable slices**.
- Do not add systems for hypothetical future needs.
- If a decision changes, record it in the [Decision Log](#13-decision-log) and update `docs/architecture/system-map.md`.
- If a slice completes, update `docs/implementation/backlog.md`.

---

## 7. Current Implementation Status

### Completed (relative to backlog and ITEM_ARCHITECTURE phases)

| Item | Status | Evidence |
|---|---|---|
| `AttackData` as transfer object | ✅ Done | `attacks/attack_data.gd` — `RefCounted`, core + capability + weapon-shape fields |
| Bullet reads `AttackData` via `setup_attack()` | ✅ Done | `attacks/bullet.gd` |
| Infection shot via `infection_mode` flag | ✅ Done | `player/player.gd`, `attacks/bullet.gd` |
| `InfectionState` as explicit object | ✅ Done | `system/infection_state.gd` (thin; one bool) |
| Enemy infected state and speed boost | ✅ Done | `enemies/enemy_base.gd` `infect()` |
| Enemy behavior hooks via `on_infected()` | ✅ Done | Overridden in PooterEnemy, HopperEnemy, MulliganEnemy, RapperEnemy, HostEnemy |
| `ItemData` as Resource | ✅ Done | `items/data/item_data.gd` |
| `EffectData` base class | ✅ Done | `items/effects/effect_data.gd` |
| 5 concrete effect types | ✅ Done | DamageUp, MoveSpeedUp, BulletSpeedUp, FireRateUp, RangeUp |
| 290 item `.tres` resources | ✅ Done | `items/data/*.tres` |
| `InventorySystem` (container) | ✅ Done | `player/systems/inventory_system.gd` |
| `StatEvaluationSystem` (recalculate loop) | ✅ Done | `player/systems/stat_evaluation_system.gd` |
| `UpgradePickup` connects item to inventory | ✅ Done | `world/upgrade_pickup.gd` |
| `GachaPonMachine` (item shop) | ✅ Done | `world/gachapon_machine.gd` |
| Drop system with infected bonus | ✅ Done | `world/drop.gd` |
| Room door loop | ✅ Done | `world/room.gd`, `world/door.gd` |
| Multi-room dungeon (5 rooms) | ✅ Done | `world/world_dungeon.gd` |
| Difficulty scaling on respawn | ✅ Done | `world/room.gd` + `world/difficulty_machine.gd` |
| StatsUI bound to player stats | ✅ Done | `ui/stats_ui.gd` |
| Pause system | ✅ Done | `ui/pauser.gd` |
| EventBus autoload with candidate signals | ✅ Done | `system/event_bus.gd`, `project.godot` |
| Event emission wiring (damage, kills, rooms, projectiles, item pickup) | ✅ Done | `player/player.gd`, `enemies/enemy_base.gd`, `world/room.gd`, `attacks/bullet.gd`, `world/upgrade_pickup.gd` |
| Reactive effect runtime layer | ✅ Done | `items/effects/reactive_effect_data.gd`, `items/effects/reactive_effect_instance.gd`, `player/systems/effect_runtime_system.gd` |
| First reactive item (Piggy Bank) | ✅ Done | `items/effects/spawn_drops_on_damage_effect.gd`, `items/effects/spawn_drops_on_damage_runtime.gd`, `items/data/piggy_bank.tres` |
| WeaponSystem extraction from Player | ✅ Done | `player/systems/weapon_system.gd`, `player/player.gd` |
| ProjectileSystem and AttackEvaluationSystem | ✅ Done | `player/systems/projectile_system.gd`, `player/systems/attack_evaluation_system.gd`, `player/systems/weapon_system.gd` |
| First projectile capabilities (pierce + bounce) | ✅ Done | `attacks/attack_data.gd`, `attacks/bullet.gd`, `items/effects/attack_effect_data.gd`, `items/effects/piercing_projectiles_effect.gd`, `items/effects/bouncy_projectiles_effect.gd`, `items/data/needle_eye.tres`, `items/data/rubber_coat.tres` |
| Segmented beam projectile pipeline | ✅ Done | `attacks/beam_segment.gd`, `attacks/beam_segment.tscn`, `player/systems/projectile_system.gd`, `attacks/attack_data.gd` |
| Weapon replacement via data (Brimstone) | ✅ Done | `items/effects/set_weapon_type_effect.gd`, `items/data/brimstone.tres`, `player/systems/weapon_system.gd` |
| Follow-up beam scaling content | ✅ Done | `items/effects/beam_length_up_effect.gd`, `items/data/coiled_cable.tres` |
| Content batch 1 (10 passive items) | ✅ Done | `items/data/adrenal_shot.tres`, `items/data/drift_shoes.tres`, `items/data/iron_lung.tres`, `items/data/marrow_needle.tres`, `items/data/overclock_cell.tres`, `items/data/prism_cap.tres`, `items/data/turbine_core.tres`, `items/data/lucky_barrel.tres`, `items/data/blood_transfusion.tres`, `items/data/glass_cannon.tres` |
| Content batch 2 (10 passive items) | ✅ Done | `items/data/phase_anchor.tres`, `items/data/toxic_tread.tres`, `items/data/hollow_scope.tres`, `items/data/recoil_coil.tres`, `items/data/storm_syringe.tres`, `items/data/chain_spindle.tres`, `items/data/echo_heart.tres`, `items/data/snap_line.tres`, `items/data/crimson_gear.tres`, `items/data/orbit_pin.tres` |
| Mechanic batch A - Homing (5 items) | ✅ Done | `items/effects/homing_projectiles_effect.gd`, `items/data/seeker_eye.tres`, `items/data/magnet_tear.tres`, `items/data/neural_compass.tres`, `items/data/hunter_thread.tres`, `items/data/lockon_implant.tres` |
| Mechanic batch B - Split shots (5 items) | ✅ Done | `items/effects/split_shots_effect.gd`, `items/data/forked_chamber.tres`, `items/data/tri_spine.tres`, `items/data/scatter_core.tres`, `items/data/twin_fang.tres`, `items/data/prism_fork.tres` |
| Mechanic batch C - Spectral (5 items) | ✅ Done | `items/effects/spectral_projectiles_effect.gd`, `items/data/ghost_lens.tres`, `items/data/phase_plasma.tres`, `items/data/wraith_shell.tres`, `items/data/void_iris.tres`, `items/data/eclipse_filament.tres` |
| Mechanic batch D - Critical hits (5 items) | ✅ Done | `items/effects/critical_hits_effect.gd`, `attacks/attack_data.gd`, `attacks/bullet.gd`, `attacks/beam_segment.gd`, `items/data/deadeye_chip.tres`, `items/data/lucky_fang.tres`, `items/data/shatterpoint.tres`, `items/data/boom_or_bust.tres`, `items/data/executioner_lens.tres` |
| Mechanic batch E - Knockback modifiers (5 items) | ✅ Done | `items/effects/knockback_modifier_effect.gd`, `attacks/attack_data.gd`, `attacks/bullet.gd`, `attacks/beam_segment.gd`, `items/data/impact_driver.tres`, `items/data/pinball_gland.tres`, `items/data/riot_pulse.tres`, `items/data/vacuum_rounds.tres`, `items/data/hurricane_nail.tres` |
| Mechanic batch F - Kill-triggered economy (5 items) | ✅ Done | `items/effects/gain_drops_on_kill_effect.gd`, `items/effects/gain_drops_on_kill_runtime.gd`, `items/data/blood_dividend.tres`, `items/data/green_bounty.tres`, `items/data/loan_shark_tooth.tres`, `items/data/thrift_crown.tres`, `items/data/fever_market.tres` |
| Mechanic batch G - Explosions (5 items) | ✅ Done | `items/effects/explosive_projectiles_effect.gd`, `attacks/attack_data.gd`, `attacks/bullet.gd`, `attacks/beam_segment.gd`, `player/systems/projectile_system.gd`, `items/data/blast_cap.tres`, `items/data/cluster_weld.tres`, `items/data/seeker_mine.tres`, `items/data/septic_mortar.tres`, `items/data/hazard_fuse.tres` |
| Status framework runtime integration | ✅ Done | `system/status_payload.gd`, `system/hitbox.gd`, `attacks/attack_data.gd`, `attacks/bullet.gd`, `attacks/beam_segment.gd`, `enemies/enemy_base.gd`, `player/systems/projectile_system.gd` |
| Mechanic batch H - Poison statuses (5 items) | ✅ Done | `items/effects/status_attack_effect.gd`, `items/effects/poison_status_effect.gd`, `items/data/venom_sac.tres`, `items/data/septic_needle.tres`, `items/data/miasma_fan.tres`, `items/data/tracker_toxin.tres`, `items/data/black_bile.tres` |
| Mechanic batch I - Burn statuses (5 items) | ✅ Done | `items/effects/burn_status_effect.gd`, `items/data/ember_core.tres`, `items/data/cinder_coil.tres`, `items/data/blast_furnace.tres`, `items/data/wildfire_gland.tres`, `items/data/scorched_lung.tres` |
| Mechanic batch J - Freeze statuses (5 items) | ✅ Done | `items/effects/freeze_status_effect.gd`, `items/data/frost_tip.tres`, `items/data/glacier_shard.tres`, `items/data/rime_mine.tres`, `items/data/winter_scope.tres`, `items/data/brittle_heart.tres` |
| Mechanic batch K - Slow statuses (5 items) | ✅ Done | `items/effects/slow_status_effect.gd`, `items/data/tar_lens.tres`, `items/data/molasses_beam.tres`, `items/data/drag_net.tres`, `items/data/heavy_snow.tres`, `items/data/time_tax.tres` |
| Mechanic batch L - Fear statuses (5 items) | ✅ Done | `items/effects/fear_status_effect.gd`, `items/data/panic_spores.tres`, `items/data/coward_hook.tres`, `items/data/dread_compass.tres`, `items/data/nightmare_fork.tres`, `items/data/horror_dividend.tres` |
| Companion system runtime integration | ✅ Done | `player/systems/companion_system.gd`, `companions/orbital_companion.gd`, `companions/orbital_companion.tscn`, `companions/passive_follower.gd`, `companions/passive_follower.tscn`, `items/effects/companion_formation_effect.gd`, `items/effects/companion_formation_runtime.gd`, `player/player.gd` |
| Mechanic batch M - Orbitals and passive companions (10 items) | ✅ Done | `items/data/guardian_halo.tres`, `items/data/twin_satellites.tres`, `items/data/razor_ring.tres`, `items/data/squire_pod.tres`, `items/data/pair_protocol.tres`, `items/data/shepherd_orbit.tres`, `items/data/swarm_axis.tres`, `items/data/wide_guard.tres`, `items/data/blood_kites.tres`, `items/data/bulwark_hive.tres` |
| Advanced weapon archetype runtime integration | ✅ Done | `attacks/returning_blade.gd`, `attacks/returning_blade.tscn`, `attacks/expanding_ring.gd`, `attacks/expanding_ring.tscn`, `attacks/remote_orb.gd`, `attacks/remote_orb.tscn`, `attacks/orbit_shot.gd`, `attacks/orbit_shot.tscn`, `attacks/lob_burst_projectile.gd`, `attacks/lob_burst_projectile.tscn`, `player/systems/projectile_system.gd`, `attacks/attack_data.gd`, `attacks/bullet.gd`, `items/effects/set_weapon_type_effect.gd` |
| Mechanic batch N - Returning blade family (5 items) | ✅ Done | `items/data/iron_dagger.tres`, `items/data/blood_scythe.tres`, `items/data/serrated_arc.tres`, `items/data/recall_fang.tres`, `items/data/butcher_pin.tres` |
| Mechanic batch O - Expanding ring family (5 items) | ✅ Done | `items/data/ion_loop.tres`, `items/data/corona_drive.tres`, `items/data/hollow_torus.tres`, `items/data/plasma_halo.tres`, `items/data/overcharge_ring.tres` |
| Mechanic batch P - Remote orb family (5 items) | ✅ Done | `items/data/neural_orb.tres`, `items/data/pilot_core.tres`, `items/data/guided_nucleus.tres`, `items/data/drift_brain.tres`, `items/data/orbit_director.tres` |
| Mechanic batch Q - Orbit shot family (5 items) | ✅ Done | `items/data/star_sling.tres`, `items/data/satellite_vein.tres`, `items/data/micro_planetarium.tres`, `items/data/gravity_yoyo.tres`, `items/data/heliocore.tres` |
| Mechanic batch R - Lob burst family (5 items) | ✅ Done | `items/data/clot_catapult.tres`, `items/data/marrow_mortar.tres`, `items/data/gland_grenade.tres`, `items/data/hemorrhage_seed.tres`, `items/data/rupture_pod.tres` |
| Mechanic batch S - Elastic ricochet family (5 items) | ✅ Done | `items/data/rubber_cortex.tres`, `items/data/ping_pulse.tres`, `items/data/wall_waltz.tres`, `items/data/ricochet_organ.tres`, `items/data/spring_tear.tres` |
| Isaac passive mechanic coverage matrix (Rebirth + AB + AB+ + Repentance) | ✅ Done | `docs/implementation/ISAAC_PASSIVE_MECHANIC_COVERAGE_MATRIX.md` |
| Infrastructure batch U (phase 1): room/shop/curse/luck hooks | ✅ Done | `system/event_bus.gd`, `world/room.gd`, `world/gachapon_machine.gd` |
| Validation matrix for all mechanics and pairwise combinations | ✅ Done | `docs/implementation/PLAYTEST_MATRIX.md` |

This corresponds to **ITEM_ARCHITECTURE Phases 1, 2, 3, 4, 5, 6, 7, and 8 being complete**, and backlog Slices 1–36 complete.

### Additionally completed (not in original backlog — discovered in prior sessions)

| Item | Status | Evidence |
|---|---|---|
| Charm + Confusion status (M068/M069) | ✅ Done | `items/effects/charm_status_effect.gd`, `confusion_status_effect.gd`, `enemy_base.gd` behavior handling |
| Bleed status (M071) | ✅ Done | `items/effects/bleed_status_effect.gd`, tick damage in `enemy_base.gd` |
| Bait status (M072) | ✅ Done | `items/effects/bait_status_effect.gd`, bullet homing priority in `bullet.gd` |
| Chained/root status (M073) | ✅ Done | `items/effects/chained_status_effect.gd`, speed reduction in `enemy_base.gd` |
| Damage prevention (M089) | ✅ Done | `items/effects/damage_prevention_effect.gd` + runtime, `player_damage_preprocess` hook |
| Shop price/restock modifiers (M055/M057) | ✅ Done | `items/effects/shop_price_multiplier_effect.gd`, `shop_infinite_restock_effect.gd` |
| Room-entry hazard pulse (M047/M079) | ✅ Done | `items/effects/room_entry_hazard_pulse_effect.gd` + runtime |
| Projectile hazard pulse (M046) | ✅ Done | `items/effects/projectile_hazard_pulse_effect.gd` + runtime |
| Map reveal (M081) | ✅ Done | `items/effects/map_reveal_effect.gd` + runtime |
| Luck stat + luck-scaled procs (M085/M086) | ✅ Done | `items/effects/luck_up_effect.gd`, `EventBus.evaluate_luck_proc()` |
| Health stat up (M008 partial) | ✅ Done | `items/effects/health_up_effect.gd` |
| Charge shot weapon mechanic (M020) | ✅ Done | `items/effects/charge_shot_effect.gd`, `weapon_system.gd` |
| Fracture-on-hit (M025 variant) | ✅ Done | `items/effects/fracture_on_hit_effect.gd`, `bullet.gd` |
| Explosion shrapnel spawner | ✅ Done | `items/effects/explosion_shrapnel_effect.gd`, `bullet.gd` |
| Chance split shots (M025 variant) | ✅ Done | `items/effects/chance_split_shots_effect.gd`, `projectile_system.gd` |
| Spawn companions on hit/kill/damage (M043/M044) | ✅ Done | `spawn_companions_on_enemy_hit_effect.gd`, `spawn_companions_on_kill_effect.gd`, `spawn_companions_on_player_damaged_effect.gd` |
| Economy: drops on kill/room-clear/drop-pickup/enemy-hit | ✅ Done | `gain_drops_on_kill_effect.gd`, `gain_drops_on_room_clear_effect.gd`, `gain_drops_on_drop_pickup_effect.gd`, `gain_drops_on_enemy_hit_effect.gd` |
| Multiplicative stat scaler (M002) | ✅ Done | `items/effects/stat_multiplier_effect.gd` |
| Stat ramp on kill (M006) | ✅ Done | `items/effects/stat_ramp_on_kill_effect.gd` + runtime, `stat_evaluation_system.gd` post-recalculate hook |
| Stat ramp on damage taken (M005) | ✅ Done | `items/effects/stat_ramp_on_damage_effect.gd` + runtime |
| Temporary stat buff on kill (M004) | ✅ Done | `items/effects/temp_stat_buff_on_kill_effect.gd` + runtime |
| Post-recalculate applier hook in StatEvaluationSystem | ✅ Done | `register_post_recalculate_applier()`, `stats_recalculated` signal |
| 5 bait items (M072) | ✅ Done | `lure_hook`, `marked_target`, `scatter_mark`, `sniper_bait`, `bounty_bait` |
| 5 chained items (M073) | ✅ Done | `iron_shackle`, `binding_wire`, `frost_chain`, `chain_bomb`, `leash_gland` |
| 3 stat ramp items (M006) | ✅ Done | `predator_gland`, `plague_feast`, `adrenaline_surge` |
| 1 stat ramp on damage item (M005) | ✅ Done | `bloody_lust` |
| 3 multiplier items (M002) | ✅ Done | `catalyst_vial`, `speed_amplifier`, `viral_surge`, `host_tissue` |
| 2 temp buff items (M004) | ✅ Done | `berserker_gland`, `infected_rush`, `frenzy_organ` |
| Maintenance refactor — proc-chance centralization | ✅ Done | `items/effects/reactive_effect_instance.gd` (added `evaluate_proc()` helper); 7 runtimes migrated: `gain_drops_on_kill_runtime.gd`, `gain_drops_on_enemy_hit_runtime.gd`, `gain_drops_on_drop_pickup_runtime.gd`, `gain_drops_on_room_clear_runtime.gd`, `spawn_drops_on_damage_runtime.gd`, `spawn_companions_on_enemy_hit_runtime.gd`, `spawn_companions_on_player_damaged_runtime.gd` |
| Maintenance refactor — companion spawner base class | ✅ Done | `items/effects/abstract_companion_spawner_runtime.gd` (new base class); `spawn_companions_on_kill_runtime.gd`, `spawn_companions_on_enemy_hit_runtime.gd`, `spawn_companions_on_player_damaged_runtime.gd` refactored to extend it |
| Safety: EffectRuntimeSystem duplicate registration | ✅ Done | `player/systems/effect_runtime_system.gd` — `_register_item()` now detects duplicate ItemData reference, cleanly deactivates previous runtimes before registering new ones, emits warning |
| Diagnostic: SetWeaponTypeEffect overwrite warning | ✅ Done | `items/effects/set_weapon_type_effect.gd` — `apply_to_attack_data()` logs a warning when overwriting a non-default weapon type; behavior unchanged |
| Directional Shot Appender infrastructure (Slice 38) | ✅ Done | `attacks/attack_data.gd` (`appended_shot_offsets: Array[float]`), `items/effects/directional_shot_appender_effect.gd` (new), `player/systems/projectile_system.gd` (appended shot loop in `_spawn_tear_projectile`). See architectural rules below. |
| Backward Shot item | ✅ Done | `items/data/backward_shot.tres` — `DirectionalShotAppenderEffect` with `angle_offsets_degrees = [180.0]` |
| Side Shots item | ✅ Done | `items/data/side_shots.tres` — `angle_offsets_degrees = [90.0, -90.0]` |
| Cross Shot item | ✅ Done | `items/data/cross_shot.tres` — `angle_offsets_degrees = [90.0, -90.0, 180.0]` |
| Diagonal Shot item | ✅ Done | `items/data/diagonal_shot.tres` — `angle_offsets_degrees = [45.0, -45.0, 135.0, -135.0]` |
| Burst Cadence infrastructure (Slice 39) | ✅ Done | `attacks/attack_data.gd` (4 new cadence fields), `items/effects/cadence_shot_effect.gd` (new), `player/systems/weapon_system.gd` (`_cadence_shot_count`, `_process_cadence()`, `_fire_cadence_shot()`). See architectural rules below. |
| Viral Pulse item (Slice 39 test) | ✅ Done | `items/data/viral_pulse.tres` — every 3 shots fires an extra explosive shot (×2 dmg, 32px explosion) |
| Enemy spawn tier metadata consumption (Slice 41 integration) | ✅ Done | `world/enemy_spawn_selector.gd` (new weighted selector), `world/room.gd` (tier-aware non-boss combat respawn), `world/world_dungeon.gd` (tier provider + roster discovery). |
| Boss room + floor transition (Slice 43) | ✅ Done | `world/room.gd` (`room_type`, boss clear hook), `world/floor_transition.gd` (new), `world/floor_transition.tscn` (new), `world/world_dungeon.gd` (`notify_boss_room_cleared`, `advance_to_next_floor`), `system/Global.gd` (`floor_number`). |
| Demo loop integration (Slice 44) | ✅ Done | `world/world_dungeon.tscn` (Room3 boss role, Room5 gacha role, Infection Gacha machine, combat spawn counts), `world/world_dungeon.gd` (floor reset to gacha room, per-floor respawn with tier-gated weighted enemy selection). |
| Isolated experimental linear floor generator (Slice 45) | ✅ Done | `world/world_dungeon_random.gd`, `world/world_dungeon_random.tscn`, `world/templates/gacha_room_template.tscn`, `world/templates/combat_room_template_01.tscn`, `world/templates/boss_room_template.tscn`, `docs/implementation/ROOM_GENERATION_DESIGN.md`. Manual `WorldDungeon` preserved as fallback. |
| Room template contract hardening (Slice 46) | ✅ Done | `world/door.gd` (`connection_role`), `world/room.gd` (`get_forward_door()`, `get_backward_door()`, explicit SpawnPoints contract), `world/room.tscn` (base `SpawnPoints`, semantic door roles), `world/world_dungeon_random.gd` (semantic door wiring, documented standard spacing). |
| Demo floor generation pipeline completion (Slice 47) | ✅ Done | `world/room.gd` (shared RNG consumption, authoritative tier-filter path, warning on zero eligible enemies), `world/world_dungeon.gd` + `world/world_dungeon_random.gd` (shared generation RNG ownership). Tier metadata is now an actual generation system, not documentation-only metadata. |
| Player death + DeathScreen + run restart (Slice 48) | ✅ Done | `system/Global.gd` (`is_dead`, `reset_run_state()`), `system/event_bus.gd` (`player_died` signal), `player/player.gd` (`die()` emits signal), `ui/death_screen.gd` + `ui/death_screen.tscn` (ALWAYS-mode CanvasLayer, pauses tree, RESTART resets Global + reloads scene), `ui/pauser.gd` (ESC blocked during death), `world/world_dungeon.tscn` + `world/world_dungeon_random.tscn` (DeathScreen instanced in both). |

**Total items: 295. Total effect types: 75.**

### Directional Shot Appender — Architecture Rules (do not re-investigate)

- **`AttackData.appended_shot_offsets`:** `Array[float]` of degrees relative to the original firing direction. Starts empty. `DirectionalShotAppenderEffect` appends values. Multiple items accumulate additively (one item adds `[180.0]`, another adds `[90.0, -90.0]` → combined `[180.0, 90.0, -90.0]`).
- **`DirectionalShotAppenderEffect`:** Extends `AttackEffectData`. Export: `angle_offsets_degrees: Array[float]`. `apply_to_attack_data()` appends each angle.
- **`ProjectileSystem` tear path:** After spawning primary shots (which may already be a split fan), iterates `appended_shot_offsets`. For each angle: clones AttackData, **clears `appended_shot_offsets` on the clone** (critical — prevents recursive appending), rotates `direction` by the angle, then calls `_build_attack_directions()` on the clone so split also applies to appended shots.
- **Supported weapon types:** Tear only (intentional first slice). Beam/ring/orb/blade/orbit/lob/elastic silently ignore the field.
- **Split + Backward Shot composition:** Intentional. A backward shot on a player with Split Shots produces a backward split fan, not a single backward bullet. This is correct Isaac-like behavior.
- **Stacking two Backward Shot items:** Both append `180.0`, producing two overlapping backward bullets. By-design doubling, matches Isaac item stacking semantics.

### Burst Cadence — Architecture Rules (do not re-investigate)

- **State ownership:** `WeaponSystem._cadence_shot_count: int` is the single persistent counter. It is reset to 0 when `attack_data.cadence_interval <= 0` (no cadence item equipped), so picking up and removing cadence items always leaves the counter in a clean state.
- **Configuration in AttackData:** `cadence_interval`, `cadence_shot_split_bonus`, `cadence_shot_damage_multiplier`, `cadence_shot_explosion_radius`. Evaluated fresh every shot by `AttackEvaluationSystem`. Multiple cadence items use minimum interval; bonuses accumulate additively (split) or multiplicatively (damage multiplier).
- **`CadenceShotEffect extends AttackEffectData`:** Writes cadence configuration to AttackData in `apply_to_attack_data()`. No runtime/reactive instance needed.
- **Cadence shot firing:** `WeaponSystem._fire_cadence_shot()` calls `projectile_system.spawn_projectile()` **directly** (not via `_emit_attack()`). This prevents recursive cadence triggering. `cadence_interval = 0` is set on the clone before spawning.
- **Cadence shot is additive:** The Nth normal shot fires normally AND an additional special shot fires. No shots are replaced or suppressed.
- **Cadence shot inherits all evaluated AttackData:** Homing, pierce, bounce, split (+ bonus), spectral, directional appenders, weapon_type, status payloads, infection_shot all inherit from the evaluated base shot.
- **Weapon replacements:** If the player has a weapon replacement (e.g., brimstone), the cadence shot uses the same `weapon_type`. The cadence bonus split and explosion apply to that weapon type. Beam-specific limitations (no split, no appended shots) are inherited — consistent with Isaac-like design.
- **Known first-slice limitation:** Multiple cadence items with different intervals share one counter using minimum interval. Items designed for different intervals may fire their bonuses at unexpected times. Acceptable for current catalogue size; can be revisited if needed.

### Not yet implemented

| Item | Phase (ITEM_ARCHITECTURE) |
|---|---|
| Active items | Future |
| Trinket system | Future |
| `ItemPoolSystem` (pool rules, room-typed pools) | Future |
| `ShopSystem` | Future |
| `FamiliarSystem` | Future |
| `TransformationSystem` | Future |
| DNA resource / DNA drops | README Phase 4+ |
| Mutation system | README Phase 5+ |

---

## 8. Current Recommended Next Milestone

> **This section changes after every completed milestone.** The Agent session that completes a milestone is responsible for updating it before ending the session.

**As of August 2026 (post no-playtest technical phase + design consolidation):**

### CURRENT DEMO GOAL

The demo is a **combat/build/infection vertical slice** — not a procedural dungeon showcase.

Target loop:
```
Gacha room → combat rooms → boss room → floor transition → next floor (harder) → repeat
```

The player can return to the Gacha room during a floor as appropriate.

### CURRENT DEMO SCOPE (Confirmed Decisions)

**Room model for the demo — four categories, deliberately simple:**

| Room Type | Contents | Notes |
|-----------|----------|-------|
| GACHA ROOM | Normal gacha machine + Infection gacha machine | Main economy/build room. May contain DifficultyMachine and RespawnMachine as dev tools. |
| COMBAT ROOM | Enemy encounter, hand-authored layout | Doors close while enemies live; open on clear. Small number of hand-authored layouts acceptable for demo. |
| BOSS ROOM | One boss per floor | Defeating boss allows floor progression. |
| FLOOR TRANSITION | Trapdoor/exit object | Entering starts next floor at higher difficulty tier. |

**Explicitly out of scope for current demo:**
- Shop rooms
- Secret rooms
- Treasure-only rooms
- Shrine/healing rooms
- Procedural room layout generation
- Minimap
- Random room graph
- Isaac-style full room taxonomy

**F1/Debug Menu scope (non-negotiable rule):**
- F1 debug menu is a **development-only tool**. It must never be part of gameplay generation, item pools, or progression. The DifficultyMachine and RespawnMachine are also dev tools that may coexist in the Gacha room for testing purposes.

### ACTIVE MILESTONE: Gameplay Validation Gate

**Slices 38, 39, 41, 42, 43, 44, 45, 46, and 47 are implemented and statically validated. Gameplay testing is the current gate.**

| Slice | Status |
|-------|--------|
| Slice 38 — Directional Shot Appenders | ✅ Implemented + statically validated. Gameplay validation pending. |
| Slice 39 — Burst Cadence | ✅ Implemented + statically validated. Gameplay validation pending. |
| Slice 41 — Enemy Spawn Tier Classification | ✅ Implemented + statically validated. Gameplay validation pending. |
| Slice 42 — Item Pool Classification | ✅ Implemented + statically validated. Gameplay validation pending. |
| Slice 43 — Boss Room + Floor Transition | ✅ Implemented + statically validated. Gameplay validation pending. |
| Slice 44 — Demo Loop Integration | ✅ Implemented + statically validated. Gameplay validation pending. |
| Slice 45 — Isolated WorldDungeonRandom linear generation | ✅ Implemented + statically validated. Gameplay validation pending. |
| Slice 46 — Room template contract hardening | ✅ Implemented + statically validated. Gameplay validation pending. |
| Slice 47 — Demo floor generation pipeline completion | ✅ Implemented + statically validated. Gameplay validation pending. |
| Slice 48 — Player death + DeathScreen + run restart | ✅ Implemented + statically validated. Gameplay validation pending. |
| **Pre-Playtest Final Static Audit (2026-08-19)** | ✅ Complete. See [PRE_PLAYTEST_FINAL_AUDIT.md](PRE_PLAYTEST_FINAL_AUDIT.md). All static bugs fixed. |

**After gameplay validation of Slices 38/39/41/42/43/44/45/46/47:** assess stabilization findings and tune only what playtest evidence supports.

### NEXT MILESTONES (After Gameplay Validation)

Priority order (subject to change after playtest results):

1. **Gameplay validation pass — Demo Loop Integrity (highest priority)**
   - Validate boss-room clear → floor transition spawn → floor increment → reset to gacha room.
   - Validate non-boss combat room enemy selection is tier-gated and weighted by metadata.
   - Validate Infection Gacha machine appears in the gacha room and uses `pool_tag = "infection_gacha"`.
   - Validate `WorldDungeonRandom` generates `GACHA -> COMBAT x N -> BOSS` and does not break manual `WorldDungeon` fallback.
   - Validate semantic door roles (`FORWARD` / `BACKWARD`) are respected in generated templates.
   - Validate generated combat templates use `SpawnPoints/*` and no longer depend on baked enemy nodes.
   - Validate weighted selection with replacement produces repeated enemies where appropriate.
   - Validate zero-eligible tier cases surface as warnings and do not silently fall back to out-of-tier baked enemies.

2. **Gameplay validation pass — Economy / progression pressure**
   - Validate floor progression difficulty pressure (`Global.floor_number` and `Global.difficulty_level`) feels coherent.
   - Validate no progression lock when a room receives no eligible enemies for a tier.

3. **Post-playtest stabilization only**
   - Adjust spawn weights/tier caps and floor-difficulty formula only from observed gameplay.
   - Keep procedural generation and advanced room taxonomy deferred.

### DESIGNER SETUP REQUIRED (WorldDungeonRandom)

When gameplay testing resumes:
1. Add new combat room templates in `res://world/templates/`.
2. Ensure each combat template uses the base `SpawnPoints` node and adds `SpawnPoints/*` markers.
3. Register templates in `combat_room_templates` on `world/world_dungeon_random.tscn`.
4. Configure per-template `enemy_spawn_min_count` / `enemy_spawn_max_count`.
5. Preserve the semantic door contract:
   - `Door2` currently carries `connection_role = FORWARD`
   - `Door4` currently carries `connection_role = BACKWARD`
   A template may rename internal nodes later only if it still preserves the semantic role contract exposed by `Door.connection_role`.
6. Respect the current standard room spacing contract: generated rooms assume the base room footprint and use `room_spacing = Vector2(352, 0)`.
7. Keep manual `world/world_dungeon.tscn` as fallback until `WorldDungeonRandom` is gameplay-validated.

### What NOT to do before gameplay validation

- Do not implement `WeaponConfig` extraction (P1 deferred — defer until weapon count expands beyond 8).
- Do not implement procedural room layout generation.
- Do not implement RoomNode/RoomGraph/Floor classes.
- Do not implement active items, trinket system, or ItemPoolSystem.
- Do not add directional appender support to non-tear weapons yet (defer until gameplay confirms it is needed).
- Do not add new mechanic batches before validating Slices 38–39.

---

Do not blindly advance to the next item on the roadmap. After completing any milestone, ask:

1. **What did playtesting reveal?** If Infection still feels unvalidated, address that before building more infrastructure.
2. **Has a new blocker appeared?** If a completed system exposed a gap, promote that gap ahead of the original order.
3. **Is the next roadmap phase still the highest-leverage work?** If new item content would answer the core gameplay question faster than infrastructure, content takes priority.
4. **Does the project still feel small and testable?** If it does not, stop adding systems and stabilize what exists.

Only advance to a new infrastructure phase when the current gameplay loop cannot express something it needs to express without that infrastructure.

---

## 9. Known Milestones

The milestones below come from `ITEM_ARCHITECTURE.md`. They represent a coherent sequence designed to avoid rework. **The order has logical prerequisites** — Reactive Items require EventBus; Weapon Replacement requires WeaponSystem — but the order is not a rigid contract. If a later milestone becomes the most valuable work, record the reasoning in the [Decision Log](#13-decision-log) before proceeding.

### When it is acceptable to modify this roadmap

**Acceptable:**
- A completed milestone revealed that a later phase is now immediately necessary.
- A gameplay need cannot be expressed without a system not yet on the roadmap (add it and record why in the Decision Log).
- A phase is smaller than expected and can be merged with the next (record the merge).

**Not acceptable:**
- Implementing a future phase to avoid doing the current one.
- Adding a system because it "would be useful later" without a concrete gameplay need today.
- Changing the milestone order without updating this document and the [Decision Log](#13-decision-log).

---

### Phase 4 — EventBus

Implement a global autoload with Godot signals only. No logic — infrastructure only.

Candidate signals (from ITEM_ARCHITECTURE):
- `player_damaged`
- `enemy_killed`
- `room_entered`
- `room_cleared`
- `projectile_spawned`
- `projectile_destroyed`
- `item_collected`
- `enemy_spawned`
- `boss_killed`

**Definition of Done:**
- An autoload node emits and exposes named signals.
- No existing system changes behavior after this phase.
- The project remains playable and identical to before.

---

### Phase 5 — Reactive Items

Validate items that react to events instead of modifying stats directly.

Validation candidates (per ITEM_ARCHITECTURE):
- Piggy Bank (react to `player_damaged` → spawn drops).
- Holy Mantle (react to `player_damaged` → block damage once).
- Bloody Lust (react to `player_damaged` → boost damage temporarily).

**Definition of Done:**
- At least one reactive item works without any `if has_item_x` check in system code.
- Effect subscribes to the EventBus signal it needs.
- StatEvaluationSystem remains the only stat calculator.
- Project remains playable.

---

### Phase 6 — WeaponSystem

Extract weapon firing from `Player` into a dedicated `WeaponSystem` child node.

- `WeaponSystem` knows weapon types (TearWeapon initially).
- `WeaponSystem` produces `AttackData`.
- `WeaponSystem` does **not** know items.
- Player delegates fire input to `WeaponSystem`.
- Migration: the current tear-shooting logic in `player.gd` moves into `WeaponSystem`.

**Definition of Done:**
- Player fires tears through `WeaponSystem`.
- `AttackData` is still the handoff object to the bullet.
- No item or effect references exist inside `WeaponSystem`.
- Infection shot continues to work.
- Project remains playable.

---

### Phase 7 — ProjectileSystem with Capabilities

Extract projectile spawning and behavior from `Bullet` into a `ProjectileSystem`.

Capability model:
- `CanHome`, `CanBounce`, `CanPierce`, `CanSplit`, `CanSpectral`, `CanFragment`.
- Effects add capabilities to `AttackData`.
- `ProjectileSystem` reads capabilities and configures projectile behavior.
- No item names or item IDs inside `ProjectileSystem`.

Validate:
- Homing
- Bounce
- Piercing
- Split

**Definition of Done:**
- At least two capabilities (e.g., Piercing and Bounce) work without item-specific code in the projectile.
- `Bullet` remains the physical entity; `ProjectileSystem` configures it via data.
- All existing weapons continue to fire correctly.
- Project remains playable.

---

### Phase 8 — Weapon Replacement (Brimstone)

Implement Brimstone as validation of the full weapon replacement pipeline.

- Brimstone replaces the tear weapon type.
- Implemented as a `SetWeaponTypeEffect` on the Brimstone item.
- `WeaponSystem` reads weapon type from resolved state, not from item directly.

**Definition of Done:**
- Brimstone item grants a laser weapon that replaces tears.
- Removing Brimstone from inventory restores tears.
- No `if has_brimstone:` anywhere.
- Project remains playable.

---

### Future phases (not yet scheduled)

After Phase 8 is validated:
- Active Items.
- Trinket system.
- ItemPoolSystem (room-typed pools, DefaultRule, ChaosRule, SacredOrbRule).
- ShopSystem.
- FamiliarSystem.
- TransformationSystem.
- DNA drops and infection economy.

---

## 10. Architecture Review Protocol

The purpose of this section is to prevent Agent sessions from blindly implementing decisions that may no longer be correct. **Architecture must never evolve silently.**

Every Agent session must execute this protocol before beginning any milestone. The protocol is not optional and is not shortened for small tasks.

---

### Step 1 — Review the current architecture

Before writing any code:

1. Read [Section 3 — Current Architecture](#3-current-architecture) and verify that your understanding of each system matches what is actually in the files.
2. Read every file directly affected by the planned milestone.
3. Identify every system boundary the milestone will touch: which systems produce data, which consume it, which nodes are added or removed.

If your understanding of the code contradicts any description in section 3, the description may be out of date. Correct it before proceeding.

---

### Step 2 — Determine whether the milestone fits the existing architecture

Ask: can the planned milestone be implemented cleanly using the systems that already exist, without violating any decision in [Section 6 — Architecture Decisions](#6-architecture-decisions)?

- If **yes**: proceed to implementation.
- If **no**: identify the friction before writing code, not after. Continue to Step 3.

---

### Step 3 — Classify every friction point

For each gap, mismatch, or problem found, assign it one of these categories:

| Category | Definition | Example |
|---|---|---|
| **Bug** | The code does not do what the documentation says it should do. | A system described as decoupled has direct references it should not have. |
| **Technical Debt** | A known compromise that works now but will cause problems later. | Core player subsystems are injected in `_ready()` instead of being scene-declared. |
| **Missing Feature** | The gameplay needs something that simply does not exist yet. | EventBus signals are required but the autoload has not been created. |
| **Architecture Problem** | The planned milestone cannot be implemented without violating a principle in Section 6. | A new item effect requires item-specific conditional logic inside a system. |

Do not conflate these categories. A missing feature does not justify violating an architecture decision. An architecture problem must be resolved before any code is written.

---

### Step 4 — Determine the correct response for each issue

| Category | Response |
|---|---|
| **Bug** | Fix immediately if it is in the path of the current milestone. If it is outside the path and deferring is safe, record it in [Known Technical Debt](#14-known-technical-debt). Never leave a bug undocumented. |
| **Technical Debt** | Record it in [Known Technical Debt](#14-known-technical-debt). Do not fix it unless the current milestone directly requires it. Do not let existing debt grow silently. |
| **Missing Feature** | If required by the current milestone, implement it as part of the milestone. If adjacent but not required, add it to [Section 9 — Known Milestones](#9-known-milestones). |
| **Architecture Problem** | Stop. Do not implement workarounds. Proceed to Step 5. |

---

### Step 5 — Respond to Architecture Problems

An architecture problem means the current milestone, as planned, cannot be completed without violating Section 6 or making the codebase measurably harder to maintain.

Respond in this order of preference:

1. **Reframe the milestone.** Find a smaller version of the same goal that fits the existing architecture. A milestone that fits cleanly is always better than one that requires silent compromise.

2. **Propose an architecture change.** If the architecture genuinely needs to evolve to support the milestone, write a [Decision Log](#13-decision-log) entry before writing any code. The entry must include all four of these fields:
   - **Reasoning** — Why the existing architecture cannot accommodate this milestone as designed.
   - **Alternatives considered** — What else was evaluated and why it was rejected.
   - **Expected impact** — Which systems change behavior, which boundaries move, which existing tests or manual checks are affected.
   - **Affected files** — Every file that changes as a result of the architecture change.

3. **Request human review.** If the problem is ambiguous — if it is not clear whether the correct response is to reframe, to change the architecture, or to defer — stop and ask. Do not guess. Do not implement a workaround and document it afterward. The cost of asking is always lower than the cost of an undocumented architectural drift.

---

### Step 6 — Challenge previous assumptions when the repository proves them wrong

Architecture decisions are made at a specific point in time with the information available at that time. As the repository evolves, some decisions will become wrong.

If evidence emerges that a previous assumption is no longer valid — a system that is harder to extend than designed, a data flow that has become circular, a boundary that has blurred through accumulated changes — you must:

1. **Document the finding.** Add an entry to the [Decision Log](#13-decision-log) explaining what changed and what the evidence is.
2. **Do not silently replace the architecture.** Even if the replacement is obviously better, the change must be recorded before it is made.
3. **Do not defend a decision just because it is documented.** Documented decisions can be wrong. The goal is a correct codebase, not historical consistency.

The rule is: architecture can change, but it must never change without a written record of why.

---

### Pre-implementation checklist

Before beginning any milestone, confirm all of the following:

- [ ] Section 3 (Current Architecture) matches the actual files.
- [ ] Every friction point is classified as Bug, Technical Debt, Missing Feature, or Architecture Problem.
- [ ] No Architecture Problem is left unresolved.
- [ ] Any architecture change has a [Decision Log](#13-decision-log) entry written before the first line of code.
- [ ] Any compromise introduced has a [Known Technical Debt](#14-known-technical-debt) entry.
- [ ] The milestone still aligns with [Section 8 — Current Recommended Next Milestone](#8-current-recommended-next-milestone).

---

## 11. Rules for Future Agent Sessions

### Before starting any task
1. Read this document, starting with [Section 8 — Current Recommended Next Milestone](#8-current-recommended-next-milestone).
2. Read `README.md`, `ITEM_ARCHITECTURE.md`, `docs/architecture/system-map.md`, `docs/implementation/backlog.md`.
3. Confirm the task is consistent with the current recommended milestone, or that it has been explicitly prioritized above it with a recorded reason.
4. Identify the smallest slice that validates the task.

### During implementation
- One slice at a time.
- Never modify gameplay code that is not directly required by the current slice.
- Never add a new system because it "might be needed later."
- Never mutate `Stats` directly from a pickup, item, or effect outside the `StatEvaluationSystem` recalculate loop.
- Never put item names, item IDs, or `if has_item_x` checks inside system code (Player, WeaponSystem, ProjectileSystem, Room, etc.).
- Use `AttackData` as the transfer object for all attack intent.
- Keep `InventorySystem` as a container.
- If a compromise is introduced (shortcut, temporary solution, known gap), add an entry to [Known Technical Debt](#14-known-technical-debt) immediately.

### After completing a task
- Verify the project is still playable: move, shoot, infect an enemy, collect an item, confirm stat change.
- Update `docs/implementation/backlog.md` to mark the slice done.
- If architecture changed, update `docs/architecture/system-map.md` and add an entry to the [Decision Log](#13-decision-log).
- Update [Section 7 — Current Implementation Status](#7-current-implementation-status) if a system was completed.
- Update [Section 8 — Current Recommended Next Milestone](#8-current-recommended-next-milestone) with the new recommended work.

### After completing a milestone
- Re-evaluate the roadmap using the four questions in [Section 8](#8-current-recommended-next-milestone).
- Do not assume the next milestone on the list is automatically the right next step.
- Record the re-evaluation outcome in [Section 8](#8-current-recommended-next-milestone) before ending the session.

### Documentation rules
- Do not duplicate content already in `README.md` or `ITEM_ARCHITECTURE.md`.
- Update existing documents; do not create parallel architecture documents.
- Record playtest findings in documentation when infection feel changes.
- If a new architectural decision is made, record it in the [Decision Log](#13-decision-log) before modifying any code.

---

## 12. Definitions of Done — Per Milestone

| Phase | Done When |
|---|---|
| **Phase 4 — EventBus** | Autoload emits named signals. No gameplay change. Project playable. |
| **Phase 5 — Reactive Items** | At least one item reacts to an EventBus signal with no `if has_item` check in any system. Stats still rebuilt by StatEvaluationSystem. Playable. |
| **Phase 6 — WeaponSystem** | Player fires through WeaponSystem. AttackData is still the handoff. Infection works. No item references inside WeaponSystem. Playable. |
| **Phase 7 — ProjectileSystem** | At least two projectile capabilities (e.g., Piercing, Bounce) work via data flags, not item checks. Playable. |
| **Phase 8 — Weapon Replacement** | Brimstone replaces tears. Removing it restores tears. Zero `if has_brimstone` lines. Playable. |
| **Any content slice** | New item .tres + new EffectData subclass added. Item appears in gachapon pool. Stat change is visible in StatsUI after pickup. Playable. |

---

## 13. Decision Log

> **This section is appended to, never overwritten.** Each entry records a deliberate architectural decision made during a session. Entries are listed newest first. Future Agent sessions use this log to understand not just what the architecture is, but why it became that way.

### Entry format

```
**[Date] — [Short title of decision]**
Decision: [What was decided]
Reasoning: [Why this was the right call at this moment]
Alternatives considered: [What else was evaluated and why it was rejected]
Affected files: [Which files changed as a result]
```

### Entries

**[2026-08-19] — Temporary milestone: Pre-Playtest Stabilization & Tooling**
Decision: Normal backlog progression (Slice 38 — directional shot appenders) is temporarily suspended. Active milestone changed to Pre-Playtest Stabilization & Tooling for approximately one week while manual playtesting is unavailable.
Reasoning: Slice 38 and future content batches require gameplay feel assessment. Spending a no-playtest window on those would produce work that cannot be validated until testing resumes, accumulating uncertainty. The stabilization milestone targets work whose correctness can be determined statically: a confirmed door collision bug, missing debug tooling, and a static audit of the large item/effect pipeline.
Alternatives considered: (1) Continue Slice 38 anyway and validate later — rejected because directional appenders interact with projectile diversity, balance, and feel, all of which require playtesting; (2) Do no code work during the window — rejected because the door bug and missing debug tooling are high-leverage improvements with demonstrable value.
Expected impact: No architecture changes. `world/door.tscn` and `world/door.gd` change to add a `StaticBody2D` blocker. A new debug UI scene is added. PLAYTEST_MATRIX gains targeted test entries. Section 8 temporarily points to this milestone instead of Slice 38.
Affected files: `world/door.tscn`, `world/door.gd`, `ui/debug_menu.tscn` (new), `ui/debug_menu.gd` (new), `world/world.tscn`, `docs/implementation/AGENT_CONTEXT.md`, `docs/implementation/PLAYTEST_MATRIX.md`.

**[2026-08-19] — Confirmed code bug: door.tscn CollisionPolygon2D is an orphan node**
Decision: Documented as confirmed code bug (Category A). Door physical collision must be added via a StaticBody2D child node before any bounce/projectile/movement testing that involves closed doors is meaningful.
Reasoning: Static inspection of `door.tscn` shows `CollisionPolygon2D` as a direct child of the root `Node2D`. In Godot 4, a `CollisionPolygon2D` without a `CollisionObject2D` parent is inert. Compare with `wall.tscn` where the `CollisionPolygon2D` is correctly a child of a `StaticBody2D`. The door currently passes projectiles, enemies, and raycasts when closed.
Alternatives considered: N/A — this is a structural bug with no design ambiguity.
Expected impact: After fix, closed doors act as walls for all physics interactions. This makes several PLAYTEST_MATRIX combinations (bounce in small rooms, beam against closed doors) meaningful.
Affected files: `world/door.tscn`, `world/door.gd`.

**[2026-07-17] — Phase 8 implemented with segmented beam replacement pipeline**
Decision: Weapon replacement is now executed as data (`SetWeaponTypeEffect`) that switches `AttackData.weapon_type` to `segmented_beam`, with `ProjectileSystem` materializing `BeamSegment` entities.
Reasoning: This completes Phase 8 without introducing parallel combat paths, preserving AttackData/ProjectileSystem/Hitbox reuse and keeping item-specific logic out of systems.
Alternatives considered: Keep beam behavior inside `WeaponSystem` or add item-specific branching in projectile code; rejected because both approaches couple systems to content.
Affected files: `attacks/attack_data.gd`, `attacks/beam_segment.gd`, `attacks/beam_segment.tscn`, `player/systems/projectile_system.gd`, `player/systems/weapon_system.gd`, `items/effects/set_weapon_type_effect.gd`, `items/data/brimstone.tres`, `items/effects/beam_length_up_effect.gd`, `items/data/coiled_cable.tres`, `attacks/bullet.gd`.

**[2026-07-17] — Brimstone uses segmented projectile beam architecture**
Decision: Brimstone will be implemented using a segmented projectile beam architecture.
Reasoning: The repository already uses AttackData, ProjectileSystem, Hitbox, and data-driven capabilities as the combat pipeline. A segmented beam preserves this architecture and avoids introducing a parallel combat pipeline.
Alternatives considered: (1) Raycast beam; (2) persistent Area2D beam. Both were rejected because they require separate behavior paths and reduce system reuse.
Expected impact: WeaponSystem will produce beam attack data. ProjectileSystem will materialize beam segments. Existing attack capabilities should remain reusable where applicable. No item-specific conditionals may be introduced.
Affected files: `player/systems/weapon_system.gd`, `player/systems/projectile_system.gd`, `attacks/attack_data.gd`, `attacks/`, `items/effects/`, `items/data/`.

**[2026-07-17] — Projectile capabilities resolved through AttackEvaluationSystem + ProjectileSystem**
Decision: Attack-time capability evaluation was separated into `AttackEvaluationSystem`, and projectile materialization was delegated to `ProjectileSystem`.
Reasoning: Phase 7 required capability-driven projectile behavior without moving item logic into WeaponSystem or Bullet. This preserves system boundaries while enabling additive capability effects.
Alternatives considered: (1) evaluate item effects directly inside `WeaponSystem`, rejected because it couples weapon logic to inventory traversal; (2) hardcode capability conditionals in `Bullet`, rejected because it prevents scalable capability composition.
Affected files: `player/systems/attack_evaluation_system.gd`, `player/systems/projectile_system.gd`, `player/systems/weapon_system.gd`, `attacks/attack_data.gd`, `attacks/bullet.gd`, `items/effects/attack_effect_data.gd`, `items/effects/piercing_projectiles_effect.gd`, `items/effects/bouncy_projectiles_effect.gd`, `items/data/needle_eye.tres`, `items/data/rubber_coat.tres`, `player/player.gd`.

**[2026-07-17] — Weapon firing delegated to WeaponSystem**
Decision: Attack construction and bullet spawn flow were moved out of `Player` into a dedicated `WeaponSystem` node, while preserving current tear/infection behavior.
Reasoning: Phase 6 required reducing coupling in Player and establishing a clean seam between fire input and projectile materialization before introducing projectile capabilities and weapon replacement.
Alternatives considered: (1) leave shooting in `Player` and add capability logic there, rejected because it further couples unrelated concerns; (2) create a full multi-weapon hierarchy immediately, rejected as overengineering before Phase 7 validation.
Affected files: `player/systems/weapon_system.gd`, `player/player.gd`.

**[2026-07-17] — Reactive effects run through dedicated runtime instances**
Decision: Reactive effects were implemented through `ReactiveEffectData` + `ReactiveEffectInstance` and a dedicated `EffectRuntimeSystem` instead of extending `EffectData.apply_to_stats()` with runtime side effects.
Reasoning: Phase 5 required event-driven behavior, but `StatEvaluationSystem` must remain the only stat calculator and `InventorySystem` must remain a container. A runtime layer keeps execution out of data objects and avoids item-specific code in core systems.
Alternatives considered: (1) put EventBus subscriptions directly in `EffectData` subclasses, rejected because it mixes static data with runtime lifecycle and breaks architectural boundaries; (2) run reactive logic inside `InventorySystem`, rejected because it turns inventory into a gameplay coordinator.
Affected files: `items/effects/reactive_effect_data.gd`, `items/effects/reactive_effect_instance.gd`, `player/systems/effect_runtime_system.gd`, `player/systems/inventory_system.gd`, `player/player.gd`, `items/effects/spawn_drops_on_damage_effect.gd`, `items/effects/spawn_drops_on_damage_runtime.gd`, `items/data/piggy_bank.tres`.

---

## 14. Known Technical Debt

> **This section is updated whenever a compromise is introduced.** Record the debt immediately — not retroactively. Each entry describes what the compromise is, why it was acceptable at the time, and what the correct solution looks like when it becomes necessary.

Future Agent sessions must check this section before touching any system listed here, to avoid making the debt worse.

### Entry format

```
**[Short description of debt]**
Location: [File or system]
Compromise: [What was done instead of the correct solution]
Reason accepted: [Why this was acceptable at the time]
Correct solution: [What the proper fix looks like]
Priority: Low / Medium / High
```

### Current entries

**Door CollisionPolygon2D is inert (orphan node)**
Location: `world/door.tscn`
Compromise: `CollisionPolygon2D` is a direct child of the root `Node2D` with no parent `CollisionObject2D`. In Godot 4 this node has no physics effect. Closed doors are visually closed but physically open.
Reason accepted: Was not identified until static audit (August 2026).
Correct solution: Wrap the `CollisionPolygon2D` in a `StaticBody2D` child (`BlockerBody`); toggle `CollisionPolygon2D.disabled` in `door.gd` open/close methods. Scheduled as Priority 1 of the Pre-Playtest Stabilization milestone.
Priority: High

**MapRevealRuntime writes to Global intel fields that have no consumer**
Location: `items/effects/map_reveal_runtime.gd`, `system/Global.gd`
Compromise: `Global.reveal_map_level`, `reveal_room_types_level`, `reveal_secret_walls_level`, etc. are incremented/decremented by `MapRevealRuntime`, but no UI element, minimap, or room system reads these values. Items that grant map intelligence appear to do nothing observable to the player.
Reason accepted: Minimap and room-reveal UI are future features. The intel infrastructure was created in anticipation.
Correct solution: When a minimap or room-reveal system is added, it should read `Global.reveal_map_level` to determine display level. Until then, these items are non-functional from the player's perspective.
Priority: Medium

**InfectionState is a thin wrapper around a single bool**
Location: `system/infection_state.gd`
Compromise: `InfectionState` currently contains only `is_infected: bool`. It was introduced as a typed object to preserve the extension path, but holds no additional state.
Reason accepted: The prototype is still answering "is infection fun?" Adding duration, intensity, or source tracking before that question is answered would be premature.
Correct solution: When infection needs more than two states (infected / not infected), add fields directly to `InfectionState` rather than scattering new bools across `EnemyBase`.
Priority: Low

**Player subsystems are created dynamically in `_ready()`**
Location: `player/player.gd` (`_ensure_effect_runtime_system`, `_ensure_attack_evaluation_system`, `_ensure_projectile_system`, `_ensure_weapon_system`)
Compromise: Core player systems are injected in code instead of being explicitly present in `player.tscn`.
Reason accepted: This keeps milestone slices focused on architecture behavior with minimal scene-file churn.
Correct solution: Move `EffectRuntimeSystem`, `AttackEvaluationSystem`, `ProjectileSystem`, and `WeaponSystem` to explicit children in `player/player.tscn` once scene migration is scheduled.
Priority: Low

**GachaPonMachine loads all items from disk on _ready()**
Location: `world/gachapon_machine.gd` — `_refresh_passive_item_pool()`
Compromise: Items are loaded by scanning the filesystem at runtime using `DirAccess`. There is no pool-tag filtering. Both gacha machines (normal + infection) currently draw from the full item pool.
Reason accepted: `ItemPoolSystem` is a future phase. The current approach is sufficient for a single shop with no pool rules.
Correct solution: Pass a `pool_tag: String` parameter to `_refresh_passive_item_pool()` and filter by `item.pool_tags.has(pool_tag)`. Create Infection Gacha Machine as a variant with `pool_tag = "infection_gacha"`. Scheduled in backlog Slice 42.
Priority: Medium

---

## 15. Future Game Design Direction

> **This section documents long-term design intentions that are NOT current implementation requirements.** These are preserved here so future sessions understand the intended direction without needing to rediscover it.

### School Theme
- The game is set in a school environment. The initial floor(s) represent a primary school.
- Enemy archetypes (already named) represent school personality types: bully, nerd, rapper, bat, etc.
- Future progression: primary school → high school/institute → university.
- Enemy variants can evolve with progression, similar to Isaac champion/variant system.

### Room Subjects (Future)
- Different school subjects may eventually become room themes (Biology lab, Math class, PE hall, etc.).
- A subject could determine room visual style, layout, and special gameplay rules.
- Multiple room layout variants would exist per subject.
- NOT required for the current demo.

### Future Special Rooms (Not for Current Demo)
| Room Type | Concept |
|-----------|---------|
| Shop | Buy items with drops |
| Secret room | Hidden room with better reward |
| Infirmary | Healing/HP restoration |
| Technology/crafting | Item modification |
| Recreation/social | Social mechanics |
| NPC/friendship rooms | NPC interaction, potential friendship system |

### Friendship System (Long-Term)
- Some enemies/NPCs may become friends with the player.
- Friendships provide specific item or reward outcomes.
- Design not yet specified.

### Academic Progression (Long-Term)
- Subject choices may influence academic path, career/degree arc, end-game outcomes, and item unlocks.
- This is a long-term progression system, not part of the current demo.

### Item Pool Philosophy (Current Demo → Future)
- **Current demo:** Two gacha machines — Normal and Infection. Pool membership via `pool_tags` field.
- **Future:** Full Isaac-style item pool taxonomy (treasure, secret, shop, angel, devil, etc.) can extend the existing `pool_tags` system without replacement.
- The `pool_tags: PackedStringArray` in `ItemData` already supports multi-pool membership.

---

## 16. Key File Reference

| Purpose | File |
|---|---|
| Player controller | [player/player.gd](../../player/player.gd) |
| Enemy base | [enemies/enemy_base.gd](../../enemies/enemy_base.gd) |
| Attack transfer object | [attacks/attack_data.gd](../../attacks/attack_data.gd) |
| Projectile | [attacks/bullet.gd](../../attacks/bullet.gd) |
| Infection state | [system/infection_state.gd](../../system/infection_state.gd) |
| Stats resource | [system/stats.gd](../../system/stats.gd) |
| Global singleton | [system/Global.gd](../../system/Global.gd) |
| Hitbox | [system/hitbox.gd](../../system/hitbox.gd) |
| Hurtbox | [system/hurtbox.gd](../../system/hurtbox.gd) |
| Item data class | [items/data/item_data.gd](../../items/data/item_data.gd) |
| Effect base class | [items/effects/effect_data.gd](../../items/effects/effect_data.gd) |
| Weapon system | [player/systems/weapon_system.gd](../../player/systems/weapon_system.gd) |
| Projectile system | [player/systems/projectile_system.gd](../../player/systems/projectile_system.gd) |
| Attack evaluation | [player/systems/attack_evaluation_system.gd](../../player/systems/attack_evaluation_system.gd) |
| Beam segment projectile | [attacks/beam_segment.gd](../../attacks/beam_segment.gd) |
| Inventory | [player/systems/inventory_system.gd](../../player/systems/inventory_system.gd) |
| Stat evaluator | [player/systems/stat_evaluation_system.gd](../../player/systems/stat_evaluation_system.gd) |
| Room | [world/room.gd](../../world/room.gd) |
| Door | [world/door.gd](../../world/door.gd) |
| Drop | [world/drop.gd](../../world/drop.gd) |
| Upgrade pickup | [world/upgrade_pickup.gd](../../world/upgrade_pickup.gd) |
| Gachapon machine | [world/gachapon_machine.gd](../../world/gachapon_machine.gd) |
| World dungeon | [world/world_dungeon.gd](../../world/world_dungeon.gd) |
| Stats UI | [ui/stats_ui.gd](../../ui/stats_ui.gd) |
