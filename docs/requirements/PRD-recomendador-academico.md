# PRD: Sistema Experto de Recomendaciones Académicas

> **Status:** Draft
> **Autor:** Architect (rol ACE)
> **Última actualización:** 2026-08-05
> **Stakeholders:** Equipo de desarrollo, profesor del curso

---

## Resumen ejecutivo

Sistema experto en Common Lisp que recomienda cursos universitarios a un
estudiante a partir de sus intereses, cursos aprobados, horario disponible,
tolerancia a la dificultad y área profesional de interés. Además de la
recomendación, el sistema **explica** por qué recomendó cada curso —listando
las reglas que dispararon— y entrega estadísticas sobre el avance del
estudiante y sobre el catálogo de cursos.

El valor del proyecto no está en ordenar una lista: está en que un motor de
inferencia propio, con reglas declarativas y trazabilidad, produce y justifica
la recomendación.

---

## Planteamiento del problema

### Situación actual

La selección de cursos cada semestre la hace el estudiante manualmente,
cruzando a mano el plan de estudios, los requisitos aprobados, los choques de
horario y su interés profesional. La orientación académica formal es escasa y
no escala: un orientador no puede revisar el expediente de cada estudiante
cada semestre.

### Puntos de dolor

- Los requisitos entre cursos forman un grafo que es difícil de razonar
  mentalmente; se descubren tarde los cursos "cuello de botella".
- El estudiante no ve el impacto de matricular un curso en su ruta de
  graduación.
- Las decisiones se toman sin considerar la carga real del semestre
  (dificultad combinada), lo que produce sobrecarga y reprobación.
- No hay explicación: cuando alguien recomienda un curso, no queda registro
  del razonamiento.

### Impacto

Matrícula subóptima: atraso en la graduación, semestres sobrecargados y
cursos de interés que se descubren cuando ya no hay espacio para tomarlos.

---

## Objetivos

### Objetivos primarios

1. Recomendar un conjunto de cursos elegibles y priorizados para el próximo
   semestre, a partir del perfil completo del estudiante.
2. Justificar cada recomendación con la cadena de reglas que la produjo.
3. Entregar estadísticas del estudiante y del catálogo que sustenten la
   decisión de matrícula.

### Métricas de éxito

| Métrica | Objetivo | Método de medición |
| ------- | -------- | ------------------ |
| Cobertura del catálogo | 40–60 cursos modelados con requisitos reales | Conteo sobre `data/courses.lisp` |
| Reglas en la base de conocimiento | ≥ 25 reglas declarativas | Conteo de formas `defrule` |
| Trazabilidad | 100% de las recomendaciones con explicación no vacía | Prueba automatizada sobre casos de ejemplo |
| Corrección de requisitos | 0 recomendaciones que violen un requisito | Prueba de invariante sobre todos los perfiles de prueba |
| Cobertura de pruebas | Cada regla con al menos un caso que la dispare | Suite FiveAM |
| Gate verde | `verify.sh` en `pass` en la entrega | `VERIFY_RESULT=pass` |

### No-objetivos

- **No** es un sistema de matrícula: no reserva cupos ni se conecta al sistema
  de la universidad.
- **No** tiene interfaz web ni gráfica (decisión D-02).
- **No** usa aprendizaje automático. Es un sistema experto basado en reglas;
  el conocimiento es explícito y auditable.
- **No** modela la malla curricular completa de la carrera (decisión D-03).
- **No** persiste el historial entre ejecuciones más allá de archivos de
  perfil cargables.

---

## Historias de usuario

### Persona: Estudiante universitario

**Como** estudiante de una carrera de ingeniería
**quiero** indicar qué aprobé, qué me interesa y cuánto tiempo tengo
**para** recibir una lista priorizada de cursos que sí puedo llevar el próximo
semestre.

**Criterios de aceptación:**

- [ ] La CLI captura: cursos aprobados, áreas de interés, bloques de horario
      disponibles, tolerancia a dificultad y área profesional objetivo.
- [ ] El sistema nunca recomienda un curso cuyos requisitos no estén
      aprobados.
- [ ] El sistema nunca recomienda un curso que choque con el horario
      declarado.
- [ ] La lista sale ordenada por prioridad, con la prioridad visible.

### Persona: Estudiante que cuestiona la recomendación

**Como** estudiante
**quiero** ver por qué el sistema me recomendó cada curso
**para** poder confiar en la recomendación o descartarla con criterio.

**Criterios de aceptación:**

- [ ] Para cada curso recomendado se pueden listar las reglas que dispararon.
- [ ] Cada regla mostrada indica los hechos que la activaron.
- [ ] La explicación es legible para alguien que no programa.

### Persona: Profesor / evaluador del curso

**Como** evaluador
**quiero** inspeccionar la base de conocimiento y la traza de inferencia
**para** verificar que existe un motor de inferencia real y no lógica cableada.

**Criterios de aceptación:**

- [ ] Las reglas están declaradas como datos, separadas del motor.
- [ ] Se puede ejecutar el motor en modo traza y ver el ciclo
      match → seleccionar → disparar.
- [ ] Se puede agregar una regla nueva sin tocar el código del motor.

---

## Requisitos

### Requisitos funcionales

| ID | Requisito | Prioridad | Notas |
| -- | --------- | --------- | ----- |
| FR-001 | Cargar el catálogo de cursos desde `data/courses.lisp` | Must | S-expressions, sin recompilar |
| FR-002 | Cargar/capturar el perfil del estudiante (aprobados, intereses, horario, dificultad, área) | Must | Vía CLI o archivo de perfil |
| FR-010 | Motor de encadenamiento hacia adelante con memoria de trabajo, agenda y resolución de conflictos | Must | Núcleo del proyecto (ADR-005) |
| FR-011 | Macro `defrule` para declarar reglas como datos | Must | Reglas fuera del motor |
| FR-012 | Pattern matching con variables y unificación sobre hechos | Must | |
| FR-013 | Resolución de conflictos por prioridad de regla y recencia del hecho | Must | Determinista y documentada |
| FR-014 | Modo traza del ciclo de inferencia | Should | Requisito de evaluación |
| FR-020 | Verificar requisitos: un curso es elegible solo si todos sus requisitos están aprobados | Must | Invariante duro (BR-001) |
| FR-021 | Descartar cursos ya aprobados | Must | BR-002 |
| FR-022 | Descartar cursos que chocan con el horario disponible | Must | BR-003 |
| FR-023 | Ponderar por afinidad con las áreas de interés del estudiante | Must | |
| FR-024 | Ponderar por afinidad con el área profesional objetivo | Must | |
| FR-025 | Ajustar por tolerancia a la dificultad declarada | Must | |
| FR-026 | Priorizar cursos cuello de botella (los que desbloquean más cursos) | Should | Aporta valor real de orientación |
| FR-027 | Respetar un tope de créditos/carga por semestre | Must | BR-004 |
| FR-030 | Explicar cada recomendación listando reglas disparadas y hechos que las activaron | Must | Diferenciador del sistema experto |
| FR-040 | Estadísticas del estudiante: avance de carrera, créditos aprobados vs. totales, distribución por área, carga estimada | Must | Decisión D-04 |
| FR-041 | Estadísticas del catálogo: cursos más recomendados, cuellos de botella, dificultad promedio por área, cobertura de reglas | Must | Decisión D-04 |
| FR-050 | CLI interactiva de sesión completa (captura → inferencia → resultados → explicación → estadísticas) | Must | D-02 |
| FR-051 | Cargar perfiles de ejemplo para la demostración | Should | Facilita la defensa del proyecto |

### Requisitos no funcionales

| ID | Requisito | Objetivo | Notas |
| -- | --------- | -------- | ----- |
| NFR-001 | Rendimiento | Sesión completa < 2 s con 60 cursos y 30 reglas | Suficiente para CLI |
| NFR-002 | Portabilidad | Carga en SBCL; lo específico de SBCL aislado en `src/main.lisp` | ANSI Common Lisp |
| NFR-003 | Auditabilidad | Toda regla legible sin ejecutar el código | Requisito del curso |
| NFR-004 | Extensibilidad | Agregar una regla no requiere modificar el motor | Verificable con una prueba |
| NFR-005 | Reproducibilidad | Misma entrada ⇒ misma salida (resolución de conflictos determinista) | Sin dependencia de orden de hash |
| NFR-006 | Verificabilidad | `.ace/scripts/verify.sh` compila y corre la suite | Gate de la entrega |

---

## Experiencia de usuario

### Flujo principal

```text
[1. El estudiante inicia la sesión CLI]
        ↓
[2. El sistema pregunta cursos aprobados]
        ↓
[3. El sistema pregunta áreas de interés y área profesional objetivo]
        ↓
[4. El sistema pregunta bloques de horario disponibles y tolerancia a dificultad]
        ↓
[5. Los datos se afirman como hechos en la memoria de trabajo]
        ↓
[6. El motor corre hasta quiescencia (ninguna regla más por disparar)]
        ↓
[7. Se presentan los cursos recomendados, ordenados por prioridad]
        ↓
[8. El estudiante pide la explicación de un curso → se listan las reglas disparadas]
        ↓
[9. Se muestran las estadísticas del estudiante y del catálogo]
```

### Casos borde

| Escenario | Comportamiento esperado |
| --------- | ----------------------- |
| Estudiante de primer ingreso (sin aprobados) | Recomienda únicamente cursos sin requisitos |
| Ningún curso pasa los filtros | Mensaje explícito indicando qué filtro eliminó todo, no lista vacía muda |
| El horario disponible es demasiado estrecho | Se avisa que el horario es el factor limitante y se sugiere ampliarlo |
| Curso aprobado que no existe en el catálogo | Advertencia y se ignora; no se aborta la sesión |
| Requisito circular en los datos del catálogo | Se detecta al cargar y se reporta como error de datos |
| Todos los cursos de interés ya están aprobados | Se recomienda por área profesional y por cuellos de botella |
| Tope de créditos menor que el curso más pequeño | Se explica que no cabe ningún curso con esa restricción |

---

## Consideraciones técnicas

### Dependencias

- SBCL 2.6.7 (implementación de referencia)
- ASDF (gestión del sistema)
- Quicklisp (obtención de dependencias)
- FiveAM (pruebas)

Sin dependencias de motores de reglas externos: es una decisión, no una
omisión (ADR-005).

### Restricciones

- Entrega funcional en semana 15, con equipo estudiantil y tiempo parcial.
- El motor debe escribirse desde cero (D-01).
- Sin interfaz web (D-02).

### Riesgos

| Riesgo | Probabilidad | Impacto | Mitigación |
| ------ | ------------ | ------- | ---------- |
| El pattern matching con variables se subestima y consume el cronograma | Alta | Alto | Es la tarea T003, temprana y aislada, con pruebas propias antes de construir reglas encima |
| La captura del catálogo (40–60 cursos) se pospone y bloquea las pruebas | Media | Alto | T002 va en paralelo al motor; es trabajo de datos, no de código |
| Las reglas terminan cableadas en Lisp por presión de tiempo | Media | Alto | Prueba de extensibilidad (NFR-004): agregar una regla sin tocar el motor |
| Bucle infinito en el motor por reglas que se reactivan | Media | Medio | Refracción: un mismo binding no vuelve a disparar la misma regla |
| Estadísticas dejadas para el final y entregadas a medias | Media | Medio | T010/T011 con tarea y semana propias, no como "si sobra tiempo" |
| Sobrecarga documental del framework ACE vs. tiempo de código | Baja | Medio | La documentación pesada ya está hecha en esta fase |

---

## Cronograma

Ver `docs/planning/implementation_plan.md` §Cronograma. Las fechas del
calendario académico están **pendientes de confirmar**.

| Hito | Semana | Dependencias |
| ---- | ------ | ------------ |
| Entrega del borrador | Por confirmar | Documentación de arquitectura + esqueleto de código + motor mínimo |
| Motor de inferencia funcional | Semana 11 | T001–T004 |
| Base de conocimiento completa | Semana 12 | T002, T005 |
| Recomendaciones + explicación | Semana 13 | T005, T006 |
| Estadísticas | Semana 14 | T007, T008 |
| Sistema 100% funcional y documentado | Semana 15 | Todas |

---

## Preguntas abiertas

Quedan **dos**, y ninguna se puede decidir internamente: dependen de hechos
externos al equipo.

- [ ] ¿Cuáles son las fechas del calendario para el borrador y la semana 15?
- [ ] ¿El profesor exige un formato específico de informe además del código?

Ambas se resuelven con un mensaje al profesor. Ninguna bloquea el código.

### Ya resueltas — no reabrir sin ADR

| Pregunta | Resolución |
| -------- | ---------- |
| ¿Horario por bloques o por hora exacta? | Bloques discretos `(día franja)` — ADR-006 |
| ¿Qué carrera y universidad? | Bachillerato en Ing. en Sistemas de Computación, Universidad Fidélitas — 47 cursos en `data/courses.lisp` |
| ¿Con qué criterio se asigna la dificultad 1–5? | Fórmula cuatrimestre + laboratorio, tope 5 — decisión D-05 |
| ¿Los pesos de priorización BR-010 a BR-015? | Ratificados como están — decisión D-06 |
| ¿El umbral de cuello de botella (3)? | Se mantiene en 3 — decisión D-07 |
| ¿La excepción de BR-005? | Se mantiene — decisión D-08 |
| ¿Qué hacer con las reglas que nunca disparan? | Se conservan; T013 debe ejercitarlas o se eliminan — decisión D-09 |
| ¿Se espera a los datos oficiales? | No: se entrega con los provisionales, etiquetados — decisión D-10 |
| ¿Cómo se reparten las tareas? | Quedan 3 (T012–T014) y están en curso; el equipo aporta datos oficiales si los consigue |

El detalle y la justificación de D-05 a D-10 están en
[PROJECT_CONTEXT.md](../context/PROJECT_CONTEXT.md#decisiones-de-criterio-experto-ratificadas-2026-08-05).

---

## Apéndice

### Glosario

Ver `.ace/knowledge/glossary.md` para el glosario completo del dominio y del
motor.

### Referencias

- `docs/context/PROJECT_CONTEXT.md` — decisiones de la fase DISCUSS
- `docs/adr/ADR-005-motor-inferencia.md` — diseño del motor
- `docs/adr/ADR-006-representacion-conocimiento.md` — representación de hechos y reglas
- `.ace/knowledge/business-rules.md` — reglas del dominio (BR-xxx)

---

## Aprobación

| Rol | Nombre | Fecha | Firma |
| --- | ------ | ----- | ----- |
| Equipo | | | |
| Profesor | | | |

---

*Este PRD sigue los estándares de documentación de ACE-Framework*
