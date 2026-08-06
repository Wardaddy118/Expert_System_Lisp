# T005 — Reglas como datos: macro defrule

**Status:** verified
**Fecha:** 2026-08-05

`src/engine/rules.lisp` define la estructura `rule` (nombre, docstring,
prioridad, orden de declaración, condiciones `:when`, plantillas
`:then`) y la macro `defrule`, que registra/reemplaza una regla en
`*rules*` sin ejecutar código de decisión. El docstring es opcional
(las reglas académicas sí lo traen, citando su BR; las pruebas pueden
omitirlo).

`tests/engine/rules-tests.lisp` prueba registro, redefinición
(no duplica) y extensibilidad (NFR-004: una regla nueva no toca el motor).

**Archivos:** `src/engine/rules.lisp`, `tests/engine/rules-tests.lisp`
