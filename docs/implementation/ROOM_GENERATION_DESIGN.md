# Room Generation Design (Operational Guide)

**Status**: IMPLEMENTED + STATICALLY VALIDATED, GAMEPLAY VALIDATION PENDING  
**Last Updated**: 2026-08-19  
**Scope**: Current operational guide for the experimental `WorldDungeonRandom` demo pipeline. Manual `WorldDungeon` remains fallback.

---

## Goal

This guide is for returning to Godot after time away and being able to:

1. open the experimental scene,
2. create or duplicate combat room templates,
3. author layout and SpawnPoints,
4. register templates,
5. run the current linear floor demo pipeline.

Current generated floor structure is intentionally simple:

```text
GACHA -> COMBAT x N -> BOSS -> FLOOR TRANSITION -> NEXT FLOOR
```

Nothing in this guide assumes branching maps, random walk generation, minimaps, secret rooms, or other future systems.

---

## Current Scenes You Can Use

### Experimental scene

- `res://world/world_dungeon_random.tscn`

This is the scene to open when testing the generated demo floor pipeline.

### Manual fallback scene

- `res://world/world_dungeon.tscn`

Use this if the experimental implementation fails or if you need the previous manual fallback.

---

## Current Runtime Structure

### WorldDungeonRandom owns

- number of combat rooms per floor
- room order
- room template selection
- room positioning
- room-to-room connection wiring
- floor progression
- enemy roster discovery
- current floor tier source
- shared generation RNG

### Room templates own

- room shell
- walls and collisions
- doors
- navigation
- `SpawnPoints`
- room-local enemy count settings
- room-local content such as machines or boss placeholder enemies

### Enemy system owns

- tier filtering
- weighted enemy selection
- repeated picks of the same enemy
- enemy instantiation into room SpawnPoints

---

## Starting The Experimental Scene

### Designer actions

1. Open Godot.
2. Open `res://world/world_dungeon_random.tscn`.
3. Run that scene directly.

### Generator behaviour

When the scene starts, the game currently:

1. randomizes the shared generation RNG,
2. synchronizes `Global.floor_number` and `Global.difficulty_level`,
3. scans `res://enemies/` for `*_enemy.tscn`,
4. builds a floor sequence:
   - one gacha room,
   - `combat_rooms_per_floor` random combat templates,
   - one boss room,
5. instantiates those rooms,
6. spaces them horizontally,
7. wires forward/backward room connections,
8. injects the enemy roster into non-boss combat rooms,
9. calls `respawn_enemies()` on each generated room,
10. moves player and camera to the generated gacha room.

### Code changes

Only needed if you want to alter the generator itself, not to run the scene.

### Gameplay validation

Still required to confirm the scene actually behaves correctly in motion, traversal, and progression.

---

## Creating A New Combat Room Template

### Designer actions

1. Duplicate:
   - `res://world/templates/combat_room_template_01.tscn`
2. Rename it, for example:
   - `combat_room_template_02.tscn`
3. Open the duplicated scene.

### Generator behaviour

Nothing happens automatically until the new template is registered in `WorldDungeonRandom`.

### Code changes

Not required to create a new template scene.

### Gameplay validation

Required later to confirm traversal, enemy placement, and readability.

---

## Designing The Room Layout

Current combat templates are built by instancing:

- `res://world/room.tscn`

That inherited base room already contains:

- walls
- doors
- navigation
- `Enemies`
- `SpawnPoints`

### Designer actions

Inside the duplicated combat template, you can:

1. add decorations,
2. add obstacles,
3. adjust existing room-local content,
4. move or replace inherited nodes if needed.

### What must remain unchanged

These parts are part of the current contract and should remain intact unless the generator is intentionally updated later:

1. The root remains a Room-based scene.
2. The inherited doors remain present.
3. The inherited `SpawnPoints` node remains present.
4. The room remains compatible with the current standard spacing assumption.

### Generator behaviour

The generator does not inspect your room internals except through the Room contract:

- forward door
- backward door
- SpawnPoints
- room-local enemy count settings

### Code changes

Not required just to design layout.

### Gameplay validation

You will need runtime validation for collision readability, pathing, spacing, and camera feel.

---

## Using The Inherited SpawnPoints Node

The base Room scene now contains an inherited empty node:

- `SpawnPoints`

Current combat template example uses children under that node:

```text
SpawnPoints
├── Spawn01
├── Spawn02
├── Spawn03
├── Spawn04
└── Spawn05
```

### Designer actions

To use SpawnPoints in a combat template:

1. Select the inherited `SpawnPoints` node.
2. Add `Marker2D` children under it.
3. Name them however you want; the generator only needs them to be `Node2D` children.
4. Move them to the positions where enemies should be allowed to spawn.

### Generator behaviour

For non-boss combat rooms, Room resolves spawn positions in this order:

1. `SpawnPoints/*`
2. baked enemy positions under `Enemies`
3. fallback positions near room center

That means combat templates do not need baked enemies for generated combat composition.

### Code changes

Not required to add or move SpawnPoints.

### Gameplay validation

You still need to verify enemy placement feels good and does not clip into obstacles.

---

## Adding, Removing, Or Moving SpawnPoints

### Designer actions

You can freely:

1. add more SpawnPoint markers,
2. remove SpawnPoint markers,
3. move existing SpawnPoint markers.

### Generator behaviour

- If there are enough SpawnPoints, selected enemies use those positions.
- If there are fewer SpawnPoints than selected enemies, Room repeats positions from the available list.
- If there are zero SpawnPoints, Room falls back to baked enemy positions or center fallback positions.

### Code changes

Not required.

### Gameplay validation

You need to confirm repeated positions or sparse points do not create unfair or overlapping spawns.

---

## Configuring enemy_spawn_min_count And enemy_spawn_max_count

Current combat template example already sets:

- `enemy_spawn_min_count = 3`
- `enemy_spawn_max_count = 5`

### Designer actions

On the room root, set:

1. `enemy_spawn_min_count`
2. `enemy_spawn_max_count`

Use `enemy_spawn_count` only if you want a fixed count.

### Generator behaviour

Room resolves enemy count in this order:

1. If `enemy_spawn_min_count > 0` and `enemy_spawn_max_count >= enemy_spawn_min_count`, it rolls a random value in that range.
2. Otherwise, if `enemy_spawn_count > 0`, it uses that fixed count.
3. Otherwise, it falls back to available spawn positions.
4. Otherwise, it falls back to baked enemy template count.

### Code changes

Not required.

### Gameplay validation

Required later to determine if each room’s enemy count range feels correct.

---

## Registering A Template In WorldDungeonRandom

### Designer actions

1. Open `res://world/world_dungeon_random.tscn`.
2. Select the root `WorldDungeonRandom` node.
3. In the exported property `combat_room_templates`, add your new combat template scene.

### Generator behaviour

At floor generation time, the generator randomly chooses from the registered `combat_room_templates` array.

### Code changes

Not required unless you want different generator logic.

### Gameplay validation

Required to confirm the new template appears and behaves correctly in actual runs.

---

## How Template Selection Works

### Generator behaviour

The generator currently:

1. always places one gacha template first,
2. then places `combat_rooms_per_floor` combat templates,
3. then places one boss template last.

Combat template selection is random.

Important current behavior:

- repetition is allowed,
- the same combat template can appear multiple times in one floor,
- template identity does not control which enemies appear.

### Designer actions

Only register templates. The generator handles selection automatically.

### Code changes

Only needed if you want to change the selection policy.

### Gameplay validation

You need runtime checks to confirm repetition is acceptable and variety feels sufficient.

---

## How Enemy Selection Works

### Generator behaviour

Actual runtime flow:

```text
current floor number
  -> current spawn tier
  -> tier-eligible enemy scenes
  -> weighted random selection
  -> spawn count
  -> SpawnPoints positions
  -> enemy instances under Room.Enemies
```

Current tier source:

- `Global.floor_number`
- clamped by `WorldDungeonRandom.get_current_spawn_tier()`

Tier rules:

- an enemy is eligible if current tier is at least `spawn_tier_min`
- and either `spawn_tier_max == 0` or current tier is at most `spawn_tier_max`

Weight rule:

- `spawn_weight` is used as relative probability among eligible enemies

Selection rule:

- selection is with replacement
- the same enemy can be selected multiple times in the same room

Important Isaac-like progression behavior:

- early enemies remain available on later floors if their metadata allows it
- later enemies do not appear early unless their minimum tier allows it

### Designer actions

None, unless you are authoring room-local enemy counts or SpawnPoints.

### Code changes

Only needed if enemy metadata or selector behavior itself must change.

### Gameplay validation

You must verify:

1. weight distribution feels right,
2. repeated enemies are acceptable,
3. higher floors feel progressively harder without excluding all early enemies.

---

## How Many Enemies Can Appear, And Where

### Generator behaviour

How many enemies can appear:

- comes from room-local count settings on the template

Where they appear:

- first from `SpawnPoints/*`
- then from baked enemy positions if no SpawnPoints are present
- then from fallback center-near positions if neither exists

### Designer actions

1. Set the count range on the room root.
2. Place SpawnPoints where valid spawn locations should exist.

### Gameplay validation

You need to confirm enemies are not spawning inside walls, machines, doors, or blocking geometry.

---

## What Happens If The Same Template Is Selected Repeatedly

### Generator behaviour

Nothing special happens.

Current design allows:

```text
CombatTemplate02
CombatTemplate02
CombatTemplate01
CombatTemplate02
```

The layout may repeat, but enemy count and enemy composition can still vary.

### Designer actions

No special action required.

### Gameplay validation

Required to decide whether repetition is acceptable for the demo.

---

## What Happens If The Same Enemy Is Selected Repeatedly

### Generator behaviour

Weighted selection is performed with replacement.

That means one room can legitimately generate:

```text
Bat
Bat
Bat
Nerd
```

This is currently allowed by design.

### Designer actions

None.

### Gameplay validation

Required to confirm whether repetition feels good and whether spawn weights need tuning.

---

## Understanding The Gacha Room

Current gacha template scene:

- `res://world/templates/gacha_room_template.tscn`

It currently contains:

1. normal Gacha machine,
2. Infection Gacha machine,
3. RespawnMachine,
4. DifficultyMachine.

### Generator behaviour

- The gacha room is always the first generated room of each floor.
- After a floor transition, the next floor is rebuilt and starts again from a gacha room.

### Designer actions

You do not need to place the gacha room manually in generated floors.

### Code changes

Only needed if the gacha room content itself should change.

### Gameplay validation

You still need to confirm both pools appear and work correctly in the generated run loop.

---

## Understanding Boss -> Floor Transition -> Next Floor

Current boss template scene:

- `res://world/templates/boss_room_template.tscn`

Current boss setup:

- one placeholder Rapper enemy baked into the template

Current floor transition behavior:

1. boss room is cleared,
2. world spawns `FloorTransition` into that boss room,
3. player enters the transition,
4. transition calls `advance_to_next_floor()` on the active world,
5. world increments `Global.floor_number`,
6. world updates `Global.difficulty_level`,
7. world rebuilds the whole linear floor,
8. player and camera are moved to the new gacha room.

### Designer actions

None are required for floor progression once the boss template is registered.

### Gameplay validation

Still required to verify that the transition appears reliably and that floor rebuild feels correct.

---

## What Changes When floor_number Increases

### Generator behaviour

When `Global.floor_number` increases:

1. current spawn tier can increase,
2. more enemies may become eligible based on `spawn_tier_min`,
3. early enemies can still remain eligible if allowed by metadata,
4. `Global.difficulty_level` also increases,
5. respawned/generated enemies receive stronger multipliers through the existing difficulty path.

### Gameplay validation

You will need to validate whether the combined effect of tier progression plus difficulty scaling feels correct.

---

## Switching Back To Manual WorldDungeon Fallback

### Designer actions

If the experimental scene fails, open and run:

- `res://world/world_dungeon.tscn`

This remains the fallback scene.

### Generator behaviour

The manual fallback uses the shared Room/Door architecture but remains a separate scene with manually placed rooms.

### Code changes

Not required to switch back.

### Gameplay validation

Manual fallback should also be rechecked after any shared Room/Door changes.

---

## Semantic Door Contract

Each `Door` now has a semantic role:

- `NONE`
- `FORWARD`
- `BACKWARD`

Current base-room convention:

- `Door2` = `FORWARD`
- `Door4` = `BACKWARD`

### What must remain unchanged when authoring a template

1. The inherited doors must remain present.
2. The forward/backward semantic role must remain correct.
3. The generator should not need to know arbitrary internal node names.

You may preserve the inherited nodes as they are unless a later code change intentionally changes the contract.

---

## Designer Actions

These are the things you do manually in Godot:

1. Open `world_dungeon_random.tscn`.
2. Duplicate `combat_room_template_01.tscn`.
3. Edit room layout.
4. Use inherited `SpawnPoints`.
5. Add/remove/move SpawnPoint markers.
6. Set `enemy_spawn_min_count` and `enemy_spawn_max_count`.
7. Register the new template in `combat_room_templates`.
8. Run the scene and test the result.
9. Switch to `world_dungeon.tscn` if the experimental scene fails.

---

## Generator Behaviour

These are the things the game does automatically:

1. Builds the linear room sequence.
2. Randomly selects combat templates, allowing repetition.
3. Positions rooms using the standard spacing contract.
4. Connects rooms through semantic forward/backward doors.
5. Determines the current tier from floor number.
6. Filters eligible enemies.
7. Applies weighted random selection.
8. Rolls enemy count.
9. Uses SpawnPoints for enemy placement.
10. Spawns boss-room floor transition.
11. Advances to next floor and rebuilds the chain.
12. Restarts the next floor at the gacha room.

---

## Code Changes

These require Copilot/development work rather than designer setup:

1. Changing the generator order or structure.
2. Changing the enemy selection algorithm.
3. Changing the semantic door contract.
4. Changing the standard room spacing assumption.
5. Adding new world-level procedural systems.
6. Changing floor progression logic.

---

## Gameplay Validation

These cannot be confirmed from static inspection alone:

1. WorldDungeonRandom loads and plays correctly.
2. Door traversal feels correct.
3. SpawnPoints produce good combat spacing.
4. Template repetition feels acceptable.
5. Same-enemy repetition feels acceptable.
6. Weight distribution feels correct.
7. Floor 2+ progression feels right.
8. Manual fallback still behaves correctly after shared scene/script changes.

See `docs/implementation/PLAYTEST_MATRIX.md` for the current validation checklist.

---

## First 30 Minutes After Returning To Godot

1. Open `res://world/world_dungeon_random.tscn` and run it once.
2. If it fails or behaves unexpectedly, switch immediately to `res://world/world_dungeon.tscn` to confirm the manual fallback still runs.
3. Duplicate `res://world/templates/combat_room_template_01.tscn` into a second combat template.
4. Open the new template and place a few obstacles/decorative elements for a distinct layout.
5. Under the inherited `SpawnPoints` node, move existing markers or add/remove markers to match the new layout.
6. Set room-root `enemy_spawn_min_count` and `enemy_spawn_max_count` for that template.
7. Open `res://world/world_dungeon_random.tscn` and add the new template to `combat_room_templates`.
8. Run `world_dungeon_random.tscn` again.
9. Confirm the generated floor still follows `GACHA -> COMBAT x N -> BOSS`.
10. Traverse rooms and verify:
    - gacha room appears first,
    - combat layouts can repeat,
    - enemy positions follow SpawnPoints,
    - boss room appears last,
    - floor transition advances to a new floor,
    - generated floor 2 uses the updated floor/tier path.
