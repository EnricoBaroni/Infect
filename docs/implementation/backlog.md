# Backlog de implementación inicial

Este documento es el plan operativo para empezar el desarrollo en el repositorio sin perder el foco de validación de gameplay.

## Objetivo del backlog

Validar la arquitectura con slices pequeños, jugables y verificables. La prioridad es:
1. estabilizar el flujo de ataque base;
2. validar Infection como estado de gameplay;
3. conectar el ingreso de ítems con el estado del jugador;
4. dejar una base estable para continuar con contenido.

## Slice 1 — Ataque base

### Tarea objetivo
Separar la intención del ataque de la materialización del proyectil y dejar el flujo de disparo estable.

### Archivos probablemente afectados
- [player/player.gd](player/player.gd)
- [attacks/bullet.gd](attacks/bullet.gd)
- [system/hitbox.gd](system/hitbox.gd)
- [system/hurtbox.gd](system/hurtbox.gd)

### Resultado esperado
El jugador sigue disparando, pero el ataque ya pasa por una estructura clara que puede crecer sin romper el flujo.

## Slice 2 — Infection como estado explícito

### Tarea objetivo
Hacer que un enemigo infectado tenga un estado claramente representado y verificable.

### Archivos probablemente afectados
- [enemies/enemy_base.gd](enemies/enemy_base.gd)
- [enemies/bat_enemy.gd](enemies/bat_enemy.gd)
- [attacks/bullet.gd](attacks/bullet.gd)

### Resultado esperado
La Infection ya no es sólo un cambio visual o un flag de una línea; pasa a ser una condición de gameplay con identidad clara.

## Slice 3 — Cambio mínimo de comportamiento tras Infection

### Tarea objetivo
Que el enemigo infectado reaccione de forma diferente sin romper su IA base.

### Archivos probablemente afectados
- [enemies/enemy_base.gd](enemies/enemy_base.gd)
- [enemies/bat_enemy.gd](enemies/bat_enemy.gd)

### Resultado esperado
La Infection ya es una decisión jugable y no solo un estado visible.

## Slice 4 — Primer pickup de contenido

### Tarea objetivo
Introducir la primera forma de recoger un ítem como contenido de juego.

### Archivos probablemente afectados
- [items/data/item_data.gd](items/data/item_data.gd)
- [items/effects/effect_data.gd](items/effects/effect_data.gd)
- [world/upgrade_pickup.gd](world/upgrade_pickup.gd)

### Resultado esperado
El proyecto puede registrar un primer item como dato de contenido y no como lógica ad hoc.

## Slice 5 — Inventory y cálculo de stats

### Tarea objetivo
Registrar el ítem recogido y reconstruir el estado final del jugador mediante un resolutor.

### Archivos probablemente afectados
- [player/systems/inventory_system.gd](player/systems/inventory_system.gd)
- [player/systems/stat_evaluation_system.gd](player/systems/stat_evaluation_system.gd)
- [system/stats.gd](system/stats.gd)
- [world/upgrade_pickup.gd](world/upgrade_pickup.gd)

### Resultado esperado
Los stats dejan de ser modificados directamente desde pickups; el juego se mueve hacia un flujo reconstruible.

## Slice 6 — Reward y loop de room

### Tarea objetivo
Conectar el combate con un reward mínimo y validar el riesgo/recompensa en una room.

### Archivos probablemente afectados
- [world/room.gd](world/room.gd)
- [world/drop.gd](world/drop.gd)
- [world/world_dungeon.gd](world/world_dungeon.gd)

### Resultado esperado
La room deja de ser solo un espacio de combate y pasa a ser una unidad de progresión testable.

## Slice 7 — EventBus mínimo

### Tarea objetivo
Agregar una capa global mínima de señales para habilitar ítems reactivos sin cambiar el comportamiento actual del gameplay.

### Archivos afectados
- [system/event_bus.gd](system/event_bus.gd)
- [project.godot](project.godot)
- [player/player.gd](player/player.gd)
- [enemies/enemy_base.gd](enemies/enemy_base.gd)
- [attacks/bullet.gd](attacks/bullet.gd)
- [world/room.gd](world/room.gd)
- [world/upgrade_pickup.gd](world/upgrade_pickup.gd)

### Resultado obtenido
- EventBus autoload implementado con señales candidatas (`player_damaged`, `enemy_killed`, `room_entered`, `room_cleared`, `projectile_spawned`, `projectile_destroyed`, `item_collected`, `enemy_spawned`, `boss_killed`).
- Emisión conectada en puntos de ciclo de vida de combate y room sin introducir cambios funcionales de gameplay.
- La base queda lista para validar ítems reactivos en el siguiente slice.

## Slice 8 — Primer ítem reactivo

### Tarea objetivo
Validar Phase 5 con un ítem reactivo completo que consuma señales del EventBus sin condicionales por ID en sistemas base.

### Archivos probablemente afectados
- [items/effects/effect_data.gd](items/effects/effect_data.gd)
- [items/effects/](items/effects/)
- [player/systems/inventory_system.gd](player/systems/inventory_system.gd)
- [system/event_bus.gd](system/event_bus.gd)

### Resultado esperado
Al menos un efecto reactivo funcional, desacoplado y verificable en gameplay.

### Resultado obtenido
- Runtime reactivo implementado con `ReactiveEffectData`, `ReactiveEffectInstance` y `EffectRuntimeSystem`.
- Primer ítem reactivo validado: **Piggy Bank** (`+1 drop` al recibir daño del jugador).
- Integración realizada sin condicionales por ítem en sistemas base.

## Slice 9 — WeaponSystem base

### Tarea objetivo
Extraer la construcción del ataque y el disparo desde `Player` hacia un `WeaponSystem` dedicado, preservando comportamiento actual (normal + infection shot).

### Archivos probablemente afectados
- [player/player.gd](player/player.gd)
- [player/systems/](player/systems/)
- [attacks/attack_data.gd](attacks/attack_data.gd)

### Resultado esperado
`Player` delega disparo a `WeaponSystem` y deja de ser responsable directo de construcción de ataque.

### Resultado obtenido
- `WeaponSystem` implementado en `player/systems/weapon_system.gd`.
- `Player` ahora delega el disparo en `WeaponSystem` preservando normal shot e infection shot.
- `AttackData` sigue siendo la pieza de transferencia entre intención y entidad física.

## Slice 10 — ProjectileSystem mínimo con capacidades

### Tarea objetivo
Extraer la interpretación de capacidades del proyectil desde `Bullet` hacia un `ProjectileSystem` que configure comportamiento por datos.

### Archivos probablemente afectados
- [attacks/bullet.gd](attacks/bullet.gd)
- [attacks/attack_data.gd](attacks/attack_data.gd)
- [player/systems/weapon_system.gd](player/systems/weapon_system.gd)
- [player/systems/](player/systems/)

### Resultado esperado
La configuración del proyectil se resuelve por capacidades de datos y no por condicionales específicos.

### Resultado obtenido
- `ProjectileSystem` implementado para materializar `AttackData`.
- `AttackEvaluationSystem` implementado para aplicar `AttackEffectData` antes del spawn.
- Capacidad de `pierce` y `bounce` validada con efectos data-driven y nuevos ítems (`Needle Eye`, `Rubber Coat`).

## Slice 11 — Weapon replacement (Brimstone validation)

### Tarea objetivo
Validar reemplazo de arma por dato para que una configuración de weapon type sustituya tears por láser sin condicionales por ítem.

### Archivos probablemente afectados
- [player/systems/weapon_system.gd](player/systems/weapon_system.gd)
- [items/effects/](items/effects/)
- [items/data/](items/data/)
- [attacks/](attacks/)

### Resultado esperado
Un ítem de reemplazo de arma cambia el flujo de disparo de tears a láser y revierte correctamente al removerlo.

### Resultado obtenido
- Brimstone implementado como `SetWeaponTypeEffect` data-driven.
- `ProjectileSystem` materializa haz segmentado (`BeamSegment`) cuando `weapon_type = segmented_beam`.
- No se introdujeron condicionales por ítem en sistemas base.
- Se agregó contenido de seguimiento coherente con el pipeline: `Coiled Cable` (extensión de haz).

## Slice 12 — Validación humana y hardening de weapon pipeline

### Tarea objetivo
Validar en gameplay real el pacing, alcance y claridad del haz segmentado antes de iniciar sistemas futuros.

### Archivos probablemente afectados
- [items/data/brimstone.tres](items/data/brimstone.tres)
- [items/data/coiled_cable.tres](items/data/coiled_cable.tres)
- [items/effects/set_weapon_type_effect.gd](items/effects/set_weapon_type_effect.gd)
- [attacks/beam_segment.gd](attacks/beam_segment.gd)

### Resultado esperado
Ajustes de balance basados en playtest humano y registro de hallazgos en documentación.

### Nota de prioridad
- Este slice queda pendiente para validación humana posterior.
- Prioridad inmediata cambiada a crecimiento de contenido pasivo por batches, usando arquitectura existente.

## Slice 13 — Item ecosystem batch 1

### Tarea objetivo
Agregar 8-15 ítems pasivos nuevos reutilizando efectos existentes y composición data-driven.

### Archivos afectados
- [items/data/](items/data/)

### Resultado obtenido
- Se agregaron 10 ítems pasivos nuevos:
	- `adrenal_shot`
	- `drift_shoes`
	- `iron_lung`
	- `marrow_needle`
	- `overclock_cell`
	- `prism_cap`
	- `turbine_core`
	- `lucky_barrel`
	- `blood_transfusion`
	- `glass_cannon`
- Todos son data-driven y reutilizan `EffectData` existentes sin condicionales por ítem.
- Integración validada estructuralmente: pool por `.tres`, stack aditivo por `StatEvaluationSystem`, actualización de UI por lectura de `player_stats` en `StatsUI`.

## Slice 14 — Item ecosystem batch 2

### Tarea objetivo
Agregar un segundo batch de 8-15 ítems pasivos manteniendo composición de efectos y sin sistemas nuevos.

### Archivos probablemente afectados
- [items/data/](items/data/)

### Resultado esperado
Nuevo incremento de variedad de builds sin cambios de arquitectura base.

### Resultado obtenido
- Se agregaron 10 ítems pasivos nuevos:
	- `phase_anchor`
	- `toxic_tread`
	- `hollow_scope`
	- `recoil_coil`
	- `storm_syringe`
	- `chain_spindle`
	- `echo_heart`
	- `snap_line`
	- `crimson_gear`
	- `orbit_pin`
- Todos reutilizan efectos existentes y mantienen composición data-driven.
- Integración validada estructuralmente: pool por `.tres`, stack en `StatEvaluationSystem`/`AttackEvaluationSystem`, UI por lectura de `player_stats`.

## Slice 15 — Validación humana de contenido y tuning

### Tarea objetivo
Validar calidad de gameplay del ecosistema expandido de ítems antes de continuar con más batches de contenido.

### Archivos probablemente afectados
- [items/data/](items/data/)
- [docs/implementation/AGENT_CONTEXT.md](docs/implementation/AGENT_CONTEXT.md)

### Resultado esperado
Parámetros de ítems ajustados con evidencia de playtest humano y límites claros para siguientes batches.

### Estado actual
- Sigue pendiente de ejecución humana.
- Se avanzó primero con batches mecánicos para aumentar diversidad real de builds usando la arquitectura ya establecida.

## Slice 16 — Mechanic batch A (Homing)

### Tarea objetivo
Introducir exactamente un nuevo efecto reusable de ataque para tracking de proyectiles y crear 4-8 ítems pasivos compuestos alrededor de ese efecto.

### Archivos afectados
- [items/effects/homing_projectiles_effect.gd](items/effects/homing_projectiles_effect.gd)
- [attacks/attack_data.gd](attacks/attack_data.gd)
- [attacks/bullet.gd](attacks/bullet.gd)
- [items/data/](items/data/)

### Resultado obtenido
- Se agregó `HomingProjectilesEffect` como `AttackEffectData` reusable.
- `AttackData` ahora incluye `homing_strength` y `homing_radius`.
- `Bullet` aplica steering al objetivo enemigo más cercano dentro de radio.
- Se agregaron 5 ítems del batch: `seeker_eye`, `magnet_tear`, `neural_compass`, `hunter_thread`, `lockon_implant`.
- Integración validada estructuralmente sin condicionales por ítem.

## Slice 17 — Mechanic batch B (Split shots)

### Tarea objetivo
Introducir exactamente un nuevo efecto reusable de ataque para abanico de disparos y crear 4-8 ítems pasivos compuestos alrededor de ese efecto.

### Archivos afectados
- [items/effects/split_shots_effect.gd](items/effects/split_shots_effect.gd)
- [attacks/attack_data.gd](attacks/attack_data.gd)
- [player/systems/projectile_system.gd](player/systems/projectile_system.gd)
- [items/data/](items/data/)

### Resultado obtenido
- Se agregó `SplitShotsEffect` como `AttackEffectData` reusable.
- `AttackData` ahora incluye `split_count` y `split_spread_degrees`.
- `ProjectileSystem` genera múltiples direcciones por disparo y clona `AttackData` por proyectil materializado.
- Se agregaron 5 ítems del batch: `forked_chamber`, `tri_spine`, `scatter_core`, `twin_fang`, `prism_fork`.
- Integración validada estructuralmente sin sistemas ad hoc.

## Slice 18 — Mechanic batch C (Spectral)

### Tarea objetivo
Introducir exactamente un nuevo efecto reusable de ataque para disparos espectrales y crear 4-8 ítems pasivos compuestos alrededor de ese efecto.

### Archivos afectados
- [items/effects/spectral_projectiles_effect.gd](items/effects/spectral_projectiles_effect.gd)
- [attacks/attack_data.gd](attacks/attack_data.gd)
- [attacks/bullet.gd](attacks/bullet.gd)
- [items/data/](items/data/)

### Resultado obtenido
- Se agregó `SpectralProjectilesEffect` como `AttackEffectData` reusable.
- `AttackData` ahora incluye `spectral`.
- `Bullet` ignora colisiones de cuerpo con obstáculos cuando el tiro es spectral.
- Se agregaron 5 ítems del batch: `ghost_lens`, `phase_plasma`, `wraith_shell`, `void_iris`, `eclipse_filament`.
- Integración validada estructuralmente: recursos cargables, stack aditivo, sin condicionales por ítem.

## Slice 19 — Validación humana de interacciones mecánicas

### Tarea objetivo
Validar legibilidad, dificultad y balance de combinaciones entre mecánicas de proyectil (pierce, bounce, homing, split, spectral y beam).

### Archivos probablemente afectados
- [items/data/](items/data/)
- [docs/implementation/AGENT_CONTEXT.md](docs/implementation/AGENT_CONTEXT.md)

### Resultado esperado
- Registro de hallazgos de playtest con ajustes de parámetros en ítems outlier.
- Definición de límites para continuar batches automáticos sin degradar claridad de gameplay.

## Slice 20 — Preparación de playtest matrix completa

### Tarea objetivo
Consolidar una matriz completa de validación para todas las mecánicas implementadas y todas sus combinaciones por pares antes de nuevas implementaciones.

### Archivos afectados
- [docs/implementation/PLAYTEST_MATRIX.md](docs/implementation/PLAYTEST_MATRIX.md)
- [docs/implementation/AGENT_CONTEXT.md](docs/implementation/AGENT_CONTEXT.md)

### Resultado obtenido
- Matriz completa creada en `PLAYTEST_MATRIX.md` con:
	- auditoría individual de 12 mecánicas,
	- 66 combinaciones por pares,
	- comportamiento esperado, fallos potenciales, riesgos de balance, legibilidad visual y riesgos de performance,
	- lista priorizada de combinaciones que requieren validación humana.

## Slice 21 — Ejecución de playtests Prioridad A (integridad de run)

### Tarea objetivo
Ejecutar los escenarios críticos que pueden invalidar runs (bugs de combinación, loops, picos de performance, progresión rota).

### Archivos probablemente afectados
- [docs/implementation/PLAYTEST_MATRIX.md](docs/implementation/PLAYTEST_MATRIX.md)
- [docs/implementation/AGENT_CONTEXT.md](docs/implementation/AGENT_CONTEXT.md)
- [items/data/](items/data/)

### Resultado esperado
- Evidencia de ejecución de casos Priority A.
- Lista cerrada de bugs críticos corregidos o confirmados como no reproducibles.

## Slice 22 — Ejecución de playtests Prioridad B/C y tuning numérico

### Tarea objetivo
Validar legibilidad y comportamiento emergente de combinaciones no críticas, y recién después ajustar balance numérico.

### Archivos probablemente afectados
- [docs/implementation/PLAYTEST_MATRIX.md](docs/implementation/PLAYTEST_MATRIX.md)
- [docs/implementation/AGENT_CONTEXT.md](docs/implementation/AGENT_CONTEXT.md)
- [items/data/](items/data/)

### Resultado esperado
- Registro de hallazgos no críticos y decisiones de tuning.
- Criterio documentado para retomar implementación de nuevas mecánicas sin perder claridad de gameplay.

## Slice 23 — Mechanic batch D (Critical hits)

### Tarea objetivo
Introducir un efecto reusable de críticos para proyectiles y beam, y crear 5 ítems con perfiles de riesgo/consistencia distintos.

### Archivos afectados
- [items/effects/critical_hits_effect.gd](items/effects/critical_hits_effect.gd)
- [attacks/attack_data.gd](attacks/attack_data.gd)
- [attacks/bullet.gd](attacks/bullet.gd)
- [attacks/beam_segment.gd](attacks/beam_segment.gd)
- [player/systems/projectile_system.gd](player/systems/projectile_system.gd)
- [items/data/](items/data/)

### Resultado obtenido
- Se agregó `CriticalHitsEffect` como `AttackEffectData` reusable.
- `AttackData` ahora incluye `crit_chance` y `crit_multiplier`.
- Crítico resuelto por proyectil/segmento (tears y beam), preservando infección = daño 0.
- Se agregaron 5 ítems del batch: `deadeye_chip`, `lucky_fang`, `shatterpoint`, `boom_or_bust`, `executioner_lens`.

## Slice 24 — Mechanic batch E (Knockback modifiers)

### Tarea objetivo
Introducir un efecto reusable para modificar knockback por payload de ataque y crear 5 ítems con estilos de control distintos.

### Archivos afectados
- [items/effects/knockback_modifier_effect.gd](items/effects/knockback_modifier_effect.gd)
- [attacks/attack_data.gd](attacks/attack_data.gd)
- [attacks/bullet.gd](attacks/bullet.gd)
- [attacks/beam_segment.gd](attacks/beam_segment.gd)
- [player/systems/projectile_system.gd](player/systems/projectile_system.gd)
- [items/data/](items/data/)

### Resultado obtenido
- Se agregó `KnockbackModifierEffect` como `AttackEffectData` reusable.
- `AttackData` ahora incluye `knockback_multiplier` y `knockback_flat_bonus`.
- Knockback aplicado en tears y beam; propagación validada en clone path de `ProjectileSystem`.
- Se agregaron 5 ítems del batch: `impact_driver`, `pinball_gland`, `riot_pulse`, `vacuum_rounds`, `hurricane_nail`.

## Slice 25 — Mechanic batch F (Kill-triggered economy)

### Tarea objetivo
Introducir un efecto reactivo reusable de economía por kills y crear 5 ítems centrados en estilos de progresión/riesgo.

### Archivos afectados
- [items/effects/gain_drops_on_kill_effect.gd](items/effects/gain_drops_on_kill_effect.gd)
- [items/effects/gain_drops_on_kill_runtime.gd](items/effects/gain_drops_on_kill_runtime.gd)
- [items/data/](items/data/)

### Resultado obtenido
- Se agregó `GainDropsOnKillEffect` + runtime reactivo por señal `enemy_killed`.
- Soporta bonus adicional cuando el enemigo muerto estaba infectado.
- Se agregaron 5 ítems del batch: `blood_dividend`, `green_bounty`, `loan_shark_tooth`, `thrift_crown`, `fever_market`.

## Slice 26 — Mechanic batch G (Explosions)

### Tarea objetivo
Introducir una mecánica reusable de explosiones sobre impacto/muerte proyectil sin condicionales por ítem, con 5-10 ítems composables.

### Archivos probablemente afectados
- [attacks/attack_data.gd](attacks/attack_data.gd)
- [attacks/bullet.gd](attacks/bullet.gd)
- [player/systems/projectile_system.gd](player/systems/projectile_system.gd)
- [items/effects/](items/effects/)
- [items/data/](items/data/)

### Resultado esperado
- Un nuevo `AttackEffectData` reusable de explosión.
- Integración compatible con split/homing/spectral/beam según corresponda sin lógica por ID.
- 5-10 ítems nuevos con perfiles de riesgo y sinergias emergentes.

### Resultado obtenido
- Se agregó `ExplosiveProjectilesEffect` como `AttackEffectData` reusable.
- `AttackData` ahora incluye `explosion_radius`, `explosion_damage_multiplier`, `explosion_inherits_infection`.
- Explosiones por impacto integradas en tears y beam segments, con propagación validada en clone path de `ProjectileSystem`.
- Se agregaron 5 ítems del batch: `blast_cap`, `cluster_weld`, `seeker_mine`, `septic_mortar`, `hazard_fuse`.

## Slice 27 — Mechanic batch H (Poison)

### Tarea objetivo
Introducir una mecánica reusable de veneno (daño en el tiempo/debuff) data-driven y crear 5-10 ítems composables.

### Archivos probablemente afectados
- [attacks/attack_data.gd](attacks/attack_data.gd)
- [system/hitbox.gd](system/hitbox.gd)
- [enemies/enemy_base.gd](enemies/enemy_base.gd)
- [items/effects/](items/effects/)
- [items/data/](items/data/)

### Resultado esperado
- Un nuevo efecto reusable de veneno sin condicionales por ítem.
- Integración compatible con split/pierce/homing/infection mediante composición de payload.
- 5-10 ítems nuevos con perfiles de riesgo y sinergias emergentes.

### Resultado obtenido
- Se implementó framework de status payloads compartido (`StatusPayload`, transporte por `Hitbox`, clonación en `AttackData`/`ProjectileSystem`, runtime en `EnemyBase`).
- Se agregó `PoisonStatusEffect` como `AttackEffectData` reusable de DoT con duración, tick interval, stacks y regla de stack.
- Se agregaron 5 ítems del batch: `venom_sac`, `septic_needle`, `miasma_fan`, `tracker_toxin`, `black_bile`.

## Slice 28 — Mechanic batch I (Burn)

### Tarea objetivo
Introducir efecto reusable de burn sobre el framework de status y crear 5-10 ítems composables.

### Archivos afectados
- [items/effects/burn_status_effect.gd](items/effects/burn_status_effect.gd)
- [items/data/](items/data/)

### Resultado obtenido
- Se agregó `BurnStatusEffect` como `AttackEffectData` reusable de DoT.
- Se agregaron 5 ítems del batch: `ember_core`, `cinder_coil`, `blast_furnace`, `wildfire_gland`, `scorched_lung`.

## Slice 29 — Mechanic batch J (Freeze)

### Tarea objetivo
Introducir efecto reusable de freeze sobre el framework de status y crear 5-10 ítems composables.

### Archivos afectados
- [items/effects/freeze_status_effect.gd](items/effects/freeze_status_effect.gd)
- [items/data/](items/data/)

### Resultado obtenido
- Se agregó `FreezeStatusEffect` como `AttackEffectData` reusable con multiplicador de velocidad 0..1.
- Se agregaron 5 ítems del batch: `frost_tip`, `glacier_shard`, `rime_mine`, `winter_scope`, `brittle_heart`.

## Slice 30 — Mechanic batch K (Slow)

### Tarea objetivo
Introducir efecto reusable de slow sobre el framework de status y crear 5-10 ítems composables.

### Archivos afectados
- [items/effects/slow_status_effect.gd](items/effects/slow_status_effect.gd)
- [items/data/](items/data/)

### Resultado obtenido
- Se agregó `SlowStatusEffect` como `AttackEffectData` reusable con duración y stack rules.
- Se agregaron 5 ítems del batch: `tar_lens`, `molasses_beam`, `drag_net`, `heavy_snow`, `time_tax`.

## Slice 31 — Mechanic batch L (Fear)

### Tarea objetivo
Introducir efecto reusable de fear sobre el framework de status y crear 5-10 ítems composables.

### Archivos afectados
- [items/effects/fear_status_effect.gd](items/effects/fear_status_effect.gd)
- [enemies/enemy_base.gd](enemies/enemy_base.gd)
- [items/data/](items/data/)

### Resultado obtenido
- Se agregó `FearStatusEffect` como `AttackEffectData` reusable y se integró reacción de movimiento en `EnemyBase` (inversión de intención de chase/charge).
- Se agregaron 5 ítems del batch: `panic_spores`, `coward_hook`, `dread_compass`, `nightmare_fork`, `horror_dividend`.

## Slice 32 — Mechanic batch M (Orbitals and Passive Companions)

### Tarea objetivo
Implementar un sistema reusable de orbitals y companions pasivos (followers) sin condicionales por ítem, con configuración data-driven por efecto.

### Archivos afectados
- [player/systems/companion_system.gd](player/systems/companion_system.gd)
- [companions/orbital_companion.gd](companions/orbital_companion.gd)
- [companions/orbital_companion.tscn](companions/orbital_companion.tscn)
- [companions/passive_follower.gd](companions/passive_follower.gd)
- [companions/passive_follower.tscn](companions/passive_follower.tscn)
- [items/effects/companion_formation_effect.gd](items/effects/companion_formation_effect.gd)
- [items/effects/companion_formation_runtime.gd](items/effects/companion_formation_runtime.gd)
- [player/player.gd](player/player.gd)
- [items/data/](items/data/)

### Resultado obtenido
- Se agregó `CompanionSystem` para gestionar ciclo de vida de companions por fuente runtime (spawn/clear por source key).
- Se implementaron dos entidades reutilizables: `OrbitalCompanion` y `PassiveFollower`, ambas con daño de contacto y cooldown por enemigo.
- Se agregó `CompanionFormationEffect` + `CompanionFormationRuntime` para configurar composiciones de orbitals/followers por datos.
- Se agregaron 10 ítems del batch: `guardian_halo`, `twin_satellites`, `razor_ring`, `squire_pod`, `pair_protocol`, `shepherd_orbit`, `swarm_axis`, `wide_guard`, `blood_kites`, `bulwark_hive`.

## Slice 33 — Mechanic batches N-S (Advanced Weapon Archetypes)

### Tarea objetivo
Implementar familias de comportamiento de arma reutilizables (inspiradas en Knife, Ring, Remote Orb, Orbit, Lob Burst y Elastic Ricochet) sin condicionales por ítem, usando el pipeline genérico de `AttackData` + `ProjectileSystem`.

### Archivos afectados
- [attacks/attack_data.gd](attacks/attack_data.gd)
- [attacks/bullet.gd](attacks/bullet.gd)
- [attacks/returning_blade.gd](attacks/returning_blade.gd)
- [attacks/returning_blade.tscn](attacks/returning_blade.tscn)
- [attacks/expanding_ring.gd](attacks/expanding_ring.gd)
- [attacks/expanding_ring.tscn](attacks/expanding_ring.tscn)
- [attacks/remote_orb.gd](attacks/remote_orb.gd)
- [attacks/remote_orb.tscn](attacks/remote_orb.tscn)
- [attacks/orbit_shot.gd](attacks/orbit_shot.gd)
- [attacks/orbit_shot.tscn](attacks/orbit_shot.tscn)
- [attacks/lob_burst_projectile.gd](attacks/lob_burst_projectile.gd)
- [attacks/lob_burst_projectile.tscn](attacks/lob_burst_projectile.tscn)
- [player/systems/projectile_system.gd](player/systems/projectile_system.gd)
- [items/effects/set_weapon_type_effect.gd](items/effects/set_weapon_type_effect.gd)
- [items/data/](items/data/)

### Resultado obtenido
- Se agregaron 6 arquetipos de arma reutilizables en `ProjectileSystem`: `returning_blade`, `expanding_ring`, `remote_orb`, `orbit_shot`, `lob_burst`, `elastic_ricochet`.
- Se incorporaron parámetros genéricos de arquetipo en `AttackData` y en `SetWeaponTypeEffect` para habilitar configuración data-driven por ítem.
- Se agregaron 30 ítems (5 por familia):
	- Returning blade: `iron_dagger`, `blood_scythe`, `serrated_arc`, `recall_fang`, `butcher_pin`.
	- Expanding ring: `ion_loop`, `corona_drive`, `hollow_torus`, `plasma_halo`, `overcharge_ring`.
	- Remote orb: `neural_orb`, `pilot_core`, `guided_nucleus`, `drift_brain`, `orbit_director`.
	- Orbit shot: `star_sling`, `satellite_vein`, `micro_planetarium`, `gravity_yoyo`, `heliocore`.
	- Lob burst: `clot_catapult`, `marrow_mortar`, `gland_grenade`, `hemorrhage_seed`, `rupture_pod`.
	- Elastic ricochet: `rubber_cortex`, `ping_pulse`, `wall_waltz`, `ricochet_organ`, `spring_tear`.

## Slice 34 — Isaac passive coverage matrix (design-space lock)

### Tarea objetivo
Consolidar una matriz completa de cobertura interna para pasivos de Isaac (Rebirth + AB + AB+ + Repentance), clasificada por mecánica reusable y no por ítem.

### Archivos afectados
- [docs/implementation/ISAAC_PASSIVE_MECHANIC_COVERAGE_MATRIX.md](docs/implementation/ISAAC_PASSIVE_MECHANIC_COVERAGE_MATRIX.md)

### Resultado obtenido
- Se creó una matriz canónica de 100 familias mecánicas (`M001..M100`) con:
	- dimensión primaria/secundaria,
	- expansión mínima,
	- estado de cobertura en Infect.
- Se documentaron explícitamente las 16 dimensiones requeridas:
	- gameplay, weapon, projectile, status, economy, companion, trigger, stat, aura, spawn, death, room, shop, curse, luck y special mechanics.
- Se cambió el punto de entrada de implementación: de batches por contenido a batches por infraestructura reusable.

## Slice 35 — Infrastructure batch U (room/shop/curse/luck hook layer)

### Tarea objetivo
Crear la capa base reusable de hooks para efectos de sala/tienda/maldición/suerte sin condicionales por ítem.

### Archivos probablemente afectados
- [system/event_bus.gd](system/event_bus.gd)
- [player/](player/)
- [world/](world/)
- [items/effects/](items/effects/)

### Resultado esperado
- Señales y puntos de integración para:
	- enter/clear/leave room,
	- curse detect/remove/suppress,
	- shop open/purchase/restock,
	- luck-aware proc evaluation.
- Sin agregar ítems todavía.

### Resultado obtenido (avance inicial)
- `EventBus` extendido con hooks nuevos: `room_exited`, `shop_opened`, `shop_purchase`, `shop_restocked`, `curse_changed`.
- Se agregó helper reusable `evaluate_luck_proc(base_chance, luck, luck_to_full, max_chance)`.
- Se integró emisión de `room_exited` en `Room.deactivate()`.
- `GachaponMachine` ahora emite:
	- `shop_opened` al entrar el jugador,
	- `shop_purchase` al comprar,
	- `shop_restocked` al cargar pool.
- Todos los cambios sin authoring de nuevos ítems.

## Slice 36 — Infrastructure batch V (extended status families)

### Tarea objetivo
Extender el framework de status payload para cubrir Charm, Confusion, Bleed, Bait y Chained en forma reusable.

### Archivos probablemente afectados
- [system/](system/)
- [enemies/](enemies/)
- [items/effects/](items/effects/)
- [attacks/attack_data.gd](attacks/attack_data.gd)

### Resultado esperado
- Nuevos status types integrados al pipeline actual con reglas de stack y duración.
- Compatibilidad con split/pierce/homing/beam/arquetipos avanzados.
- Sin agregar ítems todavía.

## Slice 37 — Infrastructure batch W (economy/shop/pool modifiers)

### Tarea objetivo
Introducir efectos reusables para precios, descuentos, stock, restock y modificación de selección de pool/calidad.

### Archivos probablemente afectados
- [world/](world/)
- [items/effects/](items/effects/)
- [player/systems/](player/systems/)

### Resultado esperado
- Framework de modificadores de economía y tienda composable por efecto.
- Soporte para futuros efectos de pool bias y quality bias.
- Sin agregar ítems todavía.

## Slice 38 — Infrastructure batch X (death/spawn chains)

### Tarea objetivo
Crear infraestructura reusable para cadenas de muerte y generación secundaria (on kill / on death / on hit / room-entry pulses).

### Archivos probablemente afectados
- [system/event_bus.gd](system/event_bus.gd)
- [items/effects/](items/effects/)
- [enemies/](enemies/)
- [world/](world/)

### Resultado esperado
- Runtime genérico para mecánicas tipo contagio, death nova, kill-spawn, room pulse.
- Integración compatible con sistema de drops existente.
- Sin agregar ítems todavía.

## Validación del backlog

Cada slice debe dejar el proyecto jugable. La validación debe hacerse manualmente en la escena principal:
- mover al jugador;
- disparar;
- infectar un enemigo;
- recoger el primer item;
- confirmar que el efecto se observa en el gameplay;
- limpiar la room sin romper el flujo.

## Reglas de evolución

- Este documento se actualizará con cada slice completado.
- No se debe convertir en un plan de arquitectura completa.
- Debe servir como hoja operativa para empezar a implementar inmediatamente.
