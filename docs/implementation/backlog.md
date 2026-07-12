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
