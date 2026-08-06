# T009 — Reconstrucción de explicaciones

**Status:** verified
**Fecha:** 2026-08-05

`src/domain/explain.lisp` recorre `engine:trace-entries` y traduce cada
disparo de una regla `priority-*` que aportó puntaje a una frase legible
(`*reason-templates*`), más advertencias (hoy, la excepción de tolerancia
de cuello de botella). `explanation-reasons` + `explanation-warnings`
garantizan BR-020: toda recomendación tiene explicación no vacía —
verificado con una prueba sobre el perfil de demostración real
(`every-recommendation-has-a-nonempty-explanation`).

**Archivos:** `src/domain/explain.lisp`, `tests/domain/explain-tests.lisp`
