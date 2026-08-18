# Perfiles de demostración

Cinco perfiles de estudiante que se pueden cargar desde la CLI
(`sbcl --script run-interactive.lisp`, primera pregunta) o pasándolos a
`domain:run-session`.

| Archivo | Caso | Qué ejercita |
| ------- | ---- | ------------ |
| `sample-profile.lisp` | Segundo cuatrimestre en curso | Las **seis** razones de descarte en una sola corrida |
| `first-year.lisp` | Primer ingreso, sin aprobados | Caso borde del PRD; solo cursos sin requisitos son elegibles |
| `advanced.lisp` | Quinto cuatrimestre cumplido | Las dos reglas de **formación general** |
| `tight-schedule.lisp` | Trabaja: dos bloques libres | BR-003 a gran escala; el horario como filtro dominante |
| `low-tolerance.lisp` | Tolerancia baja a dificultad | La **excepción de BR-005**: cuello de botella que excede la tolerancia por un nivel |

## Por qué estos cinco y no otros cuatro

No son casos decorativos: entre los cinco tienen que hacer disparar **las 25
reglas** del dominio. Ese es el criterio de cierre de la decisión D-09
(`docs/context/PROJECT_CONTEXT.md`), y hay una prueba que lo verifica:
`the-demo-profiles-together-fire-every-rule`.

Antes de estos perfiles, tres reglas nunca disparaban:

| Regla | Por qué no disparaba | Perfil que la activa |
| ----- | -------------------- | -------------------- |
| `priority-general-education` | Los tres cursos de formación general del catálogo son **nocturnos**, y el perfil original excluía la noche a propósito para ejercitar el choque de horario | `advanced.lisp` |
| `recommended-via-general-education` | Misma causa | `advanced.lisp` |
| `bottleneck-exception-to-tolerance` | Necesita un cuello de botella cuya dificultad exceda la tolerancia por **exactamente** un nivel, y ningún perfil daba esa combinación | `low-tolerance.lisp` |

Las tres eran datos que no las ejercitaban, no conocimiento muerto. Por eso se
conservaron. Si en algún momento vuelve a fallar esa prueba, la salida dice
qué regla quedó sin disparar, y la decisión D-09 obliga a construirle un
perfil o a eliminarla — no a aflojar la prueba.

## Formato

Una property list leída con `read` y normalizada a hechos de perfil por
`src/domain/loader.lisp`:

```lisp
(:approved ("SC-115" "SC-202")
 :interests (software-engineering databases)
 :target-area software-engineering
 :available ((monday morning) (tuesday afternoon))
 :difficulty-tolerance 3
 :credit-limit 12)
```

Los vocabularios de áreas, días y franjas son cerrados: ver
`.ace/knowledge/glossary.md`. Un curso aprobado que no exista en el catálogo
se avisa y se ignora, no aborta la sesión.

## Advertencia sobre los datos

**Todos los campos de estos perfiles son provisionales.** La universidad no
suministra intereses, disponibilidad horaria, tolerancia ni tope de créditos
por estudiante: son invenciones del equipo para la demostración. Lo mismo vale
para los horarios y los prerrequisitos del catálogo contra los que se evalúan
(ver la cabecera de `data/courses.lisp` y la decisión D-10).
