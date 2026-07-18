# ISAAC-LIKE PROJECT - ENEMY ARCHITECTURE V1

## PROJECT GOALS [DECIDED]

1. El juego está inspirado principalmente en The Binding of Isaac.

2. La prioridad es poder crecer durante años sin reescribir sistemas completos.

3. Añadir enemigos nuevos debe ser rápido y reutilizar la mayor cantidad posible de código existente.

4. Evitar copiar y pegar lógica entre enemigos.

5. Preferir composición frente a herencia profunda.

6. Diseñar para necesidades reales observadas en Isaac, no para casos hipotéticos extremadamente raros.

7. El refactor de enemigos es independiente del refactor de items y proyectiles.

8. Los bosses pueden usar una arquitectura distinta si en el futuro resulta más conveniente.

9. Antes de añadir complejidad, la arquitectura debe funcionar correctamente con los enemigos actuales del proyecto.

---

# ENEMY ARCHITECTURE V1 [DECIDED]

Enemy
├ Stats
├ Behaviors
├ Traits
└ States (solo cuando sea necesario)

---

## STATS [DECIDED]

Responsabilidad:

Contener únicamente datos.

Ejemplos:

* Health
* MaxHealth
* Speed
* Damage
* Drops
* XP
* KnockbackResistance

Los Stats NO contienen lógica.

Los Stats NO toman decisiones.

Los Stats NO controlan comportamiento.

---

## BEHAVIORS [DECIDED]

Responsabilidad:

Contener lógica reutilizable.

Los Behaviors representan cosas que el enemigo hace.

Ejemplos observados en Isaac:

Movimiento:

* Chase
* Wander
* Charge
* Jump
* Flee
* Burrow
* Teleport
* WallCrawler
* Orbit

Ataque:

* ShootProjectile
* ShootSpread
* ShootRing
* ShootBeam
* MeleeAttack
* SpawnEnemy

Importante:

No es obligatorio decidir todavía si un enemigo tendrá un único comportamiento principal o varios comportamientos combinados.

Esa decisión queda abierta para la implementación.

---

## TRAITS [DECIDED]

Responsabilidad:

Características pasivas.

No son ataques.

No son movimiento.

Ejemplos:

* Flying
* Spectral
* Invulnerable
* ShieldFront
* Regeneration
* Invisible

Un Trait modifica cómo funciona el enemigo.

No define su comportamiento principal.

---

## STATES [DECIDED]

Responsabilidad:

Gestionar enemigos que cambian de fase o forma.

Ejemplos reales observados en Isaac:

* Host
* Globin
* Fatty
* Cod Worm
* Mushroom

No todos los enemigos necesitan States.

Los States solo existirán cuando aporten valor real.

---

# PRINCIPIOS IMPORTANTES [DECIDED]

1. Los enemigos se construyen mediante composición.

2. Los datos deben estar separados de la lógica.

3. El código reutilizable tiene prioridad sobre el código específico.

4. La arquitectura debe validarse con enemigos reales.

5. Si una idea no mejora el desarrollo futuro, probablemente no pertenece al núcleo del sistema.

6. No diseñar soluciones para problemas que todavía no existen.

7. Cada nueva capa de complejidad debe justificar claramente qué problema resuelve.

---

# DECISIONES DESCARTADAS [DISCARDED]

* Un script gigante por enemigo.
* Copiar comportamiento entre enemigos.
* Herencia profunda de enemigos.
* Diseñar sistemas específicos para champions.
* Diseñar sistemas específicos para infección.
* Diseñar primero los items antes que los enemigos.
* Diseñar para sinergias extremas de Isaac antes de tener el sistema base funcionando.

---

# PREGUNTAS ABIERTAS [OPEN]

1. ¿Los Behaviors se implementarán como Nodes o como Resources?

2. ¿Cómo se organizarán físicamente las escenas de enemigos?

3. ¿Cómo se implementarán internamente los States?

4. ¿Cuál será la primera migración de prueba (Bat, Nerd, Rapper o Bully)?

---

# CRITERIO PARA CAMBIAR ESTE DOCUMENTO

Una decisión marcada como [DECIDED] no debe cambiarse simplemente porque aparezca una idea nueva.

Solo debe cambiarse si:

* Encontramos una limitación real durante la implementación.
* Encontramos un enemigo real que no encaja en la arquitectura.
* La nueva solución demuestra ser claramente superior.

Si una propuesta contradice este documento, primero debe justificarse qué problema real resuelve.
