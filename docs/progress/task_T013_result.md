# T013 — Perfiles de demostración

**Status:** verified
**Fecha:** 2026-08-06

Cuatro perfiles nuevos junto al original, cargables desde la CLI: primer
ingreso sin aprobados, estudiante avanzado, horario muy restringido y
tolerancia baja. Documentados en `data/profiles/README.md`.

## El criterio de cierre de D-09 se cumplió

Esta era la parte que importaba de la tarea. Con los cinco perfiles:

```text
cobertura: 25 de 25 reglas dispararon
NUNCA DISPARARON: NIL
```

**Ninguna regla hubo que eliminar.** La hipótesis era que el problema estaba
en los datos y no en las reglas, y se confirmó:

| Regla | Causa real de que no disparara | Perfil que la activa |
| ----- | ------------------------------ | -------------------- |
| `priority-general-education` | Los tres cursos de formación general del catálogo (SC-103, AN-100, SC-270) tienen bloque **nocturno**, y el perfil original excluía la noche a propósito para ejercitar el choque de horario | `advanced.lisp` |
| `recommended-via-general-education` | Misma causa | `advanced.lisp` |
| `bottleneck-exception-to-tolerance` | Requiere un cuello de botella cuya dificultad exceda la tolerancia por exactamente un nivel; ningún perfil producía esa combinación | `low-tolerance.lisp` |

El caso de `low-tolerance` se construyó a propósito: SC-304 tiene dificultad
4 y es el cuello de botella del catálogo (requisito de SC-402, SC-403 y
SC-404); con tolerancia 3 la excede por exactamente un nivel, y sus
requisitos aprobados y su bloque disponible lo dejan elegible. Resultado
verificado:

```text
SC-304 (dif 4, puntaje 22)
  advertencias: (Supera tu tolerancia a la dificultad por un nivel, pero es
  un curso cuello de botella: atrasarlo cuesta mas que llevarlo ahora.)
```

## Los perfiles se cargan desde la CLI

La sesión interactiva ahora arranca preguntando si se quiere responder las
preguntas o cargar uno de los cinco perfiles. Para una demostración en vivo
importa: mostrar el caso "estudiante que solo tiene dos bloques libres" no
debería costar teclear seis respuestas.

## Comportamiento observado

| Perfil | Recomendados | Descartados |
| ------ | -----------: | ----------: |
| `sample-profile` | 2 | 40 |
| `first-year` | 3 | 40 |
| `advanced` | 4 | 27 |
| `tight-schedule` | 2 | 42 |
| `low-tolerance` | 3 | 42 |

## Pruebas

11 pruebas nuevas en `tests/domain/profiles-tests.lisp`. Dos son invariantes
duros verificados **sobre los cinco perfiles a la vez**: ninguna
recomendación viola un prerrequisito (BR-001) ni el horario declarado
(BR-003). La última es el criterio de cierre de D-09, y su mensaje de fallo
nombra la regla que quedó sin disparar.

## Verificación

```text
sh .ace/scripts/verify.sh     -> VERIFY_RESULT=pass gate=all
sbcl --script run-tests.lisp  -> Did 293 checks. Pass: 293 (100%) Fail: 0
```

Suite: 255 → 293 comprobaciones (+38).

**Archivos:** `data/profiles/first-year.lisp`, `data/profiles/advanced.lisp`,
`data/profiles/tight-schedule.lisp`, `data/profiles/low-tolerance.lisp`,
`data/profiles/README.md`, `tests/domain/profiles-tests.lisp` (todos nuevos),
`src/cli/session.lisp`, `expert-system.asd`.
