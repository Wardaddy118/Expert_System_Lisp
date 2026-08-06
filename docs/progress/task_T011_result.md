# T011 — Estadísticas del catálogo

**Status:** verified
**Fecha:** 2026-08-05

`domain:catalog-statistics` calcula, sobre la memoria de trabajo de sesiones
ya corridas (BR-030), las cuatro métricas que pedía el objetivo:

| Métrica | Cómo se deriva |
| ------- | -------------- |
| Cursos más recomendados | Cuenta, por curso, en cuántos perfiles apareció recomendado |
| Cuellos de botella con `n` | Cuántos cursos distintos declaran cada curso como requisito (parte de catálogo de BR-006) |
| Dificultad promedio por área | Agrupa los hechos `area` y promedia su `difficulty` |
| Cobertura de reglas | Nombres en la traza contra `engine:*rules*`; reporta las que nunca dispararon |

Acepta una sesión suelta o una lista, y reporta `profiles-analyzed` para que
quien lea la salida sepa sobre cuántos perfiles se calculó. Con un solo perfil
(T013 sigue pendiente) "más recomendados" no compara nada todavía, y la salida
lo dice explícitamente en vez de aparentar un ranking.

Orden determinista en todas las listas (NFR-005): por cantidad descendente,
desempatando por código de curso ascendente, y las áreas alfabéticamente. No
depende del orden de iteración de las tablas hash.

## Hallazgo inmediato

La cobertura de reglas rindió apenas se ejecutó: **3 de las 25 reglas nunca
disparan** con el catálogo y el perfil actuales.

- `bottleneck-exception-to-tolerance`
- `priority-general-education`
- `recommended-via-general-education`

Hay que decidir, por cada una, si es conocimiento muerto que sobra o si son
los datos los que no la ejercitan. Las dos de `general-education` apuntan a lo
segundo: el perfil de demostración no está cerca de terminar la carrera. La
primera necesita un cuello de botella que exceda la tolerancia por un nivel, y
con solo 6 prerrequisitos provisionales eso no se da.

## Dos defectos encontrados y corregidos de paso

1. **La suite pasaba con 225 comprobaciones mientras `run.lisp` reventaba.**
   Ninguna prueba renderizaba el informe, así que un `~-32a` inválido (mincol
   negativo) solo aparecía al ejecutar la demo. Se agregó
   `tests/cli/format-tests.lisp`, que renderiza el informe completo a un
   string en memoria: un error de directiva `FORMAT` ya no puede pasar
   inadvertido.
2. **Tres líneas del informe pasaban de 80 columnas**, contra lo que pide
   FR-050. Dos ya venían de antes (lista de horarios disponibles, motivo de
   descarte por bloque electivo) y una era nueva. Se agregó `print-wrapped` en
   la capa de presentación y una prueba que verifica el ancho sobre el informe
   completo. La traza queda excluida a propósito: lista contenido de hechos de
   longitud variable y recortarla perdería información de la explicación.

## Verificación

```text
sh .ace/scripts/verify.sh   -> VERIFY_RESULT=pass gate=all
sbcl --script run-tests.lisp -> Did 235 checks. Pass: 235 (100%) Fail: 0
sbcl --script run.lisp       -> exit 0, seccion "ESTADISTICAS DEL CATALOGO" visible
```

La suite pasó de 182 a 235 comprobaciones (+53).

**Archivos:** `src/domain/stats.lisp`, `src/cli/format.lisp`,
`src/package.lisp` (exports, incluido `engine:rule-name` para la cobertura),
`tests/domain/stats-tests.lisp`, `tests/cli/format-tests.lisp`,
`expert-system.asd` (módulo `cli` en el sistema de pruebas).
