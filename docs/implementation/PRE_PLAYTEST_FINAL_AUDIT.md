# PRE-PLAYTEST FINAL AUDIT

**Date:** 2026-08-19  
**Status:** STATIC AUDIT COMPLETE — GAMEPLAY VALIDATION PENDING  
**Author:** Copilot Agent session  
**Godot availability:** Unavailable at time of audit. This document is the handoff for the first session after returning to Godot.

---

## 1. Current Demo Objective

Validate the core gameplay loop:
```
Gacha Room → Combat Rooms → Boss Room → Floor Transition → Next Floor (harder) → Repeat
```

Key questions to answer through gameplay:
1. Is the combat/infection loop fun?
2. Do item combinations produce interesting builds?
3. Does floor difficulty progression feel coherent?
4. Does death → restart feel clean?
5. Does the generated floor structure (WorldDungeonRandom) work in motion?

---

## 2. Authoritative Source Documents

Do NOT re-investigate things already documented in these files. Read them instead:

| Document | What it covers |
|----------|---------------|
| [AGENT_CONTEXT.md](AGENT_CONTEXT.md) | Complete architecture, system contracts, implementation status, current milestone |
| [backlog.md](backlog.md) | Full slice history (1–48), current state per slice |
| [PLAYTEST_MATRIX.md](PLAYTEST_MATRIX.md) | All gameplay tests grouped by system with priority (§1–§8) |
| [ROOM_GENERATION_DESIGN.md](ROOM_GENERATION_DESIGN.md) | Designer operational guide for WorldDungeonRandom templates |
| [ENEMY_SPAWN_PROGRESSION.md](ENEMY_SPAWN_PROGRESSION.md) | Enemy tier classification methodology and final values |
| [ITEM_POOL_DESIGN.md](ITEM_POOL_DESIGN.md) | Pool composition, filtering rules, infection_gacha catalog |
| [ITEM_ARCHITECTURE_AUDIT.md](ITEM_ARCHITECTURE_AUDIT.md) | Previous item architecture audit baseline |

---

## 3. Systems Audited in This Session

All of the following were audited statically (code + scene inspection):

- WorldDungeonRandom: floor generation, room instantiation, door wiring, cleanup
- WorldDungeon (manual): floor progression, boss room, room wiring
- Room: spawn logic, door management, tier resolution, enemy pool
- EnemySpawnSelector: tier filtering, weighted selection, static cache
- Enemy roster: all 10 enemy tier metadata fields
- FloorTransition: trigger detection, lifecycle, world reference
- GachaPonMachine: pool filtering, purchase flow, body detection
- Drop: pickup detection, drop economy
- UpgradePickup: item delivery, scene root orphaning
- Door: transition logic, null safety, camera behavior
- Player.die(): signal emission, group cleanup
- DeathScreen: pause flow, restart flow, process_mode
- Pauser: ESC guard during death
- Global: all run-state fields, reset_run_state()
- EventBus: all signals including player_died
- InventorySystem: item storage, signal emissions
- StatEvaluationSystem: recalculate loop, luck field, post-recalculate appliers
- EffectRuntimeSystem: _exit_tree cleanup, duplicate registration guard
- ReactiveEffectInstance: deactivate() base, evaluate_proc()
- AttackData.copy(): all field coverage
- Item effects count: 76 files (effective types in Section 7 of AGENT_CONTEXT.md)
- Item pool counts: 295 items, 293 in gacha, 42 in infection_gacha

---

## 4. Bugs Found and Fixed

| # | Classification | File | Problem | Fix Applied |
|---|---------------|------|---------|-------------|
| A1 | BUG (A) | `world/door.gd` | `get_node(tp_position)` without null check — crashes if tp_position is invalid; also `.get_node("Marker2D")` chained without null check | Refactored: resolve destination room once with `get_node_or_null`, check null before use, use `get_node_or_null("Marker2D")` for camera pos |
| A2 | BUG (A) | `world/drop.gd` | `body.name != "Player"` — fragile node-name check | Changed to `not body.is_in_group("player")` |
| A3 | BUG (A) | `world/floor_transition.gd` | `body.name != "Player"` — fragile node-name check | Changed to `not body.is_in_group("player")` |
| A4 | BUG (A) | `world/gachapon_machine.gd` | `body.name != "Player"` in both `_on_body_entered` and `_on_body_exited` | Changed to `not body.is_in_group("player")` |
| A4b | BUG (A) | `world/difficulty_machine.gd` | `body.name != "Player"` in both handlers — same fragility | Changed to `not body.is_in_group("player")` |
| A4c | BUG (A) | `world/respawn_machine.gd` | `body.name != "Player"` in both handlers — same fragility | Changed to `not body.is_in_group("player")` |
| A5 | BUG (A) | `world/gachapon_machine.gd` | Debug `print()` statements in `use_machine()` | Removed all 4 print statements |
| A6 | BUG (A) | `world/upgrade_pickup.gd` | Debug `print()` statement in `_on_body_entered()` | Removed |
| A7 | BUG (A) | `world/door.gd` | `print("❌ Cámara no encontrada.")` in `move_camera_to()` | Changed to `push_warning()` |
| A8 | BUG (A) | `ui/debug_menu.gd` | No `process_mode = ALWAYS` — F1 was non-functional during any pause state | Added `process_mode = PROCESS_MODE_ALWAYS` in `_ready()` |
| A9 | BUG (A) | `ui/debug_menu.gd` | No `Global.is_dead` guard — F1 could theoretically open debug menu during death screen | Added `if Global.is_dead: return` guard in `_input()` |
| A10 | BUG (A) | Scene: both world scenes | DebugMenu absent from `world_dungeon.tscn` and `world_dungeon_random.tscn` — F1 dev tool completely inaccessible during normal play | Created `ui/debug_menu.tscn` and added to both scenes |

---

## 5. Architectural Inconsistencies Found

| # | Classification | Location | Finding | Action |
|---|---------------|----------|---------|--------|
| B1 | ARCHITECTURAL (B) | `world/door.gd` | `get_node()` used without null safety instead of `get_node_or_null()` — violates fail-safe pattern | Fixed (see A1 above) |

---

## 6. Documentation Errors Fixed

| # | File | Error | Fix |
|---|------|-------|-----|
| C1 | AGENT_CONTEXT.md §3.1 | Effect file count said "73 total" — outdated | Updated to "see Section 7 for current total" |
| C2 | AGENT_CONTEXT.md §3.1 | Item count said "290" — outdated | Updated to "295" |
| C3 | AGENT_CONTEXT.md §3.1 | `ui/` folder listed only `StatsUI, Pauser` — missing `DeathScreen, DebugMenu` | Updated folder listing |
| C4 | AGENT_CONTEXT.md §3.1 | `world/` folder didn't list `WorldDungeonRandom`, `FloorTransition`, templates | Updated folder listing |
| C5 | AGENT_CONTEXT.md §3.2 Player | `luck` stat missing from player stats list | Added `luck` to stats documentation |
| C6 | AGENT_CONTEXT.md §3.2 Global | Only listed 4 fields — missing `is_dead`, shop fields, map-intel fields, `reset_run_state()` | Rewrote Global description |

---

## 7. Intentional Design Decisions Confirmed (No Fix)

| # | Classification | Finding | Reason |
|---|---------------|---------|--------|
| D1 | DESIGN (D) | Boss is always `RapperEnemy` — no floor-based boss variety | Placeholder pending designer work. Boss gets HP/speed scaling via `difficulty_level`. |
| D2 | DESIGN (D) | Only one combat room template (`combat_room_template_01`) | Designer must author more. Generator already supports multiple templates. |
| D3 | DESIGN (D) | `GachaPonMachine` uses unseeded `randi()` for item selection | Gacha randomness is intentionally independent of generation seed. |
| D4 | DESIGN (D) | All purchased items show the "damage" sprite fallback | No item-specific sprites yet. Deferred. |
| D5 | DESIGN (D) | Empty gacha pool fails silently (no UX feedback) | Acceptable for demo; pool exhaustion UX is future work. |
| D6 | DESIGN (D) | `EnemySpawnSelector._metadata_cache` is a `static var` that persists across scene reloads within the same editor session | Intentional performance optimization. Metadata is constant; staleness only possible if @export values are changed in inspector and cached values remain. Acceptable for demo. |
| D7 | DESIGN (D) | `UpgradePickup` nodes spawned as children of `get_tree().current_scene` persist through WorldDungeonRandom floor transitions | Intentional pattern to prevent premature cleanup. Drops time out; uncollected pickups persist until scene reload (death). Noted as a minor demo limitation. |
| D8 | DESIGN (D) | Drops spawned via `get_tree().current_scene.add_child()` persist through floor transitions | Same as D7. Drops time out via Timer. |
| D9 | DESIGN (D) | Infection Gacha pool has only 2 exclusive items | Known gap documented in ITEM_POOL_DESIGN.md §6B. Not addressed in this session (requires new item content). |
| D10 | DESIGN (D) | Stats.gd uses `field` as backing-field accessor in property setters | Valid GDScript 4 pattern. The game works. Not a bug. |
| D11 | DESIGN (D) | `FloorTransition.advance_to_next_floor()` is called without `await` from `_on_body_entered` — `_move_player_and_camera_to_room` runs as fire-and-forget coroutine | Intentional. Camera animation completes asynchronously while the rest of the floor generation is synchronous. No race condition in current implementation. |
| D12 | DESIGN (D) | `AttackData.copy()` — all fields verified present including all cadence, appended_shots, archetype, and status payload fields | Complete. No missing fields. |
| D13 | DESIGN (D) | `EnemySpawnSelector._get_scene_metadata()` calls `scene.instantiate()` + `enemy.free()` to read @export values | Correct Godot 4 pattern. `_ready()` is NOT called since node never enters scene tree. No leak. |

---

## 8. Known Risks That Cannot Be Verified Without Godot

| Risk | System | Impact |
|------|--------|--------|
| Camera bounds — no per-template camera limits | world/templates | Player can see outside room geometry at edges. Need to test per template. |
| Room spacing 352×216 — templates must match this footprint | WorldDungeonRandom | If a template is significantly different in size, rooms may overlap or have gaps in world space. |
| SpawnPoint positions inside obstacles | combat_room_template_01 | 5 spawn points in generic grid — could be inside walls in a different template layout. Must validate per-template. |
| Gacha pool counts after filtering | GachaPonMachine | If an item has no `pool_tags` set, it would appear in neither pool. Static check not done for every item. |
| Boss difficulty scaling | boss_room_template | RapperEnemy gets HP/speed multipliers. Whether the boss is interesting/challenging on higher floors is unknown. |
| `Global.recently_moved` race | WorldDungeonRandom | Two concurrent floor-start coroutines could leave `recently_moved` in wrong state if advance is called while a prior camera animation is still running. |
| EnemySpawnSelector cache after tier changes | enemy_spawn_selector.gd | If a designer changes spawn_tier values in the Godot inspector (@export override), cached metadata won't update until editor restart. |

---

## 9. DO NOT RE-INVESTIGATE (Conclusively Resolved)

These were investigated in prior sessions and the conclusions are documented. Do not repeat the investigation unless a specific code change invalidates the documentation:

| Topic | Authority Document |
|-------|--------------------|
| Item architecture (phases 1–8, all effect types) | AGENT_CONTEXT.md §5, §7, ITEM_ARCHITECTURE_AUDIT.md |
| AttackData.copy() field completeness | Verified in this audit — complete |
| Enemy tier classification methodology | ENEMY_SPAWN_PROGRESSION.md |
| Item pool taxonomy and filtering rules | ITEM_POOL_DESIGN.md |
| Door BlockerBody collision architecture | AGENT_CONTEXT.md §3.2 Door section |
| Directional shot appender recursive-spawn prevention | AGENT_CONTEXT.md §7 Directional Shot rules |
| Burst cadence counter state semantics | AGENT_CONTEXT.md §7 Burst Cadence rules |
| EffectRuntimeSystem duplicate-registration safety | AGENT_CONTEXT.md §7 Additionally completed |
| Ramp runtime post-recalculate hook | AGENT_CONTEXT.md §7 Additionally completed |
| WorldDungeonRandom door semantic wiring | backlog.md Slice 46 |
| Death/restart flow | backlog.md Slice 48, AGENT_CONTEXT.md §7 |

---

## 10. Gameplay Tests Required (First Priority When Godot Opens)

Full playtest cases are in [PLAYTEST_MATRIX.md](PLAYTEST_MATRIX.md). Below is the **ordered priority list** for the first session back:

### P0 — Must Pass Before Claiming Demo Works

1. **Run the main scene** (`world/world_dungeon.tscn`) — confirm game starts without errors.
2. **Run WorldDungeonRandom** (`world/world_dungeon_random.tscn`) — confirm floor generates correctly.
3. **Complete a full floor loop**: Gacha → 4 Combat → Boss → Floor Transition → Floor 2.
4. **Player death**: Take enough damage to die. Confirm death screen shows. Confirm RESTART works. Confirm floor 1 restarts cleanly.
5. **Gacha purchase**: Buy from both the normal and infection gacha. Confirm correct pool filtering (normal gacha should NOT give `infected_rush` or `plague_feast`).
6. **F1 debug menu**: Open in both world scenes. Confirm item list loads. Confirm item acquisition works.

### P1 — Important Correctness

7. **Enemy tier progression**: On floor 1 (tier 1) — confirm only BatEnemy, BullyEnemy, MulliganEnemy, PooterEnemy appear in combat rooms. On floor 3+ (tier 3) — confirm RapperEnemy can appear.
8. **Door transitions**: Traverse all rooms forward and backward. Confirm camera tweens correctly.
9. **Boss clear → FloorTransition**: Defeat boss. Confirm FloorTransition spawns in boss room.
10. **Infection mechanic**: Infect an enemy. Confirm it turns green, speeds up. Confirm infected drop gives 2 drops instead of 1.
11. **ESC pause during gameplay** (not death): Confirm Pauser works normally. Confirm F1 works while paused.
12. **ESC during death**: Confirm ESC does nothing while death screen is showing.

### P2 — Balance/Feel

13. Spawn variety: verify multiple combat rooms on the same floor don't always spawn the same enemy.
14. Floor 2 difficulty: confirm enemies are harder (HP/speed multipliers applied).
15. Gacha economy pacing: confirm 1-drop cost is reasonable for early exploration.
16. Infection vs. normal build: play one infection-focused run and one normal run.

### P3 — Polish

17. Visual: confirm "YOU DIED" death screen is readable and centered.
18. Camera smoothness: confirm camera tween on door transition is not jarring.
19. Empty combat room warning: intentionally trigger zero-eligible tier case (e.g., floor 1 with only tier-3 enemies configured). Confirm warning in console, no crash.

---

## 11. Recommended First Steps When Godot Opens

1. Open `res://world/world_dungeon.tscn` (main scene, manual fallback).
2. Run. Complete P0 tests above.
3. If P0 passes: open `res://world/world_dungeon_random.tscn`.
4. Run. Complete P0 tests for WorldDungeonRandom.
5. If P0 passes for both: work through P1 tests.
6. Fix any P0/P1 bugs before testing P2/P3.
7. After passing P0/P1: author 2–3 additional combat room templates to validate template variety.
8. Report findings back and update PLAYTEST_MATRIX.md with results.

---

## 12. Current Playtest Blocker Assessment

**STATIC AUDIT COMPLETE — GAMEPLAY VALIDATION PENDING**

No static blockers found. All known code bugs have been fixed in this session.

The demo loop is architecturally complete and statically valid:
- ✅ Combat loop
- ✅ Infection mechanic
- ✅ Item system (295 items)
- ✅ Gacha + Infection Gacha with pool filtering
- ✅ Enemy tier progression (10 enemies, 5-tier model)
- ✅ Boss room + FloorTransition
- ✅ Floor advancement with difficulty scaling
- ✅ Player death + DeathScreen + clean restart
- ✅ WorldDungeon (manual, 5-room fallback)
- ✅ WorldDungeonRandom (linear generator with templates)
- ✅ DebugMenu (F1, now present in both world scenes)
- ⚠️ Only 1 combat template (zero variety — designer work required before claiming full demo)
- ⚠️ Boss always RapperEnemy (no variety — designer work required)

**The first playtest should focus on the P0 list above.**

---

*This document was generated during the final pre-playtest static audit session. Update the status field and add playtest results when Godot becomes available.*
