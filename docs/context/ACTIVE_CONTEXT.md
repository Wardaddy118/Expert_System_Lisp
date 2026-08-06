# Active Context: Primera versión funcional implementada

## Session Metadata

- **Última actualización:** 2026-08-05
- **Rol activo:** Developer
- **Mode:** EXECUTION (implementación en curso, no diseño)
- **Próxima transición:** EXECUTION → EXECUTION (quedan T012, T013 y T014;
  ver "Qué falta para la entrega final" abajo)

## Cómo arrancar en esta sesión

```bash
git checkout main && git pull   # todo esta fusionado en main
sbcl --script run.lisp        # corre la demostracion completa
sbcl --script run-tests.lisp  # corre la suite de pruebas (235 comprobaciones)
```

Si cualquiera de los dos scripts falla, **no continuar**: hay una regresión
que resolver antes de seguir con cualquier otra tarea.

## Fechas de entrega (confirmadas 2026-08-06)

| Entrega | Fecha | Semana |
| ------- | ----- | ------ |
| **Borrador** | **jueves 2026-08-06** | 13 |
| **Final: sistema 100% funcional** | **jueves 2026-08-20** | 15 |

Quedan T012, T013 y T014 para la entrega final: dos semanas, con el motor, el
dominio y las estadísticas ya verificados. El informe en **formato IEEE** lo
exige el profesor y se cree que alguien del equipo lo está redactando —
**confirmar**; si nadie lo tiene, el contenido ya existe en `docs/`.

## Estado del repositorio

- **Rama:** `feature/initial-lisp-implementation`, fusionada a `main`
- **Código de implementación:** existe y funciona. Ya no es correcto decir
  "el Architect no lo escribe": la fase de diseño cerró y esta rama contiene
  la primera versión funcional completa.
- **Gate de verificación:** en verde y ya verifica comportamiento, no solo
  compilación. `sh .ace/scripts/verify.sh` compila el sistema con ASDF (en
  orden de dependencias) y corre las 235 comprobaciones de la suite.

### Dos defectos de verificación corregidos (2026-08-05, sesión de revisión)

Ambos hacían que "verificado" no significara nada; se arreglaron antes de
seguir con tareas nuevas:

1. **El gate nunca funcionó con código Lisp real.** La primera versión de
   `.ace/scripts/verify-lisp.sh` compilaba cada archivo por separado, en un
   proceso SBCL nuevo por archivo. Todo archivo real empieza con
   `(in-package :expert-system.engine)` y ese paquete se define en
   `src/package.lisp`, que no está cargado en un proceso nuevo: fallaban
   *todos* los fuentes, más `data/*.lisp` (que son datos) y el propio `.asd`.
   Había pasado la prueba de humo inicial solo porque aquel archivo definía su
   paquete inline. Ahora el gate delega en ASDF.
2. **La suite no corría en un clon limpio.** `run-tests.lisp` cargaba
   Quicklisp pero pedía FiveAM con `asdf:load-system`, que resuelve lo ya
   instalado pero **no descarga** lo que falta. Fallaba con
   `Component #:FIVEAM not found` en cualquier máquina donde nadie la hubiera
   bajado a mano. Ahora usa `ql:quickload`. Las comprobaciones de la suite son
   reproducibles por cualquiera del equipo y por el profesor.

## Qué existe hoy

### Arquitectura (tres capas, dependencias hacia abajo)

```text
expert-system.asd   Sistemas expert-system y expert-system/tests
run.lisp             sbcl --script run.lisp -> corre la demo completa
run-tests.lisp        sbcl --script run-tests.lisp -> corre la suite FiveAM
src/
  package.lisp       Los tres paquetes: engine, domain, cli
  main.lisp          Punto de entrada; unico archivo con SB-* si hiciera falta
  engine/            Motor generico (no sabe que es un curso)
    facts.lisp       Memoria de trabajo, hechos con id de insercion monotono
    matching.lisp     Unificacion con variables, NOT, pruebas estructurales
    rules.lisp        Macro DEFRULE, *RULES*
    agenda.lisp        Conjunto de conflicto, resolucion, refraccion
    inference.lisp      Ciclo match-select-act, quiescencia, traza
  domain/            Conocimiento academico (usa engine: con prefijo)
    loader.lisp      Carga y valida data/, normaliza a hechos
    knowledge.lisp     25 defrule + post-procesamiento de dominio
    explain.lisp       Reconstruccion de explicaciones desde la traza
    stats.lisp          Estadisticas sobre la memoria de trabajo final
  cli/               Unica capa con E/S (usa domain: con prefijo)
    format.lisp       Presentacion en texto
    session.lisp        Orquesta una sesion con el perfil de demostracion
data/
  courses.lisp        Catalogo de 47 cursos (ver abajo)
  profiles/sample-profile.lisp   Perfil de demostracion fijo
tests/               Espejo de src/, un archivo de pruebas por archivo de src/
```

### El motor (src/engine/), 100% generico

Confirmado en el codigo, no solo en el diseño:

- Memoria de trabajo basada en hechos, con id de insercion monotono
  (`facts.lisp`).
- Reglas declarativas (`defrule`), guardadas como estructura de datos, no
  como codigo (`rules.lisp`).
- Matching con variables (`?var`), negacion (`not`), y cinco pruebas
  estructurales (`distinct`, `precedes`, `at-most`, `at-least`,
  `exceeds-by-one`, `at-least-below`) (`matching.lisp`).
- Agenda, resolucion de conflictos por prioridad → recencia → orden de
  declaracion, y refraccion (`agenda.lisp`).
- Encadenamiento hacia adelante con limite maximo de ciclos configurable,
  quiescencia y traza cronologica de cada disparo (`inference.lisp`).
- Su suite de pruebas (`tests/engine/`) usa exclusivamente hechos
  inventados (`color`, `ping`, `item`...). Nunca un simbolo del dominio
  academico. Verificado por inspeccion en esta sesion.

### El dominio (src/domain/)

25 reglas `defrule` en `knowledge.lisp`, mas dos funciones de
post-procesamiento que corren despues de la quiescencia del motor (por la
misma razon documentada en el propio codigo: sumar/comparar sobre un
conjunto de tamaño variable no se expresa con condiciones de aridad fija):

- Elegibilidad: cursos aprobados, prerrequisitos, compatibilidad de
  horario (BR-001 a BR-003).
- Cuello de botella con la excepcion de tolerancia (BR-005, BR-006).
- Intereses y area profesional objetivo (BR-010, BR-011).
- Puntuacion acumulada por regla (BR-010 a BR-015).
- Recomendaciones (BR-007) y motivos de descarte explicados (BR-021).
- **`apply-credit-limit`** (post-procesamiento): tope de creditos (BR-004).
- **`apply-elective-group-limit`** (post-procesamiento, nueva esta sesion):
  limite de una electiva por bloque. Corre antes que `apply-credit-limit`
  para no gastar presupuesto de creditos en una electiva que de todas
  formas se descartaria por venir del mismo bloque que otra mejor
  puntuada. Formalizada como **BR-008** en business-rules.md el
  2026-08-06; el docstring la cita.
- Explicaciones (`explain.lisp`) reconstruidas desde la traza, nunca
  generadas aparte.
- Estadisticas (`stats.lisp`) calculadas sobre la memoria de trabajo
  final, nunca con una consulta aparte al catalogo.

### El catalogo (data/courses.lisp)

**47 cursos** del Bachillerato en Ingenieria en Sistemas de Computacion,
Universidad Fidelitas: 35 obligatorios + 12 opciones electivas repartidas
en 3 bloques de 4 opciones cada uno (sexto, setimo y octavo cuatrimestre).
El estudiante recorre 35 obligatorios + 1 electiva por bloque = **38
cursos efectivos**, no 47.

**Dato oficial vs. provisional — la distincion mas importante de este
archivo.** El programa suministrado por la universidad solo trae codigo,
nombre, cuatrimestre, indicador de laboratorio e indicador de curso
colegiado, y a que bloque electivo pertenece cada electiva. Todo lo demas
que el motor necesita para razonar es provisional, inventado por el
equipo, y estan marcados asi en `data/courses.lisp` linea por linea:

| Campo | Origen | Detalle |
| ----- | ------ | ------- |
| Código, nombre, cuatrimestre | **Oficial** | Tal como lo entrego la universidad |
| Indicador de laboratorio | **Oficial** | Campo `:laboratory` |
| Indicador de curso colegiado | **Oficial** | Campo `:collegiate` |
| Pertenencia a bloque electivo | **Oficial** | Campo `:elective` / `:elective-group` |
| Créditos | Provisional | 4 uniforme para los 47 cursos, documentado como el valor mas honesto cuando no hay dato real |
| Dificultad (1-5) | Provisional | Formula por cuatrimestre + 1 si tiene laboratorio (tope 5), documentada en la cabecera del archivo |
| Área profesional | Provisional | Inferida por el equipo a partir del NOMBRE del curso, no es clasificacion de la universidad |
| Intereses del perfil de demo | Provisional | Ver `data/profiles/sample-profile.lisp` |
| Horario | Provisional | Un bloque por curso, asignado por rotacion, solo para que BR-003 tenga algo que evaluar |
| Prerrequisitos | Provisional | Solo 6 enlaces de demostracion, ver abajo. El programa oficial NO declara ninguno |
| Cuello de botella (BR-006) | Provisional (derivado) | Se calcula sobre prerrequisitos que no son oficiales; SC-304 es un cuello de botella de EJEMPLO, no una conclusion sobre el plan real |

**Prerrequisitos provisionales actuales** (confirmados leyendo
`data/courses.lisp` y el hecho que arma `src/domain/loader.lisp`, que es
`(prerequisite <curso-que-requiere> <curso-requerido>)`):

```
SC-115 → SC-202   ;; (prerequisite "SC-202" "SC-115")
SC-202 → SC-304   ;; (prerequisite "SC-304" "SC-202")
SC-315 → SC-304   ;; (prerequisite "SC-304" "SC-315")
SC-304 → SC-402   ;; (prerequisite "SC-402" "SC-304")
SC-304 → SC-403   ;; (prerequisite "SC-403" "SC-304")
SC-304 → SC-404   ;; (prerequisite "SC-404" "SC-304")
```

La flecha `A → B` se lee "A es prerrequisito de B" (A se debe completar
antes de B). El hecho de la memoria de trabajo va en el orden inverso:
primero el curso que requiere, despues el requisito — igual que en el
ejemplo de ADR-006 y en el catalogo de la version anterior.

### El perfil de demostración

`data/profiles/sample-profile.lisp` es fijo (todavia no hay captura
interactiva por consola). Fue ajustado deliberadamente para que
`run.lisp` ejercite, en una sola corrida, las **seis** razones de
descarte que el sistema conoce: ya aprobado, prerrequisitos faltantes,
choque de horario, dificultad excesiva, tope de creditos, y limite de
electiva por bloque.

## Resultado real de la última verificación

```text
$ sbcl --script run.lisp
[reporte completo: perfil, recomendaciones, descartes, estadisticas, traza]
exit code 0

$ sbcl --script run-tests.lisp
Did 182 checks.
    Pass: 182 (100%)
    Skip: 0 ( 0%)
    Fail: 0 ( 0%)
exit code 0
```

47 cursos evaluados, 295 disparos de regla registrados en la traza de la
corrida de demostracion (muy por debajo del limite de seguridad de 1000
ciclos que usa `engine:run` por omision).

## Decisiones ya tomadas (además de D-01 a D-04 en PROJECT_CONTEXT.md)

- El motor se escribió desde cero, sin RETE, con matching ingenuo — tal
  como fijó ADR-005. Confirmado en el código: `engine/matching.lisp` no
  usa ninguna estructura de indexación.
- El catálogo real (D-03: "40–60 cursos de una carrera real, con
  requisitos reales") **se cumplió parcialmente**: los 47 cursos y sus
  cuatrimestres son reales; los requisitos siguen sin ser reales (ver
  tabla de arriba). D-03 no se puede marcar cumplida del todo hasta que
  existan prerrequisitos oficiales.
- Vocabulario de área profesional provisional ampliado en esta sesión más
  allá del propuesto originalmente en `.ace/knowledge/glossary.md`:
  se agregaron `databases`, `networks`, `cybersecurity`, `data`,
  `infrastructure`, `management` y `mathematics` junto a
  `software-engineering` y `general-education`. Marcado en el glosario
  como inferencia del equipo, no dato oficial.
- El límite de una electiva por bloque se implementó como función de
  dominio normal después de la quiescencia (`apply-elective-group-limit`),
  igual que el tope de créditos (BR-004) — mismo patrón, misma
  justificación (agregación de tamaño variable, no expresable con
  condiciones de aridad fija).

## Datos oficiales incorporados

Código, nombre, cuatrimestre, indicador de laboratorio, indicador de
curso colegiado y pertenencia a bloque electivo, para los 47 cursos del
programa de Bachillerato en Ingeniería en Sistemas de Computación
suministrado por la universidad.

## Datos todavía provisionales (no presentar como oficiales)

Créditos, dificultad, horarios, área profesional, intereses del perfil de
demostración, prerrequisitos, y el cálculo de cuello de botella que
depende de esos prerrequisitos. Ver la tabla de arriba y la cabecera de
`data/courses.lisp` para el detalle exacto de cada uno.

## Limitaciones conocidas

- No existe captura interactiva del perfil por consola.
- No hay créditos, prerrequisitos ni correquisitos oficiales.
- No hay horarios reales.
- La dificultad es una fórmula provisional del equipo, no un criterio
  validado.
- Las áreas profesionales y los intereses son clasificaciones del equipo,
  no de la universidad.
- El catálogo cubre solo el Bachillerato, no las licenciaturas.
- La traza completa de una corrida es extensa (295 líneas en la
  demostración actual); no hay todavía una vista resumida.
- Algunas reglas que aparecen en la traza como "disparadas" no producen
  un hecho nuevo en ese ciclo porque el hecho ya estaba presente
  (`ENGINE:ASSERT-FACT` es idempotente): la traza registra el disparo
  igual, con una lista vacía de hechos generados. Es el comportamiento
  esperado, no un error.
- **Ambigüedad de vocabulario pendiente de aclarar:** en este documento y
  en el código, un "ciclo" de `engine:run` es una sola activación
  (match → select → act de una instanciación). No es una reconstrucción
  completa de toda la agenda. Los ~295 disparos de la demo son, por lo
  tanto, ~295 ciclos en ese sentido — hay que decidir si esta es la
  definición que se quiere usar de forma consistente en toda la
  documentación futura, o si conviene un término distinto para evitar
  confusión con "ciclo del CPU" o "ciclo de vida del proyecto".

## Qué falta para la entrega final (2026-08-20)

**Tres tareas en la cola**, en orden de dependencias:

1. **T012 — Captura interactiva del perfil** en `src/cli/session.lisp`. Hoy
   carga `data/profiles/sample-profile.lisp` fijo, no pregunta por consola.
   Es el hueco más visible en una demostración en vivo.
2. **T013 — Perfiles de demostración.** Solo existe uno. Faltan primer
   ingreso sin aprobados, estudiante avanzado, horario muy restringido y
   tolerancia baja. **Lleva el criterio de cierre de la decisión D-09:** los
   perfiles deben hacer disparar las tres reglas que hoy nunca disparan
   (`bottleneck-exception-to-tolerance`, `priority-general-education`,
   `recommended-via-general-education`) o esas reglas se eliminan.
   Verificar con la cobertura de reglas de `catalog-statistics`.
3. **T014 — Suite de aceptación** en un archivo dedicado. Los 10 criterios
   del plan ya están cubiertos de forma dispersa por las 235 comprobaciones;
   falta reunirlos.

**Fuera de la cola, y no depende de nosotros:** conseguir créditos y
prerrequisitos oficiales. Es lo que más cambiaría la fidelidad del sistema
(BR-006 depende enteramente de los prerrequisitos), pero por decisión D-10 no
bloquea la entrega: si llegan, es un cambio en `data/` y cero código.

**Coordinación pendiente:** confirmar quién redacta el informe en formato
IEEE que exige el profesor.

## Ya resuelto en esta sesión (2026-08-06)

- T011 (estadísticas de catálogo) verificada: cursos más recomendados,
  cuellos de botella con `n`, dificultad promedio por área y cobertura de
  reglas. Visible en `run.lisp`.
- BR-008 formalizado: el límite de una electiva por bloque ya no es una
  regla que solo existía en el código.
- Los dos defectos de verificación descritos arriba.
- Las seis decisiones de criterio experto ratificadas (D-05 a D-10 en
  `PROJECT_CONTEXT.md`).
- Suite: 182 → 235 comprobaciones.

Ver la sección completa de próximas tareas, con prioridad media y
posterior, en `docs/planning/implementation_plan.md` (a actualizar) y en
el historial de esta sesión.

## Archivos principales para retomar el trabajo

| Si vas a... | Empieza por |
| ----------- | ----------- |
| Entender el motor | `src/engine/inference.lisp` y `src/engine/matching.lisp` |
| Entender las reglas académicas | `src/domain/knowledge.lisp` + `.ace/knowledge/business-rules.md` |
| Agregar datos oficiales | `data/courses.lisp` (cabecera con la lista de campos pendientes de validar) |
| Agregar captura interactiva | `src/cli/session.lisp` |
| Correr o depurar | `run.lisp`, `run-tests.lisp` |
| Ver qué falta | `docs/progress/tasks.json`, esta sección "Próxima tarea recomendada" |

## Restricciones activas (sin cambios)

- `.ace/standards/lisp.md` — convenciones de código
- `.ace/standards/coding.md` — principios generales
- `docs/context/PROJECT_CONTEXT.md` — D-01 a D-04 siguen siendo
  restricciones duras
- `docs/context/system_patterns.md` — patrones y anti-patrones
- `.ace/knowledge/business-rules.md` — especificación del conocimiento
  experto (pendiente de una entrada nueva para el límite de electivas)
