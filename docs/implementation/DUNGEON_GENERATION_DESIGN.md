# Dungeon Generation Design Specification

**Status**: Full procedural design only (future)  
**Last Updated**: 2026-08-19  
**Target**: Future procedural generation beyond the current experimental linear generator  

---

> **⚠️ SCOPE CLARIFICATION (2026-08-19)**
>
> This document describes the **future** procedural dungeon system. It is a design reference, not a current implementation plan.
>
> The current isolated experimental implementation is documented in:
> - `docs/implementation/ROOM_GENERATION_DESIGN.md`
> - Scene: `res://world/world_dungeon_random.tscn`
>
> **The current demo does NOT require this system.** The demo uses a simple, hand-authored room sequence:
> - Gacha room → combat rooms → boss room → floor transition → repeat
>
> The 8–12 room grid/random-walk generator described in Sections 5 and 11 (Phase 1) is **FUTURE/PROVISIONAL**. It should only be implemented after the core demo loop (combat + infection + gacha + boss + floor progression) is validated through gameplay.
>
> Sections 1–3 (current architecture analysis) remain accurate and are valid inputs for any future work.



---

## 1. Current Architecture (Facts)

### 1.1 WorldDungeon (world_dungeon.gd)

**Owns:**
- Hardcoded array of 5 room instances: `$Room1` through `$Room5`
- Reference to `starting_room = $Room1`
- Drops label UI binding

**Behavior:**
- `_ready()`: Activates starting room
- `_process()`: Updates drops label
- `respawn_all_enemies()`: Iterates hardcoded rooms array and calls `room.respawn_enemies()`

**Code Pattern:**
```gdscript
@onready var rooms = [$Room1, $Room2, $Room3, $Room4, $Room5]
func respawn_all_enemies():
  for room in rooms:
    room.respawn_enemies()
```

### 1.2 Room (room.gd)

**Owns:**
- `active: bool` — current activation state
- `enemy_templates: Array[Dictionary]` — captured on `_ready()` from scene children; each template contains:
  - `scene: PackedScene`
  - `position: Vector2`
  - `name: String`
- `@export combat_room: bool` — determines door/enemy behavior
- `_room_cleared_emitted: bool` — prevents duplicate room_cleared events
- **4 Door instances** hardcoded: `$Door`, `$Door2`, `$Door3`, `$Door4`
- **Enemies Node2D** container for active enemy instances

**Behavior:**
- `_ready()`: Scans Enemies container for PackedScene children and builds enemy_templates array
- `_process()`: 
  - If not combat_room: always open doors
  - If combat_room: close doors while enemies exist, open them when enemies cleared
  - Emits `room_cleared` signal once per clear (tracked by `_room_cleared_emitted`)
- `activate()`: Sets `active = true`, emits `room_entered` signal
- `deactivate()`: Sets `active = false`, emits `room_exited` signal
- `open_doors()`: Opens doors with destinations (via `door.has_destination()`), closes others
- `close_doors()`: Closes all doors
- `respawn_enemies()`: Clears active enemies and re-instantiates from templates with difficulty scaling

**Door State Logic:**
```gdscript
func _process(_delta: float) -> void:
  if not combat_room:
    open_doors()
    return
  if has_enemies():
    _room_cleared_emitted = false
    close_doors()
  else:
    if active and not _room_cleared_emitted:
      _room_cleared_emitted = true
      EventBus.emit_room_cleared(...)
    open_doors()
```

### 1.3 Door (door.gd)

**Owns:**
- `@export tp_position: String` — node path to destination Room (e.g., `"../../Room2"`)
- `@export enabled: bool` — whether this door is open (default: false)
- `transition_area: Area2D` — collision trigger for player entry
- `marker_2d: Marker2D` — target position for player and camera on transition
- `blocker_shape: CollisionPolygon2D` — collision box that blocks movement when door closed

**Behavior:**
- `_ready()`: Sets `blocker_shape.disabled = enabled` (disabled shape means collision active)
- `_on_transition_area_body_entered()`:
  - Checks if door is open (`enabled == false` → return early)
  - Waits for transition cooldown if `Global.recently_moved`
  - Resolves destination via node path: `get_tree().current_scene.get_node(tp_position)`
  - Moves player to destination `marker_2d` position
  - Tweens camera to destination room's marker
  - Deactivates current room, activates destination room
  - Sets `Global.recently_moved = true` for 0.3 seconds (prevents spurious re-triggers)
- `open()`: Sets `enabled = true`, modulate WHITE, `blocker_shape.disabled = true`
- `close()`: Sets `enabled = false`, modulate BLACK, `blocker_shape.disabled = false`

**Door Identification:**
```gdscript
@export var tp_position: String  # Stores literal node path as string
# Usage in Door._on_transition_area_body_entered():
var destination_room := get_tree().current_scene.get_node(tp_position) as Room
```

### 1.4 Room Positioning & Connections

**Position Model:** Hardcoded in scene (`room.tscn` instances placed at specific coordinates in world)  
**Connection Model:** Door.tp_position references node path (brittle for procedural generation)  
**Room Identification:** Implicit via node name ($Room1, $Room2, etc.)

### 1.5 Camera & Player Transition

**Mechanism:**
1. Player touches TransitionArea (Area2D on Door)
2. Door resolves destination Room node path
3. Door teleports player to `destination_marker_2d.global_position`
4. Door tweens Camera2D from current position to destination marker
5. Current room calls `deactivate()`, destination calls `activate()`

**Dependencies:**
- Player must be in `transition_area.get_overlapping_bodies()`
- Door must have valid `tp_position` (checked: `if not tp_position: return`)
- World must have `Camera2D` node at root level

### 1.6 Room Clearing & Combat

**Combat Loop:**
- Room starts with `_room_cleared_emitted = false`
- While `has_enemies()`: doors close
- When enemies cleared:
  - `room_cleared` event emitted (once)
  - Doors open (those with destinations)
  - Dead enemies already despawned via `queue_free()`

**Door Opening Logic:**
```gdscript
func open_doors() -> void:
  for door: Door in doors:
    if door.has_destination():
      door.open()
    else:
      door.close()
```

Note: Doors without `tp_position` set stay closed (act as decorative walls).

---

## 2. Current Limitations (Blocking Procedural Generation)

| Limitation | Impact | Why It Blocks Procedural |
|-----------|--------|--------------------------|
| Hardcoded room array in WorldDungeon | Cannot instantiate dynamic room count | Need runtime room instantiation |
| Room positions hardcoded in scene | Cannot place rooms at generated coordinates | Need coordinate-based spawning |
| Door.tp_position uses node paths | Cannot reference rooms created at runtime | Need room ID system |
| No room identification system | Cannot address rooms by ID/coordinate | Need unique room references |
| No room graph | Cannot determine connectivity | Need explicit connection tracking |
| No floor/level concept | Cannot support multiple floors | Need floor abstraction |
| Limited room type (just `combat_room` bool) | Cannot distinguish boss/reward/combat | Need room type enum |
| No persistence tracking | Revisiting room respawns all enemies | Need visited/cleared state tracking |
| No seed-based generation | Cannot guarantee deterministic runs | Need RNG seeding |

---

## 3. Proposed Future Architecture

### 3.1 Conceptual Model

```
DungeonManager (singleton-like access)
    │
    ├── Floor
    │   ├── floor_number: int
    │   ├── seed: int
    │   └── room_graph: RoomGraph
    │       └── Dictionary[String, RoomNode]
    │
    └── WorldDungeon
        └── Instantiated Room nodes (created at runtime from RoomGraph)
            ├── Room1_Generated (loaded from room.tscn, with enemy templates configured)
            ├── Room2_Generated
            └── ...
```

### 3.2 Conceptual Data Flow

```
1. DungeonManager.generate_floor(floor_number, seed)
2. RoomGraph generation (grid-based walk, place boss, place reward)
3. DungeonManager.instantiate_rooms(room_graph)
4. For each RoomNode in graph:
   - Load room.tscn as child of WorldDungeon
   - Configure Room with:
     * room_id (for identification)
     * room_type (COMBAT/BOSS/REWARD)
     * door destinations (set tp_position or new ID-based system)
     * enemy templates (based on room_type and difficulty)
   - Set global_position to room_graph coordinate
5. Set player starting position in Room1_Generated
6. Activate starting room
```

### 3.3 What Stays the Same

- **Room scene structure** — 4 Door instances, Enemies container, NavigationRegion2D
- **Door scene structure** — TransitionArea, BlockerBody, Marker2D
- **Player/camera movement** — existing tweening system
- **Collision layer/mask system** — unchanged
- **EventBus signal system** — room_entered, room_cleared, room_exited
- **Difficulty scaling** — health_multiplier and speed_multiplier per room
- **Enemy template loading** — Room scans Enemies container on _ready()

### 3.4 What Changes

- **WorldDungeon** — replaces hardcoded room array with dynamically instantiated rooms from RoomGraph
- **Room identification** — adds `room_id` property instead of relying on node path
- **Door destination resolution** — changes from node path to room ID reference
- **Room persistence** — tracks visited/cleared state across transitions
- **Room spawn configuration** — enemy templates determined by room_type and generation parameters

---

## 4. Data Model

### 4.1 Room Node (RoomNode / RoomData)

**Purpose:** Represent a single room in the generated dungeon graph, before instantiation.

**Proposed Structure:**

```gdscript
class RoomNode:
  var room_id: String              # Unique identifier (e.g., "F1_R1_Combat")
  var room_type: RoomType          # Enum: COMBAT, BOSS, REWARD
  var grid_position: Vector2i      # Grid coordinates (e.g., Vector2i(2, 1))
  var world_position: Vector2      # Computed from grid_position × room_size
  var connections: Dictionary      # [String, String]: direction → neighbor_room_id
                                   # e.g., {"north": "F1_R2_Combat", "east": "F1_R3_Reward"}
  var enemy_config: Dictionary     # Enemy setup for this room (difficulty, count, types)
  var visited: bool                # True if player has entered this room
  var cleared: bool                # True if all enemies defeated (persistent per run)
  var entrance_position: Vector2   # Player spawn position within room on entry
```

**Why this structure:**
- `room_id` allows runtime reference (replaces node path)
- `grid_position` enables deterministic layout and visual debugging
- `connections` explicitly track graph edges
- `enemy_config` supports procedural difficulty scaling
- `visited`/`cleared` enable state persistence
- `world_position` computed from grid to avoid manual entry

**Owner:** RoomGraph  
**Type:** `RefCounted` class (lightweight, no scene node overhead at runtime)

---

### 4.2 Room Graph (RoomGraph)

**Purpose:** Container for all RoomNode instances in a floor, with convenience methods.

**Proposed Structure:**

```gdscript
class RoomGraph:
  var rooms: Dictionary             # room_id → RoomNode
  var starting_room_id: String
  var boss_room_id: String
  var connections: Array            # Flat list of (room_a_id, direction, room_b_id) tuples
  
  func get_room(room_id: String) -> RoomNode
  func get_neighbors(room_id: String) -> Array[String]
  func get_room_by_grid_pos(grid_pos: Vector2i) -> RoomNode
  func validate() -> bool           # Ensures starting and boss rooms exist, graph is connected
```

**Why this structure:**
- Centralized access to all room metadata
- Enables graph traversal (useful for validation, visualization, debugging)
- Validates dungeon coherence before instantiation

**Owner:** Floor  
**Type:** `RefCounted` class

---

### 4.3 Floor

**Purpose:** Represent a single floor/level with its own generated dungeon.

**Proposed Structure:**

```gdscript
class Floor:
  var floor_number: int             # 1, 2, 3, etc.
  var seed: int                     # For deterministic generation
  var room_graph: RoomGraph         # All rooms and connections for this floor
  var visited_rooms: Array[String]  # room_ids of visited rooms (persistent per run)
  var cleared_rooms: Array[String]  # room_ids of cleared rooms (persistent per run)
  
  func is_room_visited(room_id: String) -> bool
  func is_room_cleared(room_id: String) -> bool
  func mark_room_visited(room_id: String)
  func mark_room_cleared(room_id: String)
```

**Why this structure:**
- Encapsulates floor state
- Tracks which rooms have been visited/cleared
- Enables floor reset without losing run state

**Owner:** DungeonManager or Global (singleton-like)  
**Type:** `RefCounted` class

---

### 4.4 Room Type (Enum)

**Purpose:** Distinguish room categories for generation and behavior.

**Proposed Enum:**

```gdscript
enum RoomType {
  COMBAT,      # Normal enemy room
  BOSS,        # Boss encounter (marks floor exit)
  REWARD,      # Item/treasure room, no enemies
}
```

**Why only 3 types initially:**
- COMBAT handles standard enemy encounters
- BOSS handles floor progression (required for multiple floors)
- REWARD handles incentive rooms (treasure, healing, etc.)
- No SHOP, no SECRET rooms in first version (can add later without redesign)

**Future extension:** Add SHRINE, SHOP, TREASURE, CHALLENGE, etc. as needed.

---

### 4.5 Enemy Configuration (Data Structure)

**Purpose:** Tell a Room what enemies to spawn.

**Proposed Structure:**

```gdscript
class EnemyConfig:
  var enemy_types: Array[String]        # e.g., ["bat_enemy", "bully_enemy"]
  var count_per_type: Array[int]        # e.g., [2, 1] for 2 bats, 1 bully
  var difficulty_override: float        # e.g., 1.5× for harder combat
  var spawn_positions: Array[Vector2]   # Optional; if empty, randomize within room
```

**Alternative: Simpler Inline Dictionary**

```gdscript
# In RoomNode.enemy_config:
{
  "enemies": ["bat_enemy", "bully_enemy"],
  "counts": [2, 1],
  "difficulty_mod": 1.0
}
```

**Why this structure:**
- Separates generation logic from Room scene
- Supports difficulty scaling per room
- Allows randomized or fixed spawn positions
- Can be modified by generator before instantiation

**Owner:** RoomNode  
**Type:** `RefCounted` class or inline Dictionary

---

## 5. Generation Algorithm Recommendation

### 5.1 Comparison of Approaches

| Approach | Pros | Cons | Fit for Isaac-like Demo |
|----------|------|------|--------------------------|
| **A. Random Walk** | Natural branching, good exploration, Mazey feel | Unpredictable difficulty curve, hard to guarantee boss connection | ⚠️ Okay but risky |
| **B. Grid-based Graph** | Deterministic, easy to debug/visualize, scalable, predictable difficulty | Less organic feel, requires explicit connection rules | ✅ **Best choice** |
| **C. Hand-authored Templates** | Full control, predictable, compact content | Requires manual design for each layout, not truly procedural | ❌ Not procedural |
| **D. Hybrid (Templates + Placement)** | Combines control with proceduralism | Complexity, two systems to maintain | ⏳ Future optimization |

### 5.2 Recommended: Grid-Based Room Graph Generation

**Algorithm Outline:**

```
1. Create 4×4 grid (customizable size)
2. Seed RNG with Floor.seed
3. Place starting room at (0, 0)
4. Random walk from (0, 0):
   - From current position, randomly pick unvisited neighbor (up/down/left/right)
   - Place room, record connection
   - Continue until N rooms placed (e.g., 8–12 rooms per floor)
5. Place boss room at far corner or random end-of-path position
6. Place 1–2 reward rooms in branching paths
7. Validate graph: check all rooms reachable from start
8. Return RoomGraph
```

**Why this approach:**
- **Deterministic:** Same seed produces same layout every time
- **Debuggable:** Grid-based positions are easy to visualize and print
- **Scalable:** Works for 1 floor or 10 floors
- **Isaac-like:** Produces connected, somewhat random-feeling dungeons without being maze-like
- **Simple:** ~50–100 lines of GDScript, no complex graph algorithms needed

**Pseudo-code:**

```gdscript
func generate_dungeon_grid(floor_number: int, seed: int, grid_size: Vector2i = Vector2i(4, 4)) -> RoomGraph:
  var rng = RandomNumberGenerator.new()
  rng.seed = seed
  
  var room_graph = RoomGraph.new()
  var placed_positions = [Vector2i(0, 0)]  # Starting room
  
  # Random walk to place rooms
  var current_pos = Vector2i(0, 0)
  while placed_positions.size() < desired_room_count:
    var neighbors = get_unvisited_neighbors(current_pos, grid_size, placed_positions)
    if neighbors.is_empty():
      current_pos = placed_positions[rng.randi_range(0, placed_positions.size() - 1)]
      continue
    var next_pos = neighbors[rng.randi_range(0, neighbors.size() - 1)]
    placed_positions.append(next_pos)
    record_connection(room_graph, current_pos, next_pos)
    current_pos = next_pos
  
  # Place boss room at far end
  var boss_pos = placed_positions[placed_positions.size() - 1]
  mark_as_boss(room_graph, boss_pos)
  
  # Place reward rooms
  for i in range(reward_room_count):
    var reward_pos = placed_positions[rng.randi_range(0, placed_positions.size() - 1)]
    if reward_pos != boss_pos and reward_pos != Vector2i(0, 0):
      mark_as_reward(room_graph, reward_pos)
  
  return room_graph
```

### 5.3 Alternative: Expand When Blocked

If random walk gets stuck:
1. Backtrack to last position with unvisited neighbors
2. Try different direction
3. If all neighbors visited, pick random previously placed position and try again

This ensures we always fill target room count.

---

## 6. Room Type Model

### 6.1 Minimum Viable Room Types

```
RoomType.COMBAT
  ├── Spawn 2–4 enemies (randomized from enemy pool)
  ├── Doors close until enemies cleared
  ├── Drop 1 per enemy killed
  └── Difficulty scales with floor_number

RoomType.BOSS
  ├── Spawn single boss enemy (different HP/behavior)
  ├── Doors close until boss defeated
  ├── Mark floor as cleared (exit point to next floor)
  └── Drop significant reward

RoomType.REWARD
  ├── No enemies
  ├── Doors always open
  ├── Contains 1–3 random items or healing
  └── Optional: treasure chest item
```

### 6.2 Implementation in Room.gd

**Current:**
```gdscript
@export var combat_room: bool = true

func _process(_delta: float) -> void:
  if not combat_room:
    open_doors()
    return
  # ...
```

**Proposed (no scene change needed):**

```gdscript
@export var room_type: RoomType = RoomType.COMBAT

func _process(_delta: float) -> void:
  match room_type:
    RoomType.COMBAT:
      if has_enemies(): close_doors()
      else: open_doors()
    
    RoomType.BOSS:
      if has_enemies(): close_doors()
      else: 
        open_doors()
        EventBus.emit_signal("boss_defeated")
    
    RoomType.REWARD:
      open_doors()
```

**Why no major refactor needed:**
- Existing door logic generalizes to room_type
- Enemy templates already determined by room configuration
- REWARD rooms just have empty enemy list

---

## 7. Room Persistence Model

### 7.1 Revisiting a Room

**Current Behavior:** `respawn_all_enemies()` called globally, respawns all enemies in all rooms.

**Proposed Behavior:**
- When player re-enters a room that was already cleared, **do not respawn enemies**
- When player re-enters a room that was not fully cleared, **resume from saved state** (or respawn)

### 7.2 Persistence State

**Per Room, Per Run:**
```gdscript
class RoomPersistenceState:
  var visited: bool                    # Player entered at least once
  var cleared: bool                    # All enemies defeated
  var enemy_state: Array               # Optional: save individual enemy HP/status (future)
  var collected_items: Array[String]   # Optional: track item pickups (future)
```

**Storage:** Floor.visited_rooms and Floor.cleared_rooms arrays store room_ids.

### 7.3 Integration with Room.respawn_enemies()

**Option A: Check Floor state before spawning**

```gdscript
# In Room._ready() or when entering:
if Floor.is_room_cleared(room_id):
  # Don't call respawn_enemies(), skip to _process with empty enemy list
  return

# Otherwise, call respawn_enemies() normally
respawn_enemies()
```

**Option B: Skip respawn call from WorldDungeon**

```gdscript
# In WorldDungeon.respawn_all_enemies():
for room in rooms:
  if not Floor.is_room_cleared(room.room_id):
    room.respawn_enemies()
```

**Recommendation:** Option B (easier to debug, respawn call is explicit).

### 7.4 Door State on Revisit

**Current:** Doors controlled by `has_enemies()` in `_process()`.  
**Proposed:** Same logic applies. If room cleared, `has_enemies()` returns false, doors open.

No changes needed to Door.gd.

---

## 8. Floor Model & Multiple Floors

### 8.1 Floor Abstraction

```gdscript
class Floor:
  var floor_number: int
  var seed: int
  var room_graph: RoomGraph
  var visited_rooms: Array[String]
  var cleared_rooms: Array[String]
  
  var boss_defeated: bool            # True when boss room cleared
  var player_current_room_id: String # Track player position
```

### 8.2 Floor Progression

**Conceptual Flow:**

```
Global State:
  current_floor: Floor = Floor(1)
  
Player beats boss → Signal room_cleared event
EventBus listener in DungeonManager:
  Mark floor.boss_defeated = true
  Create next floor: Floor(2, seed + 1)
  Unload current rooms
  Generate and instantiate new rooms from Floor(2)
  Activate Floor(2) Room(0)
  Player enters Floor(2)
```

### 8.3 Each Floor is Isolated

**File/Memory Isolation:**

```
Floor 1 (5–8 rooms, ~200KB if loaded)
  → Unloaded when floor clears
  → Save data persists to Global/save system
  → Can be re-generated with same seed

Floor 2 (5–8 rooms, ~200KB if loaded)
  → Active during play
  → Player progression tracked here
  → Unloaded on game over or floor completion
```

**Seed Derivation (recommended):**

```gdscript
func derive_floor_seed(base_seed: int, floor_number: int) -> int:
  # Same base seed + different floor number = different but deterministic layout
  return base_seed * 31 + floor_number
```

This ensures runs are deterministic per base seed, but each floor differs.

---

## 9. Integration Points with Existing Code

### 9.1 WorldDungeon Changes

**Current:**
```gdscript
@onready var rooms = [$Room1, $Room2, $Room3, $Room4, $Room5]

func _ready():
  starting_room.activate()
```

**Future (pseudocode):**
```gdscript
var rooms: Array[Room] = []

func _ready():
  var dungeon_manager = DungeonManager.get_singleton()
  var floor = dungeon_manager.get_current_floor()
  instantiate_rooms_from_graph(floor.room_graph)
  
  var starting_room = get_node_or_null("Room_F1_R1_Combat")
  if starting_room:
    starting_room.activate()

func instantiate_rooms_from_graph(room_graph: RoomGraph):
  for room_node in room_graph.rooms.values():
    var room_scene = preload("res://world/room.tscn")
    var room_instance = room_scene.instantiate()
    
    # Configure room with generated data
    room_instance.room_id = room_node.room_id
    room_instance.room_type = room_node.room_type
    configure_doors(room_instance, room_node)
    configure_enemies(room_instance, room_node.enemy_config)
    
    # Position in world
    room_instance.global_position = room_node.world_position
    
    # Add to world
    add_child(room_instance)
    rooms.append(room_instance)
```

**Key Changes:**
- Replace hardcoded `$Room1..$Room5` with dynamic loop
- Call `configure_doors()` and `configure_enemies()` to set runtime properties
- Position rooms based on `room_node.world_position`

### 9.2 Room Changes

**Add:**
```gdscript
@export var room_id: String = ""
@export var room_type: RoomType = RoomType.COMBAT

func configure_for_generation(room_id: String, room_type: RoomType, enemy_config: Dictionary):
  self.room_id = room_id
  self.room_type = room_type
  # Parse enemy_config and populate self.enemies children before _ready()
```

**No breaking changes needed.** Existing properties stay; add new ones.

### 9.3 Door Changes

**Current:**
```gdscript
@export var tp_position: String  # Node path

# Usage in _on_transition_area_body_entered():
var destination_room := get_tree().current_scene.get_node(tp_position) as Room
```

**Option 1: Keep node paths (short term)**

If room_id is set, WorldDungeon can register rooms in a global dictionary:
```gdscript
# In WorldDungeon:
var rooms_by_id: Dictionary[String, Room] = {}
for room in rooms:
  rooms_by_id[room.room_id] = room

# Share globally:
DungeonManager.set_room_registry(rooms_by_id)

# In Door._on_transition_area_body_entered():
var destination_room = DungeonManager.get_room_by_id(destination_room_id)
```

**Option 2: Replace tp_position with room_id (longer term)**

```gdscript
@export var destination_room_id: String = ""

# In _on_transition_area_body_entered():
var destination_room = DungeonManager.get_room_by_id(destination_room_id)
```

**Recommendation:** Start with Option 1 (no door.tscn changes), migrate to Option 2 later.

### 9.4 EventBus Integration

**Keep:**
- `room_entered` signal → triggered by Room.activate()
- `room_exited` signal → triggered by Room.deactivate()
- `room_cleared` signal → triggered by Room when enemies cleared

**Add (new):**
- `floor_completed` signal → triggered by DungeonManager when boss defeated
- `boss_defeated` signal → triggered when boss_room is cleared

---

## 10. What Should NOT Change

| System | Reason |
|--------|--------|
| Room scene structure (Enemies container, 4 Doors) | Compatible with generation; no refactor needed |
| Door scene structure (TransitionArea, BlockerBody) | Collision system proven; don't break it |
| Player/camera tweening | Works well; keep as-is |
| Collision layer/mask system | Comprehensive; no issues found |
| Navigation setup (NavigationRegion2D per room) | Already decoupled from generation |
| EventBus signal system | Scalable; generation just triggers same signals |
| Difficulty scaling (health/speed multipliers) | Works per-room; generation can configure |
| Enemy template loading (from scene children) | Flexible enough for any enemy configuration |
| Global drops/currency system | Persists across floors correctly |

---

## 11. Suggested Implementation Phases

### Phase 1: Minimal Viable Procedural (Estimated: 6–8 hours)

**Goal:** Generate a single floor with 8 rooms, boss, spawn players.

**Scope:**
1. Create `RoomNode` RefCounted class
2. Create `RoomGraph` RefCounted class with basic methods
3. Create `Floor` RefCounted class
4. Implement grid-based random walk generator (100 lines)
5. Modify `WorldDungeon` to instantiate from RoomGraph
6. Assign enemy_config to rooms (reuse enemy templates from scene)
7. Set door `tp_position` values at runtime based on room IDs
8. Test: Generate floor, walk rooms, defeat enemies, clear floor

**NOT included:**
- Multiple floors / floor progression
- Room persistence on revisit
- Different room types (BOSS/REWARD)
- Difficulty scaling per room

### Phase 2: Multiple Floors & Progression (Estimated: 4–6 hours)

**Goal:** Sequence of floors, boss exit, next floor transition.

**Scope:**
1. Create `DungeonManager` to track current floor
2. Implement floor progression on boss defeat
3. Create Floor(2), Floor(3), etc. with different seeds
4. Unload/reload room graph on floor change
5. Add `floor_completed` signal to EventBus
6. Test: Beat floor 1 → enter floor 2 → different layout

### Phase 3: Room Persistence (Estimated: 2–4 hours)

**Goal:** Revisiting cleared room doesn't respawn enemies.

**Scope:**
1. Add `visited_rooms`, `cleared_rooms` arrays to Floor
2. Modify `Room._ready()` to check Floor.is_room_cleared()
3. Skip `respawn_enemies()` if already cleared
4. Test: Clear room → revisit → no enemies

### Phase 4: Room Types & Variety (Estimated: 4–6 hours)

**Goal:** Boss rooms, reward rooms, difficulty scaling.

**Scope:**
1. Add RoomType enum (COMBAT, BOSS, REWARD)
2. Modify generator to place 1 boss, 1–2 rewards
3. Create boss enemy variant (higher HP)
4. Create reward room (item drops instead of enemies)
5. Add difficulty_mod per room based on floor
6. Test: Boss room harder, reward room free items

### Phase 5: Determinism & Debug Tools (Estimated: 2–3 hours)

**Goal:** Reproducible runs, visualization aids.

**Scope:**
1. Expose seed in UI or debug panel
2. Add room ID labels in debug mode
3. Print room_graph.to_string() on generation
4. Verify same seed produces same layout
5. Test: Run A with seed X → generate, record nodes; run B with seed X → same nodes

**Total Estimated Effort:** 18–27 hours across 5 phases  
**Recommended Rollout:** 1–2 phases per week during active development

---

## 12. Open Design Decisions (Requiring Human/Gameplay Discussion)

### 12.1 Room Count Per Floor

**Question:** How many rooms should each floor have?

**Options:**
- A. Fixed: Always 8 rooms (deterministic, manageable)
- B. Variable: 6–12 rooms based on seed (more variety, longer runs)
- C. Scaling: 4 rooms on floor 1, +2 per floor (difficulty increases)

**Impact:** Affects run length, difficulty curve, content volume  
**Decision Required Before:** Phase 1 implementation

### 12.2 Boss Room Type vs. Special Handling

**Question:** Should boss room be `RoomType.BOSS`, or just a COMBAT room with a boss enemy?

**Options:**
- A. RoomType.BOSS (distinct type, easier to track floor exit)
- B. RoomType.COMBAT with boss_enemy flag (simpler enum, same behavior)

**Impact:** Code clarity vs. simplicity  
**Recommended:** Option A (clearer intent)

### 12.3 Reward Room Contents

**Question:** What should reward rooms contain?

**Options:**
- A. Random item pool (1–2 items per room)
- B. Healing pickup (HP restoration)
- C. Guaranteed item + optional rarer item (Isaac-like)
- D. Currency drops (extra money)

**Impact:** Run length, player power curve, item diversity  
**Decision Required Before:** Phase 4

### 12.4 Difficulty Scaling Per Floor

**Question:** How should difficulty increase across floors?

**Options:**
- A. Global.difficulty_level only (player-chosen, not floor-dependent)
- B. Floor-dependent: difficulty_mod = 1.0 + (floor_number - 1) × 0.2
- C. Room-dependent: Boss > Combat > Reward
- D. Combination: Floor × Room type

**Impact:** Early/late game balance, run difficulty  
**Current Code:** Uses Global.difficulty_level in Room.respawn_enemies()  
**Decision Required Before:** Phase 4

### 12.5 Deterministic vs. Replayability

**Question:** Should players see the same dungeon layout every run with same seed, or always random?

**Current Plan:** Deterministic (same seed = same layout)

**Trade-off:**
- Pro: Speedrunners can memorize floors, reproducible bugs
- Con: Potential for boring repetition

**Alternative:** Store seed in run metadata, allow player to set seed for debugging

**Decision Required Before:** Phase 5

### 12.6 Floor Infinity or Capped

**Question:** Should dungeon be infinite (endless floors), or capped (e.g., 3 floors)?

**Current Plan:** Capped at 3–5 floors for demo

**Impact:** Endgame goal, victory condition, content volume  
**Decision Required Before:** Phase 2

---

## 13. Summary: Ready for Design Review

### What Has Been Analyzed
✅ Current Room/Door/WorldDungeon architecture (concrete facts)  
✅ Hardcoded vs. procedural components  
✅ Collision, navigation, camera systems (no changes needed)  
✅ EventBus integration points  
✅ Data model requirements  

### What Has Been Proposed
✅ RoomNode / RoomGraph / Floor data model  
✅ Grid-based random walk generation algorithm  
✅ 3-tier room type system (COMBAT, BOSS, REWARD)  
✅ Persistence model for revisiting rooms  
✅ Integration points with existing code  
✅ 5-phase implementation roadmap  

### What Remains Open (Requires Discussion)
⏳ Room count per floor  
⏳ Reward room contents  
⏳ Difficulty scaling strategy  
⏳ Determinism vs. seed management  
⏳ Infinite vs. capped floors  
⏳ Boss room special handling  

### Next Steps
1. Review this document with game designer / team
2. Make decisions on Section 12 open questions
3. Proceed to Phase 1 when ready
4. Create RoomNode/RoomGraph/Floor classes as RefCounted
5. Implement grid-based generator (~100 LOC)
6. Integrate with WorldDungeon instantiation

**This specification is a complete, technically grounded blueprint for procedural dungeon generation. No architectural refactor will be needed to implement any of the phases outlined above.**
