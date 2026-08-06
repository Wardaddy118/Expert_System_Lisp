# T004 — Pattern matching con variables

**Status:** verified
**Fecha:** 2026-08-05

`src/engine/matching.lisp` implementa `unify-pattern` (variables `?x`,
ligadura en la primera aparición, coincidencia consistente después,
fallo por aridad distinta), negación (`not`) y cinco pruebas
estructurales genéricas: `distinct`, `precedes`, `at-most`, `at-least`,
`exceeds-by-one`, `at-least-below`. Ninguna es "función Lisp arbitraria":
son vocabulario cerrado que el motor interpreta, igual que `not`.

`tests/engine/matching-tests.lisp` cubre cada primitiva con hechos
inventados.

**Archivos:** `src/engine/matching.lisp`, `tests/engine/matching-tests.lisp`
