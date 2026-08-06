# T003 — Hechos y memoria de trabajo

**Status:** verified
**Fecha:** 2026-08-05

`src/engine/facts.lisp` define `working-memory` (lista de hechos + id de
inserción monótono), `make-working-memory`, `assert-fact` (idempotente),
`fact-present-p` y `query-facts`. Genérico: no menciona ningún símbolo del
dominio académico.

`tests/engine/facts-tests.lisp` prueba con hechos inventados
(`(color rojo)`, `(shape circle)`), no con cursos.

**Archivos:** `src/engine/facts.lisp`, `tests/engine/facts-tests.lisp`
