# T002 — Catálogo de cursos en data/

**Status:** verified
**Fecha:** 2026-08-05

`data/courses.lisp` trae 47 cursos (dentro del rango 40–60 de D-03) del
Bachillerato en Ingeniería en Sistemas de Computación, Universidad
Fidélitas: código, nombre, cuatrimestre, indicador de laboratorio e
indicador de curso colegiado son datos oficiales del programa. Créditos,
área, dificultad, prerrequisitos y horario son provisionales,
identificados como tales en el propio archivo (comentarios `-- OFICIAL --`
/ `-- PROVISIONAL (demo) --` en cada curso, más una cabecera con la lista
de campos pendientes de validar).

**Cumplimiento parcial de D-03:** el conteo de cursos y sus cuatrimestres
son reales; los requisitos siguen sin serlo (el programa no los declara).
No cerrar D-03 como completamente cumplida hasta tener prerrequisitos
oficiales.

**Archivos:** `data/courses.lisp`
