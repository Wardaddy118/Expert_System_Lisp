# T001 — Esqueleto ASDF del sistema

**Status:** verified
**Fecha:** 2026-08-05

`expert-system.asd` define `expert-system` (sin dependencias externas) y
`expert-system/tests` (depende de FiveAM). `src/package.lisp` declara los
tres paquetes `expert-system.engine`, `expert-system.domain` y
`expert-system.cli` con sus nicknames `engine`, `domain`, `cli`.

`sbcl --script run.lisp` y `sbcl --script run-tests.lisp` cargan el
sistema completo y corren la suite (182 comprobaciones, 0 fallos) sin
error.

**Archivos:** `expert-system.asd`, `src/package.lisp`
