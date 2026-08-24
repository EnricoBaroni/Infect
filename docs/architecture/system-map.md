# Mapa de arquitectura funcional

Este documento es la referencia técnica mínima del proyecto para el desarrollo actual. No sustituye a [README.md](README.md) ni a [ITEM_ARCHITECTURE.md](ITEM_ARCHITECTURE.md); los complementa.

## Propósito

Definir de forma compacta qué sistema es responsable de qué parte del gameplay, con el nivel de complejidad que este repositorio realmente necesita en esta fase.

## Sistema principal: `Player`

Responsabilidad:
- mover al personaje;
- recibir input;
- disparar normal;
- disparar en modo Infection;
- recibir daño;
- exponer el estado final del personaje al resto del flujo.

No debe convertirse en un coordinador global de todos los sistemas.

## Sistema principal: `EnemyBase`

Responsabilidad:
- comportamiento base del enemigo;
- movimiento y IA mínima;
- reacción a colisiones;
- reacción al estado de Infection;
- muerte y drops.

La base común debe permitir crear variantes sin duplicar toda la lógica.

## Sistema de ataque: `AttackData`

Responsabilidad:
- encapsular una intención de ataque antes de convertirla en entidad física;
- transportar daño, rango, dirección, tipo de ataque y flags de estado.

Debe ser una estructura ligera, no una entidad del árbol de escena.

## Sistema de arma: `WeaponSystem`

Responsabilidad:
- construir `AttackData` a partir del input de disparo y del estado actual del jugador;
- delegar la materialización física al flujo de proyectiles.

No debe conocer ítems ni reglas específicas por contenido.

## Sistema de evaluación de ataque: `AttackEvaluationSystem`

Responsabilidad:
- aplicar efectos de ataque activos al `AttackData` antes de materializar el proyectil;
- mantener fuera de `WeaponSystem` el recorrido de efectos de inventario.

Debe operar de forma aditiva y data-driven.

## Sistema de proyectiles

Responsabilidad:
- materializar `AttackData` en un proyectil o entidad física;
- moverla;
- aplicar duración útil;
- responder a colisiones;
- interpretar capacidades (por ejemplo: pierce, bounce).

El proyectil no debe ser el lugar donde vive la lógica completa del juego.

Estado actual:
- incluye proyectil de lágrima (`Bullet`) y haz segmentado (`BeamSegment`) bajo el mismo flujo de materialización.

## Reemplazo de arma por datos

Responsabilidad:
- permitir que un efecto de ataque cambie el tipo de arma escribiendo en `AttackData.weapon_type`;
- mantener la materialización dentro de `ProjectileSystem` sin condicionales por ítem.

Validación actual:
- Brimstone implementado como reemplazo a haz segmentado.

## Sistema de colisión: `Hitbox` y `Hurtbox`

Responsabilidad:
- `Hitbox` emite el golpe;
- `Hurtbox` recibe el golpe y lo reenvía al receptor.

Estos dos sistemas deben seguir siendo una capa de contacto físico y no una capa de economía ni de contenido.

## Sistema de Infection: `InfectionState`

Responsabilidad:
- representarla como un estado explícito del enemigo infectado;
- permitir que el enemigo tenga una reacción clara y verificable;
- impedir que Infection siga siendo un simple flag disperso en varias partes del código.

## Sistema de contenido: `ItemDefinition`

Responsabilidad:
- describir un ítem como dato;
- no contener gameplay ejecutable.

Un ítem debe decir qué es, no cómo se ejecuta.

## Sistema de ejecución de efectos: `EffectInstance`

Responsabilidad:
- encapsular la ejecución de un efecto de un ítem;
- aplicarse a un runtime específico del jugador o del combate.

Debe existir para evitar mezclar contenido y comportamiento.

Estado actual:
- implementado como capa mínima de runtime reactivo (`ReactiveEffectInstance` + `EffectRuntimeSystem`);
- activo para efectos que consumen señales de `EventBus`.

## Sistema de eventos: `EventBus`

Responsabilidad:
- exponer señales globales de gameplay para efectos reactivos y telemetría interna mínima;
- evitar acoplar sistemas entre sí mediante referencias directas.

Debe mantenerse como infraestructura ligera de señales, sin lógica de negocio.

## Sistema de inventario: `Inventory`

Responsabilidad:
- registrar ítems recogidos;
- registrar instancias de efectos;
- mantener el registro del estado del jugador dentro de una run.

No debe hacerse cargo de todo el combate.

## Sistema de stats: `StatResolver`

Responsabilidad:
- construir el estado final del jugador a partir de:
  - stats base;
  - ítems activos;
  - efectos registrados;
  - modificadores internos temporales.

La regla es clara: no mutar stats desde pickups o efectos de forma aislada.

## Sistema de companions: `CompanionSystem`

Responsabilidad:
- gestionar el ciclo de vida de companions (orbitals y seguidores pasivos) por fuente de runtime;
- hacer spawn y limpieza de entidades companion vinculadas a ítems sin condicionales por ítem.

Entidades reutilizables: `OrbitalCompanion` (daño de contacto en órbita) y `PassiveFollower` (seguidor con daño de contacto).
Configuración por datos vía `CompanionFormationEffect` + `CompanionFormationRuntime`.

## Sistema de estado de enemigos: `StatusPayload`

Responsabilidad:
- transportar configuraciones de estado (veneno, quemadura, freeze, slow, miedo, encanto, confusión, sangrado, cebo, encadenado) desde `AttackData` al `Hurtbox`/`EnemyBase`;
- permitir que `EnemyBase` aplique múltiples estados simultáneos con stacking, duración y ticks de daño sin condicionales por estado en sistemas de ataque.

`StatusPayload` vive en `system/status_payload.gd`. El runtime de estados está integrado en `EnemyBase`.

## Límites de la arquitectura actual

No crear todavía:
- un `WeaponController` separado como abstracción de alto nivel;
- un `CombatResolver` independiente;
- un `EnemyStatusModel` paralelo al enemigo;
- un `RoomEncounterController` separado de la room.

Estas capas pueden llegar más adelante si el gameplay lo exige, pero hoy no son la prioridad.

## Reglas de mantenimiento

- Mantener el proyecto jugable tras cada tarea.
- Enfocar el trabajo en slices pequeños.
- Validar gameplay antes de ampliar sistema.
- Si una decisión deja de ser válida, actualizar esta referencia y dejar constancia en la documentación que corresponda.
