# T012 — CLI de sesión completa

**Status:** verified
**Fecha:** 2026-08-06

La sesión ahora se puede conducir por consola. `cli:start-interactive`
pregunta los seis campos del perfil, corre el motor, presenta el informe y
deja consultar cursos puntuales.

```bash
sbcl --script run-interactive.lisp   # sesion que pregunta
sbcl --script run.lisp               # demostracion con perfil fijo
```

## Cómo quedó separado

`run.lisp` **no** se volvió interactivo, a propósito: es la demostración
reproducible y es lo que corre el gate de verificación. Un gate que se queda
esperando que alguien teclee no es un gate. La sesión interactiva vive en
`run-interactive.lisp`.

En el dominio hizo falta separar dos cosas que estaban pegadas:

| Antes | Ahora |
| ----- | ----- |
| `load-profile` leía el archivo y afirmaba los hechos | `load-profile` lee; `assert-profile` afirma desde una property list |
| `run-session` cargaba, corría e infería | `run-session` (archivo), `run-session-with-profile` (perfil en memoria), `infer-session` (común a ambas) |

Sin esa separación la CLI no habría podido armar un perfil sin escribirlo
antes a disco.

## Probable sin E/S real

El objetivo de la tarea pedía que la lógica de sesión fuera probable sin E/S
real. Se cumple porque **todas** las funciones de captura reciben los streams
como argumentos y ninguna toca `*standard-input*` por dentro:

```lisp
(with-input-from-string (in "SC-115 SC-202
1
1
...")
  (cli::capture-profile wm in out))
```

13 pruebas nuevas en `tests/cli/session-tests.lisp` cubren: perfil utilizable
por el dominio, primer ingreso sin aprobados, códigos inexistentes ignorados
con aviso, códigos en minúscula normalizados, valores por omisión al acabarse
la entrada, tolerancia fuera de rango repreguntada, producto días × franjas,
varios intereses, área objetivo única, y las tres respuestas de la consulta
por curso.

## Decisiones de la captura

- **La disponibilidad se pregunta como días y franjas por separado**, y el
  sistema arma el producto. Pedir los treinta bloques uno por uno era
  insufrible y nadie lo iba a contestar bien.
- **Las opciones salen del catálogo**, no de una lista escrita a mano: las
  áreas y los días que se ofrecen son los que existen en `data/courses.lisp`.
  Si el catálogo cambia, las preguntas cambian solas.
- **EOF no es error.** Al acabarse la entrada cada pregunta toma su valor por
  omisión. Sin eso, correr la CLI con la entrada redirigida se colgaba o
  reventaba con una traza cruda.
- **La consulta responde también por los descartados.** Saber por qué *no*
  salió un curso suele importarle más al estudiante que por qué sí.

## Verificación

```text
sh .ace/scripts/verify.sh     -> VERIFY_RESULT=pass gate=all
sbcl --script run-tests.lisp  -> Did 255 checks. Pass: 255 (100%) Fail: 0
sbcl --script run.lisp        -> exit 0 (demostracion fija, sin cambios)
printf '...' | sbcl --script run-interactive.lisp -> exit 0, perfil capturado
```

Suite: 235 → 255 comprobaciones (+20).

**Archivos:** `src/cli/prompt.lisp` (nuevo), `src/cli/session.lisp`,
`src/cli/format.lisp`, `src/domain/loader.lisp`, `src/domain/knowledge.lisp`,
`src/main.lisp`, `src/package.lisp`, `run-interactive.lisp` (nuevo),
`tests/cli/session-tests.lisp` (nuevo), `expert-system.asd`.
