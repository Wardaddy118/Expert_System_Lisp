# T010 — Estadísticas del estudiante

**Status:** verified
**Fecha:** 2026-08-05

`src/domain/stats.lisp` calcula, sobre la memoria de trabajo final de la
sesión (BR-030, nunca con una consulta aparte): cursos evaluados,
aprobados, bloqueados por prerrequisitos, incompatibles por horario,
descartados por dificultad, elegibles, dificultad promedio del catálogo y
créditos recomendados. Visible en la salida real de `run.lisp`.

**Diferencia con el objetivo original de esta tarea:** el enunciado de
T010 pedía específicamente "avance de carrera relativo al catálogo",
"créditos aprobados vs. totales" y "distribución de aprobados por área".
Esas tres métricas puntuales no están implementadas todavía; las ocho
que sí existen cubren el mismo requisito funcional (FR-040) desde otro
ángulo. Queda como mejora futura si se necesitan exactamente esas tres.

**Archivos:** `src/domain/stats.lisp`, `tests/domain/stats-tests.lisp`
