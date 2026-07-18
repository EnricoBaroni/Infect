# PLAYTEST_MATRIX.md

Comprehensive playtest preparation matrix for the baseline mechanic set validated up to Slice 22.

Scope:
- Baseline validation snapshot used before autonomous content-expansion resumed.
- Focus on validation confidence for the baseline projectile/room/economy loop.
- Mechanics covered in this matrix: Damage, Fire Rate, Range, Bullet Speed, Piercing, Bounce, Homing, Split, Spectral, Beam, Infection, Reactive items.

Legend:
- Struct: Can be mostly verified by code-path/structural inspection.
- Human: Requires gameplay playtest to validate feel, readability, pacing, or emergent interaction risk.

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
