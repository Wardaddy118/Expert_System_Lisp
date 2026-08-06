# T008 — Reglas académicas del dominio

**Status:** verified
**Fecha:** 2026-08-05

`src/domain/knowledge.lisp` declara 25 `defrule` que implementan BR-001 a
BR-021 de `.ace/knowledge/business-rules.md` (más de las BR-001 a BR-015
previstas originalmente en esta tarea), cada una citando su BR en el
docstring. Incluye dos funciones de post-procesamiento fuera de
`defrule` — `apply-credit-limit` (BR-004) y `apply-elective-group-limit`
(nueva, sin BR formal todavía) — documentadas en el propio código como
la única lógica de dominio que corre después de la quiescencia, porque
agregan sobre un conjunto de tamaño variable que el matching de patrones
de aridad fija no expresa.

`tests/domain/knowledge-tests.lisp` prueba disparo y no-disparo por regla,
con hechos sintéticos aislados (no el catálogo completo).

**Archivos:** `src/domain/knowledge.lisp`, `tests/domain/knowledge-tests.lisp`
