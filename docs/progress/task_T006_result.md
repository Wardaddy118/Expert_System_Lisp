# T006 — Agenda, resolución de conflictos y ciclo de inferencia

**Status:** verified
**Fecha:** 2026-08-05

`src/engine/agenda.lisp` construye el conjunto de conflicto y resuelve por
prioridad → recencia (id de inserción más alto entre los hechos
activadores) → orden de declaración, con refracción (una instanciación
—regla + bindings— no dispara dos veces). `src/engine/inference.lisp`
implementa el ciclo match–select–act hasta quiescencia o hasta
`max-cycles` (1000 por omisión; señala `max-cycles-exceeded` si se
alcanza sin quiescencia), y registra cada disparo en una traza
cronológica.

`tests/engine/agenda-tests.lisp` y `tests/engine/inference-tests.lisp`
incluyen la prueba de terminación (regla auto-reactivante alcanza
quiescencia) y la de determinismo (misma traza en corridas repetidas).

**Archivos:** `src/engine/agenda.lisp`, `src/engine/inference.lisp`,
`tests/engine/agenda-tests.lisp`, `tests/engine/inference-tests.lisp`
