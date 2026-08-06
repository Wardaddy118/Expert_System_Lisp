# Glosario del Dominio

> Definiciones canónicas del vocabulario del proyecto.
> Todo agente y toda persona del equipo debe usar estos términos tal cual, en
> código, comentarios y documentación. El vocabulario de símbolos es
> **cerrado**: un símbolo que no está aquí no debe aparecer en `data/`.

---

## Cómo usar este documento

1. Antes de nombrar algo, buscarlo aquí.
2. Los símbolos listados en "Vocabulario cerrado" son los únicos válidos en
   los archivos de datos. Una prueba automatizada lo verifica (ADR-006).
3. Agregar un término requiere revisión del equipo y actualizar este archivo
   en el mismo commit que lo introduce.

---

## Términos del motor de inferencia

**Hecho (fact)**
Una afirmación en la memoria de trabajo. Lista plana cuyo primer elemento es un
símbolo de relación: `(approved "CI-1201")`. Ver ADR-006.

**Memoria de trabajo (working memory)**
El conjunto de hechos que el motor conoce en un momento dado. Empieza con los
datos del catálogo y del perfil, y crece con las conclusiones.

**Regla (rule)**
Estructura declarativa con condiciones (`:when`), acciones (`:then`) y
prioridad. Declarada con `defrule`. Es dato, no código.

**Condición**
Patrón que debe encontrar correspondencia en la memoria de trabajo para que la
regla sea candidata. Puede llevar variables.

**Patrón (pattern)**
Lista que se compara contra un hecho, donde los elementos que empiezan con `?`
son variables: `(prerequisite ?course ?req)`.

**Variable**
Símbolo prefijado con `?`. Se liga en su primera aparición y debe coincidir
consistentemente en el resto de la regla.

**Binding (ligadura)**
Asociación entre una variable y el valor que tomó. Un conjunto de bindings es
el resultado de un match exitoso.

**Unificación / matching**
Proceso de comparar un patrón con un hecho produciendo bindings, o fallando.

**Instanciación**
Una regla junto con un conjunto concreto de bindings que satisface todas sus
condiciones. Es lo que se dispara, no la regla en abstracto.

**Conjunto de conflicto (conflict set)**
Todas las instanciaciones aplicables en el ciclo actual.

**Agenda**
El conjunto de conflicto ordenado por los criterios de resolución.

**Resolución de conflictos**
Criterio determinista para elegir qué instanciación dispara: prioridad de la
regla → recencia del hecho → orden de declaración. Ver ADR-005.

**Recencia**
Antigüedad relativa de un hecho, medida por su identificador de inserción
monótono. Un hecho más nuevo tiene id mayor.

**Refracción**
Regla del motor que impide que una misma instanciación (regla + bindings
idénticos) dispare dos veces. Sin refracción el motor entra en bucle infinito.

**Disparar (fire)**
Ejecutar las acciones `:then` de una instanciación, afirmando hechos nuevos.

**Quiescencia**
Estado en que ninguna instanciación queda por disparar. El motor termina ahí.

**Encadenamiento hacia adelante (forward chaining)**
Estrategia que parte de los datos y deriva conclusiones. La usada aquí.

**Traza (trace)**
Registro ordenado de cada disparo: regla, bindings, hechos que la activaron y
hechos producidos. Es el insumo de la explicación.

**Explicación**
Reconstrucción legible del razonamiento que llevó a recomendar un curso,
obtenida recorriendo la traza hacia atrás desde `(recommended ?id)`.

---

## Términos del dominio académico

**Curso**
Unidad del plan de estudios, identificada por un código string como
`"CI-2400"`.

**Requisito (prerequisite)**
Curso que debe estar aprobado antes de poder llevar otro. Se modela un hecho
por par requisito–curso.

**Aprobado (approved)**
Curso que el estudiante ya cursó y ganó. Entrada del perfil.

**Elegible (eligible)**
Curso que el estudiante puede llevar: requisitos satisfechos, no aprobado ya,
y sin choque de horario. Conclusión del motor.

**Recomendado (recommended)**
Curso elegible que además superó los criterios de afinidad, dificultad y tope
de créditos. Es lo que se le presenta al estudiante.

**Prioridad (priority)**
Puntaje entero que ordena las recomendaciones. Se acumula por las reglas que
disparan sobre un curso.

**Área profesional (area)**
Clasificación temática del curso. Vocabulario cerrado, abajo.

**Área objetivo (target-area)**
Área profesional a la que el estudiante quiere dirigirse. Entrada del perfil.

**Interés (interest)**
Área que le atrae al estudiante, independiente de su área objetivo. Un
estudiante puede declarar varios.

**Dificultad (difficulty)**
Escala entera 1–5 declarada en el catálogo por criterio experto. No se infiere
de datos.

**Tolerancia a la dificultad (difficulty-tolerance)**
Escala 1–5 que declara el estudiante. Filtra cursos por encima de su umbral.

**Bloque de horario**
Par `(día franja)`. La unidad mínima de tiempo del modelo. No se manejan horas
exactas (ADR-006).

**Choque de horario**
Intersección no vacía entre los bloques de un curso y los de otro, o bloques
del curso fuera de la disponibilidad declarada.

**Cuello de botella (bottleneck)**
Curso que es requisito de muchos otros. Atrasarlo bloquea buena parte del plan,
por lo que el sistema lo prioriza.

**Carga (load)**
Suma de créditos de los cursos propuestos para un semestre. Limitada por
`credit-limit`.

**Avance de carrera**
Proporción de créditos aprobados sobre los créditos totales del plan modelado.

---

## Vocabulario cerrado

Estos son los únicos símbolos válidos en `data/`. Ampliarlos requiere
actualizar este archivo en el mismo commit.

### Áreas profesionales

**Importante:** esta clasificación es una inferencia del equipo a partir
del nombre de cada curso, **no** es una clasificación oficial de la
Universidad Fidélitas — el programa suministrado no declara área
profesional por curso. Ver `docs/context/ACTIVE_CONTEXT.md`.

| Símbolo | Significado | En uso en `data/courses.lisp` (2026-08-05) |
| ------- | ----------- | :---: |
| `software-engineering` | Ingeniería de software y desarrollo | ✅ |
| `mathematics` | Matemática general del plan | ✅ |
| `general-education` | Cursos de formación general y humanidades | ✅ |
| `databases` | Bases de datos | ✅ (agregado 2026-08-05) |
| `networks` | Redes y comunicaciones | ✅ (agregado 2026-08-05) |
| `cybersecurity` | Seguridad informática | ✅ (agregado 2026-08-05) |
| `data` | Datos, inteligencia de negocios, big data | ✅ (agregado 2026-08-05) |
| `infrastructure` | Sistemas operativos, servidores, electrónica | ✅ (agregado 2026-08-05) |
| `management` | Administración, gestión de proyectos, gobernanza | ✅ (agregado 2026-08-05) |
| `algorithms` | Algoritmos y estructuras de datos | ⬜ sin uso en el catálogo actual |
| `systems` | Sistemas operativos, redes y arquitectura | ⬜ sin uso en el catálogo actual |
| `data-science` | Datos, estadística y aprendizaje automático | ⬜ sin uso en el catálogo actual |
| `theory` | Fundamentos teóricos y matemática discreta | ⬜ sin uso en el catálogo actual |
| `security` | Seguridad informática | ⬜ sin uso; reemplazado por `cybersecurity` en el catálogo actual, se conserva por si un catálogo futuro lo necesita |

Las últimas cinco filas vienen del catálogo de demostración de 10 cursos de
la versión anterior (ya reemplazado por el catálogo real de 47). Se
conservan aquí para no borrar vocabulario ya definido; un catálogo futuro
puede volver a usarlas.

### Bloques electivos

Vocabulario cerrado para `elective-group` (`.ace/knowledge/entities.md`).
Dato oficial en cuanto a que el programa sí organiza las electivas en
estos tres bloques; los nombres simbólicos son una convención del equipo.

| Símbolo | Significado |
| ------- | ----------- |
| `sixth-term-elective` | Bloque electivo del sexto cuatrimestre (4 opciones) |
| `seventh-term-elective` | Bloque electivo del sétimo cuatrimestre (4 opciones) |
| `eighth-term-elective` | Bloque electivo del octavo cuatrimestre (4 opciones) |

### Días

`monday`, `tuesday`, `wednesday`, `thursday`, `friday`, `saturday`

### Franjas horarias

| Símbolo | Significado |
| ------- | ----------- |
| `morning` | Mañana |
| `afternoon` | Tarde |
| `evening` | Noche |

### Escalas

- **Dificultad:** entero de 1 (muy liviano) a 5 (muy exigente).
- **Tolerancia a dificultad:** entero de 1 a 5, mismo criterio.

---

## Términos que NO se usan

Para evitar ambigüedad, estos términos están prohibidos en el proyecto:

| No usar | Usar en su lugar | Razón |
| ------- | ---------------- | ----- |
| "materia" | curso | Consistencia con el catálogo |
| "nota", "calificación" | aprobado | No se modelan notas, solo aprobación |
| "score" para prioridad | prioridad (`priority`) | `score` se confunde con nota |
| "match" para recomendación | recomendación | `match` está tomado por el motor |
| "sugerir" | recomendar | Un solo verbo para la acción central |

---

## Referencias cruzadas

- `.ace/knowledge/entities.md` — relaciones y su forma exacta
- `.ace/knowledge/business-rules.md` — reglas del dominio
- `docs/adr/ADR-006-representacion-conocimiento.md` — decisión de representación

---

*Última actualización: 2026-08-05*
