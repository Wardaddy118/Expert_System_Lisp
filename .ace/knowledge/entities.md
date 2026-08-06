# Entidades del Dominio

> Catálogo canónico de las **relaciones** que pueden existir en la memoria de
> trabajo. Es la fuente de verdad del modelo de datos del sistema experto.
> Toda relación usada en `data/`, en una regla o en el motor debe estar aquí.

---

## Cómo usar este documento

1. Antes de inventar un hecho nuevo, buscarlo en estas tablas.
2. Respetar la aridad y el orden de los argumentos exactamente.
3. Respetar la capa: quién puede afirmar cada relación (ver abajo).
4. Agregar una relación exige actualizar este archivo y, si cambia el modelo,
   un ADR.

---

## Las tres capas

El modelo distingue tres orígenes de hechos. **No hay marca en el hecho**: la
distinción está en qué relación se usa. Esta disciplina es lo que hace que la
traza de inferencia sea legible (ADR-006).

| Capa | Quién la afirma | Relaciones |
| ---- | --------------- | ---------- |
| **Catálogo** | El cargador de `data/courses.lisp` | `course`, `course-name`, `term`, `laboratory`, `collegiate`, `elective`, `credits`, `area`, `difficulty`, `prerequisite`, `schedule` |
| **Perfil** | La CLI o el cargador de `data/profiles/` | `approved`, `interest`, `target-area`, `available`, `difficulty-tolerance`, `credit-limit` |
| **Derivada** | Únicamente el motor, al disparar reglas | `prerequisites-satisfied`, `schedule-fits`, `within-tolerance`, `eligible`, `area-match`, `interest-match`, `bottleneck`, `priority`, `recommended`, `excluded` |

**Invariante:** ninguna regla debe afirmar una relación de catálogo o de
perfil. Si una regla necesita hacerlo, el modelo está mal y hay que revisar
este documento antes de escribir código.

---

## Capa de catálogo

### `(course <id>)`

Declara la existencia de un curso.

- `<id>` — string, código del curso, p. ej. `"CI-2400"`.
- Único por curso. Duplicados son error de datos.

### `(course-name <id> <nombre>)`

- `<nombre>` — string legible, p. ej. `"Estructuras de Datos"`.
- Solo para presentación. Ninguna regla debe condicionar sobre el nombre.

### `(term <id> <n>)`

- `<n>` — entero, cuatrimestre del plan (1–8 en el catálogo actual).
- Dato oficial del programa académico. Todo curso tiene exactamente uno.

### `(laboratory <id>)`

- Sin argumentos además del curso. Presente solo si el curso tiene
  laboratorio; **no existe** un hecho `(laboratory <id> nil)` para los que
  no lo tienen — sin negación en los hechos (regla de modelado 4, abajo).
- Dato oficial del programa académico.

### `(collegiate <id>)`

- Igual forma que `laboratory`: presente solo si el curso es "colegiado".
- Dato oficial del programa académico.

### `(elective <id> <grupo>)`

- `<grupo>` — símbolo del vocabulario cerrado de bloques electivos
  (`.ace/knowledge/glossary.md`): `sixth-term-elective`,
  `seventh-term-elective` u `eighth-term-elective` en el catálogo actual.
- Presente solo si el curso es electivo. Un curso no electivo no tiene
  este hecho.
- Dato oficial del programa académico (a qué bloque pertenece cada
  electiva); el nombre simbólico de cada grupo es una convención del
  equipo, no una cita textual del programa.

### `(credits <id> <n>)`

- `<n>` — entero positivo.
- **Provisional en el catálogo actual:** el programa no declara créditos;
  todos los cursos usan un valor uniforme de 4. Ver la cabecera de
  `data/courses.lisp`.

### `(area <id> <área>)`

- `<área>` — símbolo del vocabulario cerrado del glosario.
- Un curso tiene exactamente un área.
- **Provisional en el catálogo actual:** inferida por el equipo a partir
  del nombre de cada curso, no es una clasificación de la universidad.

### `(difficulty <id> <n>)`

- `<n>` — entero 1–5, asignado por criterio experto.
- **Provisional en el catálogo actual:** fórmula por cuatrimestre más 1 si
  el curso tiene laboratorio (tope 5), documentada en la cabecera de
  `data/courses.lisp`. No es un criterio validado con el equipo docente.

### `(prerequisite <id> <id-requisito>)`

- **Un hecho por cada requisito.** Un curso con tres requisitos genera tres
  hechos. No se agrupan en listas (ADR-006, alternativa 3 rechazada).
- `<id-requisito>` debe existir como `course`. Referencias colgantes son error
  de datos.
- El grafo debe ser acíclico. Se valida al cargar.
- **Provisional en el catálogo actual:** el programa no declara ningún
  prerrequisito oficial. Solo existen 6 enlaces de demostración
  (`data/courses.lisp`, cabecera), suficientes para que BR-001 y BR-006
  tengan algo que evaluar. `bottleneck` calculado sobre estos enlaces es
  un ejemplo, no una conclusión sobre el plan real.

### `(schedule <id> <día> <franja>)`

- **Un hecho por bloque.** Un curso que se imparte lunes y miércoles en la
  mañana genera dos hechos.
- `<día>` y `<franja>` — símbolos del vocabulario cerrado.
- **Provisional en el catálogo actual:** un bloque único por curso,
  asignado por rotación solo para que BR-003 tenga algo que evaluar. No es
  el horario real de ningún grupo.

---

## Capa de perfil

### `(approved <id>)`

Curso que el estudiante ya aprobó.

- Si `<id>` no existe en el catálogo: advertencia, se ignora, no se aborta
  (caso borde del PRD).

### `(interest <área>)`

Área que le atrae al estudiante. Puede haber varios hechos.

### `(target-area <área>)`

Área profesional objetivo. **Exactamente uno** por perfil.

### `(available <día> <franja>)`

Bloque en que el estudiante puede llevar clases. Varios hechos.

### `(difficulty-tolerance <n>)`

- `<n>` — entero 1–5. Exactamente uno por perfil.

### `(credit-limit <n>)`

- `<n>` — entero positivo, tope de créditos del semestre. Exactamente uno.

---

## Capa derivada

Solo el motor produce estos hechos, al disparar reglas.

### `(prerequisites-satisfied <id>)`

Todos los requisitos de `<id>` están aprobados. Un curso sin requisitos lo
satisface trivialmente.

### `(schedule-fits <id>)`

Todos los bloques de `<id>` caen dentro de la disponibilidad declarada.

### `(within-tolerance <id>)`

La dificultad de `<id>` no excede la tolerancia del estudiante.

### `(eligible <id>)`

El estudiante puede llevar `<id>`: requisitos satisfechos, no aprobado, y el
horario calza. Ver BR-001 a BR-003.

### `(area-match <id>)`

El área de `<id>` coincide con el `target-area` del estudiante.

### `(interest-match <id>)`

El área de `<id>` coincide con algún `interest` declarado.

### `(bottleneck <id> <n>)`

`<id>` es requisito de `<n>` cursos, con `<n>` sobre el umbral definido en
BR-006.

### `(priority <id> <n>)`

Puntaje acumulado de `<id>`.

- **Acumulativo:** varias reglas pueden aportar. El puntaje final es la suma
  de los `priority` afirmados para ese curso.
- Se modela así para que la explicación pueda decir "sumó 10 por el área
  objetivo y 5 por ser cuello de botella", en vez de mostrar un número opaco.

### `(recommended <id>)`

`<id>` se le presenta al estudiante. Ver BR-007 y BR-004.

### `(excluded <id> <razón>)`

`<id>` fue descartado, con `<razón>` como símbolo: `already-approved`,
`missing-prerequisites`, `schedule-conflict`, `too-difficult`,
`credit-limit-exceeded`, `elective-group-limit` (BR-032, agregada
2026-08-05: otra electiva del mismo bloque quedó con mejor puntaje).

Existe para el caso borde "ningún curso pasa los filtros": permite decir cuál
filtro eliminó qué, en lugar de devolver una lista vacía sin explicación.

---

## Diagrama de dependencias entre relaciones

```text
  CATÁLOGO                    PERFIL
  course                      approved
  credits                     interest
  area                        target-area
  difficulty                  available
  prerequisite                difficulty-tolerance
  schedule                    credit-limit
     │                           │
     └─────────────┬─────────────┘
                   ▼
        prerequisites-satisfied
        schedule-fits
        within-tolerance
                   │
                   ▼
               eligible ──────────► excluded
                   │
     ┌─────────────┼─────────────┐
     ▼             ▼             ▼
 area-match   interest-match  bottleneck
     └─────────────┼─────────────┘
                   ▼
               priority
                   │
                   ▼
              recommended
```

---

## Reglas de modelado

1. **Aridad fija.** Una relación tiene siempre el mismo número de argumentos.
2. **Sin anidamiento.** Ningún argumento es una lista. Se repite el hecho.
3. **Identificadores string, categorías símbolo.** Los códigos de curso se
   comparan con `equal`; las categorías con `eq`.
4. **Sin negación en los hechos.** No existe `(not-approved ?id)`. La ausencia
   se expresa en las condiciones de las reglas, no en la memoria de trabajo.
5. **Una relación, un significado.** Si hace falta un matiz nuevo, se agrega
   una relación, no un argumento extra a una existente.

---

## Referencias cruzadas

- `.ace/knowledge/glossary.md` — vocabulario cerrado de símbolos
- `.ace/knowledge/business-rules.md` — reglas que producen la capa derivada
- `docs/adr/ADR-006-representacion-conocimiento.md` — decisión y alternativas

---

*Última actualización: 2026-08-05*
