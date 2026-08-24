# PROJECT CONTEXT

## Project Goal

Create a small roguelike inspired mainly by The Binding of Isaac and especially Tainted Keeper.

The objective is NOT to copy Isaac directly.

The objective is to preserve:

- Fast runs
- Clear gameplay
- High replayability
- Strong risk/reward decisions
- Emergent builds
- Continuous gameplay flow
- "One more run" feeling

Current priority is validating the gameplay core before building large systems.

---

# Core Gameplay Vision

Top-down action roguelike.

Player moves between rooms and clears enemies.

Combat is inspired by Isaac:

- WASD movement
- Directional shooting
- Positioning focused
- Dodging focused
- Continuous action
- Minimal menus

Player always has a physical body.

Body possession and body swapping were explored but are NOT part of the current direction.

---

# Infection System

Current unique mechanic.

The player can shoot two different attack modes:

## Normal Shot

Purpose:

- Deal damage
- Kill enemies

## Infection Shot

Activated while holding Space.

Purpose:

- Infect enemies
- Does NOT deal damage (at least in the first prototype)
- Makes enemies more dangerous
- Creates future reward opportunities

Current philosophy:

Risk -> Reward.

Inspired by Tainted Keeper's money collection decisions.

The infection mechanic should create interesting combat decisions without requiring menus or pausing gameplay.

---

# Important Design Principle

Do NOT optimize for perfect Isaac flow.

Tainted Keeper is a major inspiration.

Adding additional combat decisions is acceptable if they are integrated naturally into gameplay.

The key question is:

"Does infecting enemies create interesting decisions?"

NOT:

"Does infecting enemies preserve pure Isaac gameplay?"

---

# Current Prototype Goals

The original prototype question was:

"Is infection fun?"

The project has grown beyond a bare prototype. It now has a full item architecture (290 passive items, 73 effect types, 10 enemy types, multi-room dungeon). However, the core validation question — **whether the Infection mechanic produces interesting, sustainable combat decisions** — has not been definitively answered through systematic human playtesting.

Every system in the project exists to support that question. Do not add systems for their own sake until this loop is clearly validated.

For current implementation state and the next milestone, see [docs/implementation/AGENT_CONTEXT.md](docs/implementation/AGENT_CONTEXT.md).

Nothing else should be overengineered before this is validated.

---

# Current Development Roadmap

## Phase 1

Implement infection shot.

Requirements:

- Hold Space
- Shoot infection projectile
- Different visual feedback

## Phase 2

Implement infected enemies.

Requirements:

- Enemy can become infected
- Clear visual feedback
- Enemy becomes more dangerous

Current candidate:

- Increased movement speed

## Phase 3

Playtest.

Questions:

- Is infecting fun?
- Is infecting annoying?
- Is infecting always correct?
- Is infecting never correct?
- Does the player naturally alternate between attack modes?

## Phase 4

DNA drops.

Only after infection feels good.

## Phase 5

Temporary DNA pickups.

Only after DNA itself feels good.

## Phase 6

Items.

Only after DNA loop feels good.

---

# Future Systems (NOT IMPLEMENTED)

These are possibilities.

Do NOT design around them yet.

- DNA resource
- DNA pickups
- DNA decay
- Infection upgrades
- Mutation system
- Infection propagation
- Infection-related items
- Risk costs
- Health costs
- Cooldowns
- Additional enemy buffs

All future systems must be validated incrementally.

---

# Technical Philosophy

Current project is intentionally simple.

Avoid:

- Premature architecture
- Generic managers
- Complex inheritance trees
- Large refactors
- Systems built for hypothetical future problems

Prefer:

- Small changes
- Existing patterns
- Playtesting early
- Incremental growth

---

# Current Folder Philosophy

High-level organization.

Examples:

- player/
- enemies/
- attacks/
- world/
- ui/
- audio/
- resources/

Avoid separating everything into scenes/ and scripts/ folders.

Scenes and scripts should generally stay close together.

---

# Current Code Architecture

## player.gd

Responsibilities:

- Movement
- Shooting
- Damage reception
- Animation control

Important variables:

- input_vector
- attack_vector
- velocity

Important systems:

- CharacterBody2D
- AnimationTree
- FireRate Timer

---

## bullet.gd

Responsibilities:

- Projectile movement
- Collision
- Damage delivery

Current data:

- SPEED
- DAMAGE
- FIRE_RATE
- MAX_DISTANCE
- direction

Uses Hitbox.

---

## hitbox.gd

Current combat source.

Contains:

- damage
- knockback

All combat interactions currently start here.

Future infection implementation should preferably extend existing patterns rather than replacing them.

---

## hurtbox.gd

Receives Hitbox collisions.

Emits hurt signal.

Current damage flow:

Bullet
-> Hitbox
-> Hurtbox
-> Enemy/Player
-> Stats

---

## stats.gd

Current health system.

Used by:

- Player
- Enemies

---

## bat_enemy.gd

Current enemy implementation.

Used as the reference enemy for future infection testing.

Future infection state will likely be added here first.

---

# Current Combat Philosophy

Avoid creating separate systems too early.

Prefer extending existing projectile / hitbox / hurtbox flow.

Current combat flow:

Projectile
-> Hitbox
-> Hurtbox
-> Target

Future infection should ideally reuse this path.

---

# Important Open Questions

These questions are intentionally unresolved.

Do not assume answers.

- Does infection cost health?
- Does infection cost another resource?
- Is increased enemy danger enough risk?
- Is infection temporary?
- How is DNA generated?
- How are items purchased?
- How powerful should infection builds become?

All answers should come from playtesting.

---

# Current Success Condition

The prototype is successful if:

Holding Space to infect enemies creates fun and meaningful decisions during combat.

Nothing else matters until this is validated.