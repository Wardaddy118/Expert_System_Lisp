# Plan de Implementación: Sistema Experto de Recomendaciones Académicas

> **Status:** Draft — pendiente de aprobación del equipo
> **Creado:** 2026-08-05
> **Autor:** Architect (rol ACE)
> **PRD:** `docs/requirements/PRD-recomendador-academico.md`
> **Cola de tareas:** `docs/progress/tasks.json`
> **Línea base:** commit `9df7cf3` en `origin/main`

---

## Resumen

Se construye un sistema experto en Common Lisp que recomienda cursos
universitarios y explica sus recomendaciones. El trabajo se divide en cuatro
capas que se construyen de adentro hacia afuera: **motor genérico → carga de
datos → conocimiento del dominio → interfaz y estadísticas**.

El orden no es negociable: el motor no depende de nada y se prueba con hechos
inventados; todo lo demás depende de él. Construir reglas del dominio antes de
tener matching confiable es la forma más común de arruinar este proyecto.

---

## Prerrequisitos

- [x] Requisitos analizados (PRD escrito)
- [x] Decisiones de arquitectura tomadas (ADR-004, ADR-005, ADR-006)
- [x] Vocabulario y modelo de datos definidos (`.ace/knowledge/`)
- [x] Estándar de código Lisp definido (`.ace/standards/lisp.md`)
- [x] Gate de verificación operativo (`.ace/scripts/verify.sh`)
- [ ] Carrera y universidad a modelar confirmadas
- [ ] Fechas del calendario académico confirmadas
- [ ] Reparto de tareas entre el equipo

---

## Arquitectura

### Vista de capas

```text
┌──────────────────────────────────────────────────────────┐
│  CLI  (src/cli/)                                         │
│  Captura del perfil · flujo de sesión · presentación     │
│  Es la única capa que hace E/S con el usuario            │
└───────────────────────┬──────────────────────────────────┘
                        ▼
┌──────────────────────────────────────────────────────────┐
│  DOMINIO  (src/domain/)                                  │
│  Carga y validación de data/ · reglas académicas         │
│  (defrule) · explicaciones · estadísticas                │
│  Conoce cursos y créditos. NO conoce la CLI.             │
└───────────────────────┬──────────────────────────────────┘
                        ▼
┌──────────────────────────────────────────────────────────┐
│  MOTOR  (src/engine/)                                    │
│  Hechos · matching con variables · reglas como datos ·   │
│  agenda · resolución de conflictos · refracción ·        │
│  ciclo de inferencia · traza                             │
│  Genérico. NO sabe qué es un curso.                      │
└──────────────────────────────────────────────────────────┘

  data/         Catálogo y perfiles en S-expressions (no es código)
```

**Invariante de dependencias:** las flechas apuntan hacia abajo y nunca hacia
arriba. `engine/` no puede mencionar un solo símbolo del dominio académico.
Esa restricción es lo que hace que el motor sea demostrablemente un motor.

### Flujo de una sesión

```text
CLI captura perfil
   → domain/loader afirma hechos de catálogo y perfil en la memoria de trabajo
   → engine/inference corre hasta quiescencia disparando las reglas de domain/knowledge
   → domain/explain reconstruye el porqué desde la traza
   → domain/stats calcula métricas sobre la memoria de trabajo final
   → cli/format presenta todo en texto
```

---

## Fases

### Fase 1 — Cimientos (T001–T002)

Esqueleto ASDF que carga y compila, y el catálogo de datos. Son
independientes entre sí: pueden hacerse en paralelo por dos personas.

Al terminar esta fase el gate `verify.sh` pasa por primera vez con código
real, lo que desbloquea el ciclo de trabajo del resto del proyecto.

### Fase 2 — Motor de inferencia (T003–T006)

El núcleo. Se construye en orden estricto porque cada pieza depende de la
anterior:

1. **Hechos y memoria de trabajo** — la base sobre la que todo opera.
2. **Matching con variables** — la pieza más difícil. Se prueba sola, a fondo,
   antes de que nada dependa de ella.
3. **Reglas como datos** — la macro `defrule` y su almacenamiento.
4. **Agenda, resolución de conflictos y ciclo** — refracción incluida, o el
   motor se cuelga.

Toda esta fase se prueba con hechos inventados. Ni una línea sobre cursos.

### Fase 3 — Conocimiento del dominio (T007–T009)

Carga y validación de datos, las reglas académicas que implementan las BR del
documento de reglas, y la reconstrucción de explicaciones.

Aquí es donde el proyecto empieza a verse como un recomendador.

### Fase 4 — Estadísticas e interfaz (T010–T012)

Las dos familias de estadísticas y la CLI completa. Se dejan al final porque
dependen de todo lo anterior, pero **no son opcionales**: tienen tareas y
fechas propias precisamente para que no se conviertan en "lo que hagamos si
sobra tiempo".

### Fase 5 — Cierre (T013–T014)

Perfiles de demostración, documentación final y walkthrough de verificación
para la entrega.

---

## Cronograma

> **Las fechas están pendientes de confirmar.** El equipo debe completar la
> columna de fechas con el calendario del curso antes de arrancar la Fase 2.

| Semana | Fase | Entregable | Fecha |
| ------ | ---- | ---------- | ----- |
| Actual | Diseño | ✅ Documentación de arquitectura completa, publicada en `origin/main` (`9df7cf3`) | 2026-08-05 |
| — | Borrador | Documentación + esqueleto de código + motor mínimo | *por confirmar* |
| 11 | 1 y 2 | Motor de inferencia funcional y probado | *por confirmar* |
| 12 | 3 | Base de conocimiento completa, recomendaciones correctas | *por confirmar* |
| 13 | 3 | Explicaciones funcionando | *por confirmar* |
| 14 | 4 | Estadísticas y CLI completa | *por confirmar* |
| 15 | 5 | Sistema 100% funcional, documentado y demostrable | *por confirmar* |

### Qué mostrar en el borrador

El borrador pide avance, plan, documentación y código fuente. Con lo que hay
al terminar la Fase 1 y parte de la Fase 2 se cubre:

- **Plan y diseño:** este documento, el PRD y los tres ADR.
- **Documentación:** la base de conocimiento (glosario, entidades, reglas) —
  que además es el contenido experto del sistema, no relleno.
- **Código fuente:** esqueleto ASDF, catálogo cargable y el motor hasta donde
  llegue, con su suite de pruebas pasando.
- **Proceso:** el gate `verify.sh` en verde y la cola `tasks.json` mostrando
  qué está hecho y qué falta. Esto último distingue el trabajo de un montón de
  archivos sueltos.

---

## Estado actual del repositorio

| Elemento | Estado |
| -------- | ------ |
| Documentación de diseño | Completa y publicada (`9df7cf3`) |
| Código de implementación | **Ninguno.** Correcto: el Architect no lo escribe |
| Cola de tareas | 14 pendientes, T001 elegible |
| Gate de verificación | En rojo: no hay fuentes Lisp que verificar. Pasa a verde con T001 |

El gate en rojo no es un defecto. `.ace/scripts/verify-lisp.sh` falla
deliberadamente cuando no encuentra fuentes, porque un gate que aprueba el
silencio no es un gate. La primera vez que pase será con código real.

Estado de la cola, en cualquier momento:

```bash
npx -y -p create-ace-framework@2.7.0 ace-framework loop --dry-run
```

---

## Verificación

Cada tarea se cierra contra el mismo gate:

```bash
sh .ace/scripts/verify.sh
```

que compila todos los fuentes con SBCL y corre la suite. Una tarea no está
terminada hasta que el gate imprime `VERIFY_RESULT=pass`.

### Criterios de aceptación del sistema completo

| # | Criterio | Cómo se comprueba |
| - | -------- | ----------------- |
| 1 | Ninguna recomendación viola un requisito | Prueba de invariante sobre todos los perfiles de ejemplo |
| 2 | Ninguna recomendación choca con el horario | Ídem |
| 3 | Toda recomendación tiene explicación no vacía | Prueba automatizada (BR-020) |
| 4 | El motor es genérico | Su suite usa solo hechos inventados |
| 5 | Se puede agregar una regla sin tocar el motor | Prueba de extensibilidad (NFR-004) |
| 6 | El motor termina siempre | Prueba de refracción con regla auto-reactivante |
| 7 | Misma entrada, misma salida | Prueba de determinismo, traza idéntica en corridas repetidas |
| 8 | Catálogo entre 40 y 60 cursos | Prueba sobre `data/courses.lisp` |
| 9 | Ambas familias de estadísticas presentes | Pruebas de `stats.lisp` |
| 10 | Sesión completa en menos de 2 s | Medición en la demostración |

---

## Riesgos y mitigaciones

Ver el detalle en el PRD. Los tres que gobiernan el cronograma:

| Riesgo | Mitigación en este plan |
| ------ | ----------------------- |
| El matching con variables consume el cronograma | Es T004, temprano y aislado, con pruebas propias antes de que nada dependa de él |
| Las reglas terminan cableadas en Lisp | T014 incluye la prueba de extensibilidad; si falla, el diseño se violó |
| Las estadísticas quedan a medias | T010 y T011 tienen tarea y semana propias, no son un extra |

---

## Trabajo futuro (fuera de alcance)

Documentado para la defensa del proyecto, no para implementar:

- Red RETE en lugar de matching ingenuo (ADR-005, alternativa 2).
- Encadenamiento hacia atrás para consultas puntuales sobre un curso.
- Modelado del plan de estudios completo.
- Horarios con horas exactas y traslapes parciales (ADR-006).
- Interfaz web (ADR-004, alternativa 3).

---

## Referencias

- `docs/requirements/PRD-recomendador-academico.md`
- `docs/context/PROJECT_CONTEXT.md`
- `docs/adr/ADR-004-stack-tecnologico.md`
- `docs/adr/ADR-005-motor-inferencia.md`
- `docs/adr/ADR-006-representacion-conocimiento.md`
- `.ace/knowledge/business-rules.md`
- `.ace/standards/lisp.md`
