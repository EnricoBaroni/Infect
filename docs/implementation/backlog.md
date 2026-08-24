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

### Resultado obtenido
- Se agregó `CharmStatusEffect` (invierte dirección de chase) — ya manejado en `enemy_base.gd`.
- Se agregó `ConfusionStatusEffect` (rota direcciones aleatoriamente) — ya manejado en `enemy_base.gd`.
- Se agregó `BleedStatusEffect` (DoT stackeable) — ya manejado en `enemy_base.gd` tick loop.
- Se agregó `BaitStatusEffect` — marca enemigos como objetivo prioritario para homing; `bullet.gd` prefiere enemigos baitados.
- Se agregó `ChainedStatusEffect` — rooting vía multiplicador de velocidad en `_get_effective_speed()`.
- Se agregaron 5 ítems de bait: `lure_hook`, `marked_target`, `scatter_mark`, `sniper_bait`, `bounty_bait`.
- Se agregaron 5 ítems de chained: `iron_shackle`, `binding_wire`, `frost_chain`, `chain_bomb`, `leash_gland`.

## Slice 37 — Infrastructure batch W (stat economy)

### Tarea objetivo
Introducir multiplicadores de stats, rampas de stats por kills/daño y buffs temporales.

### Resultado obtenido
- Se agregó `StatMultiplierEffect` (M002): multiplicadores composables por stat.
- Se agregó `StatRampOnKillEffect` + `StatRampOnKillRuntime` (M006): acumulación de bonus por kills via hook post-recalculate.
- Se agregó `StatRampOnDamageEffect` + `StatRampOnDamageRuntime` (M005): acumulación por daño recibido.
- Se agregó `TempStatBuffOnKillEffect` + `TempStatBuffOnKillRuntime` (M004): buffs temporales con duración por kills.
- Se extendió `StatEvaluationSystem` con `register_post_recalculate_applier()` y señal `stats_recalculated` para que los runtimes de ramp puedan re-aplicar su bonus después de cada recalculate sin violar el contrato de stats inmutables.
- Se agregaron 10 nuevos ítems: `catalyst_vial`, `speed_amplifier`, `viral_surge`, `host_tissue`, `predator_gland`, `plague_feast`, `adrenaline_surge`, `bloody_lust`, `berserker_gland`, `infected_rush`, `frenzy_organ`.

## Slice 38 — Mechanic batch T (directional shot appenders)

### Estado
**COMPLETE** — Infrastructure and all 4 items implemented (2026-08-19). Gameplay validation pending.

### Tarea objetivo
Implementar disparos en ángulos fijos adicionales (atrás, lateral) como `AttackEffectData` reusable.

### Archivos afectados
- [attacks/attack_data.gd](attacks/attack_data.gd) — added `appended_shot_offsets: Array[float]`, updated `copy()`
- [player/systems/projectile_system.gd](player/systems/projectile_system.gd) — appended shot spawning in `_spawn_tear_projectile`
- [items/effects/directional_shot_appender_effect.gd](items/effects/directional_shot_appender_effect.gd) — new `AttackEffectData` subclass
- [items/data/backward_shot.tres](items/data/backward_shot.tres) — new item
- [items/data/side_shots.tres](items/data/side_shots.tres) — new item
- [items/data/cross_shot.tres](items/data/cross_shot.tres) — new item
- [items/data/diagonal_shot.tres](items/data/diagonal_shot.tres) — new item

### Resultado obtenido
- `DirectionalShotAppenderEffect`: appends angle offsets to `AttackData.appended_shot_offsets`; items configure `angle_offsets_degrees: Array[float]`
- `ProjectileSystem` spawns appended shots after primary shots; each appended group passes through `_build_attack_directions()` so split composes correctly
- Recursive appending prevented: offsets cleared on the clone before spawning
- Currently supported weapon types: tear only (intentional first slice)
- 4 items: `backward_shot` (180°), `side_shots` (±90°), `cross_shot` (±90°, 180°), `diagonal_shot` (±45°, ±135°)

### Pendiente
- Gameplay validation (see PLAYTEST_MATRIX.md §6)
- Opt-in support for returning_blade, orbit_shot, lob_burst, elastic_ricochet spawners (after gameplay testing confirms it is wanted)

## Slice 39 — Mechanic batch U (burst cadence)

### Estado
**COMPLETE** — Infrastructure and test item implemented (2026-08-19). Gameplay validation pending.

### Tarea objetivo
Implementar un efecto de cadencia (cada N disparos activa un disparo especial).

### Archivos afectados
- [attacks/attack_data.gd](attacks/attack_data.gd) — added `cadence_interval`, `cadence_shot_split_bonus`, `cadence_shot_damage_multiplier`, `cadence_shot_explosion_radius`; updated `copy()`
- [player/systems/weapon_system.gd](player/systems/weapon_system.gd) — added `_cadence_shot_count`, `_process_cadence()`, `_fire_cadence_shot()`
- [items/effects/cadence_shot_effect.gd](items/effects/cadence_shot_effect.gd) — new `AttackEffectData` subclass
- [items/data/viral_pulse.tres](items/data/viral_pulse.tres) — new test item

### Resultado obtenido
- `CadenceShotEffect` writes cadence configuration to `AttackData`
- `WeaponSystem` maintains `_cadence_shot_count`; fires bonus cadence shot via `projectile_system.spawn_projectile()` (not via `_emit_attack` — no recursion)
- Cadence shot is additive (Nth normal shot fires + special shot fires alongside)
- Cadence shot inherits full evaluated `AttackData` (all item effects applied)
- 1 test item: `viral_pulse` (every 3 shots: ×2 damage + 32px explosion)

### Pendiente
- Gameplay validation (see PLAYTEST_MATRIX.md §7)
- More cadence item variants (e.g., every 5 shots: +split, or every 4 shots: spectral burst)

## Slice 40 — Pre-Playtest Stabilization & Tooling *(Completado agosto 2026)*

### Tarea objetivo
Estabilización estructural y herramientas de desarrollo durante ventana sin playtest manual.

### Resultado obtenido

**Door Blocker Fix:**
- `door.tscn`: agregado `BlockerBody` (`StaticBody2D`, `collision_layer=1`, `collision_mask=0`) con el `CollisionPolygon2D` existente como hijo. Puertas cerradas ahora son obstáculos físicos reales.
- `door.gd`: renombrado `Area2D` → `TransitionArea`, agregado `blocker_shape` y sincronización en `open()`/`close()`/`_ready()`.

**Debug Menu:**
- `ui/debug_menu.gd` (nuevo): overlay de CanvasLayer activado con F1. Descubre ítems dinámicamente desde `res://items/data/`. Botones de ítem llaman `player.inventory.add_passive_item(item.duplicate())`. Botón `+ 10 Drops`.
- `world/world.tscn`: nodo `DebugMenu` agregado.

**Bug fix confirmado (Category A):**
- `enemy_base.gd`: `_dead` flag agregado en `die()` para prevenir doble disparo de `enemy_killed` y doble spawn de drops por hits diferidos en el mismo frame.

**Audit — Riesgos estructurales documentados (Category B):**
- `EffectRuntimeSystem`: registro con mismo resource reference sobreescribe runtimes anteriores. No se activa con el flujo normal (todos los pickups usan `.duplicate()`).
- `ShopPriceMultiplierRuntime`: división en deactivate puede acumular error de punto flotante.
- Map intel fields en `Global` no tienen consumer todavía. Map-reveal items son no-funcionales visualmente.

**Audit — Economy:**
- No infinite loops. No recursive drops. Shop cost mínimo correcto. Kill signals no se re-emiten por drop pickup.

**PLAYTEST_MATRIX.md:** Sección 5 agregada con 6 grupos de validación derivados del audit.

### Archivos afectados
`world/door.tscn`, `world/door.gd`, `ui/debug_menu.gd` (nuevo), `world/world.tscn`, `enemies/enemy_base.gd`, `docs/implementation/PLAYTEST_MATRIX.md`, `docs/implementation/AGENT_CONTEXT.md`, `docs/implementation/backlog.md`

---

Cada slice debe dejar el proyecto jugable. La validación debe hacerse manualmente en la escena principal:
- mover al jugador;
- disparar;
- infectar un enemigo;
- recoger el primer item;
- confirmar que el efecto se observa en el gameplay;
- limpiar la room sin romper el flujo.

---

## Slice 41 — Enemy Spawn Tier Classification *(Implemented 2026-08-19 — Not Gameplay Validated)*

### Tarea objetivo
Add data-driven spawn tier and weight metadata to all existing enemy scenes so future room generation can select enemies by floor/difficulty tier without hardcoding enemy names.

### Research basis
Isaac Rebirth wiki (bindingofisaacrebirth.fandom.com) confirmed floor appearances for 8 of 10 enemies. 2 enemies (NerdEnemy, RapperEnemy) have no direct Isaac equivalent; their tiers are design decisions.

See [docs/implementation/ENEMY_SPAWN_PROGRESSION.md](ENEMY_SPAWN_PROGRESSION.md) for full classification rationale, Isaac source data, confidence levels, and open design decisions.

### Implementation
Added to each enemy `.gd` file after `speed_multiplier`:
```gdscript
@export var spawn_tier_min: int = N   # Floor tier must be >= this for enemy to be eligible
@export var spawn_tier_max: int = N   # Floor tier must be <= this (0 = no upper limit)
@export var spawn_weight: int = N     # Relative probability when eligible
```

### Final tier assignments
| Enemy | spawn_tier_min | spawn_tier_max | spawn_weight |
|-------|---------------|----------------|-------------|
| BatEnemy | 1 | 0 | 10 |
| BullyEnemy | 1 | 3 | 8 |
| MulliganEnemy | 1 | 3 | 7 |
| PooterEnemy | 1 | 4 | 8 |
| ChargerEnemy | 2 | 0 | 7 |
| GlobinEnemy | 2 | 0 | 6 |
| HopperEnemy | 2 | 4 | 6 |
| NerdEnemy | 2 | 0 | 6 |
| HostEnemy | 2 | 0 | 5 |
| RapperEnemy | 3 | 0 | 4 |

### Correcciones respecto a valores provisionales anteriores
- MulliganEnemy: era tier 2, ahora tier 1 (Mulligan is a Chapter 1 enemy in Isaac)
- GlobinEnemy: era "1–2", ahora tier 2 (Globin is Caves+ in Isaac)
- PooterEnemy: era "2–3", ahora tier 1–4 (Pooter appears from Basement in Isaac)
- HopperEnemy: clasificado contra Leaper (Caves+), no contra Hopper (Basement+)

### Archivos afectados
All 10 enemy `.gd` files: bat_enemy, bully_enemy, charger_enemy, globin_enemy, hopper_enemy, host_enemy, mulligan_enemy, nerd_enemy, pooter_enemy, rapper_enemy.

### Pendiente
- Gameplay validation: actual tier assignment may need tuning after playtest
- All spawn_weight values are provisional design assumptions

### Integration status (post Slice 44)
- Tier metadata is now consumed in runtime by `world/enemy_spawn_selector.gd` + `Room.respawn_enemies()` for non-boss combat rooms.
- Source tier is `Global.floor_number` via `WorldDungeon.get_current_spawn_tier()`.

---

## Slice 42 — Item Pool Classification *(Implemented 2026-08-19 — Not Gameplay Validated)*

### Tarea objetivo
Establish two named item pools — NORMAL_GACHA and INFECTION_GACHA — so each gacha machine draws from its own subset of items.

### Implementation — IMPLEMENTED

**GachaPonMachine:**
- Added `@export var pool_tag: String = "gacha"` export
- `_refresh_passive_item_pool()` now filters: `if item.pool_tags.has(pool_tag)`
- To create Infection Gacha Machine: set `pool_tag = "infection_gacha"` in the inspector
- F1 debug menu unchanged — bypasses pool system by design

**Item pool_tags updated:**
- `"gacha"` → added to 293 items (all general combat/build items)
- `"infection_gacha"` → added to 42 items (items synergizing with infection mechanic)
- Old tags (`"treasure"`, `"secret"`, `"shop"`, `"angel"`, `"devil"`) preserved for future use

**Pool composition:**
| Category | gacha | infection_gacha |
|----------|-------|-----------------|
| Total items | 293 | 42 |
| Exclusive (only that pool) | 253 | 2 |
| Shared (in both) | 40 | 40 |

**infection_gacha exclusive items (not in gacha):**
- `infected_rush` (only_infected_kills = true)
- `plague_feast` (only_infected_kills = true)

See full catalog: [docs/implementation/ITEM_POOL_DESIGN.md](ITEM_POOL_DESIGN.md)

### Design Gaps Found
1. Only 2 items are truly exclusive to infection_gacha (pool feels thin)
2. No items reward the ACT of infecting enemies (only reward killing infected enemies)
3. Missing future item concepts documented in ITEM_POOL_DESIGN.md §6B

### Archivos afectados
- `world/gachapon_machine.gd` (pool filtering)
- All 295 `items/data/*.tres` (pool tags)
- `docs/implementation/ITEM_POOL_DESIGN.md` (new)

### Pendiente de playtest
- Verify infection_gacha machine provides enough variety with 42 items
- Verify gacha machine excludes infected_rush/plague_feast correctly
- Verify no item appears in the wrong pool during gameplay
- Assess whether pool size difference (42 vs 293) creates balance issues

---

## Slice 43 — Boss Room + Floor Transition *(Implemented 2026-08-19 — Not Gameplay Validated)*

### Tarea objetivo
Create a boss room with a single boss encounter and a floor transition mechanism that starts the next floor at a higher difficulty tier.

### Resultado obtenido

**Boss room designation (data-driven):**
- `Room` now exposes `room_type` enum (`GACHA`, `COMBAT`, `BOSS`) while preserving `combat_room` compatibility.
- Boss clear is detected by existing room-clear logic (`combat_room` + `has_enemies() == false`) and now triggers `WorldDungeon.notify_boss_room_cleared(self)` when room type is `BOSS`.

**Floor transition object:**
- Added `world/floor_transition.tscn` + `world/floor_transition.gd`.
- Transition is spawned dynamically in the cleared boss room by `WorldDungeon`.
- On player body entry, transition calls `WorldDungeon.advance_to_next_floor()` and self-destroys.

**Floor state wiring:**
- `Global.floor_number` added.
- `WorldDungeon.advance_to_next_floor()` increments `floor_number`, updates `difficulty_level`, respawns enemies, and returns player/camera to the gacha room.

### Archivos afectados
- New: `world/floor_transition.gd`, `world/floor_transition.tscn`
- Modified: `world/room.gd`, `world/world_dungeon.gd`, `system/Global.gd`, `world/world_dungeon.tscn`

### Estado
- Implemented: ✅
- Statically validated: ✅ (no diagnostics in changed scripts/scenes)
- Gameplay validated: ❌ (pending)

---

## Slice 44 — Demo Loop Integration *(Implemented 2026-08-19 — Not Gameplay Validated)*

### Tarea objetivo
Assemble the complete demo loop: Gacha room → combat rooms → boss room → floor transition → floor 2 with higher difficulty.

### Resultado obtenido

**Manual demo loop integrated (no procedural generation):**
- `world/world_dungeon.tscn` now configures:
	- `Room5` as `GACHA`
	- `Room3` as `BOSS`
	- `Room1/Room2/Room4` as combat rooms with `enemy_spawn_count = 2`

**Dual gacha room setup:**
- Added second gacha machine instance in `Room5` with `pool_tag = "infection_gacha"`.
- Existing machine remains normal gacha (`pool_tag = "gacha"`).
- Debug/F1 path remains decoupled from pool filtering.

**Tier-aware enemy selection consumed in runtime (Slice 41 integration):**
- Added `world/enemy_spawn_selector.gd` reusable weighted selector.
- `Room.respawn_enemies()` now uses tier eligibility and `spawn_weight` for non-boss combat rooms.
- `WorldDungeon` auto-discovers enemy scenes from `res://enemies/*_enemy.tscn` and injects this pool into non-boss combat rooms.
- Tier source: `WorldDungeon.get_current_spawn_tier()` from `Global.floor_number`.

### Archivos afectados
- Modified: `world/world_dungeon.tscn`, `world/world_dungeon.gd`, `world/room.gd`
- New: `world/enemy_spawn_selector.gd`

### Estado
- Implemented: ✅
- Statically validated: ✅ (no diagnostics in changed scripts/scenes)
- Gameplay validated: ❌ (pending)

### Pendiente
- Confirm gameplay pacing and progression pressure by floor in live playtest.
- Confirm no accidental soft-lock when a tier has no eligible enemy entries in a room.

---

## Slice 45 — Isolated Linear Template Floor Generator (WorldDungeonRandom) *(Implemented 2026-08-19 — Not Gameplay Validated)*

### Tarea objetivo
Implement an experimental floor generator isolated from the manual `WorldDungeon`, preserving manual fallback and reusing existing room/door/enemy systems.

### Resultado obtenido

**Aislamiento / fallback preserved:**
- New isolated scene + script:
	- `world/world_dungeon_random.tscn`
	- `world/world_dungeon_random.gd`
- Existing manual `world/world_dungeon.tscn` + `world/world_dungeon.gd` kept in place as fallback.

**Linear floor structure implemented:**
- Runtime generation builds:
	- `GACHA -> COMBAT x N -> BOSS`
- After boss clear, `FloorTransition` is spawned and advances to next floor.
- Next floor rebuilds a fresh linear chain and returns player to the new gacha room.

**Template-driven rooms:**
- Added room templates:
	- `world/templates/gacha_room_template.tscn`
	- `world/templates/combat_room_template_01.tscn`
	- `world/templates/boss_room_template.tscn`
- `combat_room_templates: Array[PackedScene]` supports random selection with repetition allowed.

**Spawn points and enemy composition variability:**
- `Room` now supports `SpawnPoints/*` markers for local enemy spawn positions.
- Added simple count variability exports:
	- `enemy_spawn_min_count`
	- `enemy_spawn_max_count`
	- fallback `enemy_spawn_count`

**Enemy tier reuse (no parallel system):**
- Reuses existing `EnemySpawnSelector` + tier metadata (`spawn_tier_min/max`, `spawn_weight`).
- Tier source remains floor-based (`Global.floor_number`).

**Door/transition reuse:**
- Reuses current `Door` and `Room` transition flow.
- `FloorTransition` generalized to call any world object exposing `advance_to_next_floor()`.

### Archivos afectados
- New:
	- `world/world_dungeon_random.gd`
	- `world/world_dungeon_random.tscn`
	- `world/templates/gacha_room_template.tscn`
	- `world/templates/combat_room_template_01.tscn`
	- `world/templates/boss_room_template.tscn`
	- `docs/implementation/ROOM_GENERATION_DESIGN.md`
- Modified:
	- `world/room.gd`
	- `world/floor_transition.gd`
	- `docs/implementation/DUNGEON_GENERATION_DESIGN.md`

### Estado
- Implemented: ✅
- Statically validated: ✅ (no diagnostics in changed scripts/scenes)
- Gameplay validated: ❌ (pending)

### Designer setup required
- Add more combat templates and register them in `combat_room_templates` of `world_dungeon_random.tscn`.
- Define `SpawnPoints` per combat template.
- Configure per-template enemy count ranges.

### Futuro explícitamente NO implementado en este slice
- Random walk
- Room graphs / branching paths
- Secret/shop/treasure/special rooms
- Procedural minimap
- Subject/school/friendship/crafting/academic systems

---

## Slice 46 — Room Template Contract Hardening *(Implemented 2026-08-19 — Not Gameplay Validated)*

### Tarea objetivo
Make the current Room/template architecture explicit and robust for linear generated floors before large-scale room authoring begins.

### Resultado obtenido

**Door semantic contract:**
- `Door` now exposes `connection_role` enum:
	- `NONE`
	- `FORWARD`
	- `BACKWARD`
- Base room convention is now explicit in `room.tscn`:
	- `Door2` = `FORWARD`
	- `Door4` = `BACKWARD`
- `WorldDungeonRandom` now connects generated rooms semantically and no longer depends on `Door2` / `Door4` by name.

**SpawnPoint contract:**
- `room.tscn` now includes base `SpawnPoints` node.
- `Room` now exposes helper methods for spawn-point queries.
- Generated combat templates are expected to place `Marker2D` children under inherited `SpawnPoints`.
- Manual fallback remains compatible through baked enemy position fallback.

**Standard room spacing contract:**
- `WorldDungeonRandom` now documents and codifies current standard room footprint assumptions:
	- room width: `352`
	- room height: `216`
	- generated spacing: `Vector2(352, 0)`
- No size auto-detection added.

### Archivos afectados
- Modified:
	- `world/door.gd`
	- `world/room.gd`
	- `world/room.tscn`
	- `world/templates/combat_room_template_01.tscn`
	- `world/world_dungeon_random.gd`

### Estado
- Implemented: ✅
- Statically validated: ✅ (no diagnostics in changed scripts/scenes)
- Gameplay validated: ❌ (pending)

### Pendiente
- Validate generated templates respect semantic door roles during actual room traversal.
- Validate SpawnPoints-based spawning in gameplay across multiple authored templates.

---

## Slice 47 — Demo Floor Generation Pipeline Completion *(Implemented 2026-08-19 — Not Gameplay Validated)*

### Tarea objetivo
Complete the actual runtime pipeline from floor number to tier-gated, weighted enemy generation for the linear demo generator.

### Resultado obtenido

**Tier metadata is now an actual runtime generation system:**
- `Global.floor_number` drives `get_current_spawn_tier()` in the active world.
- `Room` resolves current tier from its parent world.
- `EnemySpawnSelector` filters candidates by:
	- `spawn_tier_min`
	- `spawn_tier_max`
- Remaining eligible enemies are selected by `spawn_weight`.

**Weighted selection semantics:**
- Selection is with replacement.
- Same enemy can appear multiple times in the same room.
- Early enemies remain available on later floors if metadata permits.

**Shared RNG ownership:**
- `WorldDungeonRandom` owns the generation RNG.
- `Room` consumes parent `get_generation_rng()` for:
	- enemy count rolls
	- weighted enemy selection
- `WorldDungeon` also exposes `get_generation_rng()` for consistency in the shared Room code path.

**Zero-eligible handling:**
- If a room has an enemy pool but zero tier-eligible enemies, `Room` now emits a warning and does not silently fall back to baked out-of-tier enemies.
- Manual/baked fallback remains active only when `enemy_pool` is empty.

### Archivos afectados
- Modified:
	- `world/room.gd`
	- `world/world_dungeon.gd`
	- `world/world_dungeon_random.gd`

### Estado
- Implemented: ✅
- Statically validated: ✅ (no diagnostics in changed scripts)
- Gameplay validated: ❌ (pending)

### Pendiente
- Validate actual encounter feel and spawn diversity in gameplay.
- Validate warning-only zero-eligible behavior does not create unwanted progression skips in practice.

---

## Slice 48 — Player Death + DeathScreen + Run Restart *(Implemented 2026-08-19 — Not Gameplay Validated)*

### Tarea objetivo
Replace the permanent softlock in `player.die()` with a proper death intermediate state and a minimal Death Screen that allows clean run restarts.

### Design
- **Death sequence:** `stats.no_health` → `player.die()` → emits `EventBus.player_died` → `DeathScreen._on_player_died()` → `Global.is_dead = true` → screen shown → `get_tree().paused = true`.
- **Restart sequence:** RESTART button pressed → `get_tree().paused = false` → `Global.reset_run_state()` → `get_tree().reload_current_scene()`.
- **Freeze mechanism:** reuses `get_tree().paused` (same as normal pause). `DeathScreen` has `process_mode = ALWAYS` to remain interactive while paused.
- **Pauser guard:** `ui/pauser.gd` checks `Global.is_dead` and ignores ESC input during death, preventing accidental unpause from the normal pause toggle.
- **Scene reload resets inventory:** Player and all child systems are destroyed and reconstructed by scene reload. No explicit inventory clearing needed.

### Extension points for future Isaac-like death summary
- `_last_death_payload` dict in `DeathScreen` stores the full payload from `EventBus.player_died`.
- `player.die()` can add fields to the payload (killer entity, items collected, floor reached) without changing the screen's restart flow.
- New Label nodes for floor/build/killer summary can be added to `death_screen.tscn` and populated in `_on_player_died()` without structural changes.

### Archivos afectados
- New: `ui/death_screen.gd`, `ui/death_screen.tscn`
- Modified: `system/Global.gd` (`is_dead` flag, `reset_run_state()`)
- Modified: `system/event_bus.gd` (`player_died` signal, `emit_player_died()`)
- Modified: `player/player.gd` (`die()` emits signal instead of disabling process_mode)
- Modified: `ui/pauser.gd` (ESC blocked when `Global.is_dead`)
- Modified: `world/world_dungeon.tscn` (DeathScreen instance added)
- Modified: `world/world_dungeon_random.tscn` (DeathScreen instance added)

### Estado
- Implemented: ✅
- Statically validated: ✅
- Gameplay validated: ❌ (pending — see PLAYTEST_MATRIX.md §8)

---

## FUTURE: Procedural Dungeon Generation *(Deferred — Not for Current Demo)*

See [docs/implementation/DUNGEON_GENERATION_DESIGN.md](DUNGEON_GENERATION_DESIGN.md) for the complete specification.

Summary of planned phases:
- **Phase 1:** Single-floor grid-based room graph generation (8–12 rooms, 100 lines of GDScript)
- **Phase 2:** Multiple floors + floor progression
- **Phase 3:** Room persistence (cleared rooms don't respawn enemies)
- **Phase 4:** Boss rooms, reward rooms, difficulty scaling
- **Phase 5:** Determinism + debug tools

**Do NOT begin any of these phases until the core demo loop (Slices 41–44) is gameplay-validated.**

---

## FUTURE: School Theme + Subject System *(Long-Term Roadmap)*

These are documented design intentions, not current implementation requirements.

### School Theme
- Game setting: school environment (initial floor = primary school)
- Enemy archetypes: school-personality types (bully, nerd, etc. — already present in current roster)
- Future progression: primary school → high school/institute → university

### Room Subjects
- Different school subjects may become room themes (Biology lab, Math class, PE hall, etc.)
- Subject determines room visual/layout and potentially special gameplay rules
- Multiple room layouts per subject would be desirable

### Special Rooms (Future)
Future room systems (none for current demo):
- Shop
- Secret room
- Infirmary/healing
- Technology/crafting
- Recreation/social
- NPC/friendship rooms

### Friendship System (Future)
Some enemies/NPCs may become friends with the player, providing specific item or reward outcomes.

### Academic Progression (Future)
Subject choices may influence academic path, career/degree arc, end-game outcomes, and item unlocks. Long-term system — not part of current demo.

---

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
