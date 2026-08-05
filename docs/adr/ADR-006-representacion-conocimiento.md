# ADR-006: Representación del conocimiento

> **Status:** Accepted
> **Fecha:** 2026-08-05
> **Decisión asociada:** D-03 (`docs/context/PROJECT_CONTEXT.md`)

---

## Contexto

El motor de ADR-005 opera sobre hechos y reglas, pero no define su forma. Hay
que decidir cómo se representan tres cosas distintas que suelen confundirse:

1. **El catálogo** — datos estables del plan de estudios: cursos, créditos,
   requisitos, área, dificultad, horario.
2. **El perfil del estudiante** — datos de una sesión: qué aprobó, qué le
   interesa, cuándo puede.
3. **Las conclusiones** — lo que el motor deriva: elegibilidad, prioridad,
   recomendación.

Si las tres viven en el mismo formato sin distinción, el motor no puede
distinguir un dato de entrada de una conclusión propia, y la explicación
pierde sentido. Si viven en formatos distintos, el motor necesita saber de
cada uno y deja de ser genérico.

Restricción de alcance (D-03): 40–60 cursos de una carrera real, con
requisitos reales, simplificando lo que haga falta y documentando qué se
simplificó.

---

## Decisión

### Hechos: listas planas con símbolo de tipo al frente

Todo lo que entra a la memoria de trabajo es una lista cuyo primer elemento es
un símbolo que nombra la relación:

```lisp
;; Del catálogo (afirmados al cargar data/courses.lisp)
(course       "CI-2400")
(course-name  "CI-2400" "Estructuras de Datos")
(credits      "CI-2400" 4)
(area         "CI-2400" algorithms)
(difficulty   "CI-2400" 4)
(prerequisite "CI-2400" "CI-1201")
(schedule     "CI-2400" monday morning)

;; Del perfil del estudiante
(approved     "CI-1201")
(interest     algorithms)
(target-area  software-engineering)
(available    monday morning)
(difficulty-tolerance 3)
(credit-limit 16)

;; Derivados por el motor
(prerequisites-satisfied "CI-2400")
(eligible                "CI-2400")
(schedule-fits           "CI-2400")
(priority                "CI-2400" 27)
(recommended             "CI-2400")
```

Reglas de forma:

- **Un hecho, una afirmación.** Nada de estructuras anidadas ni property
  lists. `(prerequisite "CI-2400" "CI-1201")` repetido varias veces, no
  `(prerequisite "CI-2400" ("CI-1201" "MA-1001"))`. El pattern matching sobre
  listas planas es simple; sobre estructuras anidadas se vuelve un problema
  aparte.
- **Los identificadores de curso son strings**, comparados con `equal`. Los
  símbolos como `CI-2400` se leerían en mayúsculas y dependerían del
  readtable.
- **Las categorías son símbolos** (`algorithms`, `monday`, `morning`). Son
  vocabulario cerrado, definido en `.ace/knowledge/glossary.md`.

### Los tres tipos se distinguen por relación, no por marca

No se etiquetan los hechos como "dato" o "conclusión". La distinción está en
qué relaciones usa cada capa: `course`/`credits`/`prerequisite` solo las
afirma el cargador de datos; `eligible`/`priority`/`recommended` solo las
produce el motor. Esa disciplina está documentada en
`.ace/knowledge/entities.md` y es lo que hace la traza legible.

### El catálogo vive en `data/`, en S-expressions

`data/courses.lisp` contiene una lista de descripciones de curso, leída con
`read` y expandida a hechos por el cargador:

```lisp
(("CI-2400" :name "Estructuras de Datos"
            :credits 4
            :area algorithms
            :difficulty 4
            :prerequisites ("CI-1201")
            :schedule ((monday morning) (wednesday morning)))
 ...)
```

La forma legible por humanos (property list, requisitos agrupados) es de
**entrada**; el cargador la normaliza a hechos planos. Editar el catálogo es
cómodo y el motor sigue viendo hechos simples.

Los perfiles de ejemplo para la demostración viven en `data/profiles/`, en el
mismo estilo.

### El horario se modela por bloques discretos

`(día franja)` con franjas `morning`, `afternoon`, `evening`. No se modelan
horas exactas. Un choque de horario es la intersección no vacía de dos
conjuntos de bloques.

Es una simplificación consciente: modelar horas exactas y traslapes parciales
convertiría el proyecto en un problema de scheduling, que no es el objetivo.
Queda registrada como tal.

### La dificultad es una escala entera 1–5

Declarada en el catálogo, comparada contra la `difficulty-tolerance` del
estudiante. No se calcula ni se infiere de datos históricos: es conocimiento
experto explícito, que es justamente lo que un sistema experto codifica.

---

## Alternativas consideradas

### Alternativa 1: Estructuras CLOS para los cursos

Definir `defclass course` con slots.

- **Pros:** Idiomático en Common Lisp moderno, con validación de tipos.
- **Contras:** El motor tendría que saber leer objetos CLOS, o habría que
  aplanarlos a hechos igual. Se gana verbosidad sin ganar nada en el motor.
- **Por qué se rechazó:** El motor opera sobre hechos. Un objeto CLOS que hay
  que aplanar antes de usarse es un paso intermedio sin beneficio.

### Alternativa 2: Hechos como property lists o hash tables

`(:type course :id "CI-2400" :credits 4)`.

- **Pros:** Autodescriptivos, extensibles sin cambiar el matcher.
- **Contras:** El pattern matching posicional deja de funcionar; habría que
  escribir matching por claves, más complejo y más lento.
- **Por qué se rechazó:** Complica la pieza más delicada del proyecto
  (ADR-005) para resolver un problema que no tenemos.

### Alternativa 3: Requisitos agrupados en un solo hecho

`(prerequisites "CI-2400" ("CI-1201" "MA-1001"))`.

- **Pros:** Menos hechos en memoria.
- **Contras:** Obliga al matcher a manejar listas dentro de patrones, o a que
  las reglas hagan `every` sobre listas — lógica de dominio que se filtra
  dentro de las reglas.
- **Por qué se rechazó:** Un hecho por requisito deja que el motor haga el
  trabajo con matching puro, que es lo que se quiere demostrar.

### Alternativa 4: Modelar la malla curricular completa

- **Pros:** Más realista.
- **Contras:** La captura de datos se come el tiempo del motor.
- **Por qué se rechazó:** Decisión D-03. 40–60 cursos bastan para que las
  estadísticas del catálogo sean significativas.

---

## Consecuencias

### Positivas

- El matcher solo necesita unificar listas planas: es la versión más simple
  posible de la pieza más riesgosa.
- El catálogo se edita sin recompilar y sin parser externo.
- La traza es legible: cada línea es una relación en español técnico, no un
  volcado de objetos.
- Separar relaciones de entrada de relaciones derivadas hace que la
  explicación tenga sentido sin trabajo extra.

### Negativas

- Muchos hechos pequeños: un curso con 3 requisitos y 4 bloques de horario
  genera ~12 hechos. Con 60 cursos son cientos de hechos en memoria. A esta
  escala no es problema, pero hace el matching ingenuo más lento.
- Los bloques discretos de horario no capturan traslapes parciales reales.
  Limitación conocida y documentada.
- La dificultad declarada a mano es subjetiva. Hay que documentar el criterio
  usado para asignarla, o el evaluador lo cuestionará con razón.

### Neutras

- El vocabulario cerrado de símbolos (áreas, días, franjas) exige mantener
  `.ace/knowledge/glossary.md` al día. Es disciplina, no costo técnico.

---

## Cumplimiento

- El cargador de datos valida al arrancar: identificadores duplicados,
  requisitos que apuntan a cursos inexistentes y ciclos en el grafo de
  requisitos son errores de datos y se reportan (caso borde del PRD).
- Una prueba verifica que todos los símbolos de área usados en
  `data/courses.lisp` están en el vocabulario del glosario.
- Una prueba verifica que el catálogo tiene entre 40 y 60 cursos (D-03).
- Revisión: ninguna regla del dominio debe usar `every`, `some` ni `mapcar`
  sobre listas dentro de un hecho. Si lo necesita, el hecho está mal
  modelado.

---

## Referencias

- `docs/adr/ADR-005-motor-inferencia.md` — el motor que consume estos hechos
- `.ace/knowledge/entities.md` — catálogo completo de relaciones
- `.ace/knowledge/glossary.md` — vocabulario cerrado de símbolos
- `.ace/knowledge/business-rules.md` — reglas del dominio
