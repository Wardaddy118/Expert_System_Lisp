# Plan de Implementación: Sistema Experto de Recomendaciones Académicas

> **Status:** En ejecución — Fases 1 a 3 y parte de la Fase 4 verificadas
> **Creado:** 2026-08-05
> **Última actualización:** 2026-08-05 (implementación de la primera
> versión funcional en `feature/initial-lisp-implementation`)
> **Autor:** Architect (rol ACE); implementación por rol Developer
> **PRD:** `docs/requirements/PRD-recomendador-academico.md`
> **Cola de tareas:** `docs/progress/tasks.json` (11 de 14 verificadas)
> **Línea base:** commit `9df7cf3` en `origin/main`
> **Estado detallado y decisiones tomadas durante la implementación:**
> `docs/context/ACTIVE_CONTEXT.md`

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
- [x] Carrera y universidad a modelar confirmadas: Bachillerato en
      Ingeniería en Sistemas de Computación, Universidad Fidélitas
      (catálogo real de 47 cursos en `data/courses.lisp`)
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

Fechas confirmadas por el equipo el 2026-08-06. **Estamos en la semana 13**, no
en la 11: el proyecto va adelantado respecto al plan original, porque las fases
1 a 3 y buena parte de la 4 se completaron en una sola sesión de
implementación.

| Semana | Fecha | Entregable | Estado |
| ------ | ----- | ---------- | ------ |
| 13 | 2026-08-05 | Documentación de arquitectura completa | ✅ Hecho |
| 13 | 2026-08-05 | Motor de inferencia funcional y probado (Fases 1 y 2) | ✅ Hecho |
| 13 | 2026-08-05 | Base de conocimiento y recomendaciones correctas (Fase 3) | ✅ Hecho |
| 13 | 2026-08-05 | Explicaciones desde la traza | ✅ Hecho |
| 13 | 2026-08-06 | Estadísticas de estudiante y de catálogo (T010, T011) | ✅ Hecho |
| **13** | **2026-08-06 (jueves)** | **ENTREGA DEL BORRADOR** | ⏳ Hoy |
| 14 | 2026-08-13 | CLI interactiva (T012) y perfiles de demostración (T013) | ⬜ Pendiente |
| **15** | **2026-08-20 (jueves)** | **ENTREGA FINAL: sistema 100% funcional** (T014) | ⬜ Pendiente |

> La fecha de la semana 15 se interpretó como el jueves 20 de agosto, dos
> semanas después del borrador. Si el profesor se refería al jueves 13,
> corregir aquí y comprimir la semana 14.

### Qué queda para la entrega final

Dos semanas para tres tareas, con el sistema ya funcionando de punta a punta:

- **T012** captura interactiva del perfil. Hoy la sesión carga un perfil fijo.
- **T013** perfiles de demostración, con el criterio de cierre de la decisión
  D-09 (ejercitar las tres reglas que nunca disparan, o eliminarlas).
- **T014** suite de aceptación formalizada.

Nada de esto es riesgo de cronograma: el motor, el dominio y las estadísticas
—que era lo difícil— ya están verificados.

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
| Código de implementación | Primera versión funcional, rama `feature/initial-lisp-implementation` |
| Cola de tareas | 11 de 14 verificadas (T001–T011); T012–T014 pendientes |
| Gate de verificación | En verde: compila el sistema con ASDF y corre la suite completa |
| Suite de pruebas | 235 comprobaciones, 0 fallos (`sbcl --script run-tests.lisp`) |
| Catálogo de datos | 47 cursos reales (Fidélitas); ver `docs/context/ACTIVE_CONTEXT.md` para qué campos son oficiales y cuáles provisionales |

El gate compila con éxito desde que existe código real (Fase 1). Sigue
pendiente reapuntar `verify.test_cmd` en `.aceconfig` de
`sh .ace/scripts/verify-lisp.sh` a `asdf:test-system :expert-system/tests`,
para que verifique comportamiento (la suite de 182 pruebas) y no solo
compilación — ver la nota de T001 en `docs/progress/tasks.json`.

Estado de la cola, en cualquier momento:

```bash
npx -y -p create-ace-framework@2.7.0 ace-framework loop --dry-run
```

Para el detalle sesión a sesión — qué es oficial, qué es provisional en los
datos, y la próxima tarea recomendada — ver `docs/context/ACTIVE_CONTEXT.md`,
que es la fuente de verdad volátil; este documento es el plan estable.

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

**Estado 2026-08-05:** 1–8 verificados por la suite actual (182 pruebas,
`sbcl --script run-tests.lisp`). El criterio 9 solo parcialmente: existen
estadísticas del estudiante (T010), no del catálogo (T011, pendiente). El
criterio 10 no se ha medido formalmente; la demostración con 47 cursos y 25
reglas corre en menos de un segundo en desarrollo, pero no hay una prueba
que lo verifique.

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
