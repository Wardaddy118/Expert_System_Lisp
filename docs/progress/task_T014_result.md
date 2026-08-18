# T014 — Pruebas de aceptación del sistema

**Status:** verified
**Fecha:** 2026-08-06

`tests/acceptance-tests.lisp` reúne los diez criterios de aceptación del plan
de implementación en un solo archivo, uno por criterio, nombrados
`acceptance-<n>-...` para que el número sea visible en la corrida.

```text
ACCEPTANCE-1-NO-RECOMMENDATION-VIOLATES-A-PREREQUISITE          ....
ACCEPTANCE-2-NO-RECOMMENDATION-CONFLICTS-WITH-THE-SCHEDULE      ..............
ACCEPTANCE-3-EVERY-RECOMMENDATION-HAS-A-NON-EMPTY-EXPLANATION   ..............
ACCEPTANCE-4-THE-ENGINE-KNOWS-NOTHING-ABOUT-THE-ACADEMIC-DOMAIN ..
ACCEPTANCE-5-A-NEW-RULE-CAN-BE-ADDED-WITHOUT-TOUCHING-THE-ENGINE ..
ACCEPTANCE-6-THE-ENGINE-ALWAYS-TERMINATES                       ..
ACCEPTANCE-7-THE-SAME-INPUT-ALWAYS-PRODUCES-THE-SAME-OUTPUT     ..
ACCEPTANCE-8-THE-CATALOG-HAS-BETWEEN-FORTY-AND-SIXTY-COURSES    .
ACCEPTANCE-9-BOTH-FAMILIES-OF-STATISTICS-ARE-PRESENT            ........
ACCEPTANCE-10-A-FULL-SESSION-RUNS-IN-UNDER-TWO-SECONDS          ..
```

## Para qué sirve tenerlas juntas

Los criterios ya estaban cubiertos de forma dispersa por la suite. Reunirlos
cambia a quién le sirven: un evaluador que quiera comprobar que el sistema
cumple lo prometido no tiene que leer el proyecto entero ni saber dónde está
cada prueba. Abre este archivo y lee diez nombres.

También cambia el mensaje cuando algo falla. Cada `is` lleva su propio texto:
la prueba 1 no dice "expected T, got NIL", dice qué curso se recomendó sin
tener aprobado qué requisito.

## Dos criterios que no estaban realmente verificados

- **Criterio 9 (ambas familias de estadísticas).** Hasta T011 solo existían
  las del estudiante. Ahora la prueba comprueba las dos, e incluye que las 25
  reglas disparen.
- **Criterio 10 (sesión en menos de 2 segundos).** Nunca se había medido: el
  plan decía "corre en menos de un segundo en desarrollo" sin ninguna prueba
  detrás. Ahora se cronometra la sesión y se compara contra NFR-001. Si algún
  día se degrada, la prueba dice cuántos segundos tardó.

## Las dos que sostienen el proyecto

La 4 y la 5 son las que demuestran que esto es un sistema experto y no un
filtro con nombre elegante:

- La **4** corre el motor con hechos inventados (`(color rojo)`), sin un solo
  símbolo del dominio académico. Si necesitara cursos para pasar, el motor
  habría dejado de ser genérico.
- La **5** declara una regla en tiempo de ejecución y verifica que dispara sin
  haber tocado el motor. Si falla, se violó ADR-005.

## Verificación

```text
sh .ace/scripts/verify.sh     -> VERIFY_RESULT=pass gate=all
sbcl --script run-tests.lisp  -> Did 344 checks. Pass: 344 (100%) Fail: 0
```

Suite: 293 → 344 comprobaciones (+51).

**Archivos:** `tests/acceptance-tests.lisp` (nuevo), `expert-system.asd`.
