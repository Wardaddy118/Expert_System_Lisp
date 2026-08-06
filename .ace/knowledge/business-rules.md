# Reglas del Dominio

> Conocimiento experto que el sistema codifica. Cada regla de este documento
> corresponde a una o más formas `defrule` en la base de conocimiento.
> **Este documento es la especificación; el código es la implementación.**
> Si divergen, gana este documento y el código es un defecto.

---

## Cómo usar este documento

1. Antes de escribir una `defrule`, buscar aquí la regla de negocio (BR-xxx).
2. Cada `defrule` lleva en su docstring el identificador BR que implementa.
3. Cada BR debe tener al menos una prueba que la dispare y una que verifique
   que no dispara cuando no corresponde.
4. Agregar conocimiento = agregar una BR aquí + su `defrule` + sus pruebas, en
   el mismo commit.

---

## Categorías

| Categoría | Significado |
| --------- | ----------- |
| **Dura** | Invariante. Violarla es un defecto del sistema. Nunca se puede relajar. |
| **Estándar** | Lógica normal de recomendación. Admite casos borde documentados. |
| **Blanda** | Heurística de priorización. Los pesos son ajustables. |

---

## Reglas de elegibilidad (duras)

### BR-001: Requisitos aprobados

- **Categoría:** Dura
- **Descripción:** Un curso solo es elegible si **todos** sus requisitos están
  aprobados por el estudiante.
- **Justificación:** Es una restricción real de matrícula. Recomendar un curso
  que el estudiante no puede llevar invalida todo el sistema.
- **Aplicación:** Regla que afirma `prerequisites-satisfied` solo cuando no
  existe ningún `prerequisite` del curso sin su `approved` correspondiente.
- **Excepciones:** Ninguna.
- **Ejemplo:**

  ```text
  Válido:   CI-2400 requiere CI-1201; el estudiante aprobó CI-1201 → elegible
  Inválido: CI-2400 requiere CI-1201; no lo aprobó → excluded, missing-prerequisites
  ```

### BR-002: No recomendar lo ya aprobado

- **Categoría:** Dura
- **Descripción:** Un curso con `(approved <id>)` nunca es elegible.
- **Justificación:** Trivial pero necesaria: sin ella el sistema recomienda
  repetir cursos ganados.
- **Aplicación:** Condición negativa en la regla de elegibilidad; también
  afirma `(excluded <id> already-approved)`.
- **Excepciones:** Ninguna.

### BR-003: Sin choque de horario

- **Categoría:** Dura
- **Descripción:** Un curso es elegible solo si **todos** sus bloques
  `schedule` están dentro de los bloques `available` del estudiante.
- **Justificación:** Un curso que el estudiante no puede atender no es una
  recomendación, es ruido.
- **Aplicación:** Regla que afirma `schedule-fits`.
- **Excepciones:** Ninguna. Si el estudiante quiere evaluar sin restricción de
  horario, declara todos los bloques como disponibles.
- **Ejemplo:**

  ```text
  Válido:   curso lunes-mañana y miércoles-mañana; el estudiante tiene ambos → schedule-fits
  Inválido: curso lunes-mañana y viernes-tarde; no tiene viernes-tarde → schedule-conflict
  ```

### BR-004: Tope de créditos

- **Categoría:** Dura
- **Descripción:** La suma de créditos de los cursos recomendados no puede
  exceder el `credit-limit` del estudiante.
- **Justificación:** Restricción de matrícula y de carga real.
- **Aplicación:** Al construir el conjunto final de recomendaciones se toman
  cursos en orden de prioridad descendente mientras quepan. Los que no caben
  se marcan `(excluded <id> credit-limit-exceeded)`, no se borran.
- **Excepciones:** Ninguna.
- **Nota de diseño:** Esta regla opera sobre el conjunto ya priorizado, no
  sobre cursos individuales. Se aplica después de la quiescencia del motor.

### BR-032: Límite de una electiva por bloque

- **Categoría:** Dura
- **Añadida:** 2026-08-05, al incorporar el catálogo real de 47 cursos del
  Bachillerato en Ingeniería en Sistemas de Computación (Fidélitas), que
  organiza 12 opciones electivas en tres bloques (`sixth-term-elective`,
  `seventh-term-elective`, `eighth-term-elective`) de los que el estudiante
  cursa solo una por bloque. Numerada fuera de secuencia respecto a su
  ubicación en este documento porque se agregó después de BR-001 a BR-031;
  se coloca aquí, junto a BR-004, por ser la misma clase de restricción.
- **Descripción:** De los cursos `recommended` que pertenecen a un mismo
  `elective-group`, no se puede recomendar más de uno.
- **Justificación:** Es una restricción real de matrícula: el plan de
  estudios exige elegir una sola materia por bloque electivo. Mostrar dos
  o más de un mismo bloque como recomendadas simultáneamente sería
  información engañosa, no una recomendación real.
- **Aplicación:** Igual que BR-004, opera sobre el conjunto ya priorizado
  y corre después de la quiescencia del motor (`apply-elective-group-limit`
  en `src/domain/knowledge.lisp`), no como `defrule`: comparar "cuál del
  grupo se queda" es una agregación sobre un conjunto de tamaño variable,
  la misma razón técnica que BR-004. De los cursos `recommended` de un
  bloque, se conserva el de mayor puntaje; el resto se marca
  `(excluded <id> elective-group-limit)`. Corre **antes** que BR-004, para
  no gastar presupuesto de créditos en una electiva que de todas formas se
  descartaría por venir del mismo bloque que otra mejor puntuada.
- **Excepciones:** Ninguna.
- **Nota:** Los tres grupos válidos y el tamaño esperado de cada uno (4
  opciones) se validan al cargar el catálogo, no en esta regla — ver
  `src/domain/loader.lisp` (`validate-elective-consistency`,
  `validate-elective-group-sizes`).

---

## Reglas de filtrado (estándar)

### BR-005: Tolerancia a la dificultad

- **Categoría:** Estándar
- **Descripción:** Un curso cuya `difficulty` excede la
  `difficulty-tolerance` del estudiante no se recomienda.
- **Justificación:** Recomendar cursos que sobrepasan lo que el estudiante
  declaró tolerar produce sobrecarga y reprobación.
- **Aplicación:** Regla que afirma `within-tolerance`; en caso contrario
  `(excluded <id> too-difficult)`.
- **Excepciones:** Un curso cuello de botella (BR-006) que exceda la
  tolerancia **por un solo nivel** sí se recomienda, marcado como advertencia
  en la explicación. Atrasarlo cuesta más que llevarlo.
- **Ejemplo:**

  ```text
  Válido:   tolerancia 3, curso dificultad 3 → within-tolerance
  Inválido: tolerancia 3, curso dificultad 5 → too-difficult
  Excepción: tolerancia 3, curso dificultad 4 y es cuello de botella → se recomienda con advertencia
  ```

---

## Reglas de priorización (blandas)

Los pesos son heurísticos y ajustables. Los valores iniciales están abajo; si
se cambian, se actualiza esta tabla en el mismo commit.

| Regla | Condición | Puntos |
| ----- | --------- | ------ |
| BR-010 | El área del curso es el `target-area` | +10 |
| BR-011 | El área del curso está entre los `interest` | +5 |
| BR-012 | El curso es cuello de botella (BR-006) | +8 |
| BR-013 | El curso desbloquea al menos un curso del `target-area` | +4 |
| BR-014 | La dificultad está muy por debajo de la tolerancia (≥2 niveles) | −2 |
| BR-015 | El curso es de `general-education` y quedan pocos por llevar | +3 |

### BR-006: Cuello de botella

- **Categoría:** Estándar
- **Descripción:** Un curso es cuello de botella si es requisito de **3 o más**
  cursos del catálogo.
- **Justificación:** Atrasar un cuello de botella bloquea buena parte del plan
  de estudios. Es el conocimiento experto más valioso que el sistema aporta:
  un estudiante rara vez ve esto por su cuenta.
- **Aplicación:** Regla que cuenta los `prerequisite` que apuntan al curso y
  afirma `(bottleneck <id> <n>)` cuando `n ≥ 3`.
- **Excepciones:** El umbral 3 es ajustable; se documenta aquí si cambia.

### BR-007: De elegible a recomendado

- **Categoría:** Estándar
- **Descripción:** Un curso pasa a `recommended` si es `eligible`,
  `within-tolerance` (o la excepción de BR-005 aplica) y tiene `priority`
  acumulada mayor que cero.
- **Justificación:** Un curso elegible pero sin ninguna afinidad no aporta
  nada a la decisión; llenaría la lista de ruido.
- **Excepciones:** Si ningún curso alcanza prioridad positiva, se recomiendan
  los elegibles de mayor prioridad de todas formas, con una nota explícita de
  que no hubo coincidencia de intereses. Es preferible a devolver una lista
  vacía.

### BR-008: Una sola electiva por bloque

- **Categoría:** Dura
- **Descripción:** De los cursos `recommended` que comparten el mismo
  `elective-group`, solo se conserva el de mayor prioridad acumulada. El resto
  se marca `(excluded <id> elective-group-limit)`.
- **Justificación:** El plan de estudios ofrece cada bloque electivo como un
  menú de opciones del que el estudiante escoge **una**. Recomendar dos
  electivas del mismo bloque propone algo que la matrícula no permite, igual
  que recomendar un curso sin sus requisitos.
- **Aplicación:** `apply-elective-group-limit` en `src/domain/knowledge.lisp`.
  Es **post-procesamiento después de la quiescencia**, no una `defrule`, por
  la misma razón que BR-004: comparar entre sí un conjunto de tamaño variable
  no se expresa con condiciones de aridad fija.
- **Orden:** corre **antes** que `apply-credit-limit` (BR-004), para no gastar
  presupuesto de créditos en una electiva que igual se descartaría por venir
  del mismo bloque que otra mejor puntuada.
- **Excepciones:** Ninguna.
- **Ejemplo:**

  ```text
  Válido:   bloque 3 con SC-801 (prioridad 18) y SC-802 (prioridad 12)
            → se recomienda SC-801; SC-802 queda excluded, elective-group-limit
  Inválido: recomendar SC-801 y SC-802 juntos: el estudiante solo lleva una
  ```

> **Nota de trazabilidad:** esta regla se implementó durante la sesión de
> implementación (commit `19c680a`) y funcionaba antes de estar especificada
> aquí. Se documenta ahora para cerrar esa deuda. El orden correcto es el
> inverso: primero el BR, después la implementación.

---

## Reglas de explicación (duras)

### BR-020: Toda recomendación se explica

- **Categoría:** Dura
- **Descripción:** Todo hecho `(recommended <id>)` debe tener al menos una
  entrada en la traza que lo justifique.
- **Justificación:** Es el requisito diferenciador del sistema experto
  (FR-030). Una recomendación sin explicación es indistinguible de un filtro.
- **Aplicación:** Prueba automatizada sobre todos los perfiles de ejemplo:
  ninguna recomendación puede tener explicación vacía.
- **Excepciones:** Ninguna.

### BR-021: Toda exclusión se explica

- **Categoría:** Estándar
- **Descripción:** Cuando un curso se descarta, se afirma
  `(excluded <id> <razón>)` con una razón del vocabulario cerrado.
- **Justificación:** Sostiene el caso borde "ningún curso pasa los filtros":
  el sistema puede decir qué filtro eliminó qué en lugar de callar.

---

## Reglas de estadísticas

### BR-030: Las estadísticas se derivan de la memoria de trabajo

- **Categoría:** Dura
- **Descripción:** Toda estadística (FR-040, FR-041) se calcula sobre los
  hechos de la memoria de trabajo tras la quiescencia, no con consultas
  separadas al catálogo.
- **Justificación:** Si las estadísticas se calculan por otra vía pueden
  contradecir lo que el motor concluyó. Una sola fuente de verdad por sesión.
- **Excepciones:** Ninguna.

### BR-031: Avance de carrera

- **Categoría:** Estándar
- **Descripción:** El avance es la suma de créditos de los cursos `approved`
  dividida entre la suma de créditos de todos los `course` del catálogo.
- **Nota:** Como el catálogo es un subconjunto del plan real (D-03), el avance
  es relativo al catálogo modelado. La salida debe decirlo explícitamente para
  no inducir a error.

---

## Agregar una regla nueva

1. Definirla aquí con un identificador BR libre, categoría y justificación.
2. Escribir la `defrule` correspondiente, citando el BR en su docstring.
3. Escribir dos pruebas: una que la dispare, otra que verifique que no dispara
   cuando no corresponde.
4. Si la regla cambia el modelo de datos, actualizar
   `.ace/knowledge/entities.md` y abrir un ADR.

**Nunca** se agrega conocimiento modificando el motor. Si una regla no se puede
expresar con `defrule`, el problema es el diseño de la regla o una carencia
real del motor — y en el segundo caso corresponde un ADR, no un parche.

---

## Lista de verificación

```markdown
- [ ] La regla está documentada aquí con su BR
- [ ] Existe la defrule que la implementa, citando el BR
- [ ] Hay prueba de disparo y prueba de no-disparo
- [ ] Los símbolos usados están en el glosario
- [ ] Las relaciones usadas están en entities.md
- [ ] No se modificó el motor para acomodarla
```

---

## Referencias cruzadas

- `.ace/knowledge/entities.md` — relaciones disponibles
- `.ace/knowledge/glossary.md` — vocabulario cerrado
- `docs/adr/ADR-005-motor-inferencia.md` — cómo se ejecutan estas reglas
- `docs/requirements/PRD-recomendador-academico.md` — requisitos que originan estas reglas

---

*Última actualización: 2026-08-05*
*Modificar una regla dura requiere aprobación del equipo*
