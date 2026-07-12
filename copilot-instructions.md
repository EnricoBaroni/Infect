# Instrucciones de trabajo para GitHub Copilot

Este repositorio es un prototipo de juego roguelike en Godot centrado en la mecánica de Infection.

## Objetivo del proyecto

Consultar primero:
- [README.md](README.md)
- [ITEM_ARCHITECTURE.md](ITEM_ARCHITECTURE.md)

La prioridad actual no es construir una infraestructura enorme. La prioridad es validar que Infection produce decisiones de combate interesantes y sostenibles.

## Regla principal

Antes de implementar cualquier cambio, leer:
1. [README.md](README.md)
2. [ITEM_ARCHITECTURE.md](ITEM_ARCHITECTURE.md)
3. [docs/architecture/system-map.md](docs/architecture/system-map.md)
4. [docs/implementation/backlog.md](docs/implementation/backlog.md)

## Principios de implementación

- Mantener el proyecto jugable tras cada tarea.
- Trabajar en slices pequeños y verificables.
- Evitar sistemas genéricos nuevos si aún no están justificados por el gameplay.
- No introducir lógica de ítems ni nuevas capas de runtime sin que el backlog lo exija.
- Mantener el flujo de combate legible y acotado.
- Hacer que Infection sea un sistema explícito, no un flag disperso.
- Los stats del jugador no deben mutarse directamente desde pickups o efectos sin pasar por un resolutor.

## Reglas de arquitectura

- `Player` debe seguir siendo responsable de movimiento, input y visión del personaje.
- `EnemyBase` debe seguir siendo la base común de comportamiento del enemigo.
- `AttackData` debe ser la pieza de transferencia entre el disparo y la entidad del mundo.
- `InfectionState` debe existir como estado explícito del enemigo infectado.
- `Inventory` debe ser un contenedor de ítems y efectos registrados.
- `StatResolver` debe ser la única fuente de cálculo del estado final del jugador.
- No crear sistemas nuevos solo porque podrían ser útiles en el futuro.

## Reglas de documentación

- Si una decisión ya está descrita en [README.md](README.md) o [ITEM_ARCHITECTURE.md](ITEM_ARCHITECTURE.md), no duplicarla.
- Si una tarea toca arquitectura, actualizar [docs/architecture/system-map.md](docs/architecture/system-map.md).
- Si una tarea toca el plan de desarrollo, actualizar [docs/implementation/backlog.md](docs/implementation/backlog.md).
- Si una implementación cambia la percepción del gameplay, registrar el hallazgo en la documentación de validación relevante.

## Flujo recomendado para Copilot

1. Leer la documentación mínima requerida.
2. Confirmar si la tarea pertenece al backlog actual.
3. Hacer el cambio en el slice más pequeño posible.
4. Verificar que el proyecto sigue siendo jugable.
5. Si la tarea cambia una decisión importante, reflejarlo en la documentación correspondiente.
