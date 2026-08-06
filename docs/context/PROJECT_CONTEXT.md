# Project Context & Preferences

> Salida de la **fase DISCUSS** (`.ace/workflows/discuss-phase.md`).
> Estas decisiones son **restricciones estrictas** para la fase PLAN y para
> todo agente que trabaje en el repositorio. Cambiarlas exige un ADR nuevo.
> A diferencia de ACTIVE_CONTEXT.md (volátil por sesión), este archivo persiste.

**Proyecto:** Sistema Experto de Recomendaciones Académicas
**Rol que lo produjo:** Architect
**Fecha:** 2026-08-05
**Idioma:** documentación y comentarios en español; símbolos, nombres de
funciones y mensajes de commit en inglés.

---

## Decisiones de arquitectura (DISCUSS)

| # | Área | Decisión | ADR |
| - | ---- | -------- | --- |
| D-01 | Motor de inferencia | **Escrito desde cero en Common Lisp puro**: encadenamiento hacia adelante, pattern matching con variables, agenda y resolución de conflictos explícita. Sin LISA ni CLIPS. | [ADR-005](../adr/ADR-005-motor-inferencia.md) |
| D-02 | Interfaz | **CLI interactiva sobre SBCL**. Sesión de preguntas y respuestas por consola. Sin capa web. | [ADR-004](../adr/ADR-004-stack-tecnologico.md) |
| D-03 | Datos de cursos | **Plan de estudios real simplificado**: subconjunto representativo de 40–60 cursos de una carrera real, con requisitos reales. Ni scraping ni catálogo inventado. | [ADR-006](../adr/ADR-006-representacion-conocimiento.md) |
| D-04 | Estadísticas | **Del estudiante y del catálogo**. Ambas familias son requisito, no opcional. | [PRD §FR-040](../requirements/PRD-recomendador-academico.md) |

---

## Decisiones de criterio experto (ratificadas 2026-08-05)

Estas seis estaban marcadas como "pendientes de ratificar": había un valor
propuesto, pero nadie se había hecho responsable de él. **Ya están decididas.**
Cambiarlas ahora exige un ADR.

| # | Decisión | Qué se decidió |
| - | -------- | -------------- |
| D-05 | Criterio de dificultad | Se ratifica la fórmula: cuatrimestre (1–2 → 2, 3–5 → 3, 6–8 → 4) más 1 si el curso tiene laboratorio, con tope 5 |
| D-06 | Pesos de priorización | Se ratifican los de BR-010 a BR-015 tal como están |
| D-07 | Umbral de cuello de botella | Se mantiene en 3 cursos dependientes |
| D-08 | Excepción de BR-005 | Se mantiene: un cuello de botella que excede la tolerancia por un nivel se recomienda con advertencia |
| D-09 | Reglas que nunca disparan | Se conservan las tres, con criterio de cierre (abajo) |
| D-10 | Datos oficiales faltantes | Se entrega con los provisionales, etiquetados como tales |

### D-05 — Por qué esta fórmula de dificultad

Es **reproducible y auditable**: se deriva de dos datos que sí son oficiales
—el cuatrimestre del curso y si tiene laboratorio— con una regla que cualquiera
puede recalcular. La alternativa real no era una medición, era que cada quien
pusiera un número a ojo, y eso no se puede defender ante nadie.

Supone que los cuatrimestres avanzados y los cursos con laboratorio exigen más.
Es una hipótesis del equipo, no un dato medido, y se presenta siempre así:
**heurística del equipo, nunca clasificación de la Universidad Fidélitas.**

### D-06 — Por qué estos pesos

- El **área objetivo (+10)** pesa más que un **interés suelto (+5)** porque es
  la decisión de carrera, no una preferencia puntual.
- El **cuello de botella (+8)** pesa casi tanto como el área objetivo porque
  atrasarlo tiene costo estructural: bloquea el avance completo.
- **Desbloquear un curso del área objetivo (+4)** es un efecto de segundo
  orden, y por eso vale menos que serlo directamente.
- **−2 por estar muy por debajo de la tolerancia** evita llenar la lista de
  cursos triviales que no aportan a la carga del semestre.

Producen separación real, no empates: en la demo actual el primer recomendado
saca 27 y el segundo 15.

### D-07 — Por qué el umbral se queda en 3

Con los prerrequisitos provisionales actuales, solo SC-304 llega a 3 y podría
tentar bajarlo a 2 para "que salgan más". Eso sería **ajustar la regla a los
datos**, que es exactamente al revés de como debe hacerse. El umbral responde a
qué significa ser cuello de botella, no a cuántos queremos ver hoy.

### D-09 — Criterio de cierre para las reglas que no disparan

Hoy tres de las 25 reglas nunca disparan:
`bottleneck-exception-to-tolerance`, `priority-general-education` y
`recommended-via-general-education`. Las tres **se conservan por ahora**,
porque la hipótesis es que el problema son los datos y no las reglas.

**T013 debe crear los perfiles que las ejerciten.** Y este es el criterio de
cierre, que no admite interpretación:

> Si al terminar T013 alguna regla sigue sin disparar, **se elimina.** Una
> regla que no se puede activar ni con perfiles diseñados a propósito para
> activarla es conocimiento muerto, y conocimiento muerto en la base es peor
> que no tenerlo: infla el conteo y no se puede defender.

### D-10 — Se entrega con datos provisionales, etiquetados

No hay créditos, prerrequisitos ni horarios oficiales, y no depende de nosotros
conseguirlos a tiempo. La decisión es **no bloquear la entrega esperándolos**:

- ADR-006 separa datos de código, así que si los datos oficiales llegan es un
  cambio en `data/` y **cero líneas de código**. No hay deuda técnica en
  esperar.
- Todo campo provisional está marcado curso por curso en `data/courses.lisp` y
  resumido en `ACTIVE_CONTEXT.md`. Se presenta como heurística del equipo.
- Lo que **no** se hace: presentar un dato provisional como oficial, ni omitir
  la distinción para que el sistema se vea más completo.

La consecuencia honesta hay que decirla en la defensa: los cuellos de botella
que reporta el sistema son **correctos dado el grafo cargado**, y ese grafo es
de ejemplo. El razonamiento es real; los datos de entrada, parciales.

---

## Implicaciones que se derivan de lo anterior

### D-01 → El motor es el entregable central

- El motor de inferencia es lo que evalúa el curso. Cualquier decisión que
  reduzca el código propio del motor —usar una librería de reglas, delegar el
  matching a expresiones regulares, o resolver las recomendaciones con un
  `sort` y un `cond` gigante en vez de reglas— **contradice esta decisión y
  debe rechazarse en revisión**.
- Las reglas del dominio se declaran como datos (macro `defrule`), nunca como
  funciones Lisp cableadas. Si una regla no se puede leer sin ejecutar el
  código, está mal escrita.
- El sistema debe **explicar** cada recomendación enumerando las reglas que
  dispararon y los hechos que las activaron. Sin trazabilidad no hay sistema
  experto, hay un filtro.

### D-02 → La interfaz no debe crecer

- La CLI se limita a: capturar el perfil del estudiante, disparar el motor,
  presentar recomendaciones ordenadas, mostrar explicaciones y mostrar
  estadísticas.
- Nada de Hunchentoot, nada de HTML, ninguna dependencia de UI. Si sobra
  tiempo en la semana 14 se invierte en más reglas y más pruebas, no en una
  interfaz web.
- Salida en texto plano con `format`, legible en una terminal de 80 columnas
  para la demostración.

### D-03 → La base de cursos es dato, no código

- El catálogo vive en archivos S-expression bajo `data/`, cargables con `read`.
  No se compila catálogo dentro de los fuentes.
- 40–60 cursos es el objetivo: por debajo de 40 las estadísticas del catálogo
  pierden sentido; por encima de 60 la captura de datos consume el tiempo que
  necesita el motor.
- Se documenta la carrera y la universidad de origen, y se marca
  explícitamente qué se simplificó respecto al plan real.

### D-04 → Dos familias de estadísticas

- **Del estudiante:** avance de carrera, créditos aprobados vs. totales,
  distribución por área profesional, carga estimada del semestre propuesto.
- **Del catálogo:** cursos más recomendados, cursos cuello de botella (los que
  bloquean más cursos aguas abajo), dificultad promedio por área, cobertura de
  reglas.
- Ambas se calculan sobre la memoria de trabajo del motor, no con consultas
  aparte, para que sean coherentes con lo que el motor concluyó.

---

## Preferencias técnicas

### Lenguaje y entorno

- **Common Lisp ANSI**, implementación de referencia **SBCL 2.6.7**.
- Lo específico de SBCL se aísla en `src/main.lisp` para que el sistema pueda
  cargarse en otra implementación.
- Gestión de sistema con **ASDF**; dependencias vía **Quicklisp**.

### Estilo de código

- Ver `.ace/standards/lisp.md` (convenciones de paquetes, nombres, predicados,
  manejo de errores y estructura de archivos).

### Pruebas

- Framework **FiveAM**. Cada regla del motor y cada función pública lleva
  prueba.
- El gate `.ace/scripts/verify.sh` debe pasar antes de dar por terminada
  cualquier tarea.

### Documentación

- Todo entregable vive en `docs/`.
- Los ADR del proyecto se numeran **desde ADR-004**; ADR-001 a ADR-003
  pertenecen al framework ACE. Ver `docs/adr/README.md`.

### Control de versiones

- Commits atómicos, uno por tarea de `docs/progress/tasks.json`.
- Mensajes en inglés, en imperativo: `add forward-chaining agenda`.

---

## Restricciones del curso

- El **borrador** debe mostrar el avance real, cómo se piensa hacer, la
  documentación y el código fuente.
- En la **semana 15** el sistema debe estar 100% funcional, con código y
  documentación completos.
- Fechas exactas del calendario: **pendientes de confirmar**
  (ver `docs/planning/implementation_plan.md` §Cronograma).

---

*Producido en la fase DISCUSS del ciclo BMAD — ACE-Framework v2.7.0*
