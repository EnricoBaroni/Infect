# PLAYTEST_MATRIX.md

Comprehensive playtest preparation matrix for the baseline mechanic set validated up to Slice 22.

> **Audit update (2026-08-19):** Final pre-playtest static audit complete. See [PRE_PLAYTEST_FINAL_AUDIT.md](PRE_PLAYTEST_FINAL_AUDIT.md) for the prioritized P0/P1/P2/P3 test order for the first Godot session. Start with the P0 list there, then work through the sections below.

Scope:
- Baseline validation snapshot used before autonomous content-expansion resumed.
- Focus on validation confidence for the baseline projectile/room/economy loop.
- Mechanics covered in this matrix: Damage, Fire Rate, Range, Bullet Speed, Piercing, Bounce, Homing, Split, Spectral, Beam, Infection, Reactive items.

Legend:
- Struct: Can be mostly verified by code-path/structural inspection.
- Human: Requires gameplay playtest to validate feel, readability, pacing, or emergent interaction risk.

---

## ITEM BUG AUDIT COMPLETE (August 2026)

**Total items inspected:** 290
**Total effect families inspected:** 56 (AttackEffectData, EffectData, ReactiveEffectData)
**Category A bugs found:** 7
**Category A bugs fixed:** 7
**Category B structural risks:** 2
**Category C manual playtest requirements:** Added to §6 below
**Category D intentional/design:** None
**Items with no-op behavior:** 1 (sad_onion default value insufficient but still functional)
**Items appearing completely non-functional:** 0
**Deferred to architecture audit:** 0

### Category A Bugs Fixed

| Item | Bug | Root Cause | Fix |
|---|---|---|---|
| chain_bomb.tres | Field `explosion_damage_multiplier` unrecognized, second field `explosion_inherits_infection` misnamed | Exported field name in effect class is `extra_explosion_damage_multiplier` and `inherit_infection` | Changed to `extra_explosion_damage_multiplier = 0.65` and `inherit_infection = true` |
| lure_hook.tres | Fields `homing_strength` and `homing_radius` unrecognized | HomingProjectilesEffect exports `strength` and `radius`, not prefixed names | Changed to `strength = 4.5` and `radius = 180.0` |
| scatter_mark.tres | Fields `split_count` and `split_spread_degrees` unrecognized | SplitShotsEffect exports `extra_shots` and `spread_degrees` | Changed to `extra_shots = 1` and `spread_degrees = 14.0` |
| bounty_bait.tres | Fields `drops_on_kill` and `infected_kill_bonus` unrecognized | GainDropsOnKillEffect exports `drops_per_kill` and `infected_bonus` | Changed to `drops_per_kill = 1` and `infected_bonus = 1` |
| euthanasia.tres | All 4 crit fields `crit_*` instead of `extra_crit_*` and wrong luck/max names | CriticalHitsEffect exports `extra_crit_chance`, `extra_crit_multiplier`, `luck_to_full`, `max_crit_chance` | Changed all 4 fields to correct names with `extra_` prefix |
| razor_blade.tres | All 4 crit fields same naming error as euthanasia.tres | Same root cause | Fixed identically |
| sniper_bait.tres | All 4 crit fields same naming error | Same root cause | Fixed identically |

### Category B Structural Risks (Not Bugs)

1. **EffectRuntimeSystem registry overwrite risk:** If identical ItemData resource reference is added to inventory twice (without `.duplicate()`), the second add overwrites the first's runtime array in the dictionary, orphaning the first set of runtimes. **Mitigation:** All pickup code paths currently use `.duplicate()`, so not triggered in normal gameplay. **Recommendation:** Document as invariant in InventorySystem and EffectRuntimeSystem.

2. **ShopPriceMultiplierRuntime floating-point drift:** Division-based deactivation (`1.0 / price_multiplier`) applied to many items in different removal order can accumulate small rounding errors. **Risk:** Extremely low; shop cost is always clamped to integer >= 1 drop. **Recommendation:** No fix required (low-risk, benign edge case).

### Category C Manual Playtest Requirements

All items with field-name bugs have now been fixed. Remaining playtest entries from §5 (door blocker, debug menu, etc.) remain valid. **No additional Category C items from field audit.**

### Audit Summary by Effect Family

**AttackEffectData (51 items across 22 effect types):**
- SetWeaponTypeEffect: 20 items, all correct
- DamageUpEffect: 1 item with missing default (sad_onion → uses 0.5 default, acceptable)
- MoveSpeedUpEffect: 6 items, all correct
- FireRateUpEffect: 6 items, all correct
- RangeUpEffect: 4 items, all correct
- BulletSpeedUpEffect: 6 items, all correct
- HealthUpEffect: 1 item, correct
- LuckUpEffect: 1 item, correct
- StatMultiplierEffect: 4 items, all correct
- PiercingProjectilesEffect: 11 items, all correct
- BouncyProjectilesEffect: 11 items, all correct
- HomingProjectilesEffect: 19 items (1 fixed: lure_hook), all now correct
- SplitShotsEffect: 5 items (1 fixed: scatter_mark), all now correct
- SpectralProjectilesEffect: 3 items, all correct
- CriticalHitsEffect: 14 items (3 fixed: euthanasia, razor_blade, sniper_bait), all now correct
- KnockbackModifierEffect: 2 items, all correct
- ExplosiveProjectilesEffect: 20 items (1 fixed: chain_bomb), all now correct
- ExplosionShrapnelEffect: 4 items, all correct
- FractureOnHitEffect: 11 items, all correct
- ChargeShotEffect: 1 item, correct
- ChanceSplitShotsEffect: 5 items, all correct
- BeamLengthUpEffect: 2 items, all correct

**EffectData (StatusAttackEffect subclasses: 50+ items across 11 status types):**
- All status effects (Poison, Burn, Bleed, Fear, Bait, Charm, Confusion, Chained, Freeze, Slow, etc.): **All correct** — field names match consistently across all items

**ReactiveEffectData (19 effect types, 180+ items):**
- GainDropsOnKillEffect: 6 items (1 fixed: bounty_bait), all now correct
- GainDropsOnRoomClearEffect: 4 items, all correct
- GainDropsOnDropPickupEffect: 4 items, all correct
- GainDropsOnEnemyHitEffect: 4 items, all correct
- SpawnDropsOnDamageEffect: 2 items, all correct
- CompanionFormationEffect: 3 items, all correct
- SpawnCompanionsOnKillEffect: 12 items, all correct
- SpawnCompanionsOnEnemyHitEffect: 18 items, all correct
- SpawnCompanionsOnPlayerDamagedEffect: 6 items, all correct
- DamagePreventionEffect: 14 items, all correct
- MapRevealEffect: 1 item, all correct
- ProjectileHazardPulseEffect: 5 items, all correct
- RoomEntryHazardPulseEffect: 3 items, all correct
- ShopPriceMultiplierEffect: 9 items, all correct
- ShopInfiniteRestockEffect: 2 items, all correct
- StatRampOnKillEffect: 4 items, all correct
- StatRampOnDamageEffect: 2 items, all correct
- TempStatBuffOnKillEffect: 8 items, all correct

### Items Remaining as Design Decisions (Category D)

None. All inconsistencies were implementation bugs (wrong field names), not deliberate design choices.

### Conclusions

1. **All field-name mismatches have been fixed.** The 7 bugs were all identical pattern: `*.tres` files using stale or alternate field names that don't match current `.gd` effect class exports.

2. **No foundational architecture problems detected.** Effect pipeline is sound: ItemData → Effect → EffectData → create_runtime() → configure() → activate/deactivate lifecycle.

3. **All 290 items now have valid execution paths.** Before audit, 7 items had silent no-ops (fields would be ignored by Godot serialization). After fixes, all items are fully functional.

4. **Status quo maintenance:** The item catalogue is stable and ready for playtest validation. No new effects or items added. Next phase: manual gameplay testing of fixed items (Category C).

---

## 1. Single-Mechanic Audit Matrix

| Mechanic | Expected behavior | Potential failure cases | Balance risks | Visual readability concerns | Performance concerns | Validation type |
|---|---|---|---|---|---|---|
| Damage | Higher `stats.damage` increases per-hit output for bullets/beam segments. | Damage not applied after item recalc; infection shot accidentally still deals damage. | Burst kills trivialize rooms if stacked with high fire rate/split. | Low readability if TTK becomes too short to read enemy behavior. | Minimal alone; indirect via faster clears and projectile count combos. | Struct + Human |
| Fire Rate | Lower `stats.fire_rate` shortens `FireRate` timer cooldown. | Timer restart edge cases; floor bypass if malformed resource sets too-low base value. | Extreme DPS scaling with split/beam and damage. | Dense projectile streams hide telegraphs and drops. | Spawn/despawn event spam at very low cooldowns. | Struct + Human |
| Range | Increases projectile max distance (or beam pressure area indirectly by uptime in combat space). | Projectile lifetime mismatch causing unexpected despawn distance. | Safe-screening enemies too early with speed+homing combos. | Long-travel tears clutter screen in large rooms. | More active projectiles at once in long corridors. | Struct + Human |
| Bullet Speed | Increases projectile travel speed. | Overshoot/hit registration feel issues at very high speed. | Reduces dodge commitment cost; can over-enable infection tagging. | Harder to parse trajectory at high speed. | More collision checks per second for dense fire. | Human |
| Piercing | Bullets pass through multiple hurtboxes up to `pierce_count`. | Off-by-one on remaining pierces; enemy hurtbox multi-hit assumptions. | Multi-target melt with split/homing may flatten encounter variety. | Hit feedback ambiguity when bullet continues after hit. | More hitbox overlap processing in enemy packs. | Struct + Human |
| Bounce | Bullets reflect on body collision up to `bounce_count`. | Reverse-direction bounce into immediate re-collision loop; wall-sticking jitter. | Free room coverage can invalidate positioning challenge. | Ricochet paths can be hard to track in clutter. | Extra collision events and longer projectile lifetime. | Struct + Human |
| Homing | Bullet direction steers toward nearest enemy within radius each frame. | No target acquisition due class lookup/path assumptions; oscillation at high steer values. | Removes aiming challenge; excessive auto-hit consistency. | Curved paths may reduce player prediction of threats/outputs. | `find_children` scan each frame per bullet can spike with many bullets/enemies. | Struct + Human |
| Split | One shot becomes fan of additional shots using spread and cloned `AttackData`. | Cloned data missing fields (regression risk when `AttackData` expands); fan angle overlap bugs. | Multiplicative DPS with damage/fire rate/pierce/homing. | Projectile clutter and source ambiguity. | Projectile count explosion, especially with low cooldown. | Struct + Human |
| Spectral | Bullets ignore body collisions with obstacles (`_on_body_entered` early return). | Unexpected bypass of intended bounce behavior; room geometry pressure removed. | Can trivialize cover/line-of-sight gameplay. | Shots through walls may feel unfair/unclear without strong FX cue. | Longer-living bullets can increase active count. | Struct + Human |
| Beam | Weapon replacement spawns segmented beam entities instead of tears. | Segment count/duration extremes; replacement state not reverting on item removal. | Large beam uptime can overpower encounter pacing. | Segment overlap and hit readability at high density. | Segment spawn bursts per shot; event bus projectile events multiplied. | Struct + Human |
| Infection | Infection shots deal 0 damage, apply infection state, boost enemy speed, increase drop reward. | Infection not applied in some enemy paths; infected speed stacking unexpectedly. | Economy inflation (extra drops) or risk inversion. | Green tint may be insufficient in chaotic fights. | More enemy aggression increases collision/combat throughput. | Struct + Human |
| Reactive items | Runtime listeners react to EventBus (current: drops on player damaged). | Duplicate listeners on stacking/removal edge cases; wrong player payload match. | Infinite or runaway economy loops if damage farming is too profitable. | Reward source can be unclear amid combat noise. | Signal traffic high in dense fights; listener churn on inventory changes. | Struct + Human |

## 2. Pairwise Combination Matrix (Complete)

Each row includes required fields: expected behavior, failure cases, balance risk, visual concern, performance concern.

| Pair | Expected behavior | Potential failure cases | Balance risks | Visual readability concerns | Performance concerns | Validation type |
|---|---|---|---|---|---|---|
| Damage + Fire Rate | DPS scales by hit value and shot cadence. | Timer floor or stat recalc mismatch desyncs effective DPS. | Run-invalidating burst builds. | Enemy death too fast to read threats. | High spawn/event throughput. | Struct + Human |
| Damage + Range | High per-hit damage at safer distances. | Distance cap not matching expected stat outcome. | Low-risk sniping builds dominate. | Off-screen kills feel opaque. | More long-lived lethal bullets. | Human |
| Damage + Bullet Speed | Fast heavy tears connect quickly. | Hit feel inconsistency at high travel speed. | Burst with little counterplay. | Hard-to-track high-speed impacts. | Increased collision checks at scale. | Human |
| Damage + Piercing | High-damage multi-hit lane clear. | Piercing decrement bugs over/under-hit. | Pack deletion trivializes rooms. | Continued bullet after kill can confuse hit source. | More hurtbox interactions per bullet. | Struct + Human |
| Damage + Bounce | Heavy ricochet shots retain kill potential. | Bounce loop in tight geometry. | Accidental room wipes with minimal aim. | Ricochet kill attribution unclear. | Extended projectile lifetimes. | Struct + Human |
| Damage + Homing | Tracking heavy shots prioritize nearest targets. | Homing target jitter under high damage one-shots. | Aim skill compression; guaranteed deletes. | Curved lethal trajectories hard to parse. | Per-frame target scans plus high kill pace. | Human |
| Damage + Split | Fan of high-damage shots. | Clone data drift per branch. | Massive multiplicative burst. | Screen flood of lethal projectiles. | Projectile multiplication spikes. | Struct + Human |
| Damage + Spectral | High-damage shots through obstacles. | Obstacle interactions bypass intended risk. | Cover invalidation. | Through-wall kills reduce combat clarity. | More surviving bullets per room. | Human |
| Damage + Beam | Beam segments inherit boosted damage. | Segment damage unexpectedly stacking per frame/contact cadence. | Boss/elite melt risk. | Thick damage zones obscure enemy bullets. | Segment hit processing concentration. | Struct + Human |
| Damage + Infection | Infection shot should still do zero damage; normal shot benefits from damage stat. | Infection mode accidentally gains damage from path regression. | If infection still zero damage, economy-risk loop remains fair; if bugged, loop breaks. | Green shot vs normal distinction must remain clear. | Neutral unless combined with high fire rate. | Struct + Human |
| Damage + Reactive | Damage profile independent; reactive payout on player damage unchanged. | Event payload coupling accidentally tied to outgoing damage. | Glass-cannon + payout farming loops. | Cause of drop gain unclear during burst fights. | Slightly higher event density under aggressive play. | Human |
| Fire Rate + Range | More frequent long-travel projectiles. | Too many active bullets due long lifetime + low cooldown. | Kiting dominance. | Persistent bullet clutter. | Active projectile count climbs quickly. | Struct + Human |
| Fire Rate + Bullet Speed | Fast, frequent tears. | Physics/collision miss feel at extreme values. | Strong universal DPS scaling. | Trajectory readability reduced sharply. | Collision/event pressure rises. | Human |
| Fire Rate + Piercing | Frequent multi-target pass-through. | Pierce counters reused incorrectly across shots. | Room clear speed spikes. | Hard to parse which shot pierced what. | Hurtbox checks multiply heavily. | Struct + Human |
| Fire Rate + Bounce | Frequent ricochets. | Bounce spam in confined rooms. | Safe firing patterns become dominant. | Visual chaos from ricochet trails. | Collision callback bursts. | Struct + Human |
| Fire Rate + Homing | Frequent auto-tracking bullets. | Target selection churn/stutter. | Near-auto-win against mobile enemies. | Curving projectile swarm reduces readability. | Worst-case target scanning load. | Struct + Human |
| Fire Rate + Split | Frequent multi-projectile fans. | Projectile burst exceeds practical limits. | Run-invalidating DPS and coverage. | Severe screen clutter. | Highest projectile spawn pressure. | Struct + Human |
| Fire Rate + Spectral | Frequent through-obstacle shots. | Geometry bypass removes intended encounter gating. | Very low-risk offense. | Hard to read threat lanes through walls. | Increased active projectile lifetime and count. | Human |
| Fire Rate + Beam | Frequent segment bursts. | Beam segment overlap/cooldown mismatch. | Constant beam pressure overtunes runs. | Beam persistence can hide hazards. | Segment spawn/despawn event spikes. | Struct + Human |
| Fire Rate + Infection | Rapid infection tagging and enemy acceleration. | Infection mode cadence may make rooms uncontrollable. | Risk/reward may skew to reward farming. | Many green shots and fast enemies at once. | More AI updates from prolonged fights. | Human |
| Fire Rate + Reactive | More incoming risk opportunities triggering reactive payouts. | Damage event spam can overtrigger rewards. | Economy inflation via intentional tanking. | Feedback overlap (damage + rewards) noisy. | High signal frequency if frequently hit. | Human |
| Range + Bullet Speed | Long, fast lanes. | Bullet despawn feel inconsistent with perceived range. | Dominant safe poke style. | Projectiles appear/disappear quickly at edge. | Many far-travel collision checks. | Human |
| Range + Piercing | Deep lane penetration through packs. | Unexpected far multi-hits through narrow corridors. | Room geometry less meaningful. | Hard to read far-chain hits. | Prolonged bullet life + multi-hit checks. | Human |
| Range + Bounce | Long-lived ricochet behavior. | Bullets ping-pong too long. | Passive clear potential too high. | Late ricochet hits feel random. | Long lifespan increases callbacks. | Struct + Human |
| Range + Homing | Long-lived tracking windows. | Retargeting over long life causes path oddities. | Strong chase-and-forget playstyle. | Curved long arcs clutter view. | Longer lifetime multiplies scan cost. | Struct + Human |
| Range + Split | Broad multi-lane long-range pressure. | Outer fan shots persist excessively. | Wide map control with low commitment. | Many distant projectiles reduce clarity. | Elevated active entity count. | Struct + Human |
| Range + Spectral | Through-wall long-range control. | Encounters bypassed before engagement. | Extreme safety. | Kills from unseen angles feel unfair. | Long-lived unobstructed bullets. | Human |
| Range + Beam | Beam spacing/segment count dominates line control. | Segment placement vs room scale mismatch. | Area denial overtuning. | Beam lane may eclipse other VFX. | Segment counts scale encounter cost. | Human |
| Range + Infection | Easier long-range infection tagging. | Infection reward loop from safer positions. | Risk half of risk/reward loop reduced. | Infection source may be hard to identify at distance. | Longer fights from zero-damage shots. | Human |
| Range + Reactive | Range does not directly alter reactive trigger logic. | None structural expected beyond general combat variance. | Safer play may reduce reactive trigger frequency. | Minor. | Negligible direct effect. | Struct |
| Bullet Speed + Piercing | Fast pass-through hits. | Fast projectiles may reduce perceived pierce feedback. | Efficient lane clear. | Hard to notice pierce continuation. | High-rate collision calculations. | Human |
| Bullet Speed + Bounce | Fast ricochets. | Tunneling-feel or abrupt reversals. | Strong room coverage from ricochet speed. | Very hard path readability. | Frequent body collisions in short windows. | Human |
| Bullet Speed + Homing | Steering fast bullets toward enemies. | Overshoot/over-correction jitter. | Strong lock-on feel, low aim tax. | Curvature subtle at speed, hard to parse. | Scan + physics pressure at scale. | Human |
| Bullet Speed + Split | Fast projectile fan. | Edge fan shots become hard to validate visually. | Immediate screen-wide pressure. | Fan readability drops quickly. | Burst collision/event load. | Human |
| Bullet Speed + Spectral | Fast through-wall shots. | Invisible-seeming hits from off-angle paths. | Counterplay reduction. | Through-wall impacts feel abrupt. | More long travel checks across map. | Human |
| Bullet Speed + Beam | Mainly independent unless replacing tears with beam. | Stat expectations mismatch when beam active (speed no longer meaningful). | Build trap/confusion risk. | Player confusion on which stat matters. | Neutral. | Struct + Human |
| Bullet Speed + Infection | Fast infection application shots. | Infection tagging too easy to execute safely. | Economy loop skew. | Green shot trails can be brief/hard to parse. | Slightly more collisions from attempted tags. | Human |
| Bullet Speed + Reactive | Indirect interaction only via incoming combat pace. | None direct. | Minor. | Minor. | Minor. | Struct |
| Piercing + Bounce | Ricochet shots that can continue through enemies. | Counter interactions produce unintuitive order (body bounce vs hurtbox pierce). | High room-clear automation. | Hard to follow single projectile lifecycle. | Very long-lived multi-event projectiles. | Struct + Human |
| Piercing + Homing | Tracking projectiles pass through targets. | Re-hit cadence assumptions with pierce depletion. | Reliable multi-kill lines. | Hard to know why projectile did not disappear. | Targeting + hurtbox cost accumulates. | Human |
| Piercing + Split | Many bullets each with pierce budget. | Exponential effective hit opportunities. | Potential run invalidation by crowd deletion. | Major bullet clutter. | Heavy hurtbox event volume. | Struct + Human |
| Piercing + Spectral | Through-wall shots that also pass enemies. | Encounter geometry and body-blocking heavily bypassed. | Extreme safety and clear speed. | Low visual explanation of misses/hits. | Long-lived high-interaction bullets. | Human |
| Piercing + Beam | Tear-only pierce may not apply to beam; expectation mismatch. | Player assumption bug: pierce item appears ineffective with beam. | Build trap frustration. | Readability of beam hit persistence. | Beam already heavy; pierce mostly N/A. | Struct + Human |
| Piercing + Infection | Infection shots should infect and not damage; pierce may allow multiple infections. | Infection projectile wrongly consuming pierce/disposing unexpectedly. | Too-safe mass infection tagging. | Many infected enemies at once. | Longer encounters and AI load. | Struct + Human |
| Piercing + Reactive | Largely independent systems. | None direct expected. | Minor indirect via pace changes. | Minor. | Minor. | Struct |
| Bounce + Homing | Homing bullets that can ricochet off obstacles. | Direction reversals fight steering causing jitter loops. | High autonomous map coverage. | Erratic paths difficult to parse. | Collision + scan cost compounding. | Struct + Human |
| Bounce + Split | Multiple ricochet-capable projectiles per shot. | Constrained-room ping-pong storms. | Extreme area denial. | Severe visual noise. | Potential spike from many active ricochets. | Struct + Human |
| Bounce + Spectral | Spectral bypasses body collision, effectively suppressing bounce opportunities. | Player expectation mismatch (bounce seems disabled). | Build value confusion. | Hard to infer why no ricochet happens. | Often lower than bounce alone due fewer collisions. | Struct + Human |
| Bounce + Beam | Tear bounce likely irrelevant when beam weapon active. | Item effect perceived as nonfunctional during beam replacement. | Build trap. | Beam dominates visuals; bounce feedback absent. | Beam segment costs unchanged. | Struct + Human |
| Bounce + Infection | Infection shots may bounce before infecting target. | Bounce can redirect away, reducing intended infection control. | Risk profile variance by room geometry. | Infection intent readability reduced on ricochet. | Extended projectile life in infection mode. | Human |
| Bounce + Reactive | Mostly independent. | None direct expected. | Minor. | Minor. | Minor. | Struct |
| Homing + Split | Multiple homing bullets per shot fan then converge on targets. | Per-bullet target scans can surge; retarget jitter with dense enemy sets. | Very high consistency and DPS. | Curving swarm can obscure enemy projectiles. | Highest scan pressure combination. | Struct + Human |
| Homing + Spectral | Tracking bullets ignore geometry. | Homing through walls may overperform unexpectedly. | Very low-risk auto-targeting. | Through-wall curved paths hard to anticipate. | Long-lived scanned projectiles. | Human |
| Homing + Beam | Homing likely irrelevant with segmented beam replacement. | Expectation mismatch if homing items appear inert under beam. | Build trap. | Beam-only feedback hides homing stat value. | Neutral to low extra. | Struct + Human |
| Homing + Infection | Infection bullets track targets for easier tagging. | Risk/reward collapse if tagging becomes too safe. | Economy acceleration potential. | Many fast infected enemies and curved shots overlap. | Longer engagements plus scan load. | Human |
| Homing + Reactive | Indirect interaction via survivability/hit frequency. | None direct. | Minor except damage-farm patterns. | Minor. | Target scan cost unaffected by reactive. | Struct |
| Split + Spectral | Multi-projectile fan through obstacles. | Branches bypass geometry causing hidden hits. | Strong safety and room coverage. | High clutter plus through-wall ambiguity. | High active projectile count. | Human |
| Split + Beam | Split tears typically irrelevant when beam replaces tear weapon. | Expectation mismatch for split effects with beam active. | Build trap/low perceived value. | Beam visuals suppress split feedback. | Beam cost unchanged; split inactive path. | Struct + Human |
| Split + Infection | Fan of infection shots for multi-target tagging. | Infection spread may become uncontrollable in small rooms. | Reward inflation via mass infection. | Many green projectiles reduce readability. | Projectile count increases fight duration. | Human |
| Split + Reactive | Indirect only. | None direct expected. | Minor. | Minor. | Minor to moderate from denser fights. | Struct |
| Spectral + Beam | Spectral likely tear-specific and may not affect beam segments. | Expectation mismatch if spectral appears inactive under beam. | Build trap. | Beam collision behavior must be clear. | Neutral. | Struct + Human |
| Spectral + Infection | Infection shots through walls. | Infection applied from positions with low retaliation risk. | Risk/reward inversion toward reward. | Hard to read infection source line. | More long-lived infection projectiles. | Human |
| Spectral + Reactive | Indirect. | None direct expected. | Minor. | Minor. | Minor. | Struct |
| Beam + Infection | Infection beam segments should infect without damage while in infection mode. | Segment infection_power/damage toggling regressions. | Safer infection tagging in lines. | Green beam clarity must remain obvious. | Segment spawn/despawn under repeated fire. | Struct + Human |
| Beam + Reactive | Systems mostly separate (outgoing weapon vs incoming damage event). | None direct expected. | If beam strength reduces incoming hits, reactive value may collapse. | Minor. | Beam event load persists independently. | Struct + Human |
| Infection + Reactive | Player may intentionally take damage for drops while infecting for extra currency from kills. | Economy exploit loops; progression pacing breaks. | Highest progression-risk combo (drop inflation). | Reward source confusion (drop on hit vs drop on infected kill). | Signal and pickup churn in long runs. | Struct + Human |

## 3. Combinations Not Fully Verifiable Structurally (Require Human Validation)

These cannot be closed by code inspection alone because they depend on encounter dynamics, room geometry, readability, and player decision loops.

Priority A (run integrity / severe risk):
- Fire Rate + Split
- Fire Rate + Homing
- Fire Rate + Beam
- Split + Homing
- Split + Spectral
- Infection + Reactive
- Beam + Infection
- Piercing + Split
- Bounce + Split

Priority B (combination behavior correctness + readability):
- Bounce + Homing
- Bounce + Spectral
- Piercing + Spectral
- Homing + Spectral
- Range + Spectral
- Damage + Beam
- Fire Rate + Infection
- Split + Infection

Priority C (build-value clarity, not hard-fail):
- Beam + Split
- Beam + Homing
- Beam + Bounce
- Beam + Piercing
- Beam + Spectral
- Bullet Speed + Beam

## 4. Prioritized Playtest Checklist

Order by impact on run validity and confidence.

1. Run integrity blockers
- Verify no hard-locks/crashes when stacking high Fire Rate + Split + Homing items.
- Verify no uncontrolled projectile persistence in small rooms with Bounce + Split.
- Verify Beam fire under low cooldown does not freeze or stutter heavily.

2. Combination bugs
- Verify mixed-capability propagation per spawned bullet branch (Split with Spectral/Pierce/Bounce/Homing simultaneously).
- Verify infection mode keeps damage at zero across tear and beam replacement paths.
- Verify capability expectations when beam is active (document which tear-only effects are intentionally inactive).

3. Infinite loops / exploit loops
- Validate there is no practical infinite currency loop from Infection + Reactive damage-farming.
- Validate bounce interactions do not create indefinite ricochet loops in common room geometry.

---

## 5. Pre-Playtest Stabilization Audit (August 2026)

Added during the static audit pass. These items were identified by code inspection and cannot be confirmed without running the game.

### 5.1 Door Blocker Fix Validation (Priority: High)

**Background:** `door.tscn` previously had an orphaned `CollisionPolygon2D` with no physics parent — closed doors had zero physical presence. Fixed August 2026 (added `StaticBody2D` BlockerBody, `collision_layer = 1`). All tests below are gameplay-pending.

**Core behavior (closed door as wall):**
1. Start the game. Enter Room1. Shoot at a closed door.
   - **Expected:** bullet stops at the door surface and destroys (or bounces if bounce item equipped).
   - **Failure:** bullet passes through the closed door.
2. Equip a Bounce item (e.g., `rubber_coat`). Shoot at a closed door.
   - **Expected:** bullet deflects off the door.
   - **Failure:** bullet passes through.
3. Walk toward a closed door as the player.
   - **Expected:** player is physically blocked by the door (cannot enter adjacent room while door is closed).
   - **Failure:** player passes through.

**Combat interaction with closed doors:**
4. Equip `brimstone`. Fire beam at a closed door.
   - **Expected:** beam segments stop at door (do not extend into adjacent room).
   - **Failure:** beam extends through closed door.
5. Equip a lob burst item (e.g., `clot_catapult`). Lob a projectile toward a closed door.
   - **Expected:** the lobbed projectile lands on or near the door; burst fragments spawn at impact point; none pass through.
   - **Failure:** projectile or fragments pass through the closed door.
6. Equip `blast_cap` (explosive projectile). Shoot a closed door.
   - **Expected:** bullet destroys on contact, explosion triggers at the door surface. No regression in explosion behavior vs. shooting walls.
   - **Failure:** explosion does not trigger, or bullet passes through.
7. Check enemy with RayCast AI (e.g., `NerdEnemy` or `HostEnemy`). Verify they do not fire through a closed door at the player in an adjacent room.
   - **Expected:** RayCast returns no line-of-sight through closed door (StaticBody2D on layer 1 blocks raycast).
   - **Failure:** enemies shoot through the closed door into the adjacent room.

**Open door behavior:**
8. Clear the room. Open the door. Shoot at the open door gap.
   - **Expected:** bullet passes through freely (no invisible blocker).
   - **Failure:** bullet is blocked by an open door (blocker not disabled on open).
9. Walk toward the open door and verify transition triggers normally.
   - **Expected:** player teleports to next room, camera follows. Same behavior as before the fix.
   - **Failure:** transition fails or player gets stuck.
10. After transitioning to the next room, verify that the player does not immediately trigger a reverse transition back.
    - **Expected:** `Global.recently_moved` cooldown prevents immediate reverse transition (0.3s window).
    - **Failure:** player bounces back and forth between rooms rapidly.

**Room lifecycle:**
11. Enter a combat room (enemies active). Verify doors close. Kill all enemies. Verify doors open.
    - **Expected:** doors close on room entry, open on room clear, matching `room.gd` logic.
    - **Failure:** doors remain permanently open or closed regardless of enemy state.
12. Use `respawn` machine. Verify doors close again when enemies respawn.
    - **Expected:** `room.gd` `close_doors()` is called correctly on respawn; same door behavior as fresh room entry.
    - **Failure:** doors do not close after respawn.

### 5.2 Debug Menu Validation (Priority: High)

**Required playtest steps:**
1. Press F1. The debug menu should appear in the top-left corner.
2. Press F1 again. The debug menu should disappear. Gameplay should be unaffected while hidden.
3. Open the menu. Verify it shows approximately 290 item buttons.
4. Click a stat item (e.g., `Sad Onion` or `adrenal_shot`). Verify the stat change is reflected in StatsUI.
5. Click a reactive item (e.g., `piggy_bank`). Take damage. Verify a drop appears.
6. Click a weapon-replacement item (e.g., `brimstone`). Verify shots become a beam.
7. Click `+ 10 Drops`. Verify the drop counter increments by 10.
8. Verify the menu does not pause the game while open (enemies continue moving).

### 5.3 Map Reveal Items — No Visual Output (Priority: Low)

**Background:** `MapRevealRuntime` writes to `Global.reveal_map_level` etc., but no UI reads these fields. Items using `MapRevealRuntime` (e.g., `map_reveal_effect` items) are currently non-functional from the player's perspective.

**Required playtest step:**
- Give a map-reveal item via debug menu. Confirm whether any feedback is visible.
- **Expected:** No visible feedback (no minimap system exists yet). No crash.
- **Failure:** Game crashes or displays garbled UI.
- **Future work:** When a minimap is added, it should read `Global.reveal_map_level`.

### 5.4 Economy Stacking (Priority: Medium)

**Background:** No infinite loops were found statically. These are balance validation items.

**Required playtest steps:**

1. **Compounding drop pickup economy:**
   - Give 3 copies of a `gain_drops_on_drop_pickup` item via debug menu.
   - Kill several enemies and collect drops.
   - Record total drops gained per physical drop collected.
   - **Expected:** Each physical drop gives 1 (base) + (3 × bonus_per_pickup) total drops.
   - **Risk:** Very high drop income per room if bonus is large.

2. **Infection + kill economy combined:**
   - Give `green_bounty` (gain drops on infected kill) + `blood_dividend` (gain drops on any kill).
   - Infect all enemies in a room, then kill them.
   - **Expected:** Each infected kill pays both item bonuses (additive).
   - **Risk:** May make infected kills too lucrative compared to direct kills.

3. **Shop discount to near-zero:**
   - Give multiple `shop_price_multiplier` discount items.
   - Verify `get_effective_shop_cost(1)` returns at minimum 1 (never 0 or negative).
   - **Expected from code:** `max(0, int(ceil(1 * 0.05)))` = 1 at most aggressive discount.
   - **Note:** Code clamps multiplier at 0.05 minimum, so cost approaches but should never reach 0.

4. **Infection + reactive damage farming:**
   - Give `spawn_drops_on_damage` (Piggy Bank) + `gain_drops_on_kill_effect` (with infected bonus).
   - Intentionally get hit while infecting enemies, then kill them.
   - Record drops per room.
   - **Expected:** Economy is generous but not so fast that runs trivialize within 2 rooms.
   - **Risk:** If farming loops emerge, adjust item parameters.

### 5.5 Enemy Kill Deduplication (Priority: Medium)

**Background:** `enemy_base.gd` had a bug where multiple deferred hits in the same frame could trigger `die()` twice (emitting `enemy_killed` twice, spawning two drops). Fixed August 2026 with `_dead` flag.

**Required playtest step:**
- Stack high Fire Rate + Split or Homing. Enter a room with weak enemies.
- Kill several enemies. Verify each enemy spawns exactly one drop and one death effect.
- **Expected:** One drop per enemy, one death animation per enemy.
- **Failure (pre-fix):** Two drops and two death animations visible.
- **Note:** This should now pass after the fix, but must be confirmed in gameplay.

### 5.6 Tear-Only Effects with Non-Tear Weapons (Priority: Low)

**Background:** Several `AttackEffectData` items (Piercing, Bounce, Homing, Split, Spectral) only affect tear projectiles. When a weapon-replacement item is active (Brimstone, returning blade, etc.), these items may appear non-functional.

**Required playtest step for each combination:**
- Give a weapon-replacement item + a tear modifier item.
- Verify behavior is either correctly applied to the new weapon type OR correctly non-functional (expected build trap).
- Known expected non-functional pairings (not bugs, design):
  - Piercing + Brimstone (beam segments don't pierce in the tear sense)
  - Bounce + Brimstone (beam segments don't bounce)
  - Homing + any non-tear weapon
  - Split + any non-tear weapon

4. Performance spike checks
- Stress test 60s continuous fire with dense enemy rooms for: Fire Rate + Split + Homing, and Fire Rate + Beam.
- Capture FPS/frame-time observations in rooms with obstacles for Spectral + Split and Bounce + Split.

5. Broken progression checks
- Validate economy pacing per floor with and without infection-heavy play.
- Validate gachapon cost pressure still matters under reactive and infection drop synergies.

6. Lower-priority numerical balance
- Tune outlier DPS combinations after above checks pass.
- Tune readability-oriented parameters (spread, homing radius/strength, beam segment duration).

## 5. Evidence Anchors (Code)

Primary behavior sources for this matrix:
- `AttackData` fields: `attacks/attack_data.gd`
- Tear behavior, homing, pierce, bounce, spectral: `attacks/bullet.gd`
- Beam behavior: `attacks/beam_segment.gd`
- Attack build/spawn pipeline: `player/systems/weapon_system.gd`, `player/systems/projectile_system.gd`, `player/systems/attack_evaluation_system.gd`
- Infection application and enemy reward flag: `enemies/enemy_base.gd`, `world/drop.gd`
- Reactive item runtime and event bus: `items/effects/spawn_drops_on_damage_runtime.gd`, `player/systems/effect_runtime_system.gd`, `system/event_bus.gd`
- Progression purchase path: `world/gachapon_machine.gd`, `world/upgrade_pickup.gd`

---

## 6. Directional Shot Appender — Pending Gameplay Validation (August 2026)

**Background:** `DirectionalShotAppenderEffect` + `AttackData.appended_shot_offsets` + `ProjectileSystem` tear integration implemented 2026-08-19. Statically validated. Not yet gameplay tested.

### 6.1 Core Backward Shot Behavior (Priority: High)

**Item:** `backward_shot` (angle_offsets_degrees = [180.0])

1. Start the game. Equip `backward_shot` via debug menu.
2. Shoot in any direction.
   - **Expected:** One forward bullet AND one backward bullet spawn simultaneously from the same position.
   - **Failure A:** Only forward bullet spawns (appended shot not spawning).
   - **Failure B:** Multiple backward bullets (recursion bug — should be impossible per code, but verify).
3. Move while shooting. Confirm both bullets inherit movement correctly.
   - **Expected:** Both forward and backward bullets use `inherited_velocity` from the same AttackData.

### 6.2 Backward Shot + Split Composition (Priority: High)

**Items:** `backward_shot` + any split item (e.g., `forked_chamber`)

1. Equip both items. Shoot.
   - **Expected:** A forward fan of N+1 shots AND a backward fan of N+1 shots (the full split fan in both directions).
   - **Failure A:** Only single backward bullet instead of backward fan (appended shot not going through `_build_attack_directions()`).
   - **Failure B:** More than 2×(N+1) projectiles per shot (recursive offset re-application).
   - **This is intentional design.** Document as correct if it works.

### 6.3 Backward Shot inherits capabilities (Priority: High)

For each capability below: equip `backward_shot` + the capability item. Confirm backward bullets have the same capability as forward bullets.

| Capability | Item to test | Expected backward bullet behavior |
|---|---|---|
| Piercing | `needle_eye` | Backward bullet pierces enemies |
| Bounce | `rubber_coat` | Backward bullet bounces off walls |
| Homing | `seeker_eye` | Backward bullet homes toward enemies |
| Explosive | `blast_cap` | Backward bullet explodes on impact |
| Infection | (toggle Space) | Backward infection shot infects enemies |
| Status (e.g. poison) | `venom_sac` | Backward bullet applies poison |

### 6.4 Backward Shot with Weapon Replacement (Priority: Medium)

**Expected:** When a weapon replacement item is active (e.g., `brimstone`), `backward_shot` has no visible effect on the replacement weapon — the weapon fires as normal.

1. Equip `brimstone` + `backward_shot`. Fire.
   - **Expected:** Normal brimstone beam only. No backward beam, no backward tear.
   - **Failure:** Any additional unexpected projectile spawns.
   - **This is intentional design** (tear-only support for first slice). Document as correct if no additional projectile appears.

### 6.5 Stacking Two Backward Shot Items (Priority: Low)

1. Equip `backward_shot` twice via debug menu.
2. Shoot.
   - **Expected:** Two overlapping backward bullets (by-design doubling — same as Isaac item stacking).
   - **Failure:** Only one backward bullet (second item not appending), or more than two (recursion).
   - **Note:** Two overlapping bullets are cosmetically indistinguishable but mechanically both exist (each can pierce/deal damage independently).

### 6.6 Performance Under Rapid Fire (Priority: Low)

1. Equip `backward_shot` + `overclock_cell` (fire rate) + `forked_chamber` (split). Fire continuously in a room with enemies.
   - **Expected:** No framerate drop beyond what split alone would cause.
   - **Note:** Backward shot effectively doubles projectile count of each volley. Combined with split, projectile count is 2×(N+1) per shot. Monitor for performance degradation.

### 6.7 Side Shots, Cross Shot, Diagonal Shot (Priority: Medium)

**Items to test:** `side_shots`, `cross_shot`, `diagonal_shot`

For each item:
1. Equip the item. Shoot right (→).
   - `side_shots`: expect bullets firing up and down in addition to the normal forward bullet.
   - `cross_shot`: expect bullets firing up, down, left, and right simultaneously.
   - `diagonal_shot`: expect bullets firing at ↗ ↘ ↙ ↖ in addition to the normal forward bullet.
2. Rotate firing direction (shoot left, up, down). Confirm appended angles rotate relative to the current firing direction — they are not locked to world axes.
   - **Expected:** angles are always relative to `attack_data.direction`, not to world Vector2.RIGHT.
   - **Failure:** Appended bullets always go to world-right regardless of aim direction.
3. Equip `cross_shot`. Verify that the total bullet count per shot is 4 (1 forward + 3 appended).
4. Equip `diagonal_shot`. Verify total bullet count per shot is 5 (1 forward + 4 diagonal).
5. Equip `cross_shot` + a split item. Verify each of the 4 directions fans out independently (5 × 4 = 20 bullets per shot with 4-way split). This is intentional but extreme — note if performance degrades.

---

## 7. Burst Cadence — Pending Gameplay Validation (August 2026)

**Background:** `CadenceShotEffect` + `WeaponSystem` cadence counter + `AttackData` cadence fields implemented 2026-08-19. Statically validated. Not yet gameplay tested.

### 7.1 Core Cadence Behavior (Priority: High)

**Item:** `viral_pulse` (every_n_shots = 3, damage ×2, explosion_radius = 32)

1. Equip `viral_pulse`. Fire 3 shots.
   - **Expected:** Shots 1 and 2 fire normally. Shot 3 fires normally AND a second explosive projectile fires simultaneously from the same position.
   - **Failure A:** No special shot appears on shot 3.
   - **Failure B:** The special shot appears on shot 1 or 2 (counter off-by-one).
   - **Failure C:** The special shot appears every shot (counter not incrementing).

2. Fire 6 shots total.
   - **Expected:** Special shot on shot 3 and shot 6 (every 3rd shot).
   - **Failure:** Counter not resetting — special shot fires only once total.

3. Verify the special shot deals more damage than the normal shot (should be ×2).
   - **Expected:** Special shot kills weaker enemies in one hit when normal shot does not.

4. Verify the special shot explodes on impact.
   - **Expected:** Small explosion visible on hit (radius ≈ 32px), damaging nearby enemies.

### 7.2 Counter Reset on Item Removal (Priority: Medium)

1. Equip `viral_pulse`. Fire 2 shots (counter at 2 of 3).
2. Remove the item via debug menu (if item removal is supported).
3. Fire 2 more shots.
4. Re-equip `viral_pulse`. Fire 3 shots.
   - **Expected:** Special shot fires on the 3rd shot after re-equipping (counter restarts clean).
   - **Failure:** Special shot fires on the 1st shot after re-equipping (stale counter).
   - **Note:** `_process_cadence` resets counter to 0 when `cadence_interval <= 0`, so each shot without the item clears the counter. This should pass but must be confirmed.

### 7.3 Cadence + Split Composition (Priority: High)

**Items:** `viral_pulse` + any split item

1. Fire 3 shots.
   - **Expected:** Shot 3 normal fires (fan of split bullets) AND the cadence special shot also fires as a fan of split bullets with ×2 damage and explosion.
   - **Failure:** Cadence special shot fires as a single bullet (not going through split).
   - **Note:** Cadence shot copies full `AttackData` including `split_count`. This should work automatically.

### 7.4 Cadence + Directional Appender Composition (Priority: Medium)

**Items:** `viral_pulse` + `backward_shot`

1. Fire 3 shots.
   - **Expected:** Shot 3 fires forward + backward (normal). Cadence special shot ALSO fires forward + backward (special explosive versions). Total 4 projectiles on shot 3.
   - **Failure:** Cadence shot fires only forward (appended_shot_offsets not carried over).
   - **Note:** Cadence shot copies `appended_shot_offsets`. ProjectileSystem tear path processes them for the cadence shot. This should work automatically.

### 7.5 Cadence with Weapon Replacement (Priority: Medium)

**Items:** `viral_pulse` + `brimstone`

1. Fire 3 shots (beams).
   - **Expected:** Shot 3 fires a normal beam AND a second beam (cadence) from the same position. The cadence beam is more damaging.
   - **Intentional design:** Cadence shot uses same `weapon_type` as the base shot. If beam doesn't support split/appended, neither does the cadence beam.
   - **Note this as a known interaction, not a bug.**

### 7.6 Cadence + Infection Mode (Priority: Low)

**Item:** `viral_pulse`, toggle infection mode (hold Space).

1. Fire 3 infection shots.
   - **Expected:** Shot 3 fires a normal infection shot AND a cadence infection shot (explosive infection shot that does 0 damage but explodes).
   - **Note:** `explosion_inherits_infection` is false by default. The explosion from the cadence shot will deal normal explosion damage (not zero). This is potentially the intended interaction — the infection shot infects, the explosion deals chip damage. Verify if this feels correct.
   - **Flag for design review:** Should cadence explosions inherit infection_shot state?

### 7.7 Multiple Cadence Items (Priority: Low)

**Items:** Two `viral_pulse` items equipped.

1. Fire 3 shots.
   - **Expected:** Shot 3 fires ONE cadence special shot with stacked bonuses (×4 damage, 64px explosion) since both items write to same AttackData fields multiplicatively.
   - **Failure:** Two separate cadence shots fire (would indicate incorrect architecture).
   - **Note:** This is the documented first-slice behavior: one shared counter, stacked bonuses.

---

## 8. Demo Core Loop — Implemented, Pending Gameplay Validation (Slices 43–44)

**Background:** The sections below cover the intended demo loop (Slices 41–44). Tests are defined now so implementation can be validated immediately on completion. All entries below are **Human** validations requiring actual gameplay.

### 8.1 Infection + Gacha Economy Loop (Priority: High — Current Demo Goal)

1. Start a run. Kill 2–3 enemies WITHOUT infecting. Observe drop count.
2. Kill 2–3 enemies WITH infection. Observe drop count.
   - **Expected:** Infected kills yield 2 drops vs. 1 for normal kills.
   - **Validation goal:** Player notices and understands the trade-off.

3. Accumulate drops from infected kills. Purchase an item at the Gacha machine.
   - **Expected:** Item purchased, visible effect (stat change on UI or behavior change in next combat).

4. Purchase several items. Check if build feels meaningfully different from starting state.
   - **Validation goal:** 3-5 items create a noticeable power spike; builds diverge between runs.

### 8.2 Infection Gacha vs Normal Gacha (Priority: High — Slice 42 dependency)

1. Visit both Gacha machines in the Gacha room.
2. Purchase items from Normal Gacha. Verify items from the pool are general combat items.
3. Purchase items from Infection Gacha. Verify items are infection-synergy items (e.g., infection economy bonuses, infection-triggered companions, status effects with infection bonus).
   - **Expected:** Clear thematic distinction between the two pools.
   - **Failure:** Same items appear in both machines consistently.

4. Verify that a general-purpose item (e.g., damage up) appears in Normal Gacha and NOT in Infection Gacha.
5. Verify that an infection-economy item (e.g., green_bounty) appears in Infection Gacha and NOT in Normal Gacha.
   - **Note:** Items that belong to both pools should appear in both.

### 8.3 Combat Room Progression (Priority: High — Slice 43/44 dependency)

1. Enter the first combat room (Floor 1). Defeat all enemies.
   - **Expected:** Doors open after last enemy dies. Player can proceed.

2. Proceed through 2–3 combat rooms. Note difficulty progression.
   - **Expected:** Rooms feel manageable without items; become easier with items from Gacha room.
   - **Failure:** Player can trivially clear all rooms without any items (no challenge).

3. Return to Gacha room after clearing a combat room.
   - **Expected:** Player can navigate back to Gacha room and purchase more items.
   - **Failure:** No path back to Gacha room exists OR Gacha room enemies respawn unexpectedly.

### 8.4 Boss Room (Priority: High — Slice 43 dependency)

1. Enter the boss room. Verify the boss has significantly more HP than regular enemies.
   - **Expected:** Boss takes 5–10× more hits than a regular enemy.

2. Infect the boss. Verify infection applies (green tint, speed boost).
   - **Expected:** Boss becomes notably faster when infected. Risk/reward decision is meaningful.
   - **Design consideration:** Infecting the boss for extra drops vs. killing it faster.

3. Defeat the boss. Verify the floor transition becomes accessible.
   - **Expected:** A door/trapdoor opens or a transition object appears after boss dies.

### 8.5 Floor Transition + Difficulty Increase (Priority: High — Slice 43/44 dependency)

1. Complete Floor 1 and enter the floor transition.
   - **Expected:** Smooth transition to Floor 2. Player retains all items and drops.
   - **Failure:** Player health reset to full incorrectly OR item inventory lost.

2. Play through the first combat room on Floor 2.
   - **Expected:** Enemies are noticeably harder (more HP, faster) than Floor 1 equivalent rooms.
   - **Failure:** Floor 2 feels identical to Floor 1.

3. Verify the Gacha room on Floor 2 still works (if accessible).
   - **Expected:** Can purchase items. Items from prior floor's purchases still in inventory.

### 8.6 Full Run Validation (Priority: High — Final Demo Gate)

1. Complete a full run: Gacha room → 2-3 combat rooms → boss → floor transition → Floor 2 → boss → exit.
   - **Validation criteria:**
     - [ ] Infection trade-off felt during at least one combat room
     - [ ] At least 2-3 items purchased that changed gameplay feel
     - [ ] Boss encounter was challenging but fair
     - [ ] Floor 2 felt harder than Floor 1
     - [ ] No crashes, softlocks, or blocked progressions
     - [ ] Player death returns to a reasonable restart point
     - [ ] Run length felt appropriate (not too short, not exhausting)

---

## 9. Item Pool System — Pending Gameplay Validation (Slice 42, 2026-08-19)

**Background:** Two pool tags (`"gacha"`, `"infection_gacha"`) added to all 295 items. GachaPonMachine now filters by `pool_tag` export. Statically validated. Not yet gameplay tested.

### 9.1 Normal Gacha Pool (Priority: High)

1. Purchase several items from the Normal Gacha machine.
   - **Expected:** Receive general combat items (damage, fire rate, projectile modifiers, weapons, etc.).
   - **Failure A:** `infected_rush` or `plague_feast` appear in the normal gacha pool (both should be infection_gacha-exclusive).
   - **Failure B:** Pool exhausts quickly (unexpected). Normal gacha has 293 items — exhaustion should take many purchases.

2. Verify the Normal Gacha is NOT empty on start.
   - **Expected:** Pool size > 0 immediately after loading the scene.
   - **Failure:** Pool is empty — suggests pool_tag filtering is broken.

### 9.2 Infection Gacha Pool (Priority: High — scene integrated)

*(Infection Gacha machine is now present in `Room5` with `pool_tag = "infection_gacha"`.)*

1. Purchase several items from the Infection Gacha machine.
   - **Expected:** Receive infection-synergy items (drop economy items, items with infected_bonus, control items, viral/plague-themed items).
   - **Failure:** Items appear that have no infection relevance (e.g., pure weapon replacements, map reveal).

2. Verify `infected_rush` can appear in Infection Gacha pool.
   - **Expected:** `infected_rush` appears in Infection Gacha pool after enough purchases.
   - **Failure:** Never appears — the `infection_gacha` tag was not added correctly.

3. Verify `infected_rush` does NOT appear in Normal Gacha pool.
   - **Expected:** Cannot get `infected_rush` from the Normal Gacha machine.
   - **Failure:** Appears in normal gacha — the missing `gacha` tag is not being enforced.

### 9.3 Pool Balance Feel (Priority: Medium)

1. Play several runs purchasing from Infection Gacha only.
   - **Expected:** Items feel thematically coherent — mostly items that complement the infection risk/reward loop.
   - **Gap signal:** Pool feels too thin (exhausts quickly or offers too little variety).

2. Play several runs purchasing from Normal Gacha only.
   - **Expected:** Items feel general purpose — can build any combat style.
   - **Gap signal:** Pool feels like it contains items that would be better in Infection Gacha.

### 9.4 F1 Debug Menu Unaffected (Priority: Low)

1. Use F1 menu to acquire `infected_rush`.
   - **Expected:** Item can be acquired regardless of pool restrictions.
   - **Failure:** Item does not appear in F1 menu — pool filtering leaked into the debug menu.

---

## 10. WorldDungeonRandom Linear Generator — Pending Gameplay Validation (Slice 45, 2026-08-19)

**Background:** An isolated experimental generator was added in `world/world_dungeon_random.tscn` + `world/world_dungeon_random.gd`. Manual `world/world_dungeon.tscn` remains fallback and must continue working.

1. **Manual fallback regression check**
   - Open and run `world/world_dungeon.tscn`.
   - **Expected:** Manual world still behaves as before (no regressions).

2. **WorldDungeonRandom scene load**
   - Open and run `world/world_dungeon_random.tscn`.
   - **Expected:** Scene loads with player, camera, UI, and generated rooms.

3. **Linear chain generation**
   - Start a floor.
   - **Expected:** Generated sequence is `GACHA -> COMBAT x N -> BOSS`.

4. **Combat template random selection**
   - Restart run multiple times.
   - **Expected:** Combat rooms are selected randomly from registered templates.

5. **Template repetition allowed**
   - Observe multiple runs.
   - **Expected:** Same combat template can repeat within the same floor.

6. **Spawn point usage**
   - Enter a generated combat room.
   - **Expected:** Enemies spawn on local `SpawnPoints/*` markers from that room template.

7. **Tier min/max enforcement**
   - Floor 1 and Floor 2 comparisons.
   - **Expected:** Enemies outside tier eligibility are not spawned.

8. **Weight influence check**
   - Observe enemy frequencies across many rooms/runs.
   - **Expected:** Higher `spawn_weight` enemies appear relatively more often.

8A. **Selection with replacement**
   - Observe several generated rooms with 3-5 enemy spawns.
   - **Expected:** The same enemy may appear multiple times in one room when selected repeatedly by weight.
   - **Failure:** System behaves like unique draw without replacement unexpectedly.

9. **Run-to-run enemy variation**
   - Repeat the same floor start several times.
   - **Expected:** Composition differs between runs.

10. **Same layout, different composition**
   - Force/observe repeated use of one combat template.
   - **Expected:** Enemy composition still varies.

11. **Floor 2 tier progression**
   - Reach floor 2.
   - **Expected:** Enemy pool reflects floor-2 tier eligibility.

11A. **Early enemies remain available on later floors**
   - Reach floor 2 or 3.
   - **Expected:** Early enemies can still appear if their configured tier range includes that floor.
   - **Failure:** System incorrectly behaves as `floor N = only tier N enemies`.

12. **Floor transition rebuild**
   - Clear boss and enter transition.
   - **Expected:** New floor is generated (not just room respawn in-place).

13. **Gacha room reappears every floor**
   - After transition to next floor.
   - **Expected:** New floor starts in/at a gacha room.

14. **Boss room remains final node**
   - On each generated floor.
   - **Expected:** Boss room is always at the end of the linear chain.

15. **Door connections correctness**
   - Traverse entire chain forward and backward.
   - **Expected:** Doors always connect to previous/next generated room correctly.

15A. **Semantic door role contract**
   - Inspect at least one generated combat template in gameplay.
   - **Expected:** Forward progression uses the door marked with semantic `FORWARD`, and backtracking uses the door marked with semantic `BACKWARD`.
   - **Failure:** Generator still implicitly depends on node names rather than door roles.

16. **Camera/transition stability**
   - Move across all generated transitions repeatedly.
   - **Expected:** Camera movement and player relocation remain stable.

17. **Manual world still works after random tests**
   - Re-open and run `world/world_dungeon.tscn` after testing random scene.
   - **Expected:** Manual fallback remains fully functional.

18. **SpawnPoints explicit contract**
   - Author or inspect a generated combat template with `SpawnPoints/*` markers and no baked enemies.
   - **Expected:** Runtime enemy positions come from `SpawnPoints`, not from baked enemy nodes.

19. **Standard spacing convention**
   - Traverse several generated rooms in `WorldDungeonRandom`.
   - **Expected:** Rooms align correctly under the current fixed spacing convention (`352 x 216`, generated spacing `Vector2(352, 0)`).
   - **Failure:** Camera or transitions expose overlap/gaps that indicate the spacing contract is wrong for authored templates.

20. **Zero-eligible room behavior**
   - Temporarily create or configure a combat template/floor scenario where no enemy is eligible for the current tier.
   - **Expected:** Room emits a warning and does not silently spawn baked out-of-tier enemies.
   - **Gameplay question:** confirm whether an empty room is acceptable as a fail-safe or whether authoring safeguards are needed.

**Validation type:** All tests in this section are **Human** and currently **pending**.

---

## §8 — Death / Restart Flow (Slice 48)

These tests validate the complete player death and run-restart cycle introduced in Slice 48.

1. **Death screen appears on player death**
   - Let enemies kill the player.
   - **Expected:** "YOU DIED" screen appears with RESTART button. Gameplay is frozen (enemies stop moving, projectiles stop).
   - **Failure modes:** Screen doesn't appear; gameplay continues behind the screen; screen appears but input doesn't work.

2. **ESC does not unpause during death**
   - While the death screen is visible, press ESC.
   - **Expected:** Nothing happens — Pauser is blocked by `Global.is_dead`.
   - **Failure:** ESC unpauses the tree while the death screen is still showing, allowing player to see the game running without being able to play.

3. **RESTART resets all Global run state**
   - Die on floor 3 with 50 drops. Press RESTART.
   - **Expected:** New run starts with `floor_number = 1`, `drops = 0`, `difficulty_level = 1`. Player has no items.
   - **Failure:** Floor number, drops, or items carry over to the new run.

4. **RESTART produces a clean new run (no leftover runtimes)**
   - Acquire several reactive items (e.g., Piggy Bank, bait items, companion items). Die. Restart.
   - **Expected:** New run has no active reactive runtimes from the previous run. EventBus signals are not double-subscribed.
   - **Failure:** Duplicate signal connections from a prior run's runtimes cause double-triggering of economy/companion effects.

5. **Player group is restored after restart**
   - Die. Restart. Verify enemies chase player and that `get_tree().get_first_node_in_group("player")` returns the new player.
   - **Expected:** Player is correctly found in "player" group after scene reload.
   - **Failure:** Enemies stand still because they cannot find the player. WorldDungeon/WorldDungeonRandom fail to move player on floor start.

6. **Death screen works in WorldDungeonRandom**
   - Run `world/world_dungeon_random.tscn` as the main scene. Die. Confirm death screen appears. Restart.
   - **Expected:** Full death/restart cycle works identically in the generated world.
   - **Failure:** DeathScreen missing from scene; or EventBus connection fails in the random world context.

7. **Death screen layout is readable**
   - Confirm "YOU DIED" text and RESTART button are visible, centered, and readable against the semi-transparent background.
   - **Note:** Layout is minimal by design. Readability and visual polish are validation targets, not implementation assumptions.

8. **Death payload extensibility smoke test** (when extending the screen later)
   - When `player.die()` payload is extended with `floor_number`, confirm the value matches the floor where the player died.
   - **Expected:** Payload data matches actual run state at time of death.

**Validation type:** All tests in this section are **Human** and currently **pending**.
