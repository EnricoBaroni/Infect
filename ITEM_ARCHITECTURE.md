# ITEM_ARCHITECTURE.md

## Godot Project - Isaac-like Item System

Version: 1.0 (Frozen)

---

# PURPOSE

This document is the **single source of truth** for the Item Refactor.

It does **NOT** describe how the current project is implemented.

It defines **how the project must evolve**.

Its objective is to maintain architectural consistency throughout the entire development of the game and prevent future conversations from drifting away from the original design.

If implementation proves that a decision is wrong, this document must be updated.

Otherwise, this document should be considered frozen.

---

# PROJECT CONTEXT

The project is heavily inspired by **The Binding of Isaac**, with the gameplay philosophy centered around **Tainted Keeper**.

The objective is **NOT** to clone Isaac literally.

The objective is to reproduce the architectural principles that allow Isaac to support:

- Hundreds of items
- Emergent synergies
- Massive replayability
- Highly modular gameplay
- Extremely scalable content

Everything described in this document exists to support that goal.

---

# LONG TERM GOAL

The architecture must eventually support systems equivalent to:

- Passive Items
- Active Items
- Trinkets
- Weapon Replacements
- Projectile Modifiers
- Reactive Items
- Familiars
- Shops
- Item Pools
- Boss Rewards
- Angel / Devil Rooms
- Transformations
- Future custom mechanics

The architecture is **NOT** optimized for the first 20 items.

It is optimized to eventually support hundreds of items without becoming impossible to maintain.

---

# CORE PHILOSOPHY

Never think:

> "How do I implement this item?"

Always think:

> "Which system owns this behaviour?"

Gameplay belongs to Systems.

Items modify Systems.

Systems never belong to Items.

---

# WHAT WE ABSOLUTELY WANT TO AVOID

Never implement:

```gdscript
if has_brimstone:
```

Never implement:

```gdscript
if brimstone and spoon_bender:
```

Never implement:

```gdscript
player.damage += 1
```

Never create:

```
Brimstone.gd
```

containing hundreds of gameplay lines.

Whenever a solution starts depending on specific item combinations,
stop and rethink the architecture.

---

# GENERAL ARCHITECTURE

Player

- InventorySystem
- StatEvaluationSystem
- WeaponSystem
- ProjectileSystem

World

- RoomSystem
- DropSystem
- ShopSystem
- ItemPoolSystem

Global

- EventBus

Future

- FamiliarSystem
- TransformationSystem
- ActiveItemSystem

---

# INVENTORY SYSTEM

Responsibilities:

- Store Passive Items
- Store Active Item
- Store Trinkets

InventorySystem DOES NOT:

- Calculate stats
- Shoot weapons
- Spawn projectiles
- Execute gameplay logic

Inventory is only a container.

---

# ITEMS

Every item is a Resource.

Items contain data.

Items do NOT contain gameplay logic.

Each Item contains:

- Id
- Name
- Description
- Quality
- Pool Tags
- Effects

Nothing else.

---

# EFFECTS

Effects are the fundamental gameplay building block.

Items are compositions of Effects.

Examples:

Growth Hormones

- DamageUpEffect
- SpeedUpEffect

Brimstone

- SetWeaponEffect

Piggy Bank

- SpawnCoinsOnDamageEffect

Effects define **what changes**.

Systems define **how it works**.

---

# STAT EVALUATION SYSTEM

Responsible for:

- Damage
- Tears
- Speed
- Range
- Shot Speed
- Luck

Stats are NEVER modified directly.

Incorrect:

```gdscript
player.damage += 1
```

Correct:

```
Inventory changes
        ↓
StatEvaluationSystem.Recalculate()
        ↓
Final Stats
```

Every player stat must always be rebuildable from scratch.

---

# WEAPON SYSTEM

Responsibilities:

- Weapon Type
- Fire behaviour
- Charge mechanics
- Continuous fire
- Burst fire

WeaponSystem knows WeaponTypes.

WeaponSystem NEVER knows Items.

Expected Weapon Types:

- TearWeapon
- BrimstoneWeapon
- TechnologyWeapon
- TechXWeapon
- KnifeWeapon

---

# ATTACK DATA

WeaponSystem NEVER spawns gameplay entities directly.

Flow:

```
WeaponSystem

↓

AttackData

↓

ProjectileSystem

↓

Projectile / Laser / Knife / etc.
```

AttackData represents an attack before entering the world.

Expected fields:

- Damage
- Speed
- Range
- Size
- WeaponType
- Flags

AttackData is expected to evolve during implementation.

---

# PROJECTILE SYSTEM

ProjectileSystem transforms AttackData into gameplay entities.

Responsibilities include:

- Homing
- Bounce
- Piercing
- Spectral
- Split
- Fragmentation

ProjectileSystem knows nothing about Items.

It only interprets data.

---

# CAPABILITY MODEL

Projectile behaviour should emerge from capabilities.

Examples:

- CanHome
- CanBounce
- CanPierce
- CanSplit
- CanSpectral
- CanFragment

Effects add capabilities.

ProjectileSystem interprets capabilities.

This avoids combinatorial explosions.

---

# EVENT BUS

Global communication is implemented using Godot Signals.

Candidate events:

- player_damaged
- enemy_killed
- room_entered
- room_cleared
- projectile_spawned
- projectile_destroyed
- item_collected
- enemy_spawned
- boss_killed

Systems emit events.

Effects react to them.

---

# REACTIVE ITEMS

Some items do not modify systems directly.

Instead they react to events.

Examples:

- Piggy Bank
- Holy Mantle
- Bloody Lust
- Gimpy
- Infamy
- Cambion Conception

Reactive Items subscribe only to the events they need.

---

# ITEM POOL SYSTEM

Responsible for every item generation rule.

Examples:

- Treasure Rooms
- Shops
- Boss Rewards
- Angel Rooms
- Devil Rooms
- Secret Rooms

Rules:

- DefaultRule
- ChaosRule
- SacredOrbRule

Items never generate themselves.

Items modify generation rules.

---

# EMERGENT SYNERGIES

This is one of the primary architectural goals.

Incorrect:

```
Brimstone + Spoon Bender

↓

Specific code
```

Correct:

```
Brimstone

↓

WeaponSystem

+

Spoon Bender

↓

ProjectileSystem

↓

Natural Synergy
```

Explicit synergy code should only exist when mathematically unavoidable.

---

# IMPLEMENTATION ROADMAP

> **Historical record.** Phases 1 through 8 are complete. This section documents the design sequence followed during development and explains why the systems were built in this order. It is **not** a list of pending work. For the current milestone and next steps, see `docs/implementation/AGENT_CONTEXT.md`.

The roadmap is considered frozen.

Do not skip phases.

---

## PHASE 1 - Foundation *(Complete)*

Create:

- ItemData
- EffectData
- InventorySystem

Gameplay remains unchanged.

---

## PHASE 2 - Stats Refactor *(Complete)*

Create:

- StatEvaluationSystem

Remove every direct stat modification.

Current Upgrade Pickups must now grant Items instead of modifying stats directly.

---

## PHASE 3 - First Real Items *(Complete)*

Implement:

- DamageUpEffect
- SpeedUpEffect
- TearsUpEffect

Validate simple stat items.

---

## PHASE 4 - EventBus *(Complete)*

Implement global signals.

Infrastructure only.

---

## PHASE 5 - Reactive Items *(Complete)*

Validate:

- Piggy Bank
- Holy Mantle
- Bloody Lust

---

## PHASE 6 - Weapon Refactor *(Complete)*

Implement:

- WeaponSystem
- AttackData

Migrate the normal tear weapon.

No Brimstone yet.

---

## PHASE 7 - Projectile System *(Complete)*

Implement capabilities.

Validate:

- Homing
- Bounce
- Piercing
- Split

---

## PHASE 8 - Weapon Replacement *(Complete)*

Implement:

- Brimstone

Validate:

- WeaponSystem
- AttackData

---

# VALIDATION ITEMS

The following Isaac items are architectural validation cases.

They are NOT implementation priorities.

Sad Onion

- Validates StatEvaluationSystem

Growth Hormones

- Validates multiple Effects

Brimstone

- Validates WeaponSystem

Technology

- Validates AttackData

Tech X

- Validates WeaponSystem + ProjectileSystem

Mom's Knife

- Validates Weapon Replacement

Piggy Bank

- Validates EventBus

Holy Mantle

- Validates Reactive Effects

Chaos

- Validates ItemPoolSystem

Sacred Orb

- Validates Pool Rules

Cricket's Body

- Validates Projectile Events

If these items can be implemented cleanly,
the architecture is considered healthy.

---

# ARCHITECTURAL DECISIONS

## D001

Gameplay belongs to Systems.

Items contain data.

**Status:** LOCKED

---

## D002

Stats are always recalculated.

Never modified directly.

**Status:** LOCKED

---

## D003

WeaponSystem and ProjectileSystem are independent.

**Status:** LOCKED

---

## D004

AttackData is mandatory.

**Status:** LOCKED

---

## D005

Godot Signals are the EventBus.

**Status:** LOCKED

---

## D006

Projectile behaviour is capability-based.

**Status:** LOCKED

---

## D007

Items are compositions of Effects.

**Status:** LOCKED

---

# RULES DURING DEVELOPMENT

Before implementing any mechanic, always ask:

1. Does an existing System already own this behaviour?

2. Can this be solved with a new Effect?

3. Can this be solved by adding a new Capability?

4. Can this be solved through an existing Event?

5. Am I about to introduce a special case?

If the answer to the last question is YES, stop and rethink the implementation.

---

# WHEN MAY THIS DOCUMENT CHANGE?

Only one valid reason exists:

Implementation proves a limitation.

Never modify this document because:

- "Maybe..."
- "What if..."
- "Perhaps..."

Architecture changes only after implementation demonstrates a real problem.

---

# CURRENT STATUS

Architecture State:

**FROZEN**

Current Branch:

**ItemRefactor**

Current Objective:

Begin implementation.

Next Task:

- Create ItemData
- Create EffectData
- Create InventorySystem

No new gameplay features should be implemented before this foundation exists.