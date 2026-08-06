# T007 — Carga y validación del catálogo

**Status:** verified
**Fecha:** 2026-08-05

`src/domain/loader.lisp` lee `data/courses.lisp` y `data/profiles/`, y los
normaliza a hechos planos. Valida (señala `data-error` o
`circular-prerequisites`, aborta la carga): códigos duplicados,
requisitos que apuntan a cursos inexistentes, ciclos en el grafo de
requisitos, cuatrimestre presente en todo curso, y — ampliación sobre el
alcance original de esta tarea, agregada al incorporar el catálogo real
de 47 cursos — consistencia de `:elective`/`:elective-group` y tamaño de
cada bloque electivo (exactamente 4 opciones).

**Archivos:** `src/domain/loader.lisp`, `tests/domain/loader-tests.lisp`
